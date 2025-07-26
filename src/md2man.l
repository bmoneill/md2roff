%{
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "util.h"

typedef enum {
	PRE_SH1 = 1,
	PRE_SH2,
	PRE_SH3,
	PRE_SH4,
	PRE_SH5,
	PRE_IP,
	SUR_BI,
	SUR_B,
	SUR_I,
	SUR_UL,
	SUR_M
} ManTag;

void do_link(char *);
void do_pre(char *, ManTag);
void do_surround(char *, ManTag);
int parse_args(int, char **);
void print_head(void);
void usage(char *argv0);
%}

%option noyywrap
%option yylineno
%option no
STRING [a-zA-Z0-9!@#$%^&\:(),.?/\\\-<>|\{\}\[\]\"\'* \t]
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
        fprintf(args.output, ".RS\n.ft CR\n.nf\n.eo\n%s\n.ec\n.fi\n.ft R\n.RE", codeblock.buffer);
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
"["{STRING}+"]("{STRING}+")" { do_link(yytext); }
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
"." { fprintf(args.output, "\\."); }
%%

void do_link(char *text) {
    char *text_start = text + 1;
    char *text_end = strchr(text_start, ']');
    *text_end = '\0';
    fprintf(args.output, "%s", text_start);
}

void do_pre(char *text, ManTag type) {
	switch (type) {
		case PRE_SH1: fprintf(args.output, "\n.TH %s\n", strip_whitespace(&text[2])); break;
		case PRE_SH2: fprintf(args.output, "\n.SH %s\n", strip_whitespace(&text[3])); break;
		case PRE_SH3: fprintf(args.output, "\n.SH %s\n", strip_whitespace(&text[4])); break;
		case PRE_SH4: fprintf(args.output, "\n.SH %s\n", strip_whitespace(&text[5])); break;
		case PRE_SH5: fprintf(args.output, "\n.SH %s\n", strip_whitespace(&text[6])); break;
		case PRE_IP:  fprintf(args.output, "\n.TP\n"); break;
	}
}

void do_surround(char *text, ManTag type) {
	switch (type) {
		case SUR_BI: fprintf(args.output, "\\fB%s\\fP", strip_surround(text, 3)); break;
		case SUR_B: fprintf(args.output, "\\fB%s\\fP", strip_surround(text, 2)); break;
		case SUR_I: fprintf(args.output, "\\fI%s\\fP", strip_surround(text, 1)); break;
		case SUR_UL: fprintf(args.output, "\\fI%s\\fP", strip_surround(text, 2)); break;
		case SUR_M: fprintf(args.output, "\\fB%s\\fP", strip_surround(text, 1)); break;
	}
}

int parse_args(int argc, char **argv) {
	int opt;
	while ((opt = getopt(argc, argv, "o:t:")) != -1) {
		switch (opt) {
			case 'o': args.output = open_file(argv[optind], "w"); break;
			case 't': args.title = optarg; break;
			default: usage(argv[0]); return 0;
		}
	}

	if (optind < argc) {
		args.input = open_file(argv[optind], "r");
	}
	return 1;
}

void print_head() {
	if (args.title) {
		fprintf(args.output, ".TH %s\n", args.title);
	}
}

void usage(char *argv0) {
	fprintf(stderr, "Usage: %s [-t title] [-o outputfile] [inputfile]\n", argv0);
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
