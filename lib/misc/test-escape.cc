/**
 ** Test code for misc/escape.hh.
 */

#include <iostream>
#include <misc/contract.hh>
#include <misc/escape.hh>
#include <sstream>

using misc::escape;

int main()
{
    std::ostringstream s;

    s << escape("\a\b\f\n\r\t\v\\\"") << escape('\a');

    postcondition(s.str() == R"(\007\b\f\n\r\t\v\\\"\007)");
}
