#include <am.h>
#include <nemu.h>
#include <klib.h>

extern char _heap_start;
int main(const char *args);

Area heap = RANGE(&_heap_start, PMEM_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  nemu_trap(code);

  // should not reach here
  while (1);
}

void _trm_init() {
  printf("heap_start = %x, heap_end = %x\n" ,&_pmem_start, PMEM_END);
  int ret = main(mainargs);
  halt(ret);
}
