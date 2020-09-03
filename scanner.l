digit [0-9]
letter [a-zA-Z]
Identifier {letter}({digit}|{letter})*
Integer 0|[1-9][0-9]*
OcInteger 00|0[1-7][0-7]*
Float {Integer}\.([0-9])+
Scientific ({Integer}|{OcInteger}|{Float})[eE][+-]?({Integer}|{OcInteger})
%{
#include "head.h"

#define LIST               strcat(buf, yytext)
#define token(t)           {LIST; if (Opt_T) printf("<%s>\n", #t);}
#define tokenChar(t)       {LIST; if (Opt_T) printf("<%c>\n", (t));}
#define tokenInteger(t, i) {LIST; if (Opt_T) printf("<%s: %d>\n", #t, (i));}
#define tokenString(t, s)  {LIST; if (Opt_T) printf("<%s: %s>\n", #t, (s));}
#define MAX_LINE_LENG      256
int Opt_S = 1;
int Opt_T = 0;
int Opt_D = 0;
int linenum = 1;
char buf[MAX_LINE_LENG];
int flag=0;
%}


%%


,|;|:|\(|\)|\[|\] {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return yytext[0];}

or {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return OR;}
and {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return AND;}
not {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return NOT;}
\< {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return L;}
\<= {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return LE;}
= {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return E;}
\>= {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return GE;}
\> {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return G;}
\<\> {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return LG;}
\+|[-]|\*|\/ {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return yytext[0];}
mod {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return MOD;}

var {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return VAR;}
array {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return ARRAY;}
to {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return TO;}
of {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return OF;}

begin {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return BEGIN_T;}
end {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return END;}
:= {LIST; if(Opt_T && flag==0)printf("<%s>\n", yytext); if(flag==0)return ASSIGN;}
print {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return PRINT;}
read {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return READ;}

if {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return IF;}
then {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return THEN;}
else {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return ELSE;}
while {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return WHILE;}
do {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return DO;}

for {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return FOR;}
return {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return RETURN;}
def {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return DEF;}

integer {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return INTEGER;}
real {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return REAL;}
string {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return STRING;}
boolean {LIST; if(Opt_T && flag==0)printf("<KW%s>\n", yytext); if(flag==0)return BOOLEAN;}

{Integer}	{	
				LIST;
				if(Opt_T && flag==0)
					printf("<integer: %s>\n", yytext);
				if(flag==0)
				{
					yylval.val=atoi(yytext);
					return INT_CONST;
				}
			}
{OcInteger} {
				LIST;
				if(Opt_T && flag==0)
					printf("<oct_integer: %s>\n", yytext);
				if(flag==0)
				{
					int res=0;
					for(int i=0;i<strlen(yytext); i++)
					{
						res*=8;
						res+=yytext[i]-'0';
					}
					yylval.val=res;
					return OCINT_CONST;
				}
			}
{Float}	{
			LIST;
			if(Opt_T && flag==0)
				printf("<float: %s>\n", yytext);
			if(flag==0)
			{
				yylval.dval=strtod(yytext, NULL);
				return REAL_CONST;
			}
		}
{Scientific}	{
					LIST;
					if(Opt_T && flag==0)
						printf("<scientific: %s>\n", yytext);
					if(flag==0)
					{
						yylval.text=strdup(yytext);
						return REAL_CONST;
					}
				}
\"([ \t\40-\41\43-\176]|\"\")*\"	{
										LIST;
										yytext[strlen(yytext)-1]='\0';
										yytext++;
										char* i, *j;
										i=j=yytext;
										while(j<yytext+strlen(yytext))
										{
											if((*j)!='"')
												(*(i++))=*(j++);
											else
												(*(i++))=*((j=j+2)-2);
										}
										(*i)='\0';
										if(Opt_T && flag==0)
											printf("<string: %s>\n", yytext);
										if(flag==0)
										{
											yylval.text=strdup(yytext);
											return STR_CONST;
										}
									}
true	{
			LIST;
			if(Opt_T && flag==0)
				printf("<KW%s>\n", yytext);
			if(flag==0)
			{
				yylval.val=1;
				return BOOL_CONST;
			}
		}
false	{
			LIST;
			if(Opt_T && flag==0)
				printf("<KW%s>\n", yytext);
			if(flag==0)
			{
				yylval.val=0;
				return BOOL_CONST;
			}
		}
{Identifier}	{
					LIST;
					if(Opt_T && flag==0)
						printf("<id: %s>\n", yytext);
					if(flag==0)
					{
						yylval.text=strdup(yytext);
						if(strlen(yylval.text)>32)
							yylval.text[32]=0;
						return ID;
					}
				}

" "|\t {LIST;}
\n {LIST;
    if(Opt_S)printf("; %d: %s", linenum, buf);
    linenum++;
	buf[0]='\0';
	if(flag==2)flag=0;}
\/\* {LIST;
      if(flag==0){flag=1;}}
\*\/ {LIST;
      if(flag==0){fprintf(stderr, "lexical analyzer : <bad input: %s>\n", yytext); exit(-1);}
      else if(flag==1){flag=0;}}
\/\/ {LIST;
      if(flag==0){flag=2;}}
\/\/&S\+ {LIST;
          if(flag==0){Opt_S=1; flag=2;}}
\/\/&S[-] {LIST;
           if(flag==0){Opt_S=0; flag=2;}}
\/\/&T\+ {LIST;
          if(flag==0){Opt_T=1; flag=2;}}
\/\/&T[-] {LIST;
           if(flag==0){Opt_T=0; flag=2;}}
\/\/&D\+ {LIST;
          if(flag==0){Opt_D=1; flag=2;}}
\/\/&D[-] {LIST;
           if(flag==0){Opt_D=0; flag=2;}}
. {LIST; if(flag==0){fprintf(stderr, "lexical analyzer : <bad input: %s>\n", yytext); exit(-1);}}


%%


/*
int main( int argc, char **argv )
{
  if( argc != 2 ) {
    fprintf( stderr, "Usage: ./scanner [filename]\n" );
    exit(0);
  }
	
  FILE *fp = fopen( argv[1], "r" );
  if( fp == NULL ) {
    fprintf( stderr, "Open file error\n" );
    exit(-1);
  }
	
  yyin = fp;

  yylex();

  exit(0);
}
*/
