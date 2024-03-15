                                                                // -*- C++ -*-
%require "3.8"
%language "c++"
// Set the namespace name to `parse', instead of `yy'.
%define api.prefix {parse}
%define api.namespace {parse}
%define api.parser.class {parser}
%define api.value.type variant
%define api.token.constructor

// We use a GLR parser because it is able to handle Shift-Reduce and
// Reduce-Reduce conflicts by forking and testing each way at runtime. GLR
// permits, by allowing few conflicts, more readable and maintainable grammars.
%glr-parser
%skeleton "glr2.cc"

// In TC, we expect the GLR to resolve one Shift-Reduce and zero Reduce-Reduce
// conflict at runtime. Use %expect and %expect-rr to tell Bison about it.
  // DONE: Some code was deleted here (Other directives).
%expect 1
%expect-rr 0

%define parse.error verbose
%defines
%debug
// Prefix all the tokens with TOK_ to avoid colisions.
%define api.token.prefix {TOK_}

/* We use pointers to store the filename in the locations.  This saves
   space (pointers), time (no deep copy), but leaves the problem of
   deallocation.  This would be a perfect job for a misc::symbol
   object (passed by reference), however Bison locations require the
   filename to be passed as a pointer, thus forcing us to handle the
   allocation and deallocation of this object.

   Nevertheless, all is not lost: we can still use a misc::symbol
   object to allocate a flyweight (constant) string in the pool of
   symbols, extract it from the misc::symbol object, and use it to
   initialize the location.  The allocated data will be freed at the
   end of the program (see the documentation of misc::symbol and
   misc::unique).  */
%define api.filename.type {const std::string}
%locations

/*---------------------.
| Support for tokens.  |
`---------------------*/
%code requires
{
#include <string>
#include <misc/algorithm.hh>
#include <misc/separator.hh>
#include <misc/symbol.hh>
#include <parse/fwd.hh>

  // Pre-declare parse::parse to allow a ``reentrant'' parsing within
  // the parser.
  namespace parse
  {
    ast_type parse(Tweast& input);
  }
}

// The parsing context.
%param { ::parse::TigerDriver& td }
%parse-param { ::parse::Lexer& lexer }

%printer { yyo << $$; } <int> <std::string> <misc::symbol>;

%token <std::string>    STRING "string"
%token <misc::symbol>   ID     "identifier"
%token <int>            INT    "integer"


/*-----------------------------------------.
| Code output in the implementation file.  |
`-----------------------------------------*/

%code
{
# include <parse/tweast.hh>
# include <misc/separator.hh>
# include <misc/symbol.hh>

  namespace
  {

    /// Get the metavar from the specified map.
    template <typename T>
    T*
    metavar(parse::TigerDriver& td, unsigned key)
    {
      parse::Tweast* input = td.input_;
      return input->template take<T>(key);
    }

  }
}

%code
{
  #include <parse/scantiger.hh>  // header file generated with reflex --header-file
  #undef yylex
  #define yylex lexer.lex  // Within bison's parse() we should invoke lexer.lex(), not the global lex()
}

// Definition of the tokens, and their pretty-printing.
%token AND          "&"
       ARRAY        "array"
       ASSIGN       ":="
       BREAK        "break"
       CAST         "_cast"
       CLASS        "class"
       COLON        ":"
       COMMA        ","
       DIVIDE       "/"
       DO           "do"
       DOT          "."
       ELSE         "else"
       END          "end"
       EQ           "="
       EXTENDS      "extends"
       FOR          "for"
       FUNCTION     "function"
       GE           ">="
       GT           ">"
       IF           "if"
       IMPORT       "import"
       IN           "in"
       LBRACE       "{"
       LBRACK       "["
       LE           "<="
       LET          "let"
       LPAREN       "("
       LT           "<"
       MINUS        "-"
       METHOD       "method"
       NE           "<>"
       NEW          "new"
       NIL          "nil"
       OF           "of"
       OR           "|"
       PLUS         "+"
       PRIMITIVE    "primitive"
       RBRACE       "}"
       RBRACK       "]"
       RPAREN       ")"
       SEMI         ";"
       THEN         "then"
       TIMES        "*"
       TO           "to"
       TYPE         "type"
       VAR          "var"
       WHILE        "while"
       EOF 0        "end of file"


  // FIXME: Some code was deleted here (Priorities/associativities).
  %precedence "do" ":=" "of" "class" "method"
  %left "|"
  %left "&"
  %nonassoc ">=" "<=" "<>" "<"  ">" "="
  %left "+" "-"
  %left "*" "/"
  %right "else" "then"
  

// Solving conflicts on:
// let type foo = bar
//     type baz = bat
// which can be understood as a list of two TypeChunk containing
// a unique TypeDec each, or a single TypeChunk containing two TypeDec.
// We want the latter.
%precedence CHUNKS
%precedence TYPE
%precedence PRIMITIVE
%precedence FUNCTION

  // DONE: Some code was deleted here (Other declarations).

%start program

%%
program:
  /* Parsing a source program.  */
  exp
   
| /* Parsing an imported file.  */
  chunks
   
;

exp:
//Litterals
  "nil"
  |INT
  | STRING
// array and record
  | ID "[" exp "]" "of" exp
  | typeid "{" exp.1 "}"
  //lvalue
  |lvalue
  //function call
  | ID "(" exp.2 ")"

//operateur
  | "-" exp
  | exp "+" exp
  | exp "-" exp
  | exp "*" exp
  | exp "/" exp
  | exp "|" exp
  | exp "&" exp
  | exp ">=" exp
  | exp "<=" exp
  | exp "=" exp
  | exp "<>" exp
  | exp ">" exp
  | exp "<" exp

  | "(" exps ")"
//Assignement
  | lvalue ":=" exp
//control structure
  |"if" exp "then" exp 
  |"if" exp "then" exp "else" exp
  | "while" exp "do" exp
  | "for" ID ":=" exp "to" exp "do" exp
  | "break"
  | "let" chunks "in" exps "end"
// In Progress
  | "new" typeid // or type_id ??
  | lvalue "." ID "(" exp.3 ")"
;

exp.3:
  %empty
  | exp exp.2.1
  ;

extends:
  %empty
  | "extends" typeid
  ;
//In Progress

lvalue:
  ID
  // record filed access
  | lvalue "." ID
  //array subscript
  | lvalue "[" exp "]"
  ;



exps: 
  %empty
  |exp exps.1
  ;
exps.1:
  %empty
  |";" exp exps.1
  ;
  

exp.2:
  %empty
  |exp exp.2.1
  ;

exp.2.1:
  %empty
  |"," exp exp.2.1
  ;

exp.1:
  %empty
  |ID "=" exp exp.1.1
  ;

exp.1.1:
  %empty
  |"," ID "=" exp exp.1.1
  ;

/*---------------.
| Declarations.  |
`---------------*/

%token CHUNKS "_chunks";
chunks:
  /* Chunks are contiguous series of declarations of the same type
     (TypeDec, FunctionDec...) to which we allow certain specfic behavior like
     self referencing.
     They are held by a ChunkList, that can be empty, like in this case:
        let
        in
            ..
        end
     which is why we end the recursion with a %empty. */
  %empty                  
| tychunk   chunks 
| funchunk  chunks
| varchunk  chunks
| "import" STRING chunks
  // DONE: Some code was deleted here (More rules).
;

funchunk:
  fundec %prec CHUNKS
| fundec funchunk
;

fundec:
  "function" ID "(" tyfields ")" funchunk.1 "=" exp
| "primitive" ID "(" tyfields ")" funchunk.1
;

varchunk:
  vardec
;

vardec:
  "var" ID funchunk.1 ":=" exp ;

funchunk.1:
  %empty
| ":" typeid
;

/*--------------------.
| Type Declarations.  |
`--------------------*/

tychunk:
  /* Use `%prec CHUNKS' to do context-dependent precedence and resolve a
     shift-reduce conflict. */
  tydec %prec CHUNKS  
| tydec tychunk       
;

tydec:
  "type" ID "=" ty
  | "class" ID extends "{" classfields "}"
;

ty:
  typeid               
| "{" tyfields "}"     
| "array" "of" typeid  
| "class" extends "{" classfields "}"
;

tyfields:
  %empty               
| tyfields.1           
;

tyfields.1:
  tyfields.1 "," tyfield 
| tyfield                
;

tyfield:
  ID ":" typeid     
;

%token NAMETY "_namety";
typeid:
  ID                    
  /* This is a metavariable. It it used internally by TWEASTs to retrieve
     already parsed nodes when given an input to parse. */
| NAMETY "(" INT ")"    
;

classfields:
   %empty
  | classfield classfields
  ;

classfield:
  vardec
  |"method" ID "(" tyfields ")" classfield.2 "=" exp
  ;

classfield.2:
  %empty
  | ":" typeid
  ;
%%

void
parse::parser::error(const location_type& l, const std::string& m)
{
  // DONE: Some code was deleted here.
  td.error_ << misc::error::error_type::parse
            << td.location_
            << ": unexepected token: `"
            << misc::escape(m) << "'\n";
}
