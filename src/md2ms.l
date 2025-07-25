%{
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "util.h"

#define FLAG_BREAK_FRONT_PAGE 0x2
#define FLAG_NO_DATE_DISPLAY 0x4

typedef enum {
	PRE_TL,
	PRE_SH1,
	PRE_SH2,
	PRE_SH3,
	PRE_SH4,
	PRE_SH5,
	PRE_IP,
	SUR_BI,
	SUR_B,
	SUR_I,
	SUR_UL,
	SUR_M,
	SUR_MULTILINE_M,
} MSTag;

typedef struct {
	FILE *input;
	FILE *output;
	char *title;
	char *author;
	uint8_t flags;
} md2roff_args_t;

void do_link(char *);
void do_pre(char *, MSTag);
void do_surround(char *, MSTag);
int escape(char c);
int parse_args(int, char **);
void print_head(void);
void surround_multiline(const char *, char *, int);
void usage(char *argv0);

md2roff_args_t args;
char codeblock_buf[65536];
size_t codeblock_len = 0;
int in_codeblock = 0;
%}

%option noyywrap
%option yylineno
%option no
STRING [a-zA-Z0-9!@#$%^&\:(),.?/\\\-<>|\{\}\[\]\"\'* \t]
SPACE [ \t]+
%x CODEBLOCK
%%
"```"[^\n]*\n    {
    if (!in_codeblock) {
        codeblock_len = 0;
        in_codeblock = 1;
        codeblock_buf[0] = '\0';
        BEGIN(CODEBLOCK);
    }
}

<CODEBLOCK>{
    "```"[^\n]*\n   {
        // End of code block
        BEGIN(INITIAL);
        codeblock_buf[codeblock_len] = '\0';
        fprintf(args.output, ".IP\n.DS L\n.ft C\n%s\n.ft\n.PP", codeblock_buf);
        in_codeblock = 0;
    }
    ^([^\n]*\n) {
        if (codeblock_len + yyleng < sizeof(codeblock_buf) - 1) {
            memcpy(codeblock_buf + codeblock_len, yytext, yyleng);
            codeblock_len += yyleng;
        }
    }
    . {
        if (codeblock_len + yyleng < sizeof(codeblock_buf) - 1) {
            memcpy(codeblock_buf + codeblock_len, yytext, yyleng);
            codeblock_len += yyleng;
        }
    }
}
"["{STRING}+"]("{STRING}+")"{STRING} { do_link(yytext); }
"# "{STRING}+"\n" { do_pre(yytext, PRE_SH1); }
"## "{STRING}+"\n" { do_pre(yytext, PRE_SH2); }
"### "{STRING}+"\n" { do_pre(yytext, PRE_SH3); }
"#### "{STRING}+"\n" { do_pre(yytext, PRE_SH4); }
"##### "{STRING}+"\n" { do_pre(yytext, PRE_SH5); }
"\n* " { do_pre(yytext, PRE_IP); }
"\n- " { do_pre(yytext, PRE_IP); }
"***"{STRING}+"***" { do_surround(yytext, SUR_BI); }
"**"{STRING}+"**" { do_surround(yytext, SUR_B); }
"*"{STRING}+"*" { do_surround(yytext, SUR_I); }
"__"{STRING}+"__" { do_surround(yytext, SUR_UL); }
"`"{STRING}+"`" { do_surround(yytext, SUR_M); }
"\n\n" { fprintf(args.output, "\n.PP\n"); }
"." { fprintf(args.output, "\\."); }
%%

void do_link(char *text) {
    char *text_start = text + 1;
    char *text_end = strchr(text_start, ']');
    *text_end = '\0';

    char *url_start = text_end+2;
    char *url_end = strchr(url_start, ')');
    *url_end = '\0';

    char *after_url = url_end + 1;
    fprintf(args.output, "\n.pdfhref W -D %s -- %s\n", url_start, text_start);
    if (*after_url != '\0' && *after_url != '\n' && *after_url != ' ' && *after_url != '\t') {
        if (escape(*after_url)) {
            fprintf(args.output, "\\%s", after_url);
        } else {
            fprintf(args.output, "%s", after_url);
        }
    }

}

int escape(char c) {
    char escaped_chars[] = {'\\', '\n', '\t', '.'};
    for (int i = 0; i < sizeof(escaped_chars); i++) {
        if (c == escaped_chars[i]) {
            return 1;
        }
    }
    return 0;
}

void do_pre(char *text, MSTag type) {
	switch (type) {
		case PRE_SH1: fprintf(args.output, "\n.NH 1\n%s\n.PP", strip_whitespace(&text[2])); break;
		case PRE_SH2: fprintf(args.output, "\n.NH 2\n%s\n.PP", strip_whitespace(&text[3])); break;
		case PRE_SH3: fprintf(args.output, "\n.NH 3\n%s\n.PP", strip_whitespace(&text[4])); break;
		case PRE_SH4: fprintf(args.output, "\n.NH 4\n%s\n.PP", strip_whitespace(&text[5])); break;
		case PRE_SH5: fprintf(args.output, "\n.NH 5\n%s\n.PP", strip_whitespace(&text[6])); break;
		case PRE_IP:  fprintf(args.output, "\n.IP - \n"); break;
	}
}

void do_surround(char *text, MSTag type) {
	switch (type) {
		case SUR_BI: fprintf(args.output, "\\fB\\fI%s\\fR", strip_surround(text, 3)); break;
		case SUR_B: fprintf(args.output, "\\fB%s\\fR", strip_surround(text, 2)); break;
		case SUR_I: fprintf(args.output, "\\fI%s\\fR", strip_surround(text, 1)); break;
		case SUR_UL: fprintf(args.output, ".UL\n%s\n.R", strip_surround(text, 2)); break;
		case SUR_M: fprintf(args.output, "\\fC%s\\fR", strip_surround(text, 1)); break;
	}
}

void surround_multiline(const char *fmt, char *text, int count) {
    for (int i = count; i < strlen(text) - count; i++) {
        if (text[i] == '\n') {
            fprintf(args.output, fmt, strip_surround(&text[i+1], count));
        }
    }
}

int parse_args(int argc, char **argv) {
	int opt;
	while ((opt = getopt(argc, argv, "a:bno:pt:")) != -1) {
		switch (opt) {
			case 'b': args.flags |= FLAG_BREAK_FRONT_PAGE; break;
			case 'n': args.flags |= FLAG_NO_DATE_DISPLAY; break;
			case 'o': args.output = open_file(argv[optind], "w"); break;
			case 't': args.title = optarg; break;
			case 'a': args.author = optarg; break;
			default: usage(argv[0]); return 0;
		}
	}

	if (optind < argc) {
		args.input = open_file(argv[optind], "r");
	}
	return 1;
}

void print_head() {
	fprintf(args.output, ".fp 8 CW\n");
	if (args.flags & FLAG_BREAK_FRONT_PAGE) {
		fprintf(args.output, ".RP no\n");
	}
	if (args.flags & FLAG_NO_DATE_DISPLAY) {
		fprintf(args.output, ".ND \"\"\n");
	}
	if (args.title) {
		fprintf(args.output, ".TL \n%s\n", args.title);
	}
	if (args.author) {
		fprintf(args.output, ".AU\n%s\n", args.title);
	}
}

void usage(char *argv0) {
	fprintf(stderr, "Usage: %s [-bn] [-t title] [-a author] [-o outputfile] [inputfile]\n", argv0);
}

int main(int argc, char *argv[]) {
	yyin = stdin;
	args.input = stdin;
	args.output = stdout;
	args.flags = 0;

	if (parse_args(argc, argv)) {
		print_head();
		yyin = args.input;
		yylex();
	}

	if (args.input != stdin) {
		fclose(args.input);
	}
	if (args.output != stdout) {
		fclose(args.output);
	}
	return 0;
}
