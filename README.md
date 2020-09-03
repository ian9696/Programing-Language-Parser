A parser with syntax-directed translation scheme implemented using Lex and Yacc.\
The parser generates Java assembly code, which can be translated to Java bytecode by Jasmin and then run on Java Virtual Machine.

The parser generates assembly code with messages for semantic errors, if any. It terminates immediately when a syntax error is found.

Usage:\
make clean\
rm code.j code.class\
make\
./parser code.p\
java -jar jasmin-2.4/jasmin.jar code.j\
java code

Language features:\
Declarations for global/local variables and constants\
Arithmetic and boolean expressions\
Assignments\
Print statements\
Read statements\
Compound statements\
If statements and for/while Loops\
Procedure declarations and invocations
