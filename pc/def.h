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
