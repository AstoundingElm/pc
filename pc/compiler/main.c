#include "stdafx.h"

bool flag_verbose;
bool flag_lazy;
bool flag_notypeinfo;
bool flag_fullgen;
bool flag_nolinesync;

#include "common.c"
#include "os.c"
#include "lex.c"
#include "type.c"
#include "ast.h"
#include "ast.c"
#include "print.c"
#include "parse.c"
#include "targets.c"
#include "resolve.c"
#include "gen.c"
#include "ion.c"
#include "test.c"

//#include <signal.h>

/*
char * icky_global_program_name;

int divide_by_zero(){

    int a = 1;
int b = 0;
return a / b;
}

void cause_calamity(){

(void)divide_by_zero();

}

void almost_c99_signal_handler(int sig){

    switch(sig){
case SIGFPE: fputs("Caught SIGFPE: arithmetic exception, such as divide by zero\n", stderr); break;
case SIGILL: fputs("Caught SIGILL: illegal instruction\n", stderr); break;
case SIGINT: fputs("Caught SIGINT: interactive attention signal, probably ctrl+c\n", stderr); break;
case SIGSEGV: fputs("Caught SIGSEGV: segfault\n", stderr); break;
case SIGTERM: fputs("Caught SIGTERM: a termination request was sent to the program\n", stderr); break;
    case SIGABRT:fputs("Caught SIGABRT: usually caused by an abort() or assert()\n", stderr);
        break;

    default: 
        fputs("Caught SIGTERM: a termination requests was sent to the program, probably a ctrl+c\n", stderr);
        break;
    }

    _Exit(1);
}

void set_signal_handler(){

    signal(SIGABRT, almost_c99_signal_handler);
    signal(SIGFPE, almost_c99_signal_handler);
    signal(SIGILL, almost_c99_signal_handler);
    signal(SIGINT, almost_c99_signal_handler);
    signal(SIGSEGV, almost_c99_signal_handler);
    signal(SIGTERM, almost_c99_signal_handler);
}*/

int main(int argc, const char **argv) {
   
   //icky_global_program_name = argv[0];
   //set_signal_handler();
   //cause_calamity();
 
    return ion_main(argc, argv);
}


