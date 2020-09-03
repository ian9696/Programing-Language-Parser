all: parser

y.tab.c y.tab.h: parser.y head.h
	yacc -d parser.y

lex.yy.c: scanner.l head.h
	lex scanner.l

y.tab.o: y.tab.c
	cc -c y.tab.c

lex.yy.o: lex.yy.c
	cc -c lex.yy.c

parser: y.tab.o lex.yy.o
	cc -o parser y.tab.o lex.yy.o -lfl

clean:
	rm y.tab.c y.tab.h lex.yy.c y.tab.o lex.yy.o parser
