#include <common.h>
#include "syscall.h"

uintptr_t SYS_yield(){
  yield();
  printf("-------------------nanos-lite:  finish SYS_yield!----------------\n ");
  return 0;
}

void SYS_exit(int code){
  printf("-------------------nanos-lite:  Enter SYS_exit!----------------\n ");
  halt(code);
}

uintptr_t SYS_write(int fd, const char *buf, int len){
  //printf("-------------------nanos-lite:  Enter SYS_write!----------------\n ");
  if(fd == 1 || fd == 2){
    for(int i = 0; i < len; i++){
      putch(*buf);
      buf++;
    }
  return len;
  }
  else
  return -1;
}

uintptr_t SYS_brk(int addr){
  return 0;
}

void do_syscall(Context *c) {
  //printf("-------------------nanos-lite: enter do_syscall-----------------\n");
  
  uintptr_t a[4];
  a[0] = c->GPR1;
  printf("nanos-lite: a[0] = %d \n",a[0]);
  //printf("nanos-lite: find syscall: ");
  switch (a[0]) {
    case 0: printf("SYS_exit, argu = %d \n",c->GPRx); SYS_exit(c->GPRx);  break;
    case 1: c->GPRx = SYS_yield(); printf("SYS_yield, ret value = %d\n",c->GPRx); break;
    case 4: c->GPRx = SYS_write(c->GPR2,(void *)c->GPR3,c->GPR4); break; //printf("SYS_write, ret value = %d\n",c->GPRx); break;
    case 9: c->GPRx = SYS_brk(c->GPR2);  break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
