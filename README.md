## Programming Language Parser
A parser with syntax-directed translation scheme implemented using Lex and Yacc.

The parser generates Java assembly code, which can then be translated to Java bytecode by Jasmin and run on Java Virtual Machine.

The parser generates assembly code with messages for semantic errors, if any. It terminates immediately when a syntax error is found.

## Usage
Generate parser using Lex and Yacc.
```
make
```
Compile source code using parser.
```
./parser code.p
```
Convert to Java bytecode using Jasmin.
```
java -jar jasmin-2.4/jasmin.jar code.j
```
Run the program.
```
java code
```
Remove temporary files.
```
make clean
rm code.j code.class
```

## Language Features
Declarations for global/local variables and constants

Arithmetic and boolean expressions

Assignments

Print statements

Read statements

Compound statements

If statements and for/while loops

Procedure declarations and invocations
