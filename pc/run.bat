@echo off

cd bld 
cd Debug

intc  ../../examples/intdecls.int 
cd ..
cd ..
cd examples

gcc intdecls.s -o intdecls
intdecls
cd ..