@echo off
REM set "SIL= > nul 2>&1"
del *.exe *.c
gcc compiler/main.c  -g -o ion
ion -o pc.c compiler/pc 
gcc -g pc.c -o pc

pc -o boot.c compiler/pc
gcc -g boot.c -o boot
boot -o reboot.c  compiler/pc

gcc -g reboot.c -o reboot

REM reboot -o rereboot.c ion/ptest
REM gcc -g rereboot.c -o rereboot
REM rereboot -o rereboot.c ion/ptest

