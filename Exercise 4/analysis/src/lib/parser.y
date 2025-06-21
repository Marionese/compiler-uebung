%define parse.error verbose
%define parse.trace
%parse-param {ParseResult *out}

%code requires {
	#include <stdio.h>
	#include <stdarg.h>
	#include "ast.h"
	#include "vec.h"
	#include "symtab.h"
	
	/* Vorwärtsdeklaration für die yyparse()-Funktion */
	typedef struct ParseResult ParseResult;
	
	extern int yylex(void);
	extern int yylineno;
	extern FILE *yyin;
}

%code provides {
	/**
	 * Variantentyp des Ergebnisses des Parsevorganges.
	 */
	struct ParseResult {
		enum ParseResultTag {
			PARSE_OK,
			PARSE_ERR_SYNTAX,
			PARSE_ERR_SEMANTIC
		} tag;
		
		union {
			struct {
				Program ok;
				Symtab tab;
			};
			char err[256];
		};
	};
	
	/**
	 * Die obere Parse-Funktion: wandelt den Eingabestrom in einen AST (`Program`)
	 * um oder gibt eine Fehlermeldung zurück, falls das Programm inkorrekt ist.
	 */
	extern ParseResult astParse(FILE *input);
	
	/**
	 * Speichert die Fehlermeldung für den Rufer.
	 * Die Funktion akzeptiert eine variable Argumentliste und nutzt die Syntax von
	 * printf.
	 * @param out  Zeiger auf das Ausgabeargument der parse-Funktion
	 * @param msg  die Fehlermeldung
	 * @param ...  variable Argumentliste für die Formatierung von \p msg
	 */
	extern void yyerror(ParseResult *out, const char *msg, ...);
}

%code {
	/**
	 * Meldet einen semantischen Fehler, falls die Bedingung zutrifft.
	 */
	#define DENY(COND, ...) do { \
		if (COND) { \
			yyerror(out, __VA_ARGS__); \
			out->tag = PARSE_ERR_SEMANTIC; \
			YYABORT; \
		} \
	} while (0)
}

%union {
	/* lexical token types */
	char *string;
	double floatValue;
	int intValue;
	
	/* ast types */
	Item item;
	
	FuncDef func_def;
	FuncParam func_param;
	FuncCall func_call;
	
	Block block;
	
	Stmt stmt;
	IfStmt if_stmt;
	ForStmt for_stmt;
	WhileStmt while_stmt;
	PrintStmt print_stmt;
	VarDef var_def;
	
	Assign assign;
	Expr expr;
	
	DataType type;
	
	/* vectors of ast types */
	FuncParam *func_params;
	Stmt *stmts;
	Expr *exprs;
}

/* define the printer routines for improved debug output */
%printer { fprintf(yyoutput, "\"%s\"", $$); }     <string>
%printer { fprintf(yyoutput, "%g", $$); }         <floatValue>
%printer { fprintf(yyoutput, "%i", $$); }         <intValue>
%printer { astItemPrint(&$$, 0, yyoutput); }      <item>
%printer { astFuncDefPrint(&$$, 0, yyoutput); }   <func_def>
%printer { astFuncParamPrint(&$$, 0, yyoutput); } <func_param>
%printer { astFuncCallPrint(&$$, 0, yyoutput); }  <func_call>
%printer { astBlockPrint(&$$, 0, yyoutput); }     <block>
%printer { astStmtPrint(&$$, 0, yyoutput); }      <stmt>
%printer { astIfStmtPrint(&$$, 0, yyoutput); }    <if_stmt>
%printer { astForStmtPrint(&$$, 0, yyoutput); }   <for_stmt>
%printer { astWhileStmtPrint(&$$, 0, yyoutput); } <while_stmt>
%printer { astPrintStmtPrint(&$$, 0, yyoutput); } <print_stmt>
%printer { astVarDefPrint(&$$, 0, yyoutput); }    <var_def>
%printer { astAssignPrint(&$$, 0, yyoutput); }    <assign>
%printer { astExprPrint(&$$, 0, yyoutput); }      <expr>

/* define destructors in order to prevent memory leaks */
%destructor { free($$); }                 <string>
%destructor { astItemRelease(&$$); }      <item>
%destructor { astFuncDefRelease(&$$); }   <func_def>
%destructor { astFuncParamRelease(&$$); } <func_param>
%destructor { astFuncCallRelease(&$$); }  <func_call>
%destructor { astBlockRelease(&$$); }     <block>
%destructor { astStmtRelease(&$$); }      <stmt>
%destructor { astIfStmtRelease(&$$); }    <if_stmt>
%destructor { astForStmtRelease(&$$); }   <for_stmt>
%destructor { astWhileStmtRelease(&$$); } <while_stmt>
%destructor { astPrintStmtRelease(&$$); } <print_stmt>
%destructor { astVarDefRelease(&$$); }    <var_def>
%destructor { astAssignRelease(&$$); }    <assign>
%destructor { astExprRelease(&$$); }      <expr>

%destructor {
	if ($$ != NULL) {
		vecForEach(FuncParam *e, $$) {
			astFuncParamRelease(e);
		}
		vecRelease($$);
	}
} <func_params>

%destructor {
	if ($$ != NULL) {
		vecForEach(Stmt *e, $$) {
			astStmtRelease(e);
		}
		vecRelease($$);
	}
} <stmts>

%destructor {
	if ($$ != NULL) {
		vecForEach(Expr *e, $$) {
			astExprRelease(e);
		}
		vecRelease($$);
	}
} <exprs>

/* extra token declaration to support versions of bison older than 3.6;
 * ignore the warning in your editor */
%token YYUNDEF

/* used tokens (KW is abbreviation for keyword) */
%token LOG_AND      "&&"
%token LOG_OR       "||"
%token EQ           "=="
%token NEQ          "!="
%token LT           "<"
%token GT           ">"
%token LEQ          "<="
%token GEQ          ">="
%token ADD          "+"
%token SUB          "-"
%token MUL          "*"
%token DIV          "/"
%token ASSIGN       "="
%token KW_BOOLEAN   "bool"
%token KW_DO        "do"
%token KW_ELSE      "else"
%token KW_FLOAT     "float"
%token KW_FOR       "for"
%token KW_IF        "if"
%token KW_INT       "int"
%token KW_PRINT     "print"
%token KW_RETURN    "return"
%token KW_VOID      "void"
%token KW_WHILE     "while"
%token <intValue>   INT_LITERAL
%token <floatValue> FLOAT_LITERAL
%token <intValue>   BOOL_LITERAL
%token <string>     STRING_LITERAL
%token <string>     IDENT

/* workaround for handling dangling else */
/* LOWER_THAN_ELSE stands for a non-existing else */
%nonassoc LOWER_THAN_ELSE
%nonassoc KW_ELSE

%type <item>        item
%type <func_def>    functiondefinition
%type <func_param>  parameter
%type <func_params> parameterlist opt_parameterlist
%type <func_call>   functioncall
%type <block>       block
%type <stmt>        statement returnstatement opt_else
%type <stmts>       statementlist
%type <if_stmt>     ifstatement
%type <for_stmt>    forstatement
%type <while_stmt>  whilestatement dowhilestatement
%type <print_stmt>  print
%type <var_def>     declassignment
%type <assign>      statassignment
%type <expr>        assignment expr simpexpr term factor
%type <exprs>       argumentlist opt_argumentlist

%type <type> type

%%

start:
	program
	;

/* see EBNF grammar for further information */
program:
	/* empty */
	| program item { vecPush(out->ok.items) = $item; }
	;

item:
	declassignment ';' {
		$$ = astItemFromVarDef($declassignment);
	}
	| functiondefinition {
		$$ = astItemFromFuncDef($functiondefinition);
	}
	;

functiondefinition:
	type IDENT[ident] '(' opt_parameterlist[params] ')' '{'
		statementlist[body]
	'}' {
		$$ = astFuncDefNew($type, $ident, $params, $body);
	}
	;

opt_parameterlist:
	/* empty */ { $$ = NULL; }
	| parameterlist
	;

parameterlist:
	parameter[param] {
		vecInit($$);
		vecPush($$) = $param;
	}
	| parameterlist[list] ',' parameter[param] {
		vecPush($list) = $param;
		$$ = $list;
	}
	;

parameter:
	type IDENT[ident] {
		$$ = astFuncParamNew($type, $ident);
	}
	;

functioncall:
	IDENT[ident] '(' opt_argumentlist[args] ')' {
		$$ = astFuncCallNew($ident, $args);
	}
	;

opt_argumentlist:
	/* empty */ { $$ = NULL; }
	| argumentlist
	;

argumentlist:
	assignment[expr] {
		vecInit($$);
		vecPush($$) = $expr;
	}
	| argumentlist[list] ',' assignment[expr] {
		vecPush($list) = $expr;
		$$ = $list;
	}
	;

statementlist:
	/* empty */ {
		vecInit($$);
	}
	| statementlist[list] statement[stmt] {
		vecPush($list) = $stmt;
		$$ = $list;
	}
	;

block:
	'{' statementlist[stmts] '}' {
		$$ = astBlockNew($stmts);
	}
	;

statement:
	  ifstatement {
		$$ = astStmtFromIfStmt($ifstatement);
	  }
	| forstatement {
		$$ = astStmtFromForStmt($forstatement);
	}
	| whilestatement {
		$$ = astStmtFromWhileStmt($whilestatement);
	}
	| dowhilestatement ';' {
		$$ = astStmtFromDoWhileStmt($dowhilestatement);
	}
	| returnstatement ';'
	| print ';' {
		$$ = astStmtFromPrintStmt($print);
	}
	| declassignment ';' {
		$$ = astStmtFromVarDef($declassignment);
	}
	| statassignment ';' {
		$$ = astStmtFromAssign($statassignment);
	}
	| functioncall ';' {
		$$ = astStmtFromFuncCall($functioncall);
	}
	| block {
		$$ = astStmtFromBlock($block);
	}
	| ';' {
		$$ = astStmtNew();
	}
	;

ifstatement:
	KW_IF '(' assignment[cond] ')' statement[true] opt_else[false] {
		$$ = astIfStmtNew($cond, $true, $false);
	}
	;

/* KW_ELSE hat höhere Präzedenz, so dass die zweite Regel ausgeführt wird,
 * falls 'else' als nächstes in der Eingabe steht */
opt_else:
	/* empty */ %prec LOWER_THAN_ELSE {
		$$ = astStmtNew();
	}
	| KW_ELSE statement[body] {
		$$ = $body;
	}
	;

forstatement:
	KW_FOR '(' declassignment[init] ';' expr[cond] ';' statassignment[update] ')' statement[body] {
		$$ = astForStmtNew(
			astForInitFromVarDef($init),
			$cond, $update, $body
		);
	}
	| KW_FOR '(' statassignment[init] ';' expr[cond] ';' statassignment[update] ')' statement[body] {
		$$ = astForStmtNew(
			astForInitFromAssign($init),
			$cond, $update, $body
		);
	}
	;

dowhilestatement:
	KW_DO statement[body] KW_WHILE '(' assignment[cond] ')' {
		$$ = astWhileStmtNew($cond, $body);
	}
	;

whilestatement:
	KW_WHILE '(' assignment[cond] ')' statement[body] {
		$$ = astWhileStmtNew($cond, $body);
	}
	;

returnstatement:
	KW_RETURN {
		$$ = astStmtFromReturn(NULL);
	}
	| KW_RETURN assignment[expr] {
		$$ = astStmtFromReturn(&$expr);
	}
	;

print:
	KW_PRINT '(' opt_argumentlist[args] ')' {
		$$ = astPrintStmtNew($args);
	}
	;

declassignment:
	type IDENT[ident] {
		$$ = astVarDefNew($type, $ident, NULL);
	}
	| type IDENT[ident] ASSIGN assignment[init] {
		$$ = astVarDefNew($type, $ident, &$init);
	}
	;

type:
	KW_BOOLEAN { $$ = TYPE_BOOL; }
	| KW_FLOAT { $$ = TYPE_FLOAT; }
	| KW_INT   { $$ = TYPE_INT; }
	| KW_VOID  { $$ = TYPE_VOID; }
	;

statassignment:
	IDENT[lhs] ASSIGN assignment[rhs] {
		$$ = astAssignNew($lhs, $rhs);
	}
	;

assignment:
	IDENT[lhs] ASSIGN assignment[rhs] {
		$$ = astExprFromAssign(astAssignNew($lhs, $rhs));
	}
	| expr
	;

expr:
	simpexpr
	| simpexpr[lhs] EQ  simpexpr[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_EQ);
	}
	| simpexpr[lhs] NEQ simpexpr[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_NEQ);
	}
	| simpexpr[lhs] LEQ simpexpr[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_LEQ);
	}
	| simpexpr[lhs] GEQ simpexpr[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_GEQ);
	}
	| simpexpr[lhs] LT simpexpr[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_LT);
	}
	| simpexpr[lhs] GT simpexpr[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_GT);
	}
	;

simpexpr:
	term
	| simpexpr[lhs] ADD term[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_ADD);
	}
	| simpexpr[lhs] SUB term[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_SUB);
	}
	| simpexpr[lhs] LOG_OR term[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_LOG_OR);
	}
	;

term:
	factor
	| term[lhs] MUL factor[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_MUL);
	}
	| term[lhs] DIV factor[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_DIV);
	}
	| term[lhs] LOG_AND factor[rhs] {
		$$ = astExprFromBinOpExpr($lhs, $rhs, BIN_OP_LOG_AND);
	}
	;

factor:
	SUB factor[val] {
		$$ = astExprFromUnaryMinus($val);
	}
	| INT_LITERAL[lit] {
		$$ = astExprFromLiteral(astLiteralFromInt($lit));
	}
	| FLOAT_LITERAL[lit] {
		$$ = astExprFromLiteral(astLiteralFromFloat($lit));
	}
	| BOOL_LITERAL[lit] {
		$$ = astExprFromLiteral(astLiteralFromBool($lit));
	}
	| STRING_LITERAL[lit] {
		$$ = astExprFromLiteral(astLiteralFromString($lit));
	}
	| IDENT[id] {
		$$ = astExprFromIdent($id);
	}
	| functioncall {
		$$ = astExprFromFuncCall($functioncall);
	}
	| '(' assignment ')' {
		$$ = $assignment;
	}
	;

%%

void yyerror(ParseResult *out, const char* msg, ...) {
	va_list args;
	int len = 0;
	
	/* free the space for the ok-branch and set the error code */
	if (out->tag == PARSE_OK) {
		symtabRelease(&out->tab);
		astProgramRelease(&out->ok);
	}
	
	out->tag = PARSE_ERR_SYNTAX;
	
	/* print the message into the buffer */
	va_start(args, msg);
	len = snprintf(out->err, sizeof(out->err), "Error in line %d: ", yylineno);
	vsnprintf(out->err + len, sizeof(out->err) - len, msg, args);
	va_end(args);
}

ParseResult astParse(FILE *input) {
	ParseResult out = {
		.tag = PARSE_OK,
		.ok = astProgramNew(),
		.tab = symtabNew()
	};
	yyin = input;
	yyparse(&out);
	return out;
}
