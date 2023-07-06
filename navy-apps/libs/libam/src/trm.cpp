#include <am.h>
#include <stdlib.h>
Area heap;

void putch(char ch) {
    putchar(ch);
}

void halt(int code) {
    //printf("halt: code = %d \n" ,code);
    exit(code);
    while(1);
}
