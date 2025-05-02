del *.s

gcc compiler/main.c  -g -o ion
ion -o pc.c compiler/pc 
gcc -g pc.c -o pc
pc -gen_asm -o generated_asm.s compiler/rosetta 
gcc Code.s -o generated
generated