Decl *
InitDeclList(Decl *Head, Decl *DeclToAdd)
{
    DeclToAdd->Next = NULL;
    
    if(Head == NULL)
    {
        Head = DeclToAdd;
        return Head;
    }
}

void DeclList( Decl *Head, Decl *DeclToAdd)
{
    
    DeclToAdd->Next = NULL;
    
    Decl *It = Head;
    while(It->Next != NULL)
        It = It->Next;
    
    It->Next = DeclToAdd;
}

AggregateItem *
InitAggregateItemList(AggregateItem *Head)
{
    AggregateItem *Temp = malloc(sizeof(AggregateItem));
    Temp->Names = NULL;
    Temp->Next = NULL;
    if(Head == NULL)
    {
        Head = Temp;
        return Head;
    }
}

void
AddAggregateItemList(AggregateItem *Head, AggregateItem *ItemToAdd)
{
    ItemToAdd->Next = NULL;
    
    
    AggregateItem* It = Head;  
    while(It->Next!=NULL)
    {
        It = It->Next;
        
    }
    
    It->Next = ItemToAdd;
    
}



AggItemName *
InitAggNameList(AggItemName *Head, const char *Name)
{
    
    AggItemName *Temp = malloc(sizeof(AggItemName));
    Temp->Name = Name;
    Temp->Next = NULL;
    if(Head == NULL)
    {
        Head = Temp;
        return Head;
    }
}

void
AddAggName(AggItemName *Head, const char *Name)
{
    AggItemName *Temp = malloc(sizeof(AggItemName));
    
    Temp->Name = Name;
	Temp->Next = NULL;
	
    
    AggItemName* It = Head;  
    while(It->Next!=NULL)
    {
        It = It->Next;
        
    }
    
    It->Next = Temp;
    
    
}

/*
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
}*/


FuncParam *
InitFuncParamList(FuncParam*Head, FuncParam *ItemToAdd)
{
    ItemToAdd->Next = NULL;
    
    if(Head == NULL)
    {
        Head = ItemToAdd;
    }
    
    return Head;
}

void AddFuncParam(FuncParam *Head, FuncParam *ItemToAdd)
{
    ItemToAdd->Next = NULL;
    FuncParam* It= Head;
    while(It->Next != NULL)
    {
        It = It->Next;
    }
    
    It->Next = ItemToAdd;
}

typedef struct Node
{
    void *Data;
    struct Node *Next;
}Node;

typedef struct PList
{
    int Size;
    Node *Head;
}PList;

PList *CreatePList(void)
{
    PList *NewList = (PList*)malloc(sizeof(PList));
    NewList->Size = 0;
    NewList->Head = NULL;
    //NewList->Head->Next = NULL;
    return(NewList);
    
}

void AddToPList(PList *List, void *Data)
{
    Node *NewNode = (Node*)malloc(sizeof(Node));
    NewNode->Data = Data;
    NewNode->Next = NULL;//NULL, then prev?
    
    if(List->Head == NULL)
    {
        List->Head = NewNode;
        List->Size++;
        
    }else
    {
        Node * It = List->Head;
        while(It->Next != NULL)
        {
            It = It->Next;
        }
        
        It->Next = NewNode;
        List->Size++;
    }
}

void *RemoveFromPList(PList *List)
{
    if(List->Size == 0){/*printf("List is empty\n");*/ return NULL;};
    Node *NodeToRemove = List->Head;
    void *Data = NodeToRemove->Data;
    List->Head = NodeToRemove->Next;
    free(NodeToRemove);
    List->Size--;
    return(Data);
}