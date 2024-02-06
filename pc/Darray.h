typedef struct buffer
{
    void **Data;
    size_t Index;//count
    size_t NumberOfAllocations; //capacity
    size_t Len;
    
}Buffer;

void InitBuffer(Buffer *Buf)
{
    Buf->Index = 0;
    Buf->NumberOfAllocations = 0;
    Buf->Data = NULL;
}

int LengthOfArray(Buffer *Buf)
{
    return Buf->Index;
}

void AddBuf(Buffer *Buf, void *DataToAdd)
{
    if(Buf->NumberOfAllocations < Buf->Index + 1)
    {
        size_t PrevNumberOfAllocations = Buf->NumberOfAllocations;
        Buf->NumberOfAllocations = PrevNumberOfAllocations < Buf->NumberOfAllocations ? Buf->NumberOfAllocations : PrevNumberOfAllocations + 1;
        
        if(Buf->NumberOfAllocations == 0) printf("Nothing to add\n");
        Buf->Data = realloc(Buf->Data, sizeof(DataToAdd) * Buf->NumberOfAllocations);
    }
    
    Buf->Data[Buf->Index] = DataToAdd;
    Buf->Index++;
    //printf("%d %d\n", Buf->Index, Buf->NumberOfAllocations);
}

