#include <unistd.h>
#include <stdint.h>
#ifdef __ISA_NATIVE__
#error can not support ISA=native
#endif
#include <stdio.h>
#define SYS_yield 1
extern int _syscall_(int, uintptr_t, uintptr_t, uintptr_t);

int main() {
  write(1, "Hello World!\n", 13);
  printf("dummy:ready to yield \n");
  printf("HHHHa sdfsdfa sdfasdfwefqwefdffgdfgdsdfeltkweprtkpgk;,b,;,prtlwekrpm pgmpdmpmpkpqrwpeortjkpgndsfnl \n");
  return _syscall_(SYS_yield, 0, 0, 0);
}
