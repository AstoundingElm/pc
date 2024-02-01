#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>

typedef int64_t i64;
typedef int32_t bool32;
bool32 PTrue = 1;
bool32 PFalse = 0;


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
    else
    {
        printf("Failed to find file\n");
        exit(-1);
    }
    
    return(Result);
}

void passert(void *Expression)
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



//#define PAssert(Expression, msg) Assert(Expression, msg, __LINE__, __FILE__);



static inline void PAssert(void *Expression, const char *Msg)
{
    Assert(Expression, Msg, __LINE__, __FILE__);
}
#include <assert.h>

#define PCAssert(Expression, Message ){if(!Expression) { printf("%s on Line: %d, in File:%s\n", Message, __LINE__,   __FILE__); exit(-1); }\
}


static inline void syntaxerror(const char *Msg, int Line, const char *File)
{
    printf("Syntax Error: %s on Line: %d in file: %s\n", Msg, Line, File);
    exit(-1);
}

static inline void SyntaxError(const char *Message)
{
    syntaxerror(Message, __LINE__, __FILE__);
}

void Fatal(const char *Message)
{
    printf("%s\n",Message);
    exit(-1);
}