#ifndef __YSYX_MEMORY__
#define __YSYX_MEMORY__

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "utils.h"
#define RESET_VECTOR 0x80000000


uint64_t pmem_read(uint32_t addr,int len);
void pmem_write(int addr, int len, uint64_t data, uint64_t wmask);
void init_mem();

uint8_t* guest_to_host(uint32_t paddr);

#endif