#ifndef __YSYX_MEMORY__
#define __YSYX_MEMORY__

#include <stdint.h>

void init_mem(void);
uint64_t pmem_read(uint32_t addr,int len);
void pmem_write(int addr, int len, uint64_t data);

#endif