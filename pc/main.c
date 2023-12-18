#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>

typedef int32_t bool32;
bool32 PTrue = 1;
bool32 PFalse = 0;

typedef int64_t i64;
#include "def.h"
#include "ast.h"


void HandleKeywords(const char *Word)
{
    
    if(strcmp("int", Word) == 0){ Tok.Kind = TOK_KW;}
    else if(strcmp("i64", Word) == 0) {Tok.Kind = TOK_KW;}
}

void toknext(int UpdateSource)
{
    
    const char *Src = PSource;
    
    while(isspace(*Src))
    {
        Src++;
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
            while(isalnum(*Src))
            {
                Src++;
            }
            
            size_t TokenLength = Src - Start;
            char *SymbolString = malloc(TokenLength + 1);
            memcpy(SymbolString, Start, TokenLength);
            SymbolString[TokenLength] = 0;
            
            Tok.Text = SymbolString;
            Tok.Kind = TOK_ID;
            HandleKeywords(Tok.Text);
            
        }break;
        case '0':case '1':case '2':case '3':case '4':
        case '5':case '6':case '7':case '8':case '9':
        {
            
            //const char * temp = Src;
            while(isalnum(*Src))
            {
                Src++;
            }
            /*
            size_t TokenLength = Src - temp;
            char *SymbolString = malloc(TokenLength + 1);
            memcpy(SymbolString, temp, TokenLength);
            SymbolString[TokenLength] = '\0';
            
            Tok.Text = SymbolString;*/
            
            break;
        };
        
        case ':': {Tok.Kind = TOK_COLON; Tok.Text = ":"; Src++; }break;
        case '=' : 
        {
            Tok.Kind = TOK_EQUALS; Tok.Text = "=";  Src++;
        } break;
        case '\0': 
        {
            Tok.Kind = TOK_EOF; Tok.Text = "EOF";
        }break;
        case ';':{Tok.Kind = TOK_SEMI; Tok.Text = ";"; Src++;}break;
        case '{': {Tok.Kind = TOK_LBRACE; Tok.Text = "{";  Src++;}break;
        case '}': {Tok.Kind = TOK_RBRACE; Tok.Text = "}";  Src++;}break;
        case ',':{Tok.Kind = TOK_COMMA; Tok.Text = ","; Src++;}break;
        default:
        {
            printf("Default %c\n", *Src);
            ++Src;
        }break;
        
        
    }
    
    if(UpdateSource)
    {
        PSource = Src;
    }
    
    printf("Lexed: %s\n", Tok.Text);
    
}

void TokPeek(void)
{
    toknext(0);
}

void TokNext(void)
{
    toknext(1);
}


typedef struct Keyword
{
    const char *keyword;
    struct Keyword *Next;
}Keyword;

Keyword *Keywords = NULL;

void AddKeyword(const char* keyword)
{
    Keyword* Temp = malloc(sizeof(Keyword));
    Temp->keyword = keyword;
	Temp->Next = NULL;
	if(Keywords == NULL)
	{
        Keywords = Temp; 
        
	}
	else{
        
        for(Keyword *it = Keywords; it != NULL; it = it->Next){
            
            if(strcmp(it->keyword,keyword) == 0)
            {
                printf("Duplicate keyword: %s\n", keyword);
            }
        }
        
		Keyword* It = Keywords;  
		while(It->Next!=NULL)
		{
            It = It->Next;
            
		}
        
		It->Next = Temp;
	}
}


bool32 IsToken(TokenKind kind)
{
    return Tok.Kind == kind;
}

const char *IntKeyword = "int";
const char *StructKeyword = "struct";
const char *CharKeyword = "char";


Typespec *
ParseCType()
{
    
    Typespec *Type = malloc(sizeof(Typespec));
    printf("CType: %s\n", Tok.Text);
    if(strcmp(Tok.Text, "int" ) == 0){ 
        
        Type->kind = TYPESPEC_CINT;
        Type->name = "int";
        
        return Type;
    }
    
    printf("Couldn't parse CType!\n");
    return NULL;
}

Typespec *
ParsePType()
{
    
    //printf("PType: %s\n", Tok.Text);
    if(strcmp(Tok.Text, "i64") == 0)
    {
        Typespec *Type = malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_I64;
        Type->name = "i64";
        return Type;
    }
    
    printf("Couldn't parse PType!\n");
    return NULL;
}



Decl *DeclCVar(const char *Name, Typespec *Type, Expr *expr)
{
    Decl *decl = malloc(sizeof(Decl));
    decl->kind = DECL_CVAR;
    decl->name = Name;
    decl->var.type = Type;
    
    return decl;
}


Decl *DeclPVar(const char *Name, Typespec *Type, Expr *expr)
{
    Decl *decl = malloc(sizeof(Decl));
    decl->kind = DECL_PVAR;
    decl->name = Name;
    decl->var.type = Type;
    
    TokNext();
    return decl;
}


bool32 TokExpect(TokenKind kind, const char *Expected)
{
    
    if(Tok.Kind == kind)
    {
        TokNext();
        
        return PTrue;
        
    }
    
    printf("TokExpect failed with expected: %s, actual: %s\n", Expected, Tok.Text);
    TokNext();
    return PFalse;
}

Decl* ParseDeclCInt()
{
    
    Typespec *Type = ParseCType();
    
    Expr *expr= NULL;
    TokNext();
    const char *Name = Tok.Text;
    
    TokNext();
    
    bool32 e = TokExpect(TOK_SEMI, ";");
    
    return DeclCVar(Name, Type, expr);
}

Typespec *
ParseCStruct()
{
    Typespec *Type = malloc(sizeof(Typespec));
    if(strcmp(Tok.Text, "struct") == 0)
    {
        //Type->kind = TYPESPEC
    }
}

AggregateItem *
ParseDeclAggregateItem()
{
    Buffer *Names = malloc(sizeof(Buffer));
    InitBuffer(Names);
    
    Typespec *Type = NULL;//ParseCStructType();
    
    TokNext();
    const char* Name = Tok.Text;
    AddBuf(Names, Name);
    
    TokNext();
    /*while(IsToken(TOK_COMMA)){
        AddBuf(Names, Tok.Text);
    }
    TokNext();*/
    TokExpect(TOK_SEMI, ";");
    
    AggregateItem *it = malloc(sizeof(AggregateItem));
    //it->Names = Names;
    //it->NumNames =  LengthOfArray(Names);
    it->Type = Type;
    return it;
}


Decl *
DeclAggregate(DeclKind Kind, const char *Name, void*Items, size_t NumItems)
{
    PAssert(Kind == DECL_CSTRUCT || Kind == DECL_UNION, "Not a struct or union");
    Decl *D = malloc(sizeof(Decl));
    
    D->name = Name;
    D->kind = Kind;
    D->aggregate.items = Items; 
    D->aggregate.num_items = NumItems;
    
    return D;
}

Decl *
ParseDeclCStruct(DeclKind Kind)
{
    PAssert(Kind == DECL_CSTRUCT || Kind == DECL_UNION, "ParseDeclstruct fail\n");
    TokNext();
    const char *Name = Tok.Text;
    
    TokNext();
    TokExpect(TOK_LBRACE, "{");
    Buffer *AggregateItems = malloc(sizeof(Buffer));
    InitBuffer(AggregateItems);
    
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE))
    {
        
        AddBuf(AggregateItems, ParseDeclAggregateItem());
        
    }
    TokNext();
    TokExpect(TOK_SEMI, ";");
    size_t Len = LengthOfArray(AggregateItems);
    printf("Len: %d\n", Len);
    return DeclAggregate(Kind, Name, AggregateItems, Len);
}

Decl *
ParseDeclOpt(void)
{
    if(strcmp(Tok.Text, "int") == 0){ 
        return ParseDeclCInt();
    }
    else if(strcmp(Tok.Text, "struct") == 0)
    {
        return ParseDeclCStruct(DECL_CSTRUCT);
    }
    
    else if(Tok.Kind == TOK_ID)
    {
        const char *Name = Tok.Text;
        
        TokNext();
        TokExpect(TOK_COLON, ":");
        
        Typespec *Type = ParsePType();
        
        Expr *expr = NULL;
        return DeclPVar(Name, Type, expr);
    }
    
    return NULL;
}

Decl *
ParseDecl(void)
{
    
    Decl *decl = ParseDeclOpt();
    if(!decl){ 
        
        printf("Expected declaration keyword, got %s\n", Tok.Text); 
        exit(-1);
    }
    
    return decl;
}


int main(int ArgumentCount, char **Arguments)
{
    const char *Source = ReadFile("test.p");
    
    AddKeyword(IntKeyword);
    AddKeyword(CharKeyword);
    AddKeyword(StructKeyword);
    
    if(Source)
    {
        PSource = Source;
        
        Buffer *DeclsBuffer = malloc(sizeof(Buffer)); 
        InitBuffer(DeclsBuffer);
        
        
        TokNext();
        while(!IsToken(TOK_EOF))
        {
            
            AddBuf(DeclsBuffer, ParseDecl());
            
        }
        
        for(int i = 0; i < LengthOfArray(DeclsBuffer); i++)
        {
            
            Decl *it = DeclsBuffer->Data[i];
            
            
            printf("DeclName: %s\n", it->name);
            
            printf("DeclKind: %s\n", DeclKindStrings[it->kind]);
            if(it->kind == DECL_CSTRUCT)
            {
                
                /*for(int a = 0; a < LengthOfArray(it->aggregate.items); a++)
                {
                    
                    
                    AggregateItem *items  = it->aggregate.items->Data[a];
                    size_t NumOfItems = items->NumNames;
                    
                    printf("%d\n", NumOfItems);
                    for(int n = 0; n < LengthOfArray(items->Names); n++)
                    {
                        //char *Names = items->Names->Data[n];
                        
                    }
                    
                }*/
                printf("Num_items: %d\n", it->aggregate.num_items);
                
            }
            if(it->kind == DECL_CVAR || it->kind == DECL_PVAR)
                printf("Type: %s\n", TypespecKindStrings[it->var.type->kind]);
            //printf("Expression: %d\n", it->var.expr->int_val);
            printf("\n");
        }
        
    }
    
    return(0);
}