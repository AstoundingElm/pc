del output.s 
del *.exe *.c
gcc compiler/main.c  -g -o ion
ion -o pc.c compiler/pc 
gcc -g pc.c -o pc
pc -gen_asm -o pc_gen compiler/test
gcc output.s -o out
out