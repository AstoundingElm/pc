#include "def.h"
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
        
        while(!IsToken(TOK_EOF))
        {
            AddToPList(Decls, ParseDecl());
            
        }
        
        printf("\n");
        
        
        //Resolve
        
        bool32 Resolve = 1;
        if(Resolve){
            
            //might be createPlist in main func?
            CachedArrayTypes = CreatePList();
            
            CachedPtrTypes = CreatePList();
            Entities = CreatePList();
            FieldTemp = CreatePList();
            FieldTemp2 = CreatePList();
            CachedFuncTypes = CreatePList();
            EntityInstallType("i64", TypeI64);
            EntityInstallType("void", TypeVoid);
            Fields = CreatePList();
            Temp = calloc(1,sizeof(PList * ));
            Temp2 = calloc(1,sizeof(PList * ));
            Decl *dIt = NULL;
            
            for(size_t i = 0; i < ListLen(Decls); i++)
            {
                
                dIt = RemoveFromPListCopy(Decls, Temp, i);
                EntityInstallDecl(dIt);
                
            }
            
            
            OrderedEntities = CreatePList();
            
            Entity *end = NULL;
            
            for(size_t i = 0; i < ListLen(Entities); i++)
            {
                end = RemoveFromPListCopy(Entities,Temp,  i);
                
                CompleteEntity(end);
                
                
            }
            
            
            printf("\n");
            
            Entity *OrderedEnt = NULL;
            while((OrderedEnt = RemoveFromPList(OrderedEntities)) != NULL)
            {
                if(OrderedEnt->decl)
                {
                    PrintDecl(OrderedEnt->decl);
                    
                }
                
                else
                {
                    
                    printf("EntityName %s\n", OrderedEnt->Name);
                }
            }
            
            //End Resolve
            
            printf("\n");
        }
        
        bool32 Print = 0;
        if(Print)
        {
            Decl *It = NULL;
            while((It = RemoveFromPList(Decls)) != NULL)
            {
                PrintDecl(It);
            }
            
            
        }
        
    }
    
    printf("LineCount: %d\n", LineCount);
    return(0);
}