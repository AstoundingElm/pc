#include "def.h"
//#include "Darray.h"
#include "list.h"
#include "Lexer.h"
#include "ast.h"

#include "Print.h"

#include "Expression.h"
#include "ResolveTypes.h"
#include "resolve.h"
#include "Parse.h"
#include "Gen.c"


int main()
{
    const char *Source = ReadFile("GenTest.h");
    
    if(Source)
    {
        PSource = Source;
        
        TokNext();
        
        Decl **Decls = NULL;
        
        
        SymGlobalType("i64", TypeI64);
        SymGlobalType("void", TypeVoid);
        SymGlobalType("char", TypeChar);
        SymGlobalType("float", TypeFloat);
        
        while(!IsToken(TOK_EOF))
        {
            Decl *decl = ParseDecl();
            buf_push(Decls, decl);
            //PrintDecl(decl);
            printf("\n");
            
        }
        
        
        bool32 Resolve = 1;
        if(Resolve){
            
            
            
            for(Decl **it = Decls; it != buf_end(Decls); it++)
            {
                SymGlobalDecl(*it);
                
            }
            
            FinalizeSyms();
            for (Sym **it = OrderedSyms; it != buf_end(OrderedSyms); it++) {
                Sym *sym = *it;
                if (sym->decl) {
                    //PrintDecl(sym->decl);
                } else {
                    printf("%s", sym->Name);
                }
                
                //End Resolve
                
                printf("\n");
            }
            
            GenAll();
            
            
        }
        
        printf("LineCount: %d\n", LineCount);
        return(0);
    }
    
}