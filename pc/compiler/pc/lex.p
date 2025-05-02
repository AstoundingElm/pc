
typedef_keyword ^char
enum_keyword ^char
struct_keyword ^char
anonymousstruct_keyword ^char
union_keyword ^char
var_keyword ^char
const_keyword ^char
func_keyword ^char
function_keyword ^char
fn_keyword ^char
sizeof_keyword ^char
alignof_keyword ^char
typeof_keyword ^char
offsetof_keyword ^char
break_keyword ^char
continue_keyword ^char
return_keyword ^char
if_keyword ^char
else_keyword ^char
while_keyword ^char
do_keyword ^char
for_keyword ^char
switch_keyword ^char
case_keyword ^char
default_keyword ^char
import_keyword ^char
goto_keyword ^char
new_keyword ^char
undef_keyword ^char

/*ifndef_keyword ^char
if_defined_keyword ^char
define_keyword ^char
elif_defined_keyword ^char
pp_else_keyword ^char
pp_error_keyword ^char
pp_endif_keyword ^char*/
first_keyword ^char
last_keyword ^char
keywords ^^char

always_name ^char
foreign_name ^char
inline_name ^char
complete_name ^char
assert_name ^char
intrinsic_name ^char
declare_note_name ^char
static_assert_name ^char
void_name ^char

init_keywords() {
   inited bool
    if (inited) {
        return;

    }
   
    typedef_keyword = str_intern("typedef")
    buf_push(keywords, typedef_keyword)
    arena_end ^char = intern_arena.end
    enum_keyword = str_intern("enum")
    buf_push(keywords, enum_keyword)

    struct_keyword = str_intern("struct")
    buf_push(keywords, struct_keyword)

    anonymousstruct_keyword = str_intern("anonymousstruct")
    buf_push(keywords, anonymousstruct_keyword)

     union_keyword = str_intern("union")
    buf_push(keywords, union_keyword)

    const_keyword = str_intern("const")
    buf_push(keywords, const_keyword)

     var_keyword = str_intern("var")
    buf_push(keywords, var_keyword)
    func_keyword = str_intern("func")
    buf_push(keywords, func_keyword)
    function_keyword = str_intern("function")
    buf_push(keywords, function_keyword)

    import_keyword = str_intern("import")
    buf_push(keywords, import_keyword)
    fn_keyword = str_intern("fn")
    buf_push(keywords, fn_keyword)
    goto_keyword = str_intern("goto")
    buf_push(keywords, goto_keyword)

    sizeof_keyword = str_intern("sizeof")
    buf_push(keywords, sizeof_keyword)

    alignof_keyword = str_intern("alignof")
    buf_push(keywords, alignof_keyword)

    typeof_keyword = str_intern("typeof")
    buf_push(keywords, typeof_keyword)
    offsetof_keyword = str_intern("offsetof")
    buf_push(keywords, offsetof_keyword)

    new_keyword = str_intern("new")
    buf_push(keywords, new_keyword)

    break_keyword = str_intern("break")
    buf_push(keywords, break_keyword)

     continue_keyword = str_intern("continue")
    buf_push(keywords, continue_keyword)

    return_keyword = str_intern("return")
    buf_push(keywords, return_keyword)

     if_keyword = str_intern("if")
    buf_push(keywords, if_keyword)
    else_keyword = str_intern("else")
    buf_push(keywords, else_keyword)

     while_keyword = str_intern("while")
    buf_push(keywords, while_keyword)

     do_keyword = str_intern("do")
    buf_push(keywords, do_keyword)

     for_keyword = str_intern("for")
    buf_push(keywords, for_keyword)

     switch_keyword = str_intern("switch")
    buf_push(keywords, switch_keyword)

    case_keyword = str_intern("case")
    buf_push(keywords, case_keyword)

    default_keyword = str_intern("default")
    buf_push(keywords, default_keyword)
    undef_keyword = str_intern("undef")
    buf_push(keywords, undef_keyword)
    /*ifndef_keyword = str_intern("ifndef")
    buf_push(keywords, ifndef_keyword)

    if_defined_keyword = str_intern("if_defined")
    buf_push(keywords, if_defined_keyword)

    define_keyword = str_intern("define")
    buf_push(keywords, define_keyword)

    elif_defined_keyword = str_intern("elif_defined")
    buf_push(keywords, elif_defined_keyword)

    pp_else_keyword = str_intern("pp_else")
    buf_push(keywords, pp_else_keyword)

    pp_error_keyword = str_intern("pp_error")
    buf_push(keywords, pp_error_keyword)

     pp_endif_keyword = str_intern("pp_endif")
    buf_push(keywords, pp_endif_keyword )*/
    #assert(intern_arena.end == arena_end)

    first_keyword = typedef_keyword
    last_keyword = undef_keyword

    always_name = str_intern("always");
    foreign_name = str_intern("foreign");
    inline_name = str_intern("inline");
    complete_name = str_intern("complete");
    assert_name = str_intern("assert");
    intrinsic_name = str_intern("intrinsic");
    declare_note_name = str_intern("declare_note");
    static_assert_name = str_intern("static_assert");
    void_name = str_intern("void");

    inited = true
  
}

is_keyword_name(str ^char ) -> bool{
    return first_keyword <= str && str <= last_keyword
}

TokenKind enum {
      TOKEN_EOF,
    TOKEN_COLON,
    TOKEN_LPAREN,
    TOKEN_RPAREN,
    TOKEN_LBRACE,
    TOKEN_RBRACE,
    TOKEN_LBRACKET,
    TOKEN_RBRACKET,
    TOKEN_COMMA,
    TOKEN_DOT,
    TOKEN_AT,
    TOKEN_POUND,
    TOKEN_ELLIPSIS,
    TOKEN_QUESTION,
    TOKEN_SEMICOLON,
    TOKEN_KEYWORD,
    TOKEN_INT,
    TOKEN_FLOAT,
    TOKEN_STR,
    TOKEN_NAME,
    TOKEN_NEG,
    TOKEN_NOT,
    // Multiplicative precedence
    TOKEN_FIRST_MUL,
    TOKEN_MUL = TOKEN_FIRST_MUL,
    TOKEN_DIV,
    TOKEN_MOD,
    TOKEN_AND,
    TOKEN_LSHIFT,
    TOKEN_RSHIFT,
    TOKEN_LAST_MUL = TOKEN_RSHIFT,
    // Additive precedence
    
    TOKEN_FIRST_ADD,
    TOKEN_ADD = TOKEN_FIRST_ADD,
    TOKEN_SUB,
    TOKEN_XOR,
    TOKEN_OR,
    TOKEN_LAST_ADD = TOKEN_OR,
    // Comparative precedence
    TOKEN_FIRST_CMP,
    TOKEN_EQ = TOKEN_FIRST_CMP,
    TOKEN_NOTEQ,
    TOKEN_LT,
    TOKEN_GT,
    TOKEN_LTEQ,
    TOKEN_GTEQ,
    TOKEN_LAST_CMP = TOKEN_GTEQ,
    TOKEN_AND_AND,
    TOKEN_OR_OR,
    // Assignment operators
    TOKEN_FIRST_ASSIGN,
    TOKEN_ASSIGN = TOKEN_FIRST_ASSIGN,
    TOKEN_ADD_ASSIGN,
    TOKEN_SUB_ASSIGN,
    TOKEN_OR_ASSIGN,
    TOKEN_AND_ASSIGN,
    TOKEN_XOR_ASSIGN,
    TOKEN_LSHIFT_ASSIGN,
    TOKEN_RSHIFT_ASSIGN,
    TOKEN_MUL_ASSIGN,
    TOKEN_DIV_ASSIGN,
    TOKEN_MOD_ASSIGN,
    TOKEN_LAST_ASSIGN = TOKEN_MOD_ASSIGN,
    TOKEN_INC,
    TOKEN_DEC,
    TOKEN_COLON_ASSIGN,
    TOKEN_PTR,
    TOKEN_RET,
    NUM_TOKEN_KINDS,

} 

TokenMod enum {
    MOD_NONE,
    MOD_HEX,
    MOD_BIN,
    MOD_OCT,
    MOD_CHAR,
    MOD_MULTILINE,
} 

TokenSuffix enum {
    SUFFIX_NONE,
    SUFFIX_D,
    SUFFIX_U,
    SUFFIX_L,
    SUFFIX_UL,
    SUFFIX_LL,
    SUFFIX_ULL,
}


token_suffix_names ^[]char = {
    [SUFFIX_NONE] = "",
    [SUFFIX_D] = "d",
    [SUFFIX_U] = "u",
    [SUFFIX_L] = "l",
    [SUFFIX_UL] = "ul",
    [SUFFIX_LL] = "ll",
    [SUFFIX_ULL] = "ull",
}

token_kind_names ^[]char = {
    [TOKEN_EOF] = "EOF",
    [TOKEN_COLON] = ":",
    [TOKEN_LPAREN] = "(",
    [TOKEN_RPAREN] = ")",
    [TOKEN_LBRACE] = "{",
    [TOKEN_RBRACE] = "}",
    [TOKEN_LBRACKET] = "[",
    [TOKEN_RBRACKET] = "]",
    [TOKEN_COMMA] = ",",
    [TOKEN_DOT] = ".",
    [TOKEN_AT] = "@",
    [TOKEN_POUND] = "#",
    [TOKEN_ELLIPSIS] = "...",
    [TOKEN_QUESTION] = "?",
    [TOKEN_SEMICOLON] = ";",
    [TOKEN_KEYWORD] = "keyword",
    [TOKEN_INT] = "int",
    [TOKEN_FLOAT] = "float",
    [TOKEN_STR] = "string",
    [TOKEN_NAME] = "name",
    [TOKEN_NEG] = "~",
    [TOKEN_NOT] = "!",
    [TOKEN_MUL] = "*",
    [TOKEN_DIV] = "/",
    [TOKEN_MOD] = "%",
    [TOKEN_AND] = "&",
    [TOKEN_LSHIFT] = "<<",
    [TOKEN_RSHIFT] = ">>",
    [TOKEN_ADD] = "+",
    [TOKEN_SUB] = "-",
    [TOKEN_OR] = "|",
    [TOKEN_XOR] = "^",
    [TOKEN_EQ] = "==",
    [TOKEN_NOTEQ] = "!=",
    [TOKEN_LT] = "<",
    [TOKEN_GT] = ">",
    [TOKEN_LTEQ] = "<=",
    [TOKEN_GTEQ] = ">=",
    [TOKEN_AND_AND] = "&&",
    [TOKEN_OR_OR] = "||",
    [TOKEN_ASSIGN] = "=",
    [TOKEN_ADD_ASSIGN] = "+=",
    [TOKEN_SUB_ASSIGN] = "-=",
    [TOKEN_OR_ASSIGN] = "|=",
    [TOKEN_AND_ASSIGN] = "&=",
    [TOKEN_XOR_ASSIGN] = "^=",
    [TOKEN_MUL_ASSIGN] = "*=",
    [TOKEN_DIV_ASSIGN] = "/=",
    [TOKEN_MOD_ASSIGN] = "%=",
    [TOKEN_LSHIFT_ASSIGN] = "<<=",
    [TOKEN_RSHIFT_ASSIGN] = ">>=",
    [TOKEN_INC] = "++",
    [TOKEN_DEC] = "--",
    [TOKEN_COLON_ASSIGN] = ":=",
    [TOKEN_RET] = "->",
    [TOKEN_PTR] = "^",
   
}

token_kind_name(kind TokenKind) ^char {
    if (kind < sizeof(token_kind_names)/sizeof(*token_kind_names)) {
        return token_kind_names[kind]
    } else {
        return "<unknown>"
    }
}

assign_token_to_binary_token[NUM_TOKEN_KINDS]TokenKind = {
    [TOKEN_ADD_ASSIGN] = TOKEN_ADD,
    [TOKEN_SUB_ASSIGN] = TOKEN_SUB,
    [TOKEN_OR_ASSIGN] = TOKEN_OR,
    [TOKEN_AND_ASSIGN] = TOKEN_AND,
    [TOKEN_XOR_ASSIGN] = TOKEN_XOR,
    [TOKEN_LSHIFT_ASSIGN] = TOKEN_LSHIFT,
    [TOKEN_RSHIFT_ASSIGN] = TOKEN_RSHIFT,
    [TOKEN_MUL_ASSIGN] = TOKEN_MUL,
    [TOKEN_DIV_ASSIGN] = TOKEN_DIV,
    [TOKEN_MOD_ASSIGN] = TOKEN_MOD,
}

SrcPos struct {
    name ^char
    line int
} 

pos_builtin SrcPos = {name = "<builtin>"}

Token struct {
    kind TokenKind
    mod TokenMod
    suffix TokenSuffix
    pos SrcPos 
    start ^char
    end ^char
    union {
        int_val ullong
        float_val double
        str_val ^char
        name ^char
    }

}

token Token
line_start ^char
stream ^char 

warning(pos SrcPos, fmt ^char, ...) {
    if (pos.name == NULL) {
        pos = pos_builtin
    }
    args va_list 
    va_start(args, fmt)
    printf("%s(%d): warning: ", pos.name, pos.line)
    vprintf(fmt, args)
    printf("\n")
    va_end(args)
}

fatal fn(fmt ^char, ...) {
    args va_list
    va_start(args, fmt)
    printf("FATAL: ")
    vprintf(fmt,args)
    printf("\n")    
    va_end(args)
    exit(1)
}

fatal_error fn(pos SrcPos, fmt ^char, ...) {
    args va_list
    va_start(args, fmt)
    printf("Syntax Error: ")
    vprintf(fmt, args)
    printf("\n")
    va_end(args)
    printf("Line: %d Name: %s\n", pos.line, pos.name)
    exit(1)
}

error_here(pos SrcPos, fmt ^char, ...) {
    if (pos.name == NULL) {
        pos = pos_builtin
    }
    args va_list 
    va_start(args, fmt)
    printf("%s(%d): warning: ", pos.name, pos.line)
    vprintf(fmt, args)
    printf("\n")
    va_end(args)
    exit(1)
}

warning_here(pos SrcPos, fmt ^char, ...) {
    if (pos.name == NULL) {
        pos = pos_builtin
    }
    args va_list 
    va_start(args, fmt)
    printf("%s(%d): warning: ", pos.name, pos.line)
    vprintf(fmt, args)
    printf("\n")
    va_end(args)
}

fatal_error_here fn(pos SrcPos, fmt ^char, ...) {
    args va_list
    va_start(args, fmt)
    printf("Syntax Error: ")
    vprintf(fmt, args)
    printf("\n")
    va_end(args)
    printf("Line: %d Name: %s\n", pos.line, pos.name)
    exit(1)
}

syntax_error fn(pos SrcPos, fmt ^char, ...) {
    args va_list
    va_start(args, fmt)
    printf("Syntax Error: ")
    vprintf(fmt, args)
    printf("\n")
    printf("Line: %d Name: %s\n", pos.line, pos.name)
    va_end(args)
    exit(1)
}

token_info fn() ^char {
    if (token.kind == TOKEN_NAME || token.kind == TOKEN_KEYWORD) {
        return token.name
    } else {
        return token_kind_name(token.kind)
    }
}

char_to_digit [256]uint8 = {
    ['0'] = 0,
    ['1'] = 1,
    ['2'] = 2,
    ['3'] = 3,
    ['4'] = 4,
    ['5'] = 5,
    ['6'] = 6,
    ['7'] = 7,
    ['8'] = 8,
    ['9'] = 9,
    ['a'] = 10, ['A'] = 10,
    ['b'] = 11, ['B'] = 11,
    ['c'] = 12, ['C'] = 12,
    ['d'] = 13, ['D'] = 13,
    ['e'] = 14, ['E'] = 14,
    ['f'] = 15, ['F'] = 15,
}

scan_int fn () {
    base int = 10
    start_digits := stream
    if (*stream == '0') {
        stream++;
        if (pc_tolower(*stream) == 'x') {
            stream++;
            token.mod = MOD_HEX;
            base = 16;
            start_digits = stream;
        } else if (pc_tolower(*stream) == 'b') {
            stream++;
            token.mod = MOD_BIN;
            base = 2;
            start_digits = stream;
        } else if (pc_isdigit(*stream)) {
            token.mod = MOD_OCT;
            base = 8;
            start_digits = stream;
        }
    }
    val ullong = 0;
    while (1) {
        if (*stream == '_') {
            stream++;
            continue;
        }
        digit int = char_to_digit[(:uchar)*stream];
        if (digit == 0 && *stream != '0') {
            break;
        }
        if (digit >= base) {
            error_here(token.pos, "Digit '%c' out of range for base %d", *stream, base);
            digit = 0;
        }
        if (val > (ULLONG_MAX - digit)/base) {
            error_here(token.pos, "Integer literal overflow");
            while (pc_isdigit(*stream)) {
                stream++;
            }
            val = 0;
            break;
        }
        val = val*base + digit;
        stream++;
    }
    if (stream == start_digits) {
        error_here(token.pos, "Expected base %d digit, got '%c'", base, *stream);
    }
    token.kind = TOKEN_INT;
    token.int_val = val;
    if (pc_tolower(*stream) == 'u') {
        token.suffix = SUFFIX_U;
        stream++;
        if (pc_tolower(*stream) == 'l') {
            token.suffix = SUFFIX_UL;
            stream++;
            if (pc_tolower(*stream) == 'l') {
                token.suffix = SUFFIX_ULL;
                stream++;
            }
        }
    } else if (pc_tolower(*stream) == 'l') {
        token.suffix = SUFFIX_L;
        stream++;
        if (pc_tolower(*stream) == 'l') {
            token.suffix = SUFFIX_LL;
            stream++;
        }
    }
}

scan_float(){
    start := stream
    while pc_isdigit(*stream) {
        stream++
    }
    if (*stream == '.') {
        stream++
    }
    while pc_isdigit(*stream) {
        stream++
    }
    if (pc_tolower(*stream) == 'e') {
        stream++
        if (*stream == '+' || *stream == '-') {
            stream++
        }
        if !pc_isdigit(*stream) {
            syntax_error(token.pos, "Expected digit after float literal exponent, found '%c'.", *stream)
        }
        while pc_isdigit(*stream) {
            stream++
        }
    }
     val double = strtod(start, NULL)
    if (val == HUGE_VAL) {
        syntax_error(token.pos, "Float literal overflow")
    }
    token.kind = TOKEN_FLOAT
    token.float_val = val
     if (pc_tolower(*stream) == 'd') {
        token.suffix = SUFFIX_D;
        stream++;
    }
}

@foreign HUGE_VAL double

escape_to_char[256]char  = {
    ['0'] = '\0',
    ['\''] = '\'',
    ['"'] = '"',
    ['\\'] = '\\',
    ['n'] = '\n',
    ['r'] = '\r',
    ['t'] = '\t',
    ['v'] = '\v',
    ['b'] = '\b',
    ['a'] = '\a',
}

scan_hex_escape() int {
    #assert(*stream == 'x')
    stream++
    val int = char_to_digit[(:uchar)*stream]
    if (!val && *stream != '0') {
        error_here(token.pos, "\\x needs at least 1 hex digit");
    }
    stream++;
    digit int = char_to_digit[(:uchar)*stream];
    if (digit || *stream == '0') {
        val *= 16;
        val += digit;
        if (val > 0xFF) {
            error_here(token.pos, "\\x argument out of range");
            val = 0xFF;
        }
        stream++;
    }
    return val;
}

scan_char() {
    #assert(*stream == '\'');
    stream++;
    val int = 0;
    if (*stream == '\'') {
        error_here(token.pos, "Char literal cannot be empty");
        stream++;
    } else if (*stream == '\n') {
        error_here(token.pos, "Char literal cannot contain newline");
    } else if (*stream == '\\') {
        stream++;
        if (*stream == 'x') {
            val = scan_hex_escape();
        } else {
            val = escape_to_char[(:uchar)*stream];
            if (val == 0 && *stream != '0') {
                error_here(token.pos, "Invalid char literal escape '\\%c'", *stream);
            }
            stream++;
        }
    } else {
        val = *stream;
        stream++;
    }
    if (*stream != '\'') {
        error_here(token.pos, "Expected closing char quote, got '%c'", *stream);
    } else {
        stream++;
    }
    token.kind = TOKEN_INT;
    token.int_val = val;
    token.mod = MOD_CHAR;
}


lex_start usize

save_lex_state(){

 //memcpy(&temp_token, &token, sizeof(token));
    lex_start = pc_strlen(stream);
}

restore_lex_state(){
while(lex_start != pc_strlen(stream))
    {
        --stream;
    }

}

parse_char_escape(str ^char){

 buf_push(str, '\'');

   while(*stream != '}'){
                    //stream++;
                    buf_push(str, *stream);
                    stream++;

                }


                
                stream++;

                buf_push(str, '\'');

                stream++;
}

scan_str() {
 #assert(*stream == '"');
    stream++;
    str ^char = NULL;
 
    if (stream[0] == '"' && stream[1] == '"') {
        stream += 2;
        while (*stream) {
            if (stream[0] == '"' && stream[1] == '"' && stream[2] == '"') {
                stream += 3;
                break;
            }
            if (*stream != '\r') {
                // TODO: Should probably just read files in text mode instead.
                buf_push(str, *stream);
            }
            if (*stream == '\n') {
                token.pos.line++;
            }
            stream++;
        }
        if (!*stream) {
            error_here(token.pos, "Unexpected end of file within multi-line string literal");
        }
        token.mod = MOD_MULTILINE;
    } else {
        while (*stream && *stream != '"') {
            val char  = *stream;
            if (val == '\r') {
                token.pos.line++;

                while(*stream) {
                    if(*stream == '"') {
                    stream++;
                    break;
            }
            if(*stream != '\r') {
            buf_push(str, *stream);
            }

            if(*stream == '\n') {
                token.pos.line++;
            }  
                 if(!*stream) {
                error_here(token.pos, "Unexpected end of file within string literal");
            }
                stream++;
            }           
               
                token.mod = MOD_MULTILINE;
                break;
            } else if (val == '\\') {
                stream++;
                if (*stream == 'x') {
                    val = scan_hex_escape();
                } else {
                    val = escape_to_char[(: uchar)*stream];
                    if (val == 0 && *stream != '0') {
                        error_here(token.pos, "Invalid string literal escape '\\%c'", *stream);
                    }
                    stream++;
                }
            } else {
                stream++;
            }
            buf_push(str, val);
        }
        if (*stream) {
            stream++;
        } else {
            error_here(token.pos, "Unexpected end of file within string literal");
        }
    }

    buf_push(str, 0);
    token.kind = TOKEN_STR;
    token.str_val = str;
  
}

next_token() {
    :repeat
    token.start = stream 
    token.mod = 0
    token.suffix = 0
    switch (*stream) {
        case ' ': case '\n': case '\r': case '\t': case '\v':
        while (pc_isspace(*stream)) {
            if (*stream++ == '\n') {
                line_start = stream
                token.pos.line++
            }

        }
        goto repeat
        case '\'':
        scan_char()
        case '"':
        scan_str()
        case '.':
        if (pc_isdigit(stream[1])) {
            scan_float();
        } else if (stream[1] == '.' && stream[2] == '.') {
            token.kind = TOKEN_ELLIPSIS;
            stream += 3;
        } else {
            token.kind = TOKEN_DOT;
            stream++;
        }
        
    case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9': {
        while pc_isdigit(*stream) {
            stream++
        }
        c : char = *stream
        stream = token.start
        if (c == '.' || pc_tolower(c) == 'e') {
            scan_float()
        } else {
            scan_int()
        }
        
    }
    case 'a': case 'b': case 'c': case 'd': case 'e': case 'f': case 'g': case 'h': case 'i': case 'j':
    case 'k': case 'l': case 'm': case 'n': case 'o': case 'p': case 'q': case 'r': case 's': case 't':
    case 'u': case 'v': case 'w': case 'x': case 'y': case 'z':
    case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': case 'G': case 'H': case 'I': case 'J':
    case 'K': case 'L': case 'M': case 'N': case 'O': case 'P': case 'Q': case 'R': case 'S': case 'T':
    case 'U': case 'V': case 'W': case 'X': case 'Y': case 'Z':
    case '_':
        while pc_isalnum(*stream) || *stream == '_' {
            stream++
        }
        token.name = str_intern_range(token.start, stream)
        token.kind = is_keyword_name(token.name) ? TOKEN_KEYWORD : TOKEN_NAME

    case '<':
        token.kind = TOKEN_LT
        stream++
        if (*stream == '<') {
            token.kind = TOKEN_LSHIFT
            stream++
            if (*stream == '=') {
                token.kind = TOKEN_LSHIFT_ASSIGN
                stream++
            }
        } else if (*stream == '=') {
            token.kind = TOKEN_LTEQ
            stream++
        }
        
    case '>':
        token.kind = TOKEN_GT
        stream++
        if (*stream == '>') {
            token.kind = TOKEN_RSHIFT
            stream++
            if (*stream == '=') {
                token.kind = TOKEN_RSHIFT_ASSIGN
                stream++
            }
        } else if (*stream == '=') {
            token.kind = TOKEN_GTEQ
            stream++
        }
   
        case '^': token.kind = TOKEN_PTR
            stream++
            if(*stream == '='){

                token.kind = TOKEN_XOR_ASSIGN
                stream++
            }

            case '/':
        token.kind = TOKEN_DIV
        stream++
        if (*stream == '=') {
            token.kind = TOKEN_DIV_ASSIGN
            stream++
        } else if (*stream == '/') {
            stream++
            while (*stream && *stream != '\n') {
                stream++
            }
            goto repeat
        } else if (*stream == '*') {
            stream++
            level int = 1
            while (*stream && level > 0) {
                if (stream[0] == '/' && stream[1] == '*') {
                    level++
                    stream += 2
                } else if (stream[0] == '*' && stream[1] == '/') {
                    level--
                    stream += 2
                } else {
                    if (*stream == '\n') {
                        token.pos.line++
                    }
                    stream++
                }
            }
            goto repeat
        }

         case '-':{


            if(stream[1] == '>')
            {
                token.kind = TOKEN_RET;
                stream += 2;
                
                break;
                
            }else if(stream[1] == '-'){
                
                token.kind = TOKEN_DEC;
                stream += 2;
                break;
            }else if(stream[1] == '='){
                
                token.kind = TOKEN_SUB_ASSIGN;
                stream += 2;
                break;
            }
            
            token.kind = TOKEN_SUB;
            stream++;
        }
        
    case '\0':

        token.kind = TOKEN_EOF
        stream++
        

    case '(':
        token.kind = TOKEN_LPAREN
        stream++
    case ')':
        token.kind = TOKEN_RPAREN
        stream++

    case '{':
        token.kind = TOKEN_LBRACE
        stream++

    case '}':
        token.kind = TOKEN_RBRACE
        stream++
    case '[':
        token.kind = TOKEN_LBRACKET
        stream++

    case ']':
        token.kind = TOKEN_RBRACKET
        stream++

    case ',':
        token.kind = TOKEN_COMMA
        stream++
    case '@': 
        token.kind = TOKEN_AT 
        stream++
    case '#':
        token.kind = TOKEN_POUND
        stream++
    case '?':
        token.kind = TOKEN_QUESTION
        stream++

    case ';':
        token.kind = TOKEN_SEMICOLON
        stream++

    case '~':
        token.kind = TOKEN_NEG
        stream++

    case '!':

        token.kind = TOKEN_NOT
        stream++
        if(*stream == '=') {
            token.kind = TOKEN_NOTEQ
            stream++
        }
        

    case ':': 
        token.kind = TOKEN_COLON
        stream++
        if (*stream == '=') { 
            token.kind = TOKEN_COLON_ASSIGN 
            stream++
            break
        } 
        /*else if(*stream == ':'){
            token.kind = TOKEN_COLON_COLON
            stream++
        
        }*/
    case '=': 
        token.kind = TOKEN_ASSIGN
        stream++
        if (*stream == '=') { 
            token.kind = TOKEN_EQ 
            stream++
        } 

     if (*stream == '=') { 
            token.kind = TOKEN_XOR_ASSIGN 
            stream++
            break
        } 
        case '*': 
        token.kind = TOKEN_MUL
        stream++
        if (*stream == '=') { 
            token.kind = TOKEN_MUL_ASSIGN
            stream++
        } 
        
        case '%': 
        token.kind = TOKEN_MOD
        stream++
        if (*stream == '=') { 
            token.kind = TOKEN_MOD_ASSIGN
            stream++
        } 
        case '+': 
        token.kind = TOKEN_ADD
        stream++
        if (*stream == '=') { 
            token.kind = TOKEN_ADD_ASSIGN
            stream++
        } else if (*stream == '+') { 
            token.kind = TOKEN_INC
            stream++
        }
        case '&': 
        token.kind = TOKEN_AND
        stream++
        if (*stream == '=') { 
            token.kind = TOKEN_AND_ASSIGN
            stream++
        } else if (*stream == '&') { 
            token.kind = TOKEN_AND_AND
            stream++
        } 

         case '|': 
        token.kind = TOKEN_OR
        stream++
        if (*stream == '=') { 
            token.kind = TOKEN_OR_ASSIGN
            stream++
        } else if (*stream == '|') { 
            token.kind = TOKEN_OR_OR
            stream++
        } 

    default:
       error_here(token.pos, "Invalid '%c' token, skipping", *stream)
        stream++
        goto repeat
        
    }
    token.end = stream
}

init_stream(name ^char, buf ^char) {
    stream = buf
    line_start = stream
    token.pos.name = name ? name : "<string>"
    token.pos.line = 1
    next_token()
}

is_token(kind TokenKind) bool{
    return token.kind == kind
}

is_token_eof() bool {
    return token.kind == TOKEN_EOF
}

is_token_name(name ^char ) bool {
    return token.kind == TOKEN_NAME && token.name == name
}

is_keyword(name ^char ) bool {
    return is_token(TOKEN_KEYWORD) && token.name == name
}

match_keyword(name ^char ) -> bool{
    if (is_keyword(name)) {
        next_token()
        return true
    } else {
        return false
    }
}

match_token(kind TokenKind) -> bool {
    if (is_token(kind)) {
        next_token()
        return true
    } else {
        return false
    }
}

expect_token(kind TokenKind) bool {
    if (is_token(kind)) {
        next_token()
        return true
    } else {
        fatal_error_here(token.pos, "expected token %s, got %s", token_kind_name(kind), token_info())
        return false
    }
}