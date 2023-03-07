#include <stdint.h>
#include <assert.h>
//#include <debug.h>
#define MEM_SIZE  0x8000000
#define CONFIG_MBASE 0x80000000
#define PG_ALIGN __attribute((aligned(4096)))

#define FMT_PADDR MUXDEF(PMEM64, "0x%016"PRIx64, "0x%08"PRIx32)
#define PMEM_LEFT  ((uint64_t)CONFIG_MBASE)
#define PMEM_RIGHT ((uint64_t)CONFIG_MBASE + CONFIG_MSIZE - 1)

static uint8_t pmem[MEM_SIZE] PG_ALIGN = {};

static inline uint64_t host_read(void *addr, int len){
    switch (len){
        case 1: return *(uint8_t *)addr;
        case 2: return *(uint16_t *)addr;
        case 4: return *(uint32_t *)addr;
        case 8: return *(uint64_t *)addr;
        default: assert(0); return 0;
    }
}

static inline void host_write(void *addr, int len, uint64_t data){
    switch(len) {
        case 1: *(uint8_t *)addr = data; return;
        case 2: *(uint16_t *)addr = data; return;
        case 4: *(uint32_t *)addr = data; return;
        case 8: *(uint64_t *)addr = data; return;
        default: assert(0); return;
    }
}

uint8_t* guest_to_host(uint32_t paddr) { return pmem + paddr - CONFIG_MBASE; }

uint64_t pmem_read(uint32_t addr,int len){
    uint64_t ret = host_read(guest_to_host(addr),len);
    return ret;
} 

void pmem_write(int addr, int len, uint64_t data){
    host_write(guest_to_host(addr), len, data);
}

void init_mem() {
#ifdef CONFIG_MEM_RANDOM
  uint32_t *p = (uint32_t *)pmem;
  int i;
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
#else
  uint32_t *p = (uint32_t *)pmem;
  p[0] = 0x06428313;  //addi rd,rs,imm  x6=x5+imm
  p[1] = 0x00100073;  //ebreak
#endif
  //Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);    
}