#include <common.h>
#include "syscall.h"
#include "fs.h"
#include <sys/time.h>
#include <proc.h>
//#define STRACE 1

uintptr_t sys_execve(const char *fname, char * const argv[], char *const envp[]);

size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t ramdisk_write(const void *buf, size_t offset, size_t len);
extern char fs_name[64];

uintptr_t sys_yield(){
  yield();
  return 0;
}

void sys_exit(int code){
  //naive_uload(NULL,"/bin/nterm");
  halt(code);
}

//open a file , and return file descriper
uintptr_t sys_open(const char *pathname, int flags, int mode){
  return fs_open(pathname, flags, mode);
}

uintptr_t sys_read(int fd, void *buf, size_t len){
  return fs_read(fd, buf, len);
}

uintptr_t sys_write(int fd, const char *buf, int len){
  return fs_write(fd, buf, len);
}

//adjust offset, to write/read anywhere of file 
uintptr_t sys_lseek(int fd, size_t offset, int whence){
  return fs_lseek(fd, offset, whence);
}

uintptr_t sys_close(int fd){
  return fs_close(fd);
}

uintptr_t sys_brk(int addr){
  return 0;
}

uintptr_t sys_gettimeofday(struct timeval*tv, struct timezone *tz ){
  uint64_t us = io_read(AM_TIMER_UPTIME).us;
  tv->tv_sec = us / 1000000;
  tv->tv_usec = us - tv->tv_sec * 1000000;
  return 0;
}

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  //printf("nanos-lite: a[0] = %d \n",a[0]);
  //printf("nanos-lite: find syscall: ");
  switch (a[0]) {
    case SYS_exit: printf("Call SYS_exit! argu = %d \n",c->GPRx); sys_exit(c->GPRx);  break;
    case SYS_yield: c->GPRx = sys_yield(); 
                    #ifdef STRACE
                      printf("SYS_yield, ret value = %d\n",c->GPRx); 
                    #endif
                    break; 
    case SYS_open: c->GPRx = sys_open((void *)c->GPR2, c->GPR3, c->GPR4);
                  break; 
                  //printf("Call SYS_open! file name = %s, ret value = %d\n",fs_name,c->GPRx); break;
    case SYS_read: c->GPRx = sys_read(c->GPR2, (void *)c->GPR3, c->GPR4); 
                  break;
                  //printf("Call SYS_read! file name = %s, ret value = %d\n",fs_name ,c->GPRx); break;
    case SYS_write: c->GPRx = sys_write(c->GPR2, (void *)c->GPR3, c->GPR4); 
                  break; 
                  //printf("SYS_write, ret value = %d\n",c->GPRx); break;
    case SYS_close: c->GPRx = sys_close(c->GPR2);
                    #ifdef STRACE 
                    printf("Call SYS_close! file name = %s, ret value = %d\n",fs_name ,c->GPRx);
                    #endif
                    break;
    case SYS_lseek: c->GPRx = sys_lseek(c->GPR2, c->GPR3, c->GPR4);
                    #ifdef STRACE 
                    //printf("Call SYS_lseek! file name = %s, ret value = %d\n",fs_name ,c->GPRx); 
                    #endif
                    break;
    case SYS_brk: c->GPRx = sys_brk(c->GPR2);
                    #ifdef STRACE 
                    printf("Call SYS_brk! ret value = %d\n",c->GPRx);
                    #endif 
                    break;
    case SYS_gettimeofday: c->GPRx = sys_gettimeofday((struct timeval *)c->GPR2, (struct timezone *)c->GPR3);break;
                    //printf("Call SYS_gettimeofday! ret value = %d\n",c->GPRx); break;
    case SYS_execve: c->GPRx = sys_execve( (const char *)c->GPR2, (char **)c->GPR3, (char **)c->GPR4 ); //break;
                    printf("Call SYS_execve! ret value = %d\n", c->GPRx); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
