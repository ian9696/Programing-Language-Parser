%{
#include "head.h"

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
extern int Opt_D;

struct table *tables=NULL;
int depth=-1;
char *funcrettype="";
char *filename="";
int haserr=0;
int indcnt=-1;
int lbcnt=0;
const int stacklimit=100;
const int localslimit=100;

int yylex();

void gencmp(char *first, char *second, char *cmpop);
void ensurereal(char *first);
void ensurereal2(char *first, char *second);
char* arglisttodesc(char *arglist);
char* rettodesc(char *ret);
void geninvoke(struct entry *p, char *arg);
char* typetodesc(char *type);
void gengetval(struct entry *p);
int funcargmatch(char *arg, char *para);
char* kindtostr(int kind);
int computetypedim(char *type);
char* typedeldim(char *type, int dim);
char* typeadddim(char *type, int dim);
int isstring(char *type);
int isboolean(char *type);
int isreal(char *type);
int isinteger(char *type);
int isintegerreal(char *type);
int isscalar(char *type);
char* arithrestype(char *type, char *type2);
char* relarestype(char *type, char *type2);
char* boolrestype(char *type, char *type2);
char* mergearglist(char *arg_list_0, char *arg_list_1);
char* consarglist(char *arg_list_1, char *type);
void initentry(struct entry *p);
void pushentryindepth(struct entry *p, int indepth);
void pushentry(struct entry *p);
int checkexistbynameindepth(char *name, int indepth);
int checkexistbynamealldepth(char *name);
int checkexistbyname(char *name);
struct entry* getentrybynameindepth(char *name, int indepth);
struct entry* getentrybynamealldepth(char *name);
struct entry* getentrybyname(char *name);
struct entry* getfuncentry(char *name);
int checkfuncexist(char *name);
void pusharglist(char *arglist, char *type);
void pushconslist(char *conslist, char *type, char *attri);
void pushvarlist(char *varlist, char *type);
void showentry(struct entry *p);
void showtable();
void pushtable();
void poptable();
void pid();
int yyerror( char *msg );

%}

%left OR
%left AND
%right NOT
%left L LE E GE G LG
%left '+' '-'
%left '*' '/' MOD
%right UMINUS

%token VAR ARRAY TO OF
%token BEGIN_T END ASSIGN PRINT READ
%token IF THEN ELSE WHILE DO
%token FOR RETURN DEF
%token INTEGER REAL STRING BOOLEAN
%token INT_CONST OCINT_CONST REAL_CONST STR_CONST BOOL_CONST ID

%%

program		: ID	{
						pushtable();
						//printf("\n``````````````construct table for program %d````````````\n", depth);
						struct entry *p=malloc(sizeof(struct entry));
						initentry(p);
						p->name=strdup($1.text);
						p->kind=0;
						p->level=depth;
						p->type=strdup("void");
						pushentry(p);
						if(strcmp($1.text, filename))
						{
							printf("####################<Error> found in Line %d : program/file name mismatch\n", linenum);
							haserr=1;
						}
						printf(".class public %s\n", filename);
						printf(".super java/lang/Object\n");
						printf("\n.field public static _sc Ljava/util/Scanner;\n");
					}
					';' programbody END ID
					{
						poptable();
						//printf("\n``````````````destruct table for program %d````````````\n", depth);
						if(strcmp($1.text, $6.text))
						{
							printf("####################<Error> found in Line %d : program name inconsistent\n", linenum);
							haserr=1;
						}
					}
			;

programbody	: decl_vc_0 decl_f_0
				{
					indcnt=1;
					printf("\n.method public static main([Ljava/lang/String;)V\n");
					printf("\t.limit stack %d\n", stacklimit);
					printf("\t.limit locals %d\n", localslimit);
					printf("new java/util/Scanner\n");
					printf("dup\n");
					printf("getstatic java/lang/System/in Ljava/io/InputStream;\n");
					printf("invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
					printf("putstatic %s/_sc Ljava/util/Scanner;\n\n", filename);
				}
				compound
				{
					printf("\treturn\n");
					printf(".end method\n");
				}
			;

decl_vc_0	: decl_vc_0 decl_vc
			|	{$$.text=strdup("");}
			;

decl_f_0	: decl_f_0 decl_f
			|	{$$.text=strdup("");}
			;

decl_vc		: VAR id_list_1 ':' scalar_type ';'	{
													pushvarlist($2.text, $4.text);
												}
			| VAR id_list_1 ':' ARRAY int_ocint_const TO int_ocint_const OF type ';'
				{
					char *type=typeadddim($9.text, $7.val-$5.val+1);
					char *s=strtok(strdup(type), " []");
					int valid=1;
					s=strtok(NULL, " []");
					while(s!=NULL)
					{
						if(atoi(s)<2)
							valid=0;
						s=strtok(NULL, " []");
					}
					if(valid==0)
					{
						printf("####################<Error> found in Line %d : lowerbound>=upperbound\n", linenum);
						haserr=1;
					}
					else
						pushvarlist($2.text, type);
				}
			| VAR id_list_1 ':' INT_CONST ';'
				{
					char *s=malloc(20*sizeof(char));
					sprintf(s, "%d", $4.val);
					pushconslist($2.text, "integer", s);
				}
			| VAR id_list_1 ':' OCINT_CONST ';'
				{
					char *s=malloc(20*sizeof(char));
					sprintf(s, "%d", $4.val);
					pushconslist($2.text, "integer", s);
				}
			| VAR id_list_1 ':' REAL_CONST ';'
				{
					char *s=malloc(50*sizeof(char));
					sprintf(s, "%f", $4.dval);
					pushconslist($2.text, "real", s);
				}
			| VAR id_list_1 ':' STR_CONST ';'
				{
					pushconslist($2.text, "string", $4.text);
				}
			| VAR id_list_1 ':' BOOL_CONST ';'
				{
					pushconslist($2.text, "boolean", $4.val!=0?"true":"false");
				}
			;

id_list_1	: id_list_t ID	{
								int l=strlen($1.text);
								int l2=strlen($2.text);
								char *s=malloc((l+l2+2)*sizeof(char));
								strcpy(s, $1.text);
								s[l]=' ';
								strcpy(s+l+1, $2.text);
								$$.text=s;
							}
			;

id_list_t	: id_list_t ID  ','	{
									int l=strlen($1.text);
									int l2=strlen($2.text);
									char *s=malloc((l+l2+2)*sizeof(char));
									strcpy(s, $1.text);
									s[l]=' ';
									strcpy(s+l+1, $2.text);
									$$.text=s;
								}
			|	{$$.text=strdup("");}
			;

scalar_type	: INTEGER	{$$.text=strdup("integer");}
			| REAL	{$$.text=strdup("real");}
			| BOOLEAN	{$$.text=strdup("boolean");}
			| STRING	{$$.text=strdup("string");}
			;

int_ocint_const	: INT_CONST {$$.val=$1.val;}
				| OCINT_CONST {$$.val=$1.val;}
				;

type		: ARRAY int_ocint_const TO int_ocint_const OF type	{$$.text=typeadddim($6.text, $4.val-$2.val+1);}
			| scalar_type	{$$.text=$1.text;}
			;

decl_f		: ID	{
						pushtable();
						//printf("\n``````````````construct table for function %d````````````\n", depth);
						indcnt=0;
					}
					'(' arg_list_0 ')' ret_0
					{
						funcrettype=strdup($6.text);
						struct entry *p=malloc(sizeof(struct entry));
						initentry(p);
						p->name=strdup($1.text);
						p->kind=1;
						p->level=0;
						p->type=$6.text;
						p->attri=$4.text;
						//printf("\n*********************%s******************\n", $4.text);
						pushentryindepth(p, 0);
						printf("\n.method public static %s(%s)%s\n", p->name, arglisttodesc(p->attri), rettodesc(p->type));
						printf("\t.limit stack %d\n", stacklimit);
						printf("\t.limit locals %d\n", localslimit);
					}
					';' BEGIN_T decl_vc_0 statement_0 END END ID
					{
						funcrettype=strdup("");
						poptable();
						//printf("\n``````````````destruct table for function %d````````````\n", depth);
						if(strcmp($1.text, $14.text))
						{
							printf("####################<Error> found in Line %d : function name inconsistent\n", linenum);
							haserr=1;
						}
						printf("\treturn\n");
						printf(".end method\n");
					}
			;

arg_list_1	: arg_list_t id_list_1 ':' type
				{
					pusharglist(strdup($2.text), strdup($4.text));
					$$.text=mergearglist($1.text, consarglist($2.text, $4.text));
				}
			;

arg_list_t	: arg_list_t id_list_1 ':' type ';'
				{
					pusharglist(strdup($2.text), strdup($4.text));
					$$.text=mergearglist($1.text, consarglist($2.text, $4.text));
				}
			|	{$$.text=strdup("");}
			;

arg_list_0	: arg_list_1
				{
					$$.text=$1.text;
					//printf("\n++++++++++%s++++++++++\n", $$.text);
				}
			|
				{
					$$.text=strdup("");
					//printf("\n++++++++++%s++++++++++\n", $$.text);
				}
			;

ret_0		: ':' type
				{
					$$.text=$2.text;
					//printf("\n----------%s----------\n", $$.text);
				}
			|
				{
					$$.text=strdup("void");
					//printf("\n----------%s----------\n", $$.text);
				}
			;

compound	: BEGIN_T	{
							pushtable();
							//printf("\n``````````````construct table for compound %d````````````\n", depth);
						}
						decl_vc_0 statement_0 END
						{
							poptable();
							//printf("\n``````````````destruct table for compound %d````````````\n", depth);
						}
			;

statement_0	: statement_0 statement
			|	{$$.text=strdup("");}
			;

partialif	: IF expr
				{
					if(strcmp($2.text, "boolean"))
					{
						printf("####################<Error> found in Line %d : if then else : expression must be boolean type : found=%s, expected=%s\n", linenum, $2.text, "boolean");
						haserr=1;
					}
					$1.val=lbcnt++;
					printf("ifeq lb_false_%d\n", $1.val);
				}
				THEN statement_0
				{
					$$.val=$1.val;
				}
			;

partialprint	: PRINT
					{
						printf("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
					}
			;

statement	: compound
			| var_ref ASSIGN expr ';'
				{
					char *name=strtok($1.text, " ");
					int dim=atoi(strtok(NULL, " "));
					if(!checkexistbynamealldepth(name))
					{
						printf("####################<Error> found in Line %d : var_ref := expr : %s is not declared\n", linenum, name);
						haserr=1;
					}
					else
					{
						struct entry *pe=getentrybynamealldepth(name);
						int t=1;
						if(!(pe->kind==2 || pe->kind==3))
							printf("####################<Error> found in Line %d : var_ref := expr : cannot assign to %s\n", linenum, name);
						else if(!strcmp($3.text, ""))
							printf("####################<Error> found in Line %d : var_ref := expr : cannot assign to %s\n", linenum, name);
						else if(dim>computetypedim(pe->type))
							printf("####################<Error> found in Line %d : var_ref := expr : invalid dimension : %s\n", linenum, name);
						else if(dim<computetypedim(pe->type) || computetypedim($3.text)>0)
							printf("####################<Error> found in Line %d : var_ref := expr : array arithmetic is not allowed\n", linenum);
						else if(!funcargmatch($3.text, typedeldim(pe->type, dim))) 
							printf("####################<Error> found in Line %d : var_ref := expr : type mismatch\n", linenum);
						else
						{
							t=0;
							if(isreal(pe->type))
								ensurereal($3.text);
							if(pe->level==0)
								printf("putstatic %s/%s %s\n", filename, pe->name, typetodesc(pe->type));
							else
								printf("%s %d ; %s\n", isreal(pe->type)?"fstore":"istore", pe->ind, pe->name);
						}
						haserr=haserr|t;
					}
				}
			| partialprint var_ref ';'
				{
					char *name=strtok($2.text, " ");
					int dim=atoi(strtok(NULL, " "));
					if(!checkexistbynamealldepth(name))
					{
						printf("####################<Error> found in Line %d : print var_ref ; : %s is not declared\n", linenum, name);
						haserr=1;
					}
					else
					{
						struct entry *pe=getentrybynamealldepth(name);
						int t=1;
						if(pe->kind<=1)
							printf("####################<Error> found in Line %d : print var_ref ; : cannot print %s\n", linenum, name);
						else
						{
							if(computetypedim(pe->type)<dim)
								printf("####################<Error> found in Line %d : print var_ref : invalid dimension\n", linenum);
							else if(computetypedim(pe->type)>dim)
								printf("####################<Error> found in Line %d : print var_ref : can only print scalar\n", linenum);
							else
							{
								t=0;
								gengetval(pe);
								printf("invokevirtual java/io/PrintStream/print(%s)V\n", typetodesc(pe->type));
							}
						}
						haserr=haserr|t;
					}
				}
			| partialprint expr ';'
				{
					int t=1;
					if(!strcmp($2.text, ""))
						printf("####################<Error> found in Line %d : print expr ; : cannot print\n", linenum);
					else if(computetypedim($2.text)>0)
						printf("####################<Error> found in Line %d : print expr ; : can only print scalar\n", linenum);
					else
					{
						t=0;
						printf("invokevirtual java/io/PrintStream/print(%s)V\n", typetodesc($2.text));
					}
					haserr=haserr|t;
				}
			| READ var_ref ';'
				{
					char *name=strtok($2.text, " ");
					int dim=atoi(strtok(NULL, " "));
					int t=1;
					if(!checkexistbynamealldepth(name))
						printf("####################<Error> found in Line %d : read var_ref ; : %s is not declared\n", linenum, name);
					else
					{
						struct entry *pe=getentrybynamealldepth(name);
						if(!(pe->kind==2 || pe->kind==3))
							printf("####################<Error> found in Line %d : read var_ref ; : cannot read %s\n", linenum, name);
						else
						{
							if(computetypedim(pe->type)<dim)
								printf("####################<Error> found in Line %d : read var_ref : invalid dimension\n", linenum);
							else if(computetypedim(pe->type)>dim)
								printf("####################<Error> found in Line %d : read var_ref : can only read scalar\n", linenum);
							else
							{
								t=0;
								printf("getstatic %s/_sc Ljava/util/Scanner;\n", filename);
								char *s="nextInt";
								if(isboolean(pe->type))
									s="nextBoolean";
								else if(isreal(pe->type))
									s="nextFloat";
								printf("invokevirtual java/util/Scanner/%s()%s\n", s, typetodesc(pe->type));
								if(pe->level==0)
									printf("putstatic %s/%s %s\n", filename, pe->name, typetodesc(pe->type));
								else
									printf("%s %d ; %s\n", isreal(pe->type)?"fstore":"istore", pe->ind, pe->name);
							}
						}
					}
					haserr=haserr|t;
				}
			| partialif ELSE
				{
					printf("goto lb_true_%d\n", $1.val);
					printf("lb_false_%d:\n", $1.val);
				}
				statement_0 END IF
				{
					printf("lb_true_%d:\n", $1.val);
				}
			| partialif END IF
				{
					printf("lb_false_%d:\n", $1.val);
				}
			| WHILE
				{
					$1.val=lbcnt++;
					printf("lb_begin_%d:\n", $1.val);
				}
				expr
				{
					if(strcmp($3.text, "boolean"))
					{
						printf("####################<Error> found in Line %d : while : expression must be boolean type : found=%s, expected=%s\n", linenum, $3.text, "boolean");
						haserr=1;
					}
					printf("ifeq lb_exit_%d\n", $1.val);
				}
				DO statement_0 END DO
				{
					printf("goto lb_begin_%d\n", $1.val);
					printf("lb_exit_%d:\n", $1.val);
				}
			| FOR ID ASSIGN int_ocint_const TO int_ocint_const
				{
					int valid=1;
					if(checkexistbyname($2.text))
					{
						printf("####################<Error> found in Line %d : %s is redeclared\n", linenum, $2.text);
						valid=0;
					}
					if($4.val>$6.val)
					{
						printf("####################<Error> found in Line %d : lowerbound>upperbound\n", linenum);
						valid=0;
					}
					if(valid)
					{
						struct entry *p=malloc(sizeof(struct entry));
						initentry(p);
						p->name=strdup($2.text);
						p->kind=5;
						p->level=depth;
						p->type=strdup("integer");
						p->attri=strdup("");
						p->ind=indcnt++;
						pushentry(p);
						printf("sipush %d\n", $4.val);
						printf("istore %d ; %s\n", p->ind, p->name);
						$3.val=lbcnt++;
						printf("lb_begin_%d:\n", $3.val);
						printf("iload %d ; %s\n", p->ind, p->name);
						printf("sipush %d\n", $6.val);
						gencmp("integer", "integer", "le");
						printf("ifeq lb_exit_%d\n", $3.val);
					}
					else
						haserr=1;
					$1.val=valid;
				}
				DO statement_0
				{
					struct entry *pe=getentrybyname($2.text);
					printf("iload %d ; %s\n", pe->ind, pe->name);
					printf("sipush 1\n");
					printf("iadd\n");
					printf("istore %d ; %s\n", pe->ind, pe->name);
					printf("goto lb_begin_%d\n", $3.val);
					printf("lb_exit_%d:\n", $3.val);
				}
				END DO
				{
					if($1.val)
					{
						struct entry *pe=tables->first;
						struct entry *pre=pe;
						while(strcmp(pe->name, $2.text))
						{
							pre=pe;
							pe=pe->next;
						}
						if(pe==pre)
							tables->first=pe->next;
						else
							pre->next=pe->next;

					}
				}
			| RETURN expr ';'
				{
					int t=1;
					if(!strcmp(funcrettype, "") || !strcmp(funcrettype, "void") || !strcmp($2.text, ""))
						printf("####################<Error> found in Line %d : cannot return\n", linenum);
					else if(computetypedim($2.text)>0)
						printf("####################<Error> found in Line %d : cannot return an array\n", linenum);
					else if(!funcargmatch($2.text, funcrettype))
						printf("####################<Error> found in Line %d : return type mismatch : found=%s, expected=%s\n", linenum, $2.text, funcrettype);
					else
					{
						t=0;
						if(isinteger($2.text) && isreal(funcrettype))
							printf("i2f\n");
						printf("%s ; expr=%s, funcrettype=%s\n", isreal(funcrettype)?"freturn":"ireturn", $2.text, funcrettype);
					}
					haserr=haserr|t;
				}
			| ID '(' expr_list_0 ')' ';'
				{
					int t=1;
					if(!checkfuncexist($1.text))
						printf("####################<Error> found in Line %d : ID(expr_list_0) : %s is not declared\n", linenum, $1.text);
					else
					{
						struct entry *pe=getfuncentry($1.text);
						if(!funcargmatch($3.text, pe->attri))
							printf("####################<Error> found in Line %d : ID(expr_list_0) : parameter type mismatch : found=%s, expected=%s\n", linenum, $3.text, pe->attri);
						else
						{
							t=0;
							geninvoke(pe, $3.text);
						}
					}
					haserr=haserr|t;
				}
			;

var_ref		: ID
				{
					int l=strlen($1.text);
					char *s=malloc((l+3)*sizeof(char));
					strcpy(s, $1.text);
					strcpy(s+l, " 0");
					$$.text=s;
					//printf("var_ref : %s\n", $$.text);
				}
			| arr_ref
				{
					$$.text=$1.text;
					//printf("var_ref : %s\n", $$.text);
				}
			;

arr_ref		: ID  '[' expr ']' arr_ref_t
				{
					int l=strlen($1.text);
					char *s=malloc((l+20)*sizeof(char));
					strcpy(s, $1.text);
					sprintf(s+l, " %d", $5.val+1);
					$$.text=s;
					//printf("arr_ref : %s\n", $$.text);
				}
			;

arr_ref_t	: '[' expr ']' arr_ref_t
				{
					$$.val=1+$4.val;
					//printf("arr_ref_t : %d\n", $$.val);
				}
			|
				{
					$$.val=0;
					//printf("arr_ref_t : %d\n", $$.val);
				}
			;

expr		: expr OR expr
				{
					$$.text=boolrestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : OR : operand type error\n", linenum);
						haserr=1;
					}
					else
						printf("ior\n");
				}
			| expr AND expr
				{
					$$.text=boolrestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : AND : operand type error\n", linenum);
						haserr=1;
					}
					else
						printf("iand\n");
				}
			| NOT expr
				{
					$$.text=boolrestype($2.text, "boolean");
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : NOT : operand type error\n", linenum);
						haserr=1;
					}
					else
					{
						printf("iconst_1\n");
						printf("ixor\n");
					}
				}
			| expr L expr
				{
					$$.text=relarestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : L : operand type error\n", linenum);
						haserr=1;
					}
					else
						gencmp($1.text, $3.text, "lt");
				}
			| expr LE expr
				{
					$$.text=relarestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : LE : operand type error\n", linenum);
						haserr=1;
					}
					else
						gencmp($1.text, $3.text, "le");
				}
			| expr E expr
				{
					$$.text=relarestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : E : operand type error\n", linenum);
						haserr=1;
					}
					else
						gencmp($1.text, $3.text, "eq");
				}
			| expr GE expr
				{
					$$.text=relarestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : GE : operand type error\n", linenum);
						haserr=1;
					}
					else
						gencmp($1.text, $3.text, "ge");
				}
			| expr G expr
				{
					$$.text=relarestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : G : operand type error\n", linenum);
						haserr=1;
					}
					else
						gencmp($1.text, $3.text, "gt");
				}
			| expr LG expr
				{
					$$.text=relarestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : LG : operand type error\n", linenum);
						haserr=1;
					}
					else
						gencmp($1.text, $3.text, "ne");
				}
			| expr '+' expr
				{
					if(isstring($1.text) && isstring($3.text))
						$$.text=$1.text;
					else
					{
						$$.text=arithrestype($1.text, $3.text);
						if(strlen($$.text)==0)
						{
							printf("####################<Error> found in Line %d : + : operand type error\n", linenum);
							haserr=1;
						}
						else
						{
							if(!strcmp($$.text, "real"))
								ensurereal2($1.text, $3.text);
							printf("%s\n", isinteger($$.text)?"iadd":"fadd");
						}
					}
				}
			| expr '-' expr
				{
					$$.text=arithrestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : - : operand type error\n", linenum);
						haserr=1;
					}
					else
					{
						if(!strcmp($$.text, "real"))
							ensurereal2($1.text, $3.text);
						printf("%s\n", isinteger($$.text)?"isub":"fsub");
					}
				}
			| expr '*' expr
				{
					$$.text=arithrestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : * : operand type error\n", linenum);
						haserr=1;
					}
					else
					{
						if(!strcmp($$.text, "real"))
							ensurereal2($1.text, $3.text);
						printf("%s\n", isinteger($$.text)?"imul":"fmul");
					}
				}
			| expr '/' expr
				{
					$$.text=arithrestype($1.text, $3.text);
					if(strlen($$.text)==0)
					{
						printf("####################<Error> found in Line %d : / : operand type error\n", linenum);
						haserr=1;
					}
					else
					{
						if(!strcmp($$.text, "real"))
							ensurereal2($1.text, $3.text);
						printf("%s\n", isinteger($$.text)?"idiv":"fdiv");
					}
				}
			| expr MOD expr
				{
					$$.text=$1.text;
					if(!(isinteger($1.text)&&isinteger($3.text)))
					{
						printf("####################<Error> found in Line %d : MOD : operand type error\n", linenum);
						$$.text[0]=0;
						haserr=1;
					}
					else
						printf("irem\n");
				}
			| '-' expr	{$$.text=$2.text; printf("%s\n", isinteger($2.text)?"ineg":"fneg");} %prec UMINUS
			| int_ocint_const	{$$.text=strdup("integer"); printf("sipush %d\n", $1.val);}
			| REAL_CONST	{$$.text=strdup("real"); printf("ldc %f\n", $1.dval);}
			| STR_CONST	{$$.text=strdup("string"); printf("ldc \"%s\"\n", $1.text);}
			| BOOL_CONST	{$$.text=strdup("boolean"); printf("iconst_%d\n", $1.val);}
			| ID	{
						if(!checkexistbynamealldepth($1.text))
						{
							printf("####################<Error> found in Line %d : expr | ID : %s is not declared\n", linenum, $1.text);
							$$.text=strdup("");
							haserr=1;
						}
						else
						{
							struct entry *pe=getentrybynamealldepth($1.text);
							if(pe->kind<=1)
							{
								printf("####################<Error> found in Line %d : expr | ID : %s is not an expression\n", linenum, $1.text);
								$$.text=strdup("");
								haserr=1;
							}
							else
							{
								$$.text=strdup(pe->type);
								gengetval(pe);
							}
						}
					}
			| ID '(' expr_list_0 ')'
				{
					$$.text=strdup("");
					if(!checkfuncexist($1.text))
					{
						printf("####################<Error> found in Line %d : ID(expr_list_0) : %s is not declared\n", linenum, $1.text);
						haserr=1;
					}
					else
					{
						struct entry *pe=getfuncentry($1.text);
						if(!funcargmatch($3.text, pe->attri))
						{
							printf("####################<Error> found in Line %d : ID(expr_list_0) : parameter type mismatch : found=%s, expected=%s\n", linenum, $3.text, pe->attri);
							haserr=1;
						}
						else
						{
							$$.text=strdup(pe->type);
							if(strcmp($$.text, "void")==0)
								$$.text[0]=0;
							geninvoke(pe, $3.text);
						}
					}
				}
			| arr_ref
				{
					$$.text=strdup("");
					char *name=strtok($1.text, " ");
					int dim=atoi(strtok(NULL, " "));
					if(!checkexistbynamealldepth(name))
					{
						printf("####################<Error> found in Line %d : expr | arr_ref : %s is not declared\n", linenum, name);
						haserr=1;
					}
					else
					{
						struct entry *pe=getentrybynamealldepth(name);
						if(!(pe->kind==2 || pe->kind==3))
						{
							printf("####################<Error> found in Line %d : expr | arr_ref : %s is not an array\n", linenum, name);
							haserr=1;
						}
						else
						{
							char *type=strdup(pe->type);
							if(computetypedim(type)<dim)
							{
								printf("####################<Error> found in Line %d : expr | arr_ref : invalid dimension : %s\n", linenum, name);
								haserr=1;
							}
							else
								$$.text=typedeldim(type, dim);
						}
					}
				}
			| '(' expr ')'	{$$.text=$2.text;}
			;

expr_list_1	: expr_list_t expr
				{
					//printf("expr_list_t : %s\n", $2.text);
					if(strlen($2.text)==0)
						$2.text=strdup("bad type");
					if(strlen($1.text)==0)
						$$.text=$2.text;
					else
					{
						int l=strlen($1.text);
						int l2=strlen($2.text);
						char *s=malloc((l+l2+3)*sizeof(char));
						strcpy(s, $1.text);
						strcpy(s+l, ", ");
						strcpy(s+l+2, $2.text);
						$$.text=s;
					}
				}
			;

expr_list_t	: expr_list_t expr ','
				{
					//printf("expr_list_t : %s\n", $2.text);
					if(strlen($2.text)==0)
						$2.text=strdup("bad type");
					if(strlen($1.text)==0)
						$$.text=$2.text;
					else
					{
						int l=strlen($1.text);
						int l2=strlen($2.text);
						char *s=malloc((l+l2+3)*sizeof(char));
						strcpy(s, $1.text);
						strcpy(s+l, ", ");
						strcpy(s+l+2, $2.text);
						$$.text=s;
					}
				}
			|	{$$.text=strdup("");}
			;

expr_list_0	: expr_list_1	{$$.text=$1.text;}
			|	{$$.text=strdup("");}
			;


%%

void gencmp(char *first, char *second, char *cmpop)
{
	if(isinteger(first) && isinteger(second))
		printf("isub\n");
	else
	{
		ensurereal2(first, second);
		printf("fcmpl\n");
	}
	int i=lbcnt++;
	printf("if%s lb_true_%d\n", cmpop, i);
	printf("iconst_0\n");
	printf("goto lb_false_%d\n", i);
	printf("lb_true_%d:\n", i);
	printf("iconst_1\n");
	printf("lb_false_%d:\n", i);
}

void ensurereal(char *first)
{
	if(isinteger(first))
		printf("i2f\n");
}

void ensurereal2(char *first, char *second)
{
	if(isinteger(second))
		printf("i2f\n");
	if(isinteger(first))
	{
		printf("swap\n");
		printf("i2f\n");
		printf("swap\n");
	}
}

char* arglisttodesc(char *arglist)
{
	int cnt=0, pos=0;
	while(pos<strlen(arglist))
	{
		if(arglist[pos]==',')
			cnt++;
		pos++;
	}
	if(strlen(arglist)!=0)
		cnt++;
	char *res=malloc((cnt*20+1)*sizeof(char));
	res[0]=0;
	char *s=strtok(strdup(arglist), ", ");
	for(int i=0; i<cnt; i++)
	{
		strcpy(res+strlen(res), typetodesc(s));
		s=strtok(NULL, ", ");
	}
	return res;
}

char* rettodesc(char *ret)
{
	return !strcmp(ret, "void")?strdup("V"):typetodesc(ret);
}

void geninvoke(struct entry *p, char *arg)
{
	char *argdesc=arglisttodesc(arg);
	char *paradesc=arglisttodesc(p->attri);
	int cnt=strlen(argdesc);
	for(int i=cnt-1; i>=0; i--)
	{
		if(argdesc[cnt-1-i]=='I' && paradesc[cnt-1-i]=='F')
		{
			int tmpind=localslimit-10;
			for(int j=0; j<i; j++)
				printf("%s %d\n", argdesc[cnt-1-j]=='F'?"fstore":"istore", tmpind--);
			printf("i2f\n");
			for(int j=0; j<i; j++)
				printf("%s %d\n", argdesc[cnt-i+j]=='F'?"fload":"iload", ++tmpind);
		}
	}
	printf("invokestatic %s/%s(%s)%s\n", filename, p->name, arglisttodesc(p->attri), rettodesc(p->type));
}

char* typetodesc(char *type)
{
	char *res=strdup("Z");
	if(isinteger(type))
		res=strdup("I");
	else if(isreal(type))
		res=strdup("F");
	else if(isstring(type))
		res=strdup("Ljava/lang/String;");
	return res;
}

void gengetval(struct entry *p)
{
	if(p->kind<=1)
	{
		printf("error in gengetval");
		return;
	}
	if(p->kind==4)//constant
	{
		if(isboolean(p->type))
			printf("iconst_%d ; %s\n", !strcmp(p->attri, "true")?1:0, p->name);
		else if(isinteger(p->type))
			printf("sipush %s ; %s\n", p->attri, p->name);
		else if(isreal(p->type))
			printf("ldc %s ; %s\n", p->attri, p->name);
		else
			printf("ldc \"%s\" ; %s\n", p->attri, p->name);
	}
	else
	{
		if(p->level==0)
		{
			char *desc=typetodesc(p->type);
			printf("getstatic %s/%s %s\n", filename, p->name, desc);
		}
		else
			printf("%s %d ; %s\n", isreal(p->type)?"fload":"iload", p->ind, p->name);
	}
}

int funcargmatch(char *arg, char *para)
{
	int p = 0, q = 0;
	int l = strlen(arg), l2 = strlen(para);
	while(1)
	{
		if (p == l && q == l2)
			return 1;
		if (p == l || q == l2)
			return 0;
		if (arg[p] != para[q])
		{
			if (!(arg[p] == 'i' && para[q] == 'r'))
				return 0;
			char *s = strdup(arg + p);
			if (strlen(s) < 7)
				return 0;
			s[7] = 0;
			if (strcmp(s, "integer"))
				return 0;
			s = strdup(para + q);
			if (strlen(s) < 4)
				return 0;
			s[4] = 0;
			if (strcmp(s, "real"))
				return 0;
			p += 6;
			q += 3;
		}
		p++;
		q++;
	}
}

char* kindtostr(int kind)
{
	if(kind==0)
		return strdup("program");
	if(kind==1)
		return strdup("function");
	if(kind==2)
		return strdup("parameter");
	if(kind==3)
		return strdup("variable");
	if(kind==4)
		return strdup("constant");
	if(kind==5)
		return strdup("loop variable");
	return strdup("");
}

int computetypedim(char *type)
{
	int res=0;
	for(int i=0; i<strlen(type); i++)
		if(type[i]=='[')
			res++;
	return res;
}

char* typedeldim(char *type, int dim)
{
	if(dim==0)
		return strdup(type);
	char *s=strtok(strdup(type), " ");
	char *s2=strtok(NULL, " ");
	int p=0;
	while(dim>0)
	{
		if(s2[p]==']')
			dim--;
		p++;
	}
	if(strlen(s2+p)==0)
		return strdup(s);
	int l=strlen(s);
	char *res=strdup(type);
	strcpy(res, s);
	strcpy(res+l, " ");
	strcpy(res+l+1, s2+p);
	return res;
}

char* typeadddim(char *type, int dim)
{
	int l=strlen(type);
	char *s=malloc((l+30)*sizeof(char));
	strcpy(s, type);
	if(s[l-1]!=']')
		sprintf(s+l, " [%d]", dim);
	else
	{
		int p=0;
		while(s[p]!='[')
			p++;
		sprintf(s+p, "[%d]", dim);
		strcpy(s+strlen(s), type+p);
	}
	return s;
}

int isstring(char *type)
{
	return !strcmp(type, "string");
}

int isboolean(char *type)
{
	return !strcmp(type, "boolean");
}

int isreal(char *type)
{
	return !strcmp(type, "real");
}

int isinteger(char *type)
{
	return !strcmp(type, "integer");
}

int isintegerreal(char *type)
{
	return isinteger(type) || isreal(type);
}

int isscalar(char *type)
{
	return isinteger(type) || isreal(type) || isboolean(type) || isstring(type);
}

char* arithrestype(char *type, char *type2)
{
	char *res=malloc(10*sizeof(char));
	strcpy(res, "integer");
	if(!(isintegerreal(type) && isintegerreal(type2)))
		res[0]=0;
	else if(isreal(type) || isreal(type2) )
		strcpy(res, "real");
	return res;
}

char* relarestype(char *type, char *type2)
{
	char *res=strdup("boolean");
	if(!(isintegerreal(type) && isintegerreal(type2)))
		res[0]=0;
	return res;
}

char* boolrestype(char *type, char *type2)
{
	char *res=strdup("boolean");
	if(!(isboolean(type)&&isboolean(type2)))
		res[0]=0;
	return res;
}

char* mergearglist(char *arg_list_0, char *arg_list_1)
{
	int l=strlen(arg_list_0);
	int l2=strlen(arg_list_1);
	if(l==0)
	{
		//printf("\n//////////%s//////////\n", arg_list_1);
		return arg_list_1;
	}
	char *s=malloc((l+l2+2+1)*sizeof(char));
	strcpy(s, arg_list_0);
	strcpy(s+l, ", ");
	strcpy(s+l+2, arg_list_1);
	//printf("\n//////////%s//////////\n", s);
	return s;
}

char* consarglist(char *arg_list_1, char *type)
{
	int cnt=0;
	char *s=strtok(arg_list_1, " ");
	while(s!=NULL)
	{
		cnt++;
		s=strtok(NULL, " ");
	}
	int l=strlen(type);
	s=malloc((cnt*(l+2))*sizeof(char));
	for(int i=0;i<cnt;i++)
	{
		strcpy(s+i*(l+2), type);
		if(i!=cnt-1)
			strcpy(s+i*(l+2)+l, ", ");
	}
	//printf("\n-=-=-=-=-=%s-=-=-=-=-=\n", s);
	return s;
}

void initentry(struct entry *p)
{
	p->name=strdup("");
	p->kind=-1;
	p->level=-1;
	p->type=strdup("");
	p->attri=strdup("");
	p->ind=-1;
	p->next=NULL;
}

void pushentryindepth(struct entry *p, int indepth)
{
	if(indepth>depth)
	{
		//printf("\n~~~~~~~~~~pushentryindepth failed : no table with such depth exists~~~~~~~~~~\n");
		return;
	}
	struct table *pt=tables;
	for(int i=depth;i>indepth; i--)
		pt=pt->next;
	if(pt->first==NULL)
		pt->first=p;
	else
	{
		struct entry *pe=pt->first;
		while(pe->next!=NULL)
			pe=pe->next;
		pe->next=p;
	}
}

void pushentry(struct entry *p)
{
	pushentryindepth(p, depth);
}

int checkexistbynameindepth(char *name, int indepth)
{
	if(name==NULL || indepth<0)
		return 0;
	if(indepth>depth)
		return 0;
	struct table *pt=tables;
	for(int i=depth;i>indepth; i--)
		pt=pt->next;
	struct entry *pe=pt->first;
	while(pe!=NULL)
	{
		if(strcmp(pe->name, name)==0)
			return 1;
		pe=pe->next;
	}
	return 0;
}

int checkexistbynamealldepth(char *name)
{
	for(int i=depth; i>=0;i--)
		if(checkexistbynameindepth(name, i))
			return 1;
	return 0;
}

int checkexistbyname(char *name)
{
	return checkexistbynameindepth(name, depth);
}

struct entry* getentrybynameindepth(char *name, int indepth)
{
	struct table *pt=tables;
	for(int i=depth; i>indepth; i--)
		pt=pt->next;
	struct entry *pe=pt->first;
	while(pe!=NULL)
	{
		if(strcmp(pe->name, name)==0)
			return pe;
		pe=pe->next;
	}
	return NULL;
}

struct entry* getentrybynamealldepth(char *name)
{
	for(int i=depth; i>=0;i--)
		if(checkexistbynameindepth(name, i))
			return getentrybynameindepth(name, i);
	return NULL;
}

struct entry* getentrybyname(char *name)
{
	return getentrybynameindepth(name, depth);
}

struct entry* getfuncentry(char *name)
{
	return getentrybynameindepth(name, 0);
}

int checkfuncexist(char *name)
{
	if(!checkexistbynameindepth(name, 0))
		return 0;
	return getentrybynameindepth(name, 0)->kind==1?1:0;
}

void pusharglist(char *arglist, char *type)
{
	char *s;
	s=strtok(arglist, " ");
	while(s!=NULL)
	{
		if(checkexistbyname(s))
			printf("####################<Error> found in Line %d : %s is redeclared\n", linenum, s);
		else
		{
			struct entry *p=malloc(sizeof(struct entry));
			initentry(p);
			p->name=strdup(s);
			p->kind=2;
			p->level=depth;
			p->type=strdup(type);
			p->ind=indcnt++;
			pushentry(p);
		}
		s=strtok(NULL, " ");
	}
}

void pushconslist(char *conslist, char *type, char *attri)
{
	char *s;
	s=strtok(conslist, " ");
	while(s!=NULL)
	{
		if(checkexistbyname(s))
			printf("####################<Error> found in Line %d : %s is redeclared\n", linenum, s);
		else
		{
			struct entry *p=malloc(sizeof(struct entry));
			initentry(p);
			p->name=strdup(s);
			p->kind=4;
			p->level=depth;
			p->type=strdup(type);
			p->attri=strdup(attri);
			p->ind=depth==0?-1:indcnt++;
			pushentry(p);
		}
		s=strtok(NULL, " ");
	}
}

void pushvarlist(char *varlist, char *type)
{
	char *s;
	s=strtok(varlist, " ");
	while(s!=NULL)
	{
		if(checkexistbyname(s))
			printf("####################<Error> found in Line %d : %s is redeclared\n", linenum, s);
		else
		{
			struct entry *p=malloc(sizeof(struct entry));
			initentry(p);
			p->name=strdup(s);
			p->kind=3;
			p->level=depth;
			p->type=strdup(type);
			p->ind=depth==0?-1:indcnt++;
			pushentry(p);
			if(p->level==0)
				printf(".field public static %s %s\n", p->name, typetodesc(p->type));
		}
		s=strtok(NULL, " ");
	}
}

void showentry(struct entry *p)
{
	if(p==NULL)
	{
		//printf("\n~~~~~~~~~~showentry failed : no entry to show~~~~~~~~~~\n");
		return;
	}
	if(p->name==NULL || p->type==NULL || p->attri==NULL)
	{
		//printf("\n~~~~~~~~~~showentry failed : input is NULL~~~~~~~~~~\n");
		return;
	}
	{
		printf("%-32s\t", p->name);
		printf("%-11s\t", kindtostr(p->kind));
		printf("%d%-10s\t", p->level, p->level>0?"(local)":"(global)");
		printf("%-17s\t", p->type);
		printf("%-11s\t", p->attri);
		printf("%-5d\t", p->ind);
		printf("\n");
	}
}

void showtable()
{
	if(tables==NULL)
	{
		//printf("\n~~~~~~~~~~showtable failed : no table to show~~~~~~~~~~\n");
		return;
	}
	for(int i=0;i< 110+10;i++)
		printf("=");
	printf("\n%-32s\t%-11s\t%-11s\t%-17s\t%-11s\t%-5s\t\n","Name","Kind","Level","Type","Attribute","ind");
	for(int i=0;i< 110+10;i++)
		printf("-");
	printf("\n");
	struct entry *p=tables->first;
	while(p!=NULL)
	{
		showentry(p);
		p=p->next;
	}
	for(int i=0;i< 110+10;i++)
		printf("=");
	printf("\n");
}

void pushtable()
{
	struct table *p=malloc(sizeof(struct table));
	p->first=NULL;
	p->next=tables;
	tables=p;
	depth++;
}

void poptable()
{
	if(tables==NULL)
	{
		//printf("\n~~~~~~~~~~poptable failed : no table to pop~~~~~~~~~~\n");
		return;
	}
	if(Opt_D)
		showtable();
	struct table *p=tables;
	tables=tables->next;
	free(p);
	depth--;
}

int yyerror( char *msg )
{
        fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
        fprintf( stderr, "|--------------------------------------------------------------------------\n" );
        exit(-1);
}

int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}

	if(strlen(argv[1])>=3)
	{
		filename=strdup(argv[1]);
		filename[strlen(filename)-2]=0;
	}
	else
	{
		fprintf( stdout, "illegal filename\n" );
		exit(-1);
	}

	FILE *fp = fopen( argv[1], "r" );
	
	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}

	//setbuf(stdout, NULL);
	char *out=malloc((strlen(filename+3))*sizeof(char));
	strcpy(out, filename);
	strcpy(out+strlen(out), ".j");
	freopen(out, "w", stdout);
	
	yyin = fp;
	yyparse();

	exit(0);
	fprintf( stdout, "\n" );
	    fprintf( stdout, "|---------------------------------------------|\n" );
	if(haserr)
		fprintf( stdout, "|        There is no syntactic error!         |\n" );
	else
		fprintf( stdout, "|  There is no syntactic and semantic error!  |\n" );
	    fprintf( stdout, "|---------------------------------------------|\n" );
	exit(0);
}

