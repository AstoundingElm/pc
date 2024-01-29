

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
    if(List == NULL) 
    {
        printf("List Fail\n"); exit(-1);
    }
    
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
    if(List->Size == 0){
        
        //printf("Empty\n");
        return NULL;
        
    };
    Node *NodeToRemove = List->Head;
    void *Data = NodeToRemove->Data;
    List->Head = NodeToRemove->Next;
    free(NodeToRemove);
    List->Size--;
    return(Data);
}


//PList *Temp;
PList *Temp;
PList *Temp2;
/*
void *RemoveFromPListCopy(PList *List,  size_t i)
{
    if(i == 0){
        
        Node *NodeToRemove;  //= malloc(sizeof(Node *));
        
        NodeToRemove = List->Head;
        void *Data = NodeToRemove->Data;
        Temp = calloc(1,  sizeof(PList *));
        
        Temp->Head = NodeToRemove->Next;
        
        return(Data);
    }
    
    Node *NodeToRemove; //= malloc(sizeof(Node *));
    
    NodeToRemove = Temp->Head;
    void *Data = NodeToRemove->Data;
    Temp->Head = NodeToRemove->Next;
    
    return(Data);
}
*/

void *RemoveFromPListCopy(PList *List, PList *ListTemp,size_t i)
{
    if(i == 0){
        
        Node *NodeToRemove; //= malloc(sizeof(Node *));
        
        NodeToRemove = List->Head;
        void *Data = NodeToRemove->Data;
        //ListTemp = calloc(1, sizeof(PList *));
        ListTemp->Head = NodeToRemove->Next;
        
        return(Data);
    }
    
    
    Node *NodeToRemove; //= malloc(sizeof(Node *));
    
    NodeToRemove = ListTemp->Head;
    void *Data = NodeToRemove->Data;
    ListTemp->Head = NodeToRemove->Next;
    
    return(Data);
    
}

int ListLen( PList *List)
{
    return(List->Size);
}


void FreeList(PList* List) {
    Node* CurrentNode = List->Head;
    while (CurrentNode != NULL) {
        Node* NextNode = CurrentNode->Next;
        free(CurrentNode);
        CurrentNode = NextNode;
    }
    free(List);
}




