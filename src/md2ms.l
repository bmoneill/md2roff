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

void do_pre(char *, MSTag);
void do_surround(char *, MSTag);
FILE *open_file(const char *, const char *);
int parse_args(int, char **);
void print_head(void);
void surround_multiline(const char *, char *, int);

void usage(char *argv0);

typedef struct md2roff_args_s {
	FILE *input;
	FILE *output;
	char *title;
	char *author;
	uint8_t flags;
} md2roff_args_t;
md2roff_args_t args;
%}

%option noyywrap
%option yylineno
%option no
STRING [a-zA-Z0-9!@#$%^&(),.?/\\\-<>|\{\}\[\]\"\' \t]

%%
"# "{STRING}+"\n" do_pre(yytext, PRE_SH1);
"## "{STRING}+"\n" do_pre(yytext, PRE_SH2);
"### "{STRING}+"\n" do_pre(yytext, PRE_SH3);
"#### "{STRING}+"\n" do_pre(yytext, PRE_SH4);
"##### "{STRING}+"\n" do_pre(yytext, PRE_SH5);
"\n* " do_pre(yytext, PRE_IP);
"***"{STRING}+"***" do_surround(yytext, SUR_BI);
"**"{STRING}+"**" do_surround(yytext, SUR_B);
"*"{STRING}+"*" do_surround(yytext, SUR_I);
"__"{STRING}+"__" do_surround(yytext, SUR_UL);
"`"{STRING}+"`" do_surround(yytext, SUR_M);
"```"{STRING}+"\n"+{STRING}+"\n```" do_surround(yytext, SUR_MULTILINE_M);
"\n\n" fprintf(args.output, "\n.PP\n");
%%

void do_pre(char *text, MSTag type) {
	switch (type) {
		case PRE_SH1: fprintf(args.output, ".NH 1\n%s\n.PP", strip_whitespace(&text[2])); break;
		case PRE_SH2: fprintf(args.output, ".NH 2\n%s\n.PP", strip_whitespace(&text[3])); break;
		case PRE_SH3: fprintf(args.output, ".NH 3\n%s\n.PP", strip_whitespace(&text[4])); break;
		case PRE_SH4: fprintf(args.output, ".NH 4\n%s\n.PP", strip_whitespace(&text[5])); break;
		case PRE_SH5: fprintf(args.output, ".NH 5\n%s\n.PP", strip_whitespace(&text[6])); break;
		case PRE_IP:  fprintf(args.output, ".IP - \n"); break;
	}
	fprintf(args.output, "\n");
}

void do_surround(char *text, MSTag type) {
	switch (type) {
		case SUR_BI: fprintf(args.output, "\\fB\\fI%s\\fR", strip_surround(text, 3)); break;
		case SUR_B: fprintf(args.output, "\\fB%s\\fR", strip_surround(text, 2)); break;
		case SUR_I: fprintf(args.output, "\\fI%s\\fR", strip_surround(text, 1)); break;
		case SUR_UL: fprintf(args.output, ".UL\n%s\n.R", strip_surround(text, 2)); break;
		case SUR_M: fprintf(args.output, "\n.ft 8\n%s\n.R", strip_surround(text, 1)); break;
        case SUR_MULTILINE_M: surround_multiline(".IP\n.DS L\n.ft C\n%s\n.ft\n", text, 3); break;
	}
	fprintf(args.output, "\n");
}

void surround_multiline(const char *fmt, char *text, int count) {
    for (int i = count; i < strlen(text) - count; i++) {
        if (text[i] == '\n') {
            fprintf(args.output, fmt, strip_surround(text, count));
        }
    }
}


int parse_args(int argc, char **argv) {
	int opt;
	while ((opt = getopt(argc, argv, "a:bno:pt:")) != -1) {
		switch (opt) {
			case 'b':
				args.flags |= FLAG_BREAK_FRONT_PAGE;
				break;
			case 'n':
				args.flags |= FLAG_NO_DATE_DISPLAY;
				break;
			case 'o':
				args.output = open_file(argv[optind], "w");
				break;
			case 't':
				args.title = optarg;
				break;
			case 'a':
				args.author = optarg;
				break;
			default:
				usage(argv[0]);
				return 1;
		}
	}

	if (optind < argc) {
		args.input = open_file(argv[optind], "r");
	}
	return 0;
}

void print_head() {
	fprintf(args.output, ".fp 8 CW\n");
	return ;
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

	if (!parse_args(argc, argv)) {
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