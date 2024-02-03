#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>

typedef int64_t i64;
typedef int32_t bool32;
typedef uint64_t u64;

bool32 PTrue = 1;
bool32 PFalse = 0;

//#define PINLINE static inline 

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

#define PCAssert(Expression, Message ){if(!Expression) { printf("%s on Line: %d, in File:%s\n", Message, __LINE__,   __FILE__); exit(-1); }\
}


void Fatal(const char *Message)
{
    printf("%s\n",Message);
    exit(-1);
}