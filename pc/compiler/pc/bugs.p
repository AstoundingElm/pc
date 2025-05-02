/*



1449 1490 TOKEN_XOR resolve.ion

cast operand TYPE_ENUM over TYPE_INT

TOKEN_XOR

resolve_expr_unary?????

resolve_sym

manual breaks in swith statement

eg in c  code: 

case  SYM_NONE:
	break;
case SYM_ENUM:
	break;

then i convert it to


case  SYM_NONE:
case SYM_ENUM:

which is or istnt fallthrogh and causes bugs


TODO:
make ^ get handled in parse_expr()
macros
multiple errors that get pushed into buffer instead of failing on first error
varargs
jit assembler and pe32
rewrite lexer so that we can do save_state() easier?
remove brackets from if / while/ for etc stmts
add :: constants

queso fuego os series

x86 simulator series

ryan vries series








*/