
char *ReadFile(char *FileName)
{
    char *Result = 0;
    
    FILE *File = fopen(FileName, "r");
    if(File)
    {
        fseek(File, 0, SEEK_END);
        size_t FileSize = ftell(File);
        fseek(File, 0, SEEK_SET);
        
        Result = (char *)malloc(FileSize + 1);
        fread(Result, FileSize, 1, File);
        Result[FileSize] = 0;
        
        fclose(File);
    }
    
    return(Result);
}

void assert(void *Expression)
{
    if(!Expression) exit(-1);
}

void Assert(void *Expression, const char *msg, int Line, char *File)
{
    if(!(Expression))
    {
        printf("Assertion failed on line %d in file %s with message %s\n", Line, File, msg); exit(-1);
    }
}


#define PAssert(Expression, msg) Assert(Expression, msg, __LINE__, __FILE__);


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
        int PrevNumberOfAllocations = Buf->NumberOfAllocations;
        Buf->NumberOfAllocations = PrevNumberOfAllocations < Buf->NumberOfAllocations ? Buf->NumberOfAllocations : PrevNumberOfAllocations + 1;
        
        if(Buf->NumberOfAllocations == 0) printf("Nothing to add\n");
        Buf->Data = realloc(Buf->Data, sizeof(DataToAdd) * Buf->NumberOfAllocations);
    }
    
    Buf->Data[Buf->Index] = DataToAdd;
    Buf->Index++;
    //printf("%d %d\n", Buf->Index, Buf->NumberOfAllocations);
}



typedef struct Intern
{
    size_t Len;
    const char *String;
    
}Intern;

Intern *Interns;
Buffer *InternBuffer;

const char *StringInternRange(const char *Start, const char *End)
{
    size_t Length =  End - Start;
    
    for(int i = 0; i <= LengthOfArray(InternBuffer); i++)
    {
        Intern *it = InternBuffer->Data[i];
        if(it->Len == Length && strncmp(it->String, Start, Length) == 0)
        {
            printf("Duplicate intern string %s\n", it->String);
            //printf("Here: %s\n", it->String);
            return it->String;
        }
    }
    
    
    char *String = malloc(sizeof(char));
    memcpy(String, Start, Length);
    String[Length] = 0;
    
    
    Intern *InternToAdd = malloc(sizeof(Intern));
    InternToAdd->Len = Length;
    InternToAdd->String = String;
    AddBuf(InternBuffer, InternToAdd );
    return String;
}

const char *StringIntern(const char *String) {
    return StringInternRange(String, String + strlen(String));
}