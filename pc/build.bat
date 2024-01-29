@echo off
REM -Wno-discarded-qualifiers -Wno-pointer-to-int-cast -Wno-int-conversion 
gcc  -Wall -pedantic  -fno-exceptions   main.c -o pc
