@echo off
REM -Wno-discarded-qualifiers -Wno-pointer-to-int-cast -Wno-int-conversion 
gcc  -Wall -W -pedantic  -fno-exceptions   main.c -o pc
