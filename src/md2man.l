%{
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "util.h"

void do_pre(char *, int);
void do_surround(char *, int);
FILE *open_file(const char *, const char *);
int parse_args(int, char **);
void print_head(void);

void usage(char *argv0);

enum {
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
};

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
STRING [a-zA-Z0-9!@#$%^&*(),.?/\\\-<>|\{\}\[\]\"\' \t]

%%
"# "{STRING}+"\n" do_pre(yytext, PRE_SH1);
"## "{STRING}+"\n" do_pre(yytext, PRE_SH2);
"### "{STRING}+"\n" do_pre(yytext, PRE_SH3);
"#### "{STRING}+"\n" do_pre(yytext, PRE_SH4);
"##### "{STRING}+"\n" do_pre(yytext, PRE_SH5);
"* " do_pre(yytext, PRE_IP);
"***"{STRING}+"***" do_surround(yytext, SUR_BI);
"**"{STRING}+"**" do_surround(yytext, SUR_B);
"*"{STRING}+"*" do_surround(yytext, SUR_I);
"__"{STRING}+"__" do_surround(yytext, SUR_UL);
"`"{STRING}+"`" do_surround(yytext, SUR_M);
%%

void do_pre(char *text, int type) {
	switch (type) {
		case PRE_SH1: fprintf(args.output, ".TH %s\n", strip_whitespace(&text[2])); break;
		case PRE_SH2: fprintf(args.output, ".SH %s\n", strip_whitespace(&text[3])); break;
		case PRE_SH3: fprintf(args.output, ".SH %s\n", strip_whitespace(&text[4])); break;
		case PRE_SH4: fprintf(args.output, ".SH %s\n", strip_whitespace(&text[5])); break;
		case PRE_SH5: fprintf(args.output, ".SH %s\n", strip_whitespace(&text[6])); break;
		case PRE_IP:  fprintf(args.output, ".TP\n"); break;
	}
}

void do_surround(char *text, int type) {
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
			case 'o':
				args.output = open_file(argv[optind], "w");
				break;
			case 't':
				args.title = optarg;
				break;
			default:
				usage(argv[0]);
				return 0;
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
