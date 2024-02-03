#include "def.h"
#include "Darray.h"
#include "Lexer.h"
#include "ast.h"
#include "list.h"
#include "Print.h"

#include "Expression.h"
#include "ResolveTypes.h"
#include "resolve.h"
#include "Parse.h"



int main()
{
    const char *Source = ReadFile("ResolveTest.h");
    
    if(Source)
    {
        PSource = Source;
        
        TokNext();
        
        PList *Decls = CreatePList();
        
        PrintAggregate = CreatePList();
        CachedArrayTypes = CreatePList();
        AggregateTemp = CreatePList();
        CachedPtrTypes = CreatePList();
        Entities = CreatePList();
        FieldTemp = CreatePList();
        FieldTemp2 = CreatePList();
        CachedFuncTypes = CreatePList();
        CachedFuncParams = CreatePList();
        CachedFuncParamsLocal = CreatePList();
        CachedFuncTypesTemp = CreatePList();
        Fields = CreatePList();
        NameTemp = CreatePList();
        Temp = CreatePList();
        TempParams = CreatePList();
        PrintFields = CreatePList();
        IfTemp = CreatePList();
        Temp2 = CreatePList();
        CompoundFieldTemp = CreatePList();
        AggregateFieldTemp = CreatePList();
        CompoundArrayTemp = CreatePList();
        OrderedSyms = CreatePList();
        GlobalSyms = CreatePList();
        LocalSyms = CreatePList();
        FuncParamsTemp = CreatePList();
        StatementsTemp = CreatePList();
        FuncTypeTemp = CreatePList();
        ElseIfTemp = CreatePList();
        SwitchCasesTemp = CreatePList();
        ExprsTemp = CreatePList();
        LocalSymsTemp = CreatePList();
        
        while(!IsToken(TOK_EOF))
        {
            AddToPList(Decls, ParseDecl());
            
        }
        
        
        bool32 Resolve = 1;
        if(Resolve){
            
            
            SymGlobalType("i64", TypeI64);
            SymGlobalType("void", TypeVoid);
            SymGlobalType("char", TypeChar);
            SymGlobalType("float", TypeFloat);
            
            
            Decl *dIt = NULL;
            
            for(size_t i = 0; i < ListLen(Decls); i++)
            {
                
                dIt = RemoveFromPListCopy(Decls, Temp, i);
                SymGlobalDecl(dIt);
                
            }
            
            Sym*end = NULL;
            
            for(size_t i = 0; i < ListLen(GlobalSyms); i++)
            {
                end = RemoveFromPListCopy(GlobalSyms,Temp,  i);
                
                CompleteSym(end);
                
                
            }
            
            Sym*OrderedSym = NULL;
            while((OrderedSym = RemoveFromPList(OrderedSyms)) != NULL)
            {
                if(OrderedSym->decl)
                {
                    PrintDecl(OrderedSym->decl);
                    
                }
                
                else
                {
                    
                    printf("EntityName %s\n", OrderedSym->Name);
                }
                printf("\n");
            }
            
            //End Resolve
            
            
        }
        
        bool32 Print = 0;
        if(Print)
        {
            Decl *It = NULL;
            while((It = RemoveFromPList(Decls)) != NULL)
            {
                PrintDecl(It);
                printf("\n");
            }
            
        }
        
    }
    
    printf("LineCount: %d\n", LineCount);
    return(0);
}