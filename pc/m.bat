@echo off
REM set "SIL= > nul 2>&1"
del *.exe *.c
gcc compiler/main.c  -g -o ion
ion -o pc.c compiler/minimalist
gcc -g pc.c -o pc
pc
REM pc -o boot.c compiler/minimalist
REM gcc -g boot.c -o boot
REM boot
REM boot -o reboot.c  compiler/minimalist

REM gcc -g reboot.c -o reboot

