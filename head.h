


#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
enum yytokentype
{
	OR = 258,
	AND = 259,
	NOT = 260,
	L = 261,
	LE = 262,
	E = 263,
	GE = 264,
	G = 265,
	LG = 266,
	MOD = 267,
	UMINUS = 268,
	VAR = 269,
	ARRAY = 270,
	TO = 271,
	OF = 272,
	BEGIN_T = 273,
	END = 274,
	ASSIGN = 275,
	PRINT = 276,
	READ = 277,
	IF = 278,
	THEN = 279,
	ELSE = 280,
	WHILE = 281,
	DO = 282,
	FOR = 283,
	RETURN = 284,
	DEF = 285,
	INTEGER = 286,
	REAL = 287,
	STRING = 288,
	BOOLEAN = 289,
	INT_CONST = 290,
	OCINT_CONST = 291,
	REAL_CONST = 292,
	STR_CONST = 293,
	BOOL_CONST = 294,
	ID = 295
};
#endif
/* Tokens.  */
#define OR 258
#define AND 259
#define NOT 260
#define L 261
#define LE 262
#define E 263
#define GE 264
#define G 265
#define LG 266
#define MOD 267
#define UMINUS 268
#define VAR 269
#define ARRAY 270
#define TO 271
#define OF 272
#define BEGIN_T 273
#define END 274
#define ASSIGN 275
#define PRINT 276
#define READ 277
#define IF 278
#define THEN 279
#define ELSE 280
#define WHILE 281
#define DO 282
#define FOR 283
#define RETURN 284
#define DEF 285
#define INTEGER 286
#define REAL 287
#define STRING 288
#define BOOLEAN 289
#define INT_CONST 290
#define OCINT_CONST 291
#define REAL_CONST 292
#define STR_CONST 293
#define BOOL_CONST 294
#define ID 295


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct entry
{
	char *name;
	int kind;//0: program, 1:function, 2:parameter, 3:variable, 4:constant, 5:loop variable
	int level;
	char *type;
	char *attri;
	int ind;
	struct entry *next;
};

struct table
{
	struct entry *first;
	struct table *next;
};

typedef struct mytype
{
	int val;
	double dval;
	char *text;
} YYSTYPE;

extern YYSTYPE yylval;

int yyparse(void);

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
