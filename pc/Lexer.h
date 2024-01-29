typedef enum TokenKind
{
    TOK_EOF,
    
    TOK_ID,
    TOK_INTLIT,
    TOK_STR,
    TOK_LPAREN,
    TOK_RPAREN,
    TOK_LBRACE,
    TOK_RBRACE,
    TOK_LBRACK,
    TOK_RBRACK,
    TOK_I64,
    TOK_SEMI,
    TOK_BIN_OP,
    TOK_MUL,
    TOK_ADD,
    TOK_AND,
    TOK_NEG,
    TOK_ASSIGN,
    TOK_NOT,
    TOK_SLASH,
    TOK_PERCENT,
    TOK_PLUS,
    TOK_FLOAT,
    TOK_CMP,
    TOK_MINUS,
    TOK_COMMA,
    TOK_BIN_OP_END,
    TOK_KW,
    TOK_COLON,
    TOK_COUNT,
    TOK_DOT,
    TOK_BACKTICK,
    TOK_DEC,
    
    TOK_LESSTHAN,
    TOK_QUESTION,
    TOK_LTEQ,
    TOK_INC,
    TOK_MUL_ASSIGN,
    TOK_QUOT,
    TOK_MLCOM,
    
}TokenKind;


const char *TokToString(TokenKind Kind)
{
    switch(Kind)
    {
        case TOK_EOF: return "\0"; 
        
        case TOK_ID: return "ID"; 
        case TOK_INTLIT: return "INTLIT"; 
        case TOK_STR: return "STR";
        case TOK_LPAREN: return "("; 
        case TOK_RPAREN: return ")";
        case TOK_LBRACE: return "{";
        case TOK_RBRACE: return "}";
        case TOK_LBRACK: return "[";
        case TOK_RBRACK: return "]";
        case TOK_I64: return "i64";
        case TOK_SEMI: return ";";
        case TOK_BIN_OP: return "BIN_OP";
        case TOK_MUL: return "*";
        case TOK_ADD: return "+";
        case TOK_AND: return "&";
        case TOK_NEG: return "-";
        case TOK_ASSIGN: return "=";
        case TOK_NOT: return "!";
        case TOK_SLASH: return "/";
        case TOK_PERCENT: return "%s";
        //case TOK_PLUS: return "+";
        case TOK_FLOAT: return "FLOAT";
        case TOK_CMP: return "==";
        case TOK_LTEQ: return "<=";
        case TOK_INC: return "++";
        
        //TOK_MINUS,
        case TOK_COMMA: return ",";
        //case TOK_BIN_OP_END: return "";
        //TOK_KW,
        case TOK_COLON : return ":";
        //case TOK_COUNT :
        case TOK_DOT: return ".";
        case TOK_BACKTICK: return "`";
        case TOK_DEC: return "--";
        
        case TOK_LESSTHAN: return "<";
        case TOK_QUESTION: return "?";
        case TOK_QUOT: return "\"";
        
        default: printf("Unrecognised token in TokToString\n");
        exit(-1);
    }
    
    printf("Never get here\n");
}


//int AdvanceFlag = 0;
//int EnumFlag = 0;
typedef struct Token
{
    int Kind;
    int64_t  Value;
    char *ID;
    const char *Text;
    float FloatValue;
    
}Token;

const char *PSource;
/*
const char *PrevSrc;
const char *PrevTok;
TokenKind Temp;*/
Token Tok;
bool32 IsToken(TokenKind Kind);
void TokNext();
/*bool32 TokPeek(TokenKind Kind)
{
    const char *PrevSrc = PSource;
    const char * PrevTok = Tok.Text;
    TokenKind Temp = Tok.Kind;
    TokNext();
    if(IsToken(Kind))
    {
        return PTrue;
        
    }
    else
    {
        PSource = PrevSrc;
        Tok.Text = PrevTok;
        Tok.Kind = Temp;
        return PFalse;
    }
    
    printf("TokPeek failed");
    exit(-1);
    //return PFalse;
}*/


//bool32 IsNegVal = 0;
void TokNext()
{
    
    const char *Src = PSource;
    
    while(isspace(*Src))
    {
        Src++;
    }
    
    if(*Src == '/') 
    {
        Src++;
        if(*Src == '*')
        {
            Src++;
            
            
            for(;;){
                
                while(*Src != '*'){
                    Src++;
                }
                Src++;
                
                
                if(*Src != '/')
                {
                    continue;
                }
                else if(*Src == '/') 
                {
                    
                    Src++;
                    
                    while(isspace(*Src))
                    {
                        Src++;
                    }
                    
                }break;
            }
            
            
            
        }
    };
    
    //this cant do multiline comments next to each other
    
    
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
            while(isalnum(*Src))
            {
                Src++;
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
            bool32 IsFloat = 0;
            
            const char *ValStart = Src;
            while(isdigit(*Src))
            {
                Value *= 10;
                Value += *Src++ - '0';
                if(*Src == '.') {Src++; IsFloat = 1;}
                
            }
            
            
            size_t TokenLength = Src - ValStart;
            char *SymbolString = (char *)malloc(TokenLength + 1);
            memcpy(SymbolString, ValStart, TokenLength);
            SymbolString[TokenLength] = 0;
            Tok.Text = SymbolString;
            //printf("%s", Tok.Text);
            if(IsFloat){Tok.Kind = TOK_FLOAT; Tok.FloatValue = Value;}else{
                Tok.Kind = TOK_INTLIT;
                Tok.Value = Value;
            }
            
            
            
        }break;
        
        case ':': {Tok.Kind = TOK_COLON; Tok.Text = ":"; Src++; }break;
        case '=' : 
        {
            Src++;
            
            if(*Src == '=')
            {
                Tok.Kind = TOK_CMP; Tok.Text = "=="; Src++;
                break;
                
            }
            else
            {
                
                Tok.Kind = TOK_ASSIGN; Tok.Text = "="; //Src++;
                break;
            }
            
            
        } break;
        case '\0': 
        {
            Tok.Kind = TOK_EOF; Tok.Text = "EOF";
        }break;
        case ';':{Tok.Kind = TOK_SEMI; Tok.Text = ";"; Src++;}break;
        case '{': {Tok.Kind = TOK_LBRACE; Tok.Text = "{";  ++Src;}break;
        case '}': {Tok.Kind = TOK_RBRACE; Tok.Text = "}";  ++Src;}break;
        case ',':{Tok.Kind = TOK_COMMA; Tok.Text = ","; Src++;}break;
        case '[':{Tok.Kind = TOK_LBRACK; Tok.Text = "["; Src++;}break;
        case ']':{Tok.Kind = TOK_RBRACK; Tok.Text = "]"; Src++;}break;
        case '(':{Tok.Kind = TOK_LPAREN; Tok.Text = "("; Src++;}break;
        case ')':{Tok.Kind = TOK_RPAREN; Tok.Text = ")"; Src++;}break;
        case '*':
        {
            Src++;
            
            if(*Src == '=')
            {
                Tok.Kind = TOK_MUL_ASSIGN; Tok.Text = "*="; Src++;
                break;
            }else{
                
                Tok.Kind = TOK_MUL; Tok.Text = "*";// Src++;
                break;
            }
        }break;
        case '+':
        {
            //const char* PrevTok = Tok.Text;
            //const char *PrevSrc = PSource;
            //TokenKind PrevKind = Tok.Kind;
            Src++;
            if(*Src  == '+'){
                Tok.Kind = TOK_INC; Tok.Text = "++"; Src++;
                break;
            }
            else
            {
                //PSource = PrevSrc;
                //Tok.Text = PrevTok;
                //Tok.Kind = 
                Tok.Kind = TOK_ADD; Tok.Text = "+"; //Src++;
                break;
            }
        }break;
        case '-':{Tok.Kind = TOK_NEG; Tok.Text = "-";  Src++;}break;
        case '&':{Tok.Kind = TOK_AND; Tok.Text = "&"; Src++;}break;
        case '!':{Tok.Kind = TOK_NOT; Tok.Text = "!"; Src++;}break;
        case '.':{Tok.Kind = TOK_DOT; Tok.Text = "."; Src++;} break;
        case '\'':{Tok.Kind = TOK_STR; Tok.Text = "'";  Src++;} break;
        case '<':{
            
            
            Src++;
            if(*Src == '=')
            {
                Tok.Kind = TOK_LTEQ; Tok.Text = "<="; Src++;
                break;
            }
            
            //Tok.Kind = TOK_LESSTHAN; Tok.Text = "<"; Src++;
            
            
        } break;
        case '?': {Tok.Kind = TOK_QUESTION; Tok.Text = "?"; Src++;}break;
        case '"': { Tok.Kind = TOK_QUOT; Tok.Text = "\""; Src++;}break;
        
        default:
        {
            printf("Default %c\n", *Src);
            ++Src;
        }break;
        
        
        
    }
    
    //printf("Lexed: %s\n", Tok.Text);
    PSource = Src;
    
    
    
    
}


bool32 IsToken(TokenKind Kind)
{
    if(Tok.Kind == Kind) return PTrue;
    return PFalse;
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
        return PTrue;
    }
    
    return PFalse;
}

bool32 MatchToken(TokenKind Kind)
{
    if(IsToken(Kind))
    {
        TokNext();
        return PTrue;
    }
    
    return PFalse;
}



bool32 _TokExpect(TokenKind kind, const char *Expected, bool32 Advance)
{
    
    if(IsToken(kind))
    {
        if(Advance){
            TokNext();
        }
        return PTrue;
        
    }
    printf("TokExpect failed with expected:%s, actual: %s\n", Expected, Tok.Text);
    PAssert(0, "TokAssert");
    //exit(-1);
    return PFalse;
}

bool32 TokAssert(TokenKind Kind, const char *Expected)
{
    return _TokExpect(Kind, Expected, 0);
    
}

bool32 TokExpect(TokenKind Kind, const char *Expected)
{
    return _TokExpect(Kind, Expected, 1);
}