/* -*- C++ -*- */
// %option defines the parameters with which the reflex will be launched
%option noyywrap
// To enable compatibility with bison
%option bison-complete
%option bison-cc-parser=parser
%option bison_cc_namespace=parse
%option bison-locations

%option lex=lex
// Add a param of function lex() generate in Lexer class
%option params="::parse::TigerDriver& td"
%option namespace=parse
// Name of the class generate by reflex
%option lexer=Lexer

%top{

#define YY_EXTERN_C extern "C" // For linkage rule

#include <cerrno>
#include <climits>
#include <regex>
#include <string>

#include <boost/lexical_cast.hpp>

#include <misc/contract.hh>
  // Using misc::escape is very useful to quote non printable characters.
  // For instance
  //
  //    std::cerr << misc::escape('\n') << '\n';
  //
  // reports about `\n' instead of an actual new-line character.
#include <misc/escape.hh>
#include <misc/symbol.hh>
#include <parse/parsetiger.hh>
#include <parse/tiger-driver.hh>

  // DONE: Some code was deleted here (Define YY_USER_ACTION to update locations).
#define YY_USER_ACTION td.location_.columns(size());  

#define TOKEN(Type)                             \
  parser::make_ ## Type(td.location_)

#define TOKEN_VAL(Type, Value)                  \
  parser::make_ ## Type(Value, td.location_)

# define CHECK_EXTENSION()                              \
  do {                                                  \
    if (!td.enable_extensions_p_)                       \
      td.error_ << misc::error::error_type::scan        \
                << td.location_                         \
                << ": invalid identifier: `"            \
                << misc::escape(text()) << "'\n";       \
  } while (false)


%}

%x SC_COMMENT SC_STRING SC_BACKSLASH SC_ERROR

/* Abbreviations.  */
eol             (\n\r|\r\n|\r|\n)
blank           (\t|[ ])+
int             [0-9]+
backslash       (a|b|f|n|r|t|v|x?[0-9]+)
invalid_word            [a-zA-Z]+

  /* DONE: Some code was deleted here. */

%class{
  // FIXME: Some code was deleted here (Local variables).
  std::string token_str = "";
  std::string invalid_str = "";
}

%%
/* The rules.  */
{int}         {
                // DONE: Some code was deleted here (Decode, and check the value).
                const char *content = text();
                int val = std::atoi(content);

                if (val == -1 && !(content[0] == '-' && content[1] == '1' && content[2] == 0))
                    throw std::runtime_error("This is not a int");
                
                return TOKEN_VAL(INT, val);
              }

/* DONE: Some code was deleted here. */
{eol}         td.location_.lines();
{blank}       {
                if (invalid_str.size() > 0)
                  td.error_ << misc::error::error_type::scan
                        << td.location_
                        << ": invalid identifier: `"
                        << misc::escape(text()) << "'\n";
              }
[&]           return TOKEN(AND);
"array"       return TOKEN(ARRAY);
":="          return TOKEN(ASSIGN);
"break"       return TOKEN(BREAK);
"_cast"       return TOKEN(CAST);
"class"       return TOKEN(CLASS);
":"           return TOKEN(COLON);
","           return TOKEN(COMMA);
"/"           return TOKEN(DIVIDE);
"do"          return TOKEN(DO);
"."           return TOKEN(DOT);
"else"        return TOKEN(ELSE);
"end"         return TOKEN(END);
"="           return TOKEN(EQ);
"extends"     return TOKEN(EXTENDS);
"for"         return TOKEN(FOR);
"function"    return TOKEN(FUNCTION);
">="          return TOKEN(GE);
">"           return TOKEN(GT);
"if"          return TOKEN(IF);
"import"      return TOKEN(IMPORT);
"in"          return TOKEN(IN);
"{"           return TOKEN(LBRACE);
"["           return TOKEN(LBRACK);
"<="          return TOKEN(LE);
"let"         return TOKEN(LET);
"("           return TOKEN(LPAREN);
"<"           return TOKEN(LT);
"-"           return TOKEN(MINUS);
"method"      return TOKEN(METHOD);
"<>"          return TOKEN(NE);
"new"         return TOKEN(NEW);
"nil"         return TOKEN(NIL);
"of"          return TOKEN(OF);
"|"           return TOKEN(OR);
"+"           return TOKEN(PLUS);
"primitive"   return TOKEN(PRIMITIVE);
"}"           return TOKEN(RBRACE);
"]"           return TOKEN(RBRACK);
")"           return TOKEN(RPAREN);
";"           return TOKEN(SEMI);
"then"        return TOKEN(THEN);
"*"           return TOKEN(TIMES);
"to"          return TOKEN(TO);
"type"        return TOKEN(TYPE);
"var"         return TOKEN(VAR);
"while"       return TOKEN(WHILE);

"\""          start(SC_STRING);
"/*"          start(SC_COMMENT);
[a-zA-Z][a-zA-Z0-9_]*  return TOKEN_VAL(ID, text());

<SC_STRING> {
"\""          {
                std::string tmp = token_str;
                token_str = "";
                start(INITIAL);
                return TOKEN_VAL(STRING, tmp);
              }
[\\]          start(SC_BACKSLASH);
<<EOF>>       {
                td.error_ << misc::error::error_type::scan
                        << td.location_
                        << "expected \", but got EOF"
                        << misc::escape(text()) << "'\n";
                start(INITIAL);
              }
.             token_str.append(text());
}

<SC_BACKSLASH>  {   
{backslash}   {
                token_str.append("\\");
                token_str.append(text());
                start(SC_STRING);
              }
.             {
                td.error_ << misc::error::error_type::scan
                        << td.location_
                        << "invalid \\character in string"
                        << misc::escape(text()) << "'\n";
                start(INITIAL);
              }
}

<SC_COMMENT>  {
"*/"          start(INITIAL);
{eol}         td.location_.lines();
"/*"          start(SC_COMMENT);
<<EOF>>       {
                td.error_ << misc::error::error_type::scan
                        << td.location_
                        << "expected */, but got EOF"
                        << misc::escape(text()) << "'\n";
                start(INITIAL);
              }
.
}

%%