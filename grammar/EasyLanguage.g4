grammar EasyLanguage;

options {
	caseInsensitive = true;
}

// Parser rules
start: program EOF;

program: (using_stmt | declaration | statement | attribute_stmt)*;

// Using directives
using_stmt: USING dotted_name SEMI;
dotted_name: IDENT (DOT IDENT)*;

// Declarations
declaration:
	var_decl
	| input_decl
	| array_decl
	| const_decl
	| external_decl
	| method_decl;

// Variable declarations
var_decl: VARS COLON var_item (COMMA var_item)* SEMI;
var_item: INTRABARPERSIST? type_ref? IDENT (LPAR expr RPAR)?;

// Input declarations
input_decl: (INPUT | INPUTS) COLON input_item (COMMA input_item)* SEMI;
input_item: type_ref? IDENT LPAR expr RPAR;

// Array declarations
array_decl: ARRAY COLON array_item (COMMA array_item)* SEMI;
array_item: type_ref? IDENT array_dims? (LPAR expr RPAR)?;
array_dims: LBRACK (expr (COMMA expr)*)? RBRACK;

// Constant declarations
const_decl: CONSTS COLON const_item (COMMA const_item)* SEMI;
const_item: type_ref? IDENT LPAR expr RPAR;

// External declarations
external_decl:
	EXTERNAL COLON external_func (COMMA external_func)* SEMI;
external_func: type_ref IDENT LPAR param_list? RPAR;

// Method declarations (Object-Oriented EasyLanguage)
method_decl:
	METHOD method_return_type IDENT LPAR param_list? RPAR method_block;

method_return_type: VOID | type_ref;

method_block: (var_decl)* BEGIN statement* END SEMI?;

// Parameter lists
param_list: param (COMMA param)*;
param: type_ref IDENT;

// Types
type_spec:
	NUMERIC
	| BOOLEAN
	| BOOL
	| STRING_TYPE
	| INT
	| DOUBLE
	| FLOAT
	| TRUEFALSE_TYPE;

// General type reference: either a primitive type or a qualified name (e.g., tsopt.Job)
type_ref: type_spec | qualified_name;

// Statements
statement:
	simple_stmt
	| if_stmt
	| for_stmt
	| while_stmt
	| repeat_stmt
	| switch_stmt
	| block
	| try_stmt
	| return_stmt
	| break_stmt
	| continue_stmt
	| once_stmt
	| order_stmt
	| sl_pt_directive_stmt
	| setExitOnCloseStmt;

// Attributes like [IntrabarOrderGeneration = True]
attribute_stmt:
	LBRACK attr_assign (COMMA attr_assign)* RBRACK SEMI?;
attr_assign: IDENT ASSIGN expr;

// Simple statements
simple_stmt:
	empty_stmt
	| assign_stmt
	| plot_stmt
	| print_stmt
	| commentary_stmt
	| breakpoint_stmt
	| throw_stmt
	| expr_stmt;

empty_stmt: SEMI;

assign_stmt: lvalue assign_op expr SEMI?;
assign_op: ASSIGN | PLUS_ASSIGN | MINUS_ASSIGN;

// Assignable targets: identifier with optional member/index/data suffixes (no calls)
lvalue: IDENT (member_suffix | bracket_suffix | data_suffix)*;

plot_stmt: (
		PLOT_FN LPAR arg_list? RPAR
		| PLOT LPAR arg_list? RPAR
	) SEMI;
print_stmt: PRINT LPAR arg_list? RPAR SEMI;
throw_stmt: THROW expr SEMI;
commentary_stmt: COMMENTARY LPAR arg_list? RPAR SEMI;
breakpoint_stmt: BREAKPOINT SEMI;
expr_stmt: expr SEMI;

return_stmt: RETURN expr? SEMI;
break_stmt: BREAK_KW SEMI;
continue_stmt: CONTINUE_KW SEMI;

// Control structures
if_stmt:
	IF LPAR? expr RPAR? THEN statement (ELSE statement)? SEMI?;

for_stmt: FOR IDENT ASSIGN expr (TO | DOWNTO) expr statement;

while_stmt: WHILE expr statement;

repeat_stmt: REPEAT statement* UNTIL expr SEMI;

switch_stmt: SWITCH LPAR expr RPAR switch_body;
switch_body: BEGIN switch_section* END SEMI?;
switch_section:
	CASE case_labels COLON statement*
	| DEFAULT COLON statement*;
case_labels: case_label_item (COMMA case_label_item)*;
case_label_item: NUMBER | STRING | IDENT | TRUE | FALSE | NULL;

// Blocks
block: BEGIN statement* END SEMI?;

// Try/Catch/Finally
try_stmt:
	TRY statement+ catch_clause* finally_clause? END SEMI?;
catch_clause:
	CATCH (LPAR qualified_name IDENT? RPAR)? statement+;
finally_clause: FINALLY statement+;

// ONCE
once_stmt: ONCE (LPAR expr RPAR)? (THEN)? statement;

// Built-in stop/profit directives
sl_pt_directive_stmt:
	setStopLossStmt
	| setProfitTargetStmt
	| setStopPositionStmt
	| setStopShareStmt
	| setStopContractStmt;

// Individual directive subrules (keep specific visitor hooks)
setStopLossStmt: SETSTOPLOSS LPAR arg_list? RPAR SEMI;
setProfitTargetStmt: SETPROFITTARGET LPAR arg_list? RPAR SEMI;
setStopPositionStmt: SETSTOPPOSITION LPAR arg_list? RPAR SEMI;
setStopShareStmt: SETSTOPSHARE LPAR arg_list? RPAR SEMI;
setStopContractStmt: SETSTOPCONTRACT LPAR arg_list? RPAR SEMI;
setExitOnCloseStmt: SETEXITONCLOSE SEMI;

// Trading order statements
order_stmt:
	order_side order_qty? order_label? timing_spec price_spec order_type? SEMI;
order_side:
	BUY
	| SELL
	| SELLSHORT // single-token form
	| SELL SHORT // multi-word form
	| BUYTOCOVER // single-token form
	| BUY TO COVER; // multi-word form
order_label: LPAR STRING RPAR;
timing_spec: NEXT BAR_KW | THIS BAR_KW;
price_spec: (AT | ON) expr
	| (AT | ON) (CLOSE | OPEN | MARKET) (OF THIS BAR_KW)?;
order_type: STOP_KW | LIMIT_KW | MARKET;

order_qty: expr (SHARE | SHARES | CONTRACT | CONTRACTS)?;

qualified_name: IDENT (DOT IDENT)*;

// Expressions
expr: logical_or_expr;
logical_or_expr: logical_xor_expr (OR logical_xor_expr)*;
logical_xor_expr: logical_and_expr (XOR logical_and_expr)*;
logical_and_expr: equality_expr (AND equality_expr)*;
equality_expr: relational_expr (cmp_op relational_expr)?;
cmp_op: LE | GE | NE | LT | GT | ASSIGN;
relational_expr: additive_expr;
additive_expr:
	additive_expr PLUS multiplicative_expr
	| additive_expr MINUS multiplicative_expr
	| multiplicative_expr;
multiplicative_expr:
	multiplicative_expr MUL power_expr
	| multiplicative_expr DIV power_expr
	| multiplicative_expr MOD power_expr
	| power_expr;
power_expr: unary_expr (POWER power_expr)?;

unary_expr:
	PLUS unary_expr
	| MINUS unary_expr
	| NOT unary_expr
	| NEW qualified_name (LPAR arg_list? RPAR)?
	| postfix;

// Postfix
postfix: primary (postfix_part)*;
postfix_part:
	call_suffix
	| member_suffix
	| bracket_suffix
	| data_suffix;
call_suffix: LPAR arg_list? RPAR;
member_suffix: DOT IDENT;
bracket_suffix: LBRACK expr RBRACK;
data_suffix: OF DATA_REF | OF DATA_KW LPAR expr RPAR;

// Primary
primary: literal | series_word | IDENT | LPAR expr RPAR;
series_word:
	OPEN
	| HIGH
	| LOW
	| CLOSE
	| DATE
	| TIME
	| VOLUME
	| OPENINT
	| CLOSED
	| OPEND
	| HIGHD
	| LOWD;
literal: NUMBER | STRING | TRUE | FALSE | NULL;

// Arguments
arg_list: expr (COMMA expr)*;

//--------------------------------------------------------------------------------
// Lexer rules --------------------------------------------------------------------------------

WS: [ \t\r\n]+ -> skip;

// Comments & directives
COMMENT_SINGLE: '//' ~[\r\n]* -> skip;
// Support double-brace section markers like {{Inputs}} by skipping the entire token
COMMENT_DBL_BRACES: '{{' ( ~'}' | '}' ~'}')* '}}' -> skip;
COMMENT_MULTI: '{' ~[}]* '}' -> skip;
DIRECTIVE: '#' ~[\r\n]* -> skip;

// Skip common non-significant words
SKIPWORD: (
		'a'
		| 'an'
		| 'by'
		| 'does'
		| 'from'
		| 'is'
		| 'place'
		| 'than'
		| 'the'
		| 'was'
	) -> skip;

// Keywords and symbols
IF: 'if';
THEN: 'then';
ELSE: 'else';
BEGIN: 'begin';
END: 'end';
FOR: 'for';
TO: 'to';
DOWNTO: 'downto';
WHILE: 'while';
REPEAT: 'repeat';
UNTIL: 'until';
VARS: 'vars' | 'var' | 'variable' | 'variables';
INPUT: 'input';
INPUTS: 'inputs';
ARRAY: 'array' | 'arrays';
PRINT: 'print';
PLOT_FN: 'plot' ([1-9][0-9]?);
COMMENTARY: 'commentary';
BREAKPOINT: 'breakpoint';
PLOT: 'plot';
TRY: 'try';
CATCH: 'catch';
FINALLY: 'finally';
THROW: 'throw';
NEW: 'new';
USING: 'using';
METHOD: 'method';
VOID: 'void';
INTRABARPERSIST: 'intrabarpersist';
AND: 'and';
OR: 'or';
NOT: 'not';
ONCE: 'once';
IN: 'in';
BETWEEN: 'between';
OF: 'of';
AT: 'at';
ON: 'on';
TRUE: 'true';
FALSE: 'false';
NULL: 'null';
EXTERNAL: 'external';
SWITCH: 'switch';
CASE: 'case';
DEFAULT: 'default';
BREAK_KW: 'break';
CONTINUE_KW: 'continue';
CONSTS: 'consts' | 'const' | 'constant' | 'constants';
RETURN: 'return';

// Primitive types
NUMERIC: 'numeric';
BOOLEAN: 'boolean';
BOOL: 'bool';
STRING_TYPE: 'string';
INT: 'int';
DOUBLE: 'double';
FLOAT: 'float';
TRUEFALSE_TYPE: 'truefalse';

// Order & timing
BUY: 'buy';
SELL: 'sell';
SELLSHORT: 'sellshort';
BUYTOCOVER: 'buytocover';
NEXT: 'next';
THIS: 'this';
BAR_KW: 'bar';
MARKET: 'market';
STOP_KW: 'stop';
LIMIT_KW: 'limit';
SHARE: 'share';
SHARES: 'shares';
CONTRACT: 'contract';
CONTRACTS: 'contracts';

// Built-in stop/profit directive tokens
SETSTOPLOSS: 'setstoploss';
SETPROFITTARGET: 'setprofittarget';
SETSTOPPOSITION: 'setstopposition';
SETSTOPSHARE: 'setstopshare';
SETSTOPCONTRACT: 'setstopcontract';
SETEXITONCLOSE: 'setexitonclose';

OPEN: 'open';
HIGH: 'high';
LOW: 'low';
CLOSE: 'close';
DATE: 'date';
TIME: 'time';
VOLUME: 'volume';
OPENINT: 'openint';
CLOSED: 'closed';
OPEND: 'opend';
HIGHD: 'highd';
LOWD: 'lowd';

// Data series reference tokens
fragment DIGIT: [0-9];
DATA_REF: 'data' DIGIT+;
DATA_KW: 'data';

// Literals & identifiers
IDENT: [@_a-z][@_a-z0-9]*;
NUMBER: DIGIT+ ('.' DIGIT+)?;
STRING: '"' (~["\\] | '\\' .)* '"';

// Symbols & operators
SEMI: ';';
COMMA: ',';
COLON: ':';
DOT: '.';
LPAR: '(';
RPAR: ')';
LBRACK: '[';
RBRACK: ']';
ASSIGN: '=';
PLUS_ASSIGN: '+=';
MINUS_ASSIGN: '-=';

LE: '<=';
GE: '>=';
NE: '<>';
LT: '<';
GT: '>';
PLUS: '+';
MINUS: '-';
MUL: '*';
DIV: '/';
POWER: '^';
MOD: 'mod';
XOR: 'xor';
SHORT: 'short';
COVER: 'cover';
