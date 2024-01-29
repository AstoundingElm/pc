#include "def.h"
#include "Lexer.h"
#include "ast.h"
#include "list.h"
#include "Print.h"

#include "Expression.h"
#include "ResolveTypes.h"
#include "resolve.h"
#include "Parse.h"

int main(int ArgumentCount, char **Arguments)
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
        
        bool32 Resolve = 0;
        if(Resolve){
            
            
            Entities = CreatePList();
            EntityInstallType("i64", TypeI64);
            
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
                    //printf("EntityName %s\n", OrderedEnt->Name);
                }
                
                else
                {
                    
                    printf("EntityName %s\n", OrderedEnt->Name);
                }
            }
            
            //End Resolve
            
            printf("\n");
        }
        
        bool32 Print = 1;
        if(Print)
        {
            Decl *It = NULL;
            while((It = RemoveFromPList(Decls)) != NULL)
            {
                PrintDecl(It);
            }
            
            
        }
        
    }
    
    return(0);
}