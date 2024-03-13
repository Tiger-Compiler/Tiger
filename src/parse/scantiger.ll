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

  // FIXME: Some code was deleted here (Define YY_USER_ACTION to update locations).
  #define YY_USER_ACTION                \
      td.location_.columns(size());  
  


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

%x SC_COMMENT SC_STRING

/* Abbreviations.  */
eol             (\n\r|\r\n|\r|\n)
blank           (\t|[ ])+
int             (\+|-)?[0-9]+
string          [a-zA-Z]+
word            [a-zA-Z]+
other           .*
  /* DONE: Some code was deleted here. */

%class{
  // FIXME: Some code was deleted here (Local variables).
  std::string current_str = "";
}

%%
/* The rules.  */
{eol}         td.location_.lines();
{blank}
{int}         {
                // DONE: Some code was deleted here (Decode, and check the value).
                int val = std::atoi(text());

                if (val == -1 && (chr() != '-' || text()[1] != '1' || size() != 2))
                    throw std::runtime_error("This is not a int");
                
                return TOKEN_VAL(INT, val);
              }
  /* DONE: Some code was deleted here. */
"\""            start(SC_STRING);


<SC_STRING> {
{string}        current_str.append(text());
"\""            {
                    std::string tmp = current_str;
                    current_str = "";
                    start(INITIAL);
                    return TOKEN_VAL(STRING, tmp);
                }
}

%%