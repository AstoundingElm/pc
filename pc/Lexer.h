typedef enum TokenKind {
    TOK_EOF,
    TOK_COLON,
    TOK_LPAREN,
    TOK_RPAREN,
    TOK_LBRACE,
    TOK_RBRACE,
    TOK_LBRACK,
    TOK_RBRACK,
    TOK_COMMA,
    TOK_DOT,
    TOK_QUESTION,
    TOK_SEMI,
    TOK_KEYWORD,
    TOK_INTLIT,
    TOK_I64,
    TOK_FLOAT,
    TOK_STR,
    TOK_ID,
    TOK_NEG,
    TOK_NOT,
    // Multiplicative precedence
    TOK_FIRST_MUL,
    TOK_MUL = TOK_FIRST_MUL,
    TOK_DIV,
    TOK_MOD,
    TOK_AND,
    TOK_LSHIFT,
    TOK_RSHIFT,
    TOK_LAST_MUL = TOK_RSHIFT,
    // Additive precedence
    TOK_FIRST_ADD,
    TOK_ADD = TOK_FIRST_ADD,
    TOK_SUB,
    TOK_XOR,
    TOK_OR,
    TOK_LAST_ADD = TOK_OR,
    // Comparative precedence
    TOK_FIRST_CMP,
    TOK_EQ = TOK_FIRST_CMP,
    TOK_NOTEQ,
    TOK_LT,
    TOK_GT,
    TOK_LTEQ,
    TOK_GTEQ,
    TOK_LAST_CMP = TOK_GTEQ,
    TOK_AND_AND,
    TOK_OR_OR,
    // Assignment operators
    TOK_FIRST_ASSIGN,
    TOK_ASSIGN = TOK_FIRST_ASSIGN,
    TOK_ADD_ASSIGN,
    TOK_SUB_ASSIGN,
    TOK_OR_ASSIGN,
    TOK_AND_ASSIGN,
    TOK_XOR_ASSIGN,
    TOK_LSHIFT_ASSIGN,
    TOK_RSHIFT_ASSIGN,
    TOK_MUL_ASSIGN,
    TOK_DIV_ASSIGN,
    TOK_MOD_ASSIGN,
    TOK_LAST_ASSIGN = TOK_MOD_ASSIGN,
    TOK_INC,
    TOK_DEC,
    TOK_COLON_ASSIGN,
    
    
} TokenKind;


const char *TokToString(TokenKind Kind)
{
    switch(Kind)
    {
        
        case TOK_EOF: return "\0";
        case TOK_COLON: return ":";
        case TOK_LPAREN: return "(";
        case TOK_RPAREN: return ")";
        case TOK_LBRACE: return "{";
        case TOK_RBRACE: return "}";
        case TOK_LBRACK: return "[";
        case TOK_RBRACK: return "]";
        case TOK_COMMA: return ", ";
        case TOK_DOT: return ".";
        case TOK_QUESTION: return "?";
        case TOK_SEMI: return ";";
        case TOK_KEYWORD: return "KEYWORD";
        case TOK_INTLIT: return "INTLIT";
        case TOK_I64: return "I64";
        case TOK_FLOAT: return "FLOAT";
        case TOK_STR: return "`";
        case TOK_ID: return "TOK_ID";
        case TOK_NEG: return "-";
        case TOK_NOT: return "!";
        case TOK_MUL: return "*";
        case TOK_DIV: return "/";
        case TOK_MOD: return "%";
        case TOK_AND: return "&";
        case TOK_LSHIFT: return "<<";
        case TOK_RSHIFT: return ">>";
        case TOK_ADD: return "+";
        case TOK_SUB: return "-";
        case TOK_XOR: return "^";
        case TOK_OR: return "|";
        case TOK_EQ: return "==";
        case TOK_NOTEQ: return "!=";
        case TOK_LT: return "<";
        case TOK_GT: return ">";
        case TOK_LTEQ: return "<=";
        case TOK_GTEQ: return ">=";
        case TOK_AND_AND: return "&&";
        case TOK_OR_OR: return "||"; 
        case TOK_ASSIGN: return "=";
        case TOK_ADD_ASSIGN: return "+=";
        case TOK_SUB_ASSIGN: return "-=";
        case TOK_OR_ASSIGN: return "|=";
        case TOK_AND_ASSIGN: return "&=";
        case TOK_XOR_ASSIGN: return "^=";
        case TOK_LSHIFT_ASSIGN: return "<<=";
        case TOK_RSHIFT_ASSIGN: return ">>=";
        case TOK_MUL_ASSIGN: return "*=";
        case TOK_DIV_ASSIGN: return "/=";
        case TOK_MOD_ASSIGN: return "%=";
        case TOK_INC: return "++";
        case TOK_DEC: return "--";
        case TOK_COLON_ASSIGN: return ":=";
        
        
        
        default: printf("Unrecognised token in TokToString\n");
        exit(-1);
    }
    
    printf("Never get here\n");
}

typedef enum TokenMod {
    TOKENMOD_NONE,
    TOKENMOD_HEX,
    TOKENMOD_BIN,
    TOKENMOD_OCT,
    TOKENMOD_CHAR,
} TokenMod;

typedef struct Token
{
    TokenKind Kind;
    int64_t  Value;
    char *ID;
    const char *Text;
    double FloatValue;
    const char *StringVal;
    char CharVal;
    TokenMod Mod;
    
}Token;

const char *PSource;

Token Tok;
bool32 IsToken(TokenKind Kind);

bool32 IsEndOfLine(char C)
{
    bool32 Result = ((C == '\n') ||
                     (C  == '\r'));
    
    return(Result);
}


int LineCount = 1;


void SyntaxError(const char *Message)
{
    printf("Syntax Error: %s ; At: %d\n", Message, LineCount);
    exit(-1);
}

char EscapeToChar[256] = {
    ['n'] = '\n',
    ['r'] = '\r',
    ['t'] = '\t',
    ['v'] = '\v',
    ['b'] = '\b',
    ['a'] = '\a',
    ['0'] = 0,
};


bool32
IsWhitespace(char C)
{
    bool32 Result = ((C == ' ') ||
                     (C == '\t') ||
                     (C == '\v') ||
                     (C == '\f') ||
                     IsEndOfLine(C));
    
    if(IsEndOfLine(C))
        ++LineCount;
    return(Result);
}

bool32 IsFloat = 0;


void TokNext()
{
    
    const char *Src = PSource;
    IsFloat = 0;
    for(;;)
    {
        
        if(IsWhitespace(Src[0]))
        {
            ++Src;
        }
        else if((Src[0] == '*') &&
                (Src[1] == '/'))
        {
            printf("Dangling multi-line comment */\n");
            exit(-1);
        }
        else if((Src[0] == '/') &&
                (Src[1] == '/'))
        {
            Src += 2;
            while(Src[0] && !IsEndOfLine(Src[0]))
            {
                if(IsEndOfLine(Src[0]))
                    ++LineCount;
                ++Src;
            }
            
        }
        else if((Src[0] == '/') &&
                (Src[1] == '*'))
        {
            Src += 2;
            
            while(Src[0] &&
                  !((Src[0] == '*') &&
                    (Src[1] == '/')))
            {
                if(IsEndOfLine(Src[0])){
                    
                    ++LineCount;
                }
                
                ++Src;
            }
            
            if(Src[0] == '*')
            {
                Src += 2;
            }
            else
            {
                printf("Dangling multi-line comment /*\n");
                exit(-1);
            }
            
        }
        
        else
        {
            
            break;
        }
    }
    
    
    switch(*Src)
    {
        
        case '_':
        case 'a':case 'b':case 'c':case 'd':case 'e':case 'f':case 'g':
        case 'h':case 'i':case 'j':case 'k':case 'l':case 'm':case 'n':
        case 'o':case 'p':case 'q':case 'r':case 's':case 't':case 'u':
        case 'v':case 'w':case 'x':case 'y':case 'z':
        case 'A':case 'B':case 'C':case 'D':case 'E':case 'F':case 'G':
        case 'H':case 'I':case 'J':case 'K':case 'L':case 'M':case 'N':
        case 'O':case 'P':case 'Q':case 'R':case 'S':case 'T':case 'U':
        case 'V':case 'W':case 'X':case 'Y':case 'Z':
        {
            const char * Start = Src;
            while(isalnum(*Src) || *Src == '_')
            {
                ++Src;
                
            }
            
            size_t TokenLength = Src - Start;
            char *SymbolString = (char *)malloc(TokenLength + 1);
            memcpy(SymbolString, Start, TokenLength);
            SymbolString[TokenLength] = 0;
            
            Tok.Text = SymbolString;
            
            Tok.Kind = TOK_ID;
            
            
        }break;
        case '0':case '1':case '2':case '3':case '4':
        case '5':case '6':case '7':case '8':case '9':
        {
            int Value = 0;
            
            
            const char *ValStart = Src;
            while(isdigit(*Src))
            {
                Value *= 10;
                Value += *Src++ - '0';
                
                if(*Src == '.') {
                    Src++; IsFloat = true; //break;
                    
                }
                
            }
            
            
            if(IsFloat){
                double Val = strtod(ValStart, NULL);
                
                Tok.Kind = TOK_FLOAT; 
                Tok.FloatValue = Val;
                Tok.Text =  "Float";
                //printf("Float: %f\n", Tok.FloatValue);
            }
            else{
                
                
                
                size_t TokenLength = Src - ValStart;
                char *SymbolString = (char *)malloc(TokenLength);
                memcpy(SymbolString, ValStart, TokenLength);
                SymbolString[TokenLength] = 0;
                Tok.Text = SymbolString;
                
                Tok.Kind = TOK_INTLIT;
                Tok.Value = Value;
            }
            
            
            
        }break;
        
        case ':': 
        {
            if(Src[1] == '=')
            {
                Tok.Kind = TOK_COLON_ASSIGN; Tok.Text = ":="; Src += 2; break;
            }
            
            Tok.Kind = TOK_COLON; Tok.Text = ":"; Src++; 
        }break;
        case '=' : 
        {
            if(Src[1] == '=')
            {
                Tok.Kind = TOK_EQ; Tok.Text = "=="; Src += 2;
                
                break;
                
            }
            
            Tok.Kind = TOK_ASSIGN; Tok.Text = "="; ++Src;
            
        } break;
        
        case '\0': 
        {
            Tok.Kind = TOK_EOF; Tok.Text = "EOF"; 
        }break;
        case ';':{Tok.Kind = TOK_SEMI; Tok.Text = ";"; ++Src; }break;
        case '{': {Tok.Kind = TOK_LBRACE; Tok.Text = "{";  ++Src; }break;
        case '}': {Tok.Kind = TOK_RBRACE; Tok.Text = "}";  ++Src; }break;
        case ',':{Tok.Kind = TOK_COMMA; Tok.Text = ","; ++Src; }break;
        case '[':{Tok.Kind = TOK_LBRACK; Tok.Text = "["; ++Src; }break;
        case ']':{Tok.Kind = TOK_RBRACK; Tok.Text = "]"; ++Src; }break;
        case '(':{Tok.Kind = TOK_LPAREN; Tok.Text = "("; ++Src; }break;
        case ')':{Tok.Kind = TOK_RPAREN; Tok.Text = ")"; ++Src; }break;
        case '*':
        {
            if(Src[1] == '=')
            {
                Tok.Kind = TOK_MUL_ASSIGN; Tok.Text = "*="; Src += 2;
                
                break;
            }
            
            Tok.Kind = TOK_MUL; Tok.Text = "*"; ++Src;
            
            
        }break;
        case '+':
        {
            
            if(Src[1]  == '+'){
                Tok.Kind = TOK_INC; Tok.Text = "++"; Src += 2;
                break;
            }
            
            Tok.Kind = TOK_ADD; Tok.Text = "+"; ++Src;
            
        }break;
        case '-':{
            
            if(Src[1] == '-')
            {
                Tok.Kind = TOK_DEC; Tok.Text = "--"; Src += 2; break;
            }
            Tok.Kind = TOK_SUB; Tok.Text = "-";  ++Src;
        }break;
        
        case '!':{Tok.Kind = TOK_NOT; Tok.Text = "!"; ++Src; }break;
        case '.':{Tok.Kind = TOK_DOT; Tok.Text = "."; ++Src; } break;
        case '"':
        {
            
            assert(*Src == '"');
            Src++;
            
            char *String = NULL;
            
            while (*Src && *Src != '"') {
                
                char Val = *Src;
                
                if(Val == '\n')
                {
                    SyntaxError("String literal cannot contain newline");
                    break;
                }
                else if(Val == '\\')
                {
                    Src++;
                    Val = EscapeToChar[*(unsigned char *)Src];
                    
                    
                    if (Val == 0 && *Src != '0') {
                        printf("Invalid string literal escape '\\%c'", *Src);
                        exit(-1);
                    }
                }
                
                buf_push(String, Val);
                Src++;
            }
            
            
            if (*Src) {
                assert(*Src == '"');
                Src++;
            } else {
                SyntaxError("Unexpected end of file within string literal");
            }
            buf_push(String, 0);
            Tok.Kind = TOK_STR;
            Tok.StringVal = String;
            Tok.Text = String;
            
            
        } break;
        case '<':{
            
            if(Src[1] == '=')
            {
                Tok.Kind = TOK_LTEQ; Tok.Text = "<="; Src += 2; 
                break;
            }
            else if(Src[1] == '<')
            {
                Tok.Kind = TOK_LSHIFT; Tok.Text = "<<"; Src += 2;  
                break;
            }
            
            Tok.Kind = TOK_LT; Tok.Text = "<"; ++Src;  
            
        } break;
        case '?': {Tok.Kind = TOK_QUESTION; Tok.Text = "?"; ++Src; }break;
        
        case '&':
        {
            if(Src[1] == '&')
            {
                Tok.Kind = TOK_AND_AND; Tok.Text = "&&"; Src += 2;  break;
            }
            
            
            Tok.Kind = TOK_AND; Tok.Text = "&"; ++Src; 
            
            
        }break;
        case '|':
        {
            if(Src[1] == '|')
            {
                Tok.Kind = TOK_OR_OR; Tok.Text = "||"; Src += 2; break;
            }
            
            Tok.Kind = TOK_OR; Tok.Text = "|"; ++Src; 
        }break;
        
        case '\'':
        {
            //ScanChar(Src);
            Src++;
            char val = 0;
            if (*Src == '\'') {
                SyntaxError("Char literal cannot be empty");
                Src++;
            } else if (*Src == '\n') {
                SyntaxError("Char literal cannot contain newline");
            } else if (*Src == '\\') {
                Src++;
                val = EscapeToChar[*(unsigned char *)Src];
                if (val == 0 && *Src != '0') {
                    printf("Invalid char literal escape '\\%c'", *Src);
                    exit(-1);
                }
                Src++;
            } else {
                val = *Src;
                Src++;
            }
            if (*Src != '\'') {
                printf("Expected closing char quote, got '%c'", *Src);
                exit(-1);
            } else {
                Src++;
            }
            
            Tok.Kind = TOK_INTLIT;
            Tok.Value = val;
            Tok.Text = "char";
            
            Tok.Mod = TOKENMOD_CHAR;
            
        }break;
        
        case '%':
        {
            
            Tok.Kind = TOK_MOD; Tok.Text = "%"; ++Src;  break;
            
        }
        
        case '/':
        {
            Tok.Kind = TOK_DIV; Tok.Text = "/"; ++Src; break;
        }
        case '~':
        {
            Tok.Kind = TOK_NEG; Tok.Text = "~"; ++Src;  break;
        }
        
        default:
        {
            printf("Default lexer case %c\n", *Src);
            
            exit(-1);
        }break;
        
    }
    
    //printf("Lexed: %s\n", Tok.Text);
    PSource = Src;
}

bool32 IsToken(TokenKind Kind)
{
    if(Tok.Kind == Kind) return true;
    return false;
}


bool32 IsKeyword(const char *Keyword)
{
    return(strcmp(Tok.Text, Keyword) == 0);
}

bool32 MatchKeyword(const char *Keyword)
{
    if((strcmp(Tok.Text, Keyword) == 0))
    {
        TokNext();
        return true;
    }
    
    return(false);
}

bool32 MatchToken(TokenKind Kind)
{
    if(IsToken(Kind))
    {
        TokNext();
        return true;
    }
    
    return(false);
}

bool32 _TokExpect(TokenKind kind, const char *Expected, int Line, const char *File)
{
    if(IsToken(kind))
    {
        TokNext();
        return true;
    }
    else
    {
        
        printf("TokExpect failed at Line: %d, File: %s with expected: %s, but got %s\n", Line, File, Expected, Tok.Text);
        printf("Error in File at  Line: %d\n",  LineCount );
        exit(-1);
    }
}




#define TokExpect( Kind, Expected){_TokExpect(Kind, Expected, __LINE__, __FILE__);}

bool32 GlobalBool = 0;

bool32 _TokExpectNoError(TokenKind kind)
{
    if(IsToken(kind))
    {
        TokNext();
        return true;
    }
    else
    {
        
        GlobalBool = true;
        return false;
    }
}

#define TokExpectNoError( Kind){_TokExpectNoError(Kind);}