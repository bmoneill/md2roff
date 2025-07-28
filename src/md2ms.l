%{
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "util.h"

#define FLAG_FIRST_HEADER_TITLE 0x1
#define FLAG_BREAK_FRONT_PAGE 0x2
#define FLAG_NO_DATE_DISPLAY 0x4

typedef enum {
	PRE_TL,
	PRE_SH1,
	PRE_SH2,
	PRE_SH3,
	PRE_SH4,
	PRE_SH5,
	PRE_IP_BULLET,
	PRE_IP_DASH,
	SUR_BI,
	SUR_B,
	SUR_I,
	SUR_M,
	SUR_MULTILINE_M,
} MSTag;

void do_link(char *);
void do_pre(char *, MSTag);
void do_surround(char *, MSTag);
int escape(char c);
int parse_args(int, char **);
void print_head(void);
void surround_multiline(const char *, char *, int);
void usage(char *argv0);

bool first_header_parsed = false;
%}

%option noyywrap
%option yylineno
%option no
STRING [a-zA-Z0-9!@#$%^&\:(),.?/\\\-<>|\{\}\[\]\"\'* \t]
SPACE [ \t]+
%x CODEBLOCK
%%
"```"[^\n]*\n    {
    if (!codeblock.active) {
        codeblock.length = 0;
        codeblock.active = true;
        codeblock.buffer[0] = '\0';
        BEGIN(CODEBLOCK);
    }
}

<CODEBLOCK>{
    "```"[^\n]*\n   {
        // End of code block
        BEGIN(INITIAL);
        codeblock.buffer[codeblock.length] = '\0';
        fprintf(args.output, ".IP\n.DS L\n.ft C\n%s\n.ft\n.PP", codeblock.buffer);
        codeblock.active = false;
    }
    ^([^\n]*\n) {
        if (codeblock.length + yyleng < sizeof(codeblock.buffer) - 1) {
            memcpy(codeblock.buffer + codeblock.length, yytext, yyleng);
            codeblock.length += yyleng;
        }
    }
    . {
        if (codeblock.length + yyleng < sizeof(codeblock.buffer) - 1) {
            memcpy(codeblock.buffer + codeblock.length, yytext, yyleng);
            codeblock.length += yyleng;
        }
    }
}
"["{STRING}+"]("{STRING}+")"{STRING} { do_link(yytext); }
"# "{STRING}+"\n"                    { do_pre(yytext, PRE_SH1); }
"## "{STRING}+"\n"                   { do_pre(yytext, PRE_SH2); }
"### "{STRING}+"\n"                  { do_pre(yytext, PRE_SH3); }
"#### "{STRING}+"\n"                 { do_pre(yytext, PRE_SH4); }
"##### "{STRING}+"\n"                { do_pre(yytext, PRE_SH5); }
"\n* "                               { do_pre(yytext, PRE_IP_BULLET); }
"\n- "                               { do_pre(yytext, PRE_IP_DASH); }
"***"{STRING}+"***"                  { do_surround(yytext, SUR_BI); }
"**"{STRING}+"**"                    { do_surround(yytext, SUR_B); }
"*"{STRING}+"*"                      { do_surround(yytext, SUR_I); }
"__"{STRING}+"__"                    { do_surround(yytext, SUR_B); }
"`"{STRING}+"`"                      { do_surround(yytext, SUR_M); }
"\n\n"                               { PRINT_OUTPUT("\n.PP\n"); }
"."                                  { PRINT_OUTPUT("\\."); }
%%

void do_link(char *text) {
    char *text_start = text + 1;
    char *text_end = strchr(text_start, ']');
    *text_end = '\0';

    char *url_start = text_end+2;
    char *url_end = strchr(url_start, ')');
    *url_end = '\0';

    char *after_url = url_end + 1;
    PRINT_OUTPUT("\n.pdfhref W -D %s -- %s\n", url_start, text_start);
    if (*after_url != '\0' && *after_url != '\n' && *after_url != ' ' && *after_url != '\t') {
        if (escape(*after_url)) {
            PRINT_OUTPUT("\\%s", after_url);
        } else {
            PRINT_OUTPUT("%s", after_url);
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
		case PRE_SH1:
            if (args.flags & FLAG_FIRST_HEADER_TITLE && !first_header_parsed) {
                fprintf(args.output, ".TL\n%s\n.PP\n", strip_whitespace(&text[2]));
                first_header_parsed = 1;
            } else {
                PRINT_OUTPUT("\n.NH 1\n%s\n.PP", strip_whitespace(&text[2]));
            }
            break;
		case PRE_SH2:       PRINT_OUTPUT("\n.NH 2\n%s\n.PP", strip_whitespace(&text[3])); break;
		case PRE_SH3:       PRINT_OUTPUT("\n.NH 3\n%s\n.PP", strip_whitespace(&text[4])); break;
		case PRE_SH4:       PRINT_OUTPUT("\n.NH 4\n%s\n.PP", strip_whitespace(&text[5])); break;
		case PRE_SH5:       PRINT_OUTPUT("\n.NH 5\n%s\n.PP", strip_whitespace(&text[6])); break;
		case PRE_IP_BULLET: PRINT_OUTPUT("\n.IP \\(bu \n");                               break;
		case PRE_IP_DASH:   PRINT_OUTPUT("\n.IP - \n");                                   break;
	}
}

void do_surround(char *text, MSTag type) {
	switch (type) {
		case SUR_BI: PRINT_OUTPUT("\\fB\\fI%s\\fR", strip_surround(text, 3)); break;
		case SUR_B:  PRINT_OUTPUT("\\fB%s\\fR", strip_surround(text, 2));     break;
		case SUR_I:  PRINT_OUTPUT("\\fI%s\\fR", strip_surround(text, 1));     break;
		case SUR_M:  PRINT_OUTPUT("\\fC%s\\fR", strip_surround(text, 1));     break;
	}
}

void surround_multiline(const char *fmt, char *text, int count) {
    for (int i = count; i < strlen(text) - count; i++) {
        if (text[i] == '\n') {
            PRINT_OUTPUT(fmt, strip_surround(&text[i+1], count));
        }
    }
}

int parse_args(int argc, char **argv) {
	int opt;
	while ((opt = getopt(argc, argv, "a:bno:pt:T")) != -1) {
		switch (opt) {
			case 'b': args.flags |= FLAG_BREAK_FRONT_PAGE;        break;
			case 'n': args.flags |= FLAG_NO_DATE_DISPLAY;         break;
            case 'T': args.flags |= FLAG_FIRST_HEADER_TITLE;      break;
			case 'o': args.output = open_file(argv[optind], "w"); break;
			case 't': args.title = optarg;                        break;
			case 'a': args.author = optarg;                       break;
			default: usage(argv[0]);                              return 0;
		}
	}

	if (optind < argc) {
		args.input = open_file(argv[optind], "r");
	}
	return 1;
}

void print_head() {
		PRINT_OUTPUT(".fp 8 CW\n");
	if (args.flags & FLAG_BREAK_FRONT_PAGE) {
		PRINT_OUTPUT(".RP no\n");
	}
	if (args.flags & FLAG_NO_DATE_DISPLAY) {
		PRINT_OUTPUT(".ND \"\"\n");
	}
	if (args.title) {
		PRINT_OUTPUT(".TL \n%s\n", args.title);
	}
	if (args.author) {
		PRINT_OUTPUT(".AU\n%s\n", args.author);
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
