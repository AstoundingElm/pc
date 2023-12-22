#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>

typedef int32_t bool32;
bool32 PTrue = 1;
bool32 PFalse = 0;

#include "def.h"

#include "ast.h"
#include "list.h"

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
        case '[':{Tok.Kind = TOK_LBRACK; Tok.Text = "["; Src++;}break;
        case ']':{Tok.Kind = TOK_RBRACK; Tok.Text = "]"; Src++;}break;
        case '(':{Tok.Kind = TOK_LPAREN; Tok.Text = "("; Src++;}break;
        case ')':{Tok.Kind = TOK_RPAREN; Tok.Text = ")"; Src++;}break;
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
    
    //printf("Lexed: %s\n", Tok.Text);
    
}

void TokPeek(void)
{
    toknext(0);
}

void TokNext(void)
{
    toknext(1);
}

EnumItem *
InitEnumItemList( void *Head, EnumItem *ItemToAdd)
{
    
    ItemToAdd->Next = NULL;
    
    if(Head  == NULL)
	{
        Head = ItemToAdd; 
        return Head;
        
	}
}

void
AddEnumItemToList(void *Head,  EnumItem *Item)
{
    
    
    Item->Next = NULL;
    
    //TODO:
    /*Make sure that if there is a comma at end of enum list, 
that the comma/rbrace doesnt get added to enum lsit and effective
err message*/
    
    for(EnumItem *DupIt = Head; DupIt != NULL; DupIt = DupIt->Next)
    {
        if(strcmp(DupIt->Name, Item->Name) == 0)
        {
            printf("Duplicate enum var: %s\n", Item->Name);
            exit(-1);
        }
        
    }
    
    EnumItem* It = Head;  
    while(It->Next!=NULL)
    {
        It = It->Next;
        
    }
    
    It->Next = Item;
    
}

bool32 IsToken(TokenKind kind)
{
    return Tok.Kind == kind;
}

const char *IntKeyword = "int";
const char *StructKeyword = "struct";
const char *CharKeyword = "char";

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
    else if(strcmp(Tok.Text, "struct") == 0)
    {
        Typespec *Type = malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_ARRAY;
        return Type;
    }
    else if(strcmp(Tok.Text, "enum") == 0)
    {
        Typespec *Type = malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_ENUM;
        Type->name = "enum";
        return Type;
    }
    else if(strcmp(Tok.Text, "fn") == 0)
    {
        Typespec *Type = malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_FUNC;
        Type->name = "fn";
        return Type;
    }
    
    printf("Couldn't parse PType!\n");
    return NULL;
    
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
    
    printf("TokExpect failed with expected:%s, actual: %s\n", Expected, Tok.Text);
    TokNext();
    return PFalse;
}

AggregateItem *
ParseDeclAggregateItem()
{
    
    AggItemName *Names = NULL;
    Names = InitAggNameList(Names, Tok.Text);
    TokNext();
    while(IsToken(TOK_COMMA)){
        
        TokNext();
        
        AddAggName(Names, Tok.Text);
        TokNext();
        if(IsToken(TOK_COLON)) { TokNext(); break;}
        
    }
    
    TokNext();
    Typespec *Type = ParsePType();
    AggregateItem *it = malloc(sizeof(AggregateItem));
    
    it->Names = malloc(sizeof(AggItemName));
    it->Names = Names;
    it->Type = Type;
    
    return it;
}


Decl *
DeclAggregate(DeclKind Kind, const char *Name, AggregateItem *Items, size_t NumItems)
{
    PAssert(Kind == DECL_PSTRUCT || Kind == DECL_UNION, "Not a struct or union");
    Decl *D = malloc(sizeof(Decl));
    
    D->name = Name;
    D->kind = Kind;
    D->aggregate.Items = Items; 
    D->aggregate.num_items = NumItems;
    
    return D;
}

Decl *
ParseDeclPStruct(DeclKind Kind, const char *Name)
{
    PAssert(Kind == DECL_PSTRUCT || Kind == DECL_UNION, "ParseDeclstruct fail\n");
    
    TokNext();
    TokExpect(TOK_LBRACE, "{");
    
    AggregateItem *Items = NULL;
    
    Items = InitAggregateItemList(Items);
    
    while(!IsToken(TOK_RBRACE) && !IsToken(TOK_EOF))
    {
        
        AddAggregateItemList(Items, ParseDeclAggregateItem());
    }
    
    /*for(AggregateItem *It = Items->Next; It != NULL; It = It->Next)
    {
        for(AggItemName * Ait = It->Names; Ait != NULL; Ait = Ait->Next)
    }*/
    
    TokExpect(TOK_RBRACE, "}");
    
    size_t Len = 4;
    
    return DeclAggregate(DECL_PSTRUCT, Name, Items->Next, Len);
}

EnumItem *
ParseDeclEnumItem()
{
    
    const char *Name = Tok.Text;
    TokNext();
    Expr *Init = NULL;
    EnumItem *Item = malloc(sizeof(EnumItem));
    Item->Name = Name;
    Item->Init = Init;
    return Item;
}

Decl *
DeclEnum(const char *Name, EnumItem *Items, size_t NumItems)
{
    Decl *D = malloc(sizeof(Decl));
    D->name = Name;
    D->kind = DECL_ENUM;
    D->EnumDecl.Items = Items;
    D->EnumDecl.NumItems = NumItems;
    return D;
    
}

size_t ListLen(EnumItem *Items)
{
    size_t Counter = 0;
    for(EnumItem *It = Items; It != NULL; It = It->Next)
    {
        Counter++;
        
    }
    
    return Counter;
}

Decl *
ParseDeclEnum(const char *Name)
{
    TokNext();
    TokExpect(TOK_LBRACE, "{");
    
    EnumItem *Items = NULL;
    
    if(!IsToken(TOK_RBRACE))
    {
        
        Items = InitEnumItemList(Items, ParseDeclEnumItem());
        
        while(IsToken(TOK_COMMA)){
            TokNext();
            AddEnumItemToList( Items, ParseDeclEnumItem());
            
        }
    }
    
    TokExpect(TOK_RBRACE, "}");
    
    return DeclEnum(Name, Items, ListLen(Items));
}

Decl *
DeclFunc(const char *Name, FuncParam *Params, size_t NumOfParams, Typespec *ReturnType, StatementList *Block)
{
    Decl *Function = malloc(sizeof(Decl));
    
    Function->name = Name;
    Function->kind = DECL_FUNC;
    Function->Func.Params = Params;
    Function->Func.NumOfParams = NumOfParams;
    Function->Func.RetType = ReturnType;
    Function->Func.Block = Block;
    return Function;
}

FuncParam*
ParseDeclFuncParams()
{
    FuncParam*Param = malloc(sizeof(FuncParam));
    Param->Name = Tok.Text;
    TokNext();
    //TokExpect(TOK_COLON, ":");
    TokNext();
    Typespec *Type = ParsePType();
    Param->Type = Type;
    
    TokNext();
    
    return Param;
}

Decl *
ParseDeclOpt(void);

Statement *StatementDecl(Decl *decl)
{
    Statement *S = malloc(sizeof(Statement));
    S->Declaration = decl;
    return S;
}

Statement *
ParseStatement()
{
    Decl * decl = ParseDeclOpt();
    if(decl){
        return StatementDecl(decl);
    }
    
}

StatementList *
StmtList(PList *List, size_t NumOfStatements)
{
    StatementList *statement = malloc(sizeof(StatementList));
    statement->Statements = List;
    statement->NumOfStatements = NumOfStatements;
    return statement;
    
}

StatementList *
ParseStatementBlock()
{
    TokExpect(TOK_LBRACE, "{");
    
    PList * RStatementList = CreatePList();
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE))
    {
        AddToPList(RStatementList, ParseStatement());
    }
    
    /*Statement *StatePtr = NULL; 
    
    while((StatePtr = (Statement*)RemoveFromPList(RStatementList)) != NULL)
    {
        printf("%s\n", StatePtr->Declaration->name);
    }*/
    
    TokExpect(TOK_RBRACE, "}");
    
    return StmtList(RStatementList, 3);
}

Decl *
ParseDeclFunction()
{
    TokNext();
    const char *Name = Tok.Text;
    TokNext();
    TokExpect(TOK_LPAREN, "(");
    FuncParam *Params = NULL;
    
    if(!IsToken(TOK_RPAREN))
    {
        
        Params = InitFuncParamList(Params, ParseDeclFuncParams());
        
        while(IsToken(TOK_COMMA))
        {
            TokNext();
            AddFuncParam(Params, ParseDeclFuncParams());
            
        }
    }
    
    /*for(FuncParam *It = Params; It != NULL; It = It->Next)
    {
        //printf("ParamNames: %s\n", It->Name);
    }*/
    
    TokNext();
    TokNext();
    
    Typespec *ReturnType = NULL;
    if(IsToken(TOK_COLON))
    {
        TokNext();
        ReturnType = ParsePType();
    }
    TokNext();
    StatementList *Block = ParseStatementBlock();
    
    
    return DeclFunc(Name, Params, 3, ReturnType, Block);
}


Decl *
ParseDeclOpt(void)
{
    
    if(strcmp("fn", Tok.Text) == 0)
    {
        return ParseDeclFunction();
    }
    if(strcmp("typedef", Tok.Text) == 0)
    {
        printf("UNIMPLEMENTED\n");
        return NULL;
    }
    
    if(Tok.Kind == TOK_ID)
    {
        const char *Name = Tok.Text;
        
        TokNext();
        TokExpect(TOK_COLON, ":");
        
        Typespec *Type = ParsePType();
        
        if(strcmp("enum", Tok.Text) == 0)
        {
            
            return ParseDeclEnum( Name);
            
        }
        if(Type->kind == TYPESPEC_ARRAY)
        {
            
            return ParseDeclPStruct(DECL_PSTRUCT, Name);
        }
        
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

Decl *Decls = NULL;

int main(int ArgumentCount, char **Arguments)
{
    
    PList * TestList = CreatePList();
    Decl *Test1 = malloc(sizeof(Decl));
    Test1->name = "kef";
    Decl *Test2 = malloc(sizeof(Decl));
    Test2->name = "jefff";
    Decl *Test3 = malloc(sizeof(Decl));
    Test3->name = "ks33";
    Decl *Test4 = malloc(sizeof(Decl));
    Test4->name = "meme";
    Decl *Test5 = malloc(sizeof(Decl));
    Test5->name = "lol";
    
    AddToPList(TestList, (void *)Test1);
    AddToPList(TestList, (void *)Test2);
    AddToPList(TestList, (void *)Test3);
    AddToPList(TestList, (void *)Test4);
    AddToPList(TestList, (void *)Test5);
    //AddToPList(TestList, (void *)Test3);
    
    
    Decl * DeclPtr = NULL;//(Decl*)TestList->Head->Data;
    while((DeclPtr = (Decl*)RemoveFromPList(TestList)) != NULL)
    {
        //printf("%s\n", DeclPtr->name);
    }
    
    const char *Source = ReadFile("test.p");
    
    if(Source)
    {
        PSource = Source;
        
        TokNext();
        
        Decl *Root = malloc(sizeof(Decl));
        Root->name = "Root";
        Root->kind = DECL_ROOT;
        Decls = InitDeclList(Decls, Root);
        
        
        
        while(!IsToken(TOK_EOF))
        {
            DeclList(Decls, ParseDecl());
            
        }
        
        printf("\n");
        
        bool32 Print = 1;
        if(Print){
            for(Decl*It = Decls; It  != NULL; It = It->Next)
            {
                printf("DeclName: %s\n", It->name);
                printf("DeclKind: %s\n", DeclKindStrings[It->kind]);
                
                if(It->kind == DECL_PVAR){
                    printf("Type: %s\n", TypespecKindStrings[It->var.type->kind]);
                    printf("\n");
                    
                }
                //printf("\n");
                
                if(It->kind == DECL_PSTRUCT)
                {
                    
                    for(AggregateItem *Ait = It->aggregate.Items; Ait != NULL; Ait = Ait->Next)
                    {
                        for(AggItemName *Nit = Ait->Names; Nit != NULL; Nit = Nit->Next)
                        {
                            printf("\t");
                            printf("Struct var name: %s\n", Nit->Name);
                            
                        }
                        printf("\n");
                    }
                    
                }
                
                else if(It->kind == DECL_ENUM)
                {
                    
                    for(EnumItem *Eit = It->EnumDecl.Items; Eit != NULL; Eit = Eit->Next)
                    {
                        printf("\t");
                        printf("EnumItem: %s\n", Eit->Name);
                    }
                    printf("\n");
                }
                else if(It->kind == DECL_FUNC)
                {
                    
                    for(FuncParam *Fit = It->Func.Params; Fit != NULL; Fit = Fit->Next)
                    {
                        printf("\t");
                        printf("FuncparamName: %s\n", Fit->Name);
                        
                        
                    }
                    printf("\n");
                    
                    Statement *StatePtr = NULL; //It->Func.Block->Statements;
                    
                    while((StatePtr = (Statement*)RemoveFromPList(It->Func.Block->Statements)) != NULL)
                    {
                        printf("\t");
                        printf("Func block vars: %s\n", StatePtr->Declaration->name);
                        printf("\n");
                    }
                }
            }
            
        }
    }
    
    return(0);
}




/*
#include <stdio.h>
#include <stdlib.h>

typedef struct node {
    void* data;
    struct node* next;
} Node;

typedef struct list {
    int size;
    Node* head;
} List;

List* create_list() {
    List* new_list = (List*)malloc(sizeof(List));
    new_list->size = 0;
    new_list->head = NULL;
    return new_list;
}

void add_to_list(List* list, void* data) {
    Node* new_node = (Node*)malloc(sizeof(Node));
    new_node->data = data;
    new_node->next = list->head;
    list->head = new_node;
    list->size++;
}

void* remove_from_list(List* list) {
    if (list->size == 0) {
        return NULL;
    }
    Node* node_to_remove = list->head;
    void* data = node_to_remove->data;
    list->head = node_to_remove->next;
    free(node_to_remove);
    list->size--;
    return data;
}

void free_list(List* list) {
    Node* current_node = list->head;
    while (current_node != NULL) {
        Node* next_node = current_node->next;
        free(current_node);
        current_node = next_node;
    }
    free(list);
}

typedef struct Test
{
    char *Name;
    
}Test;

int main() {
    // create a new list
    List* int_list = create_list();
    
    Test *test1; //= malloc(sizeof(Test));
    test1->Name = "Jeff";
    
    // add some integers to the list
    int x = 42;
    add_to_list(int_list, (void*)&x);
    int y = 13;
    add_to_list(int_list, (void*)&y);
    int z = 99;
    add_to_list(int_list, (void*)&z);
    //add_to_list(int_list, (void*)test1);
    
    // remove the integers from the list and print them
    int* int_ptr = NULL;
    while ((int_ptr = (int*)remove_from_list(int_list)) != NULL) {
        printf("%d\n", *int_ptr);
    }
    
    // free the memory used by the list
    free_list(int_list);
    
    return 0;
}*/