#include "mem.h"
#include "utils.h"

#define CONFIG_MSIZE  0x8000000 //800
#define CONFIG_MBASE 0x80000000 //8000
#define PG_ALIGN __attribute((aligned(4096)))

#define FMT_PADDR MUXDEF(PMEM64, "0x%016"PRIx64, "0x%08"PRIx32)
#define PMEM_LEFT  ((uint64_t)CONFIG_MBASE)
#define PMEM_RIGHT ((uint64_t)CONFIG_MBASE + CONFIG_MSIZE - 1)

//static uint8_t pmem[MEM_SIZE] PG_ALIGN = {};
static uint8_t *pmem = NULL;

static inline uint64_t host_read(void *addr, int len){
    switch (len){
        case 1: return *(uint8_t *)addr;
        case 2: return *(uint16_t *)addr;
        case 4: return *(uint32_t *)addr;
        case 8: return *(uint64_t *)addr;
        default: assert(0); return 0;
    }
}

static inline void host_write(void *addr, int len, uint64_t data, uint64_t wmask){
    switch(len) {
        case 1: *(uint8_t *)addr = data; return;
        case 2: *(uint16_t *)addr = data; return;
        case 4: *(uint32_t *)addr = data; return;
        case 8: *(uint64_t *)addr = (*(uint64_t *)addr & ~wmask) | data; return;
        default: assert(0); return;
    }
}

uint8_t* guest_to_host(uint32_t paddr) { return pmem + paddr - CONFIG_MBASE; } //pmem + paddr - 0x80000000 = pmem + 

uint64_t pmem_read(uint32_t addr,int len){
  //printf("pmem_read: addr = %x\n",addr);
  assert((addr >= 0x80000000) && (addr <= 0x87ffffff));
  uint64_t ret = host_read(guest_to_host(addr),len);
  #ifdef CONFIG_MTRACE  
    printf("read memory, read_addr = %x ,read data = %lx\n",addr,ret);
  #endif
  return ret;
} 

void pmem_write(int addr, int len, uint64_t data, uint64_t wmask){
  //printf("pmem_write: addr = %x\n",addr);
  assert( (addr >= 0x80000000) && (addr <= 0x87ffffff));
  
  host_write(guest_to_host(addr), len, data, wmask);
  #ifdef CONFIG_MTRACE  
    Log("write memory, write_addr = %x ,write_data = %lx\n",addr,data);  
  #endif
}

void init_mem() {
  pmem = (uint8_t *)malloc(CONFIG_MSIZE);
  assert(pmem);
#ifdef CONFIG_MEM_RANDOM
  uint32_t *p = (uint32_t *)pmem;
  int i;
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
#else
  uint32_t *p = (uint32_t *)pmem;
  p[0] = 0x00400293;  //addi rd,rs,imm  x5=x0+4;
  p[1] = 0x00328313;  //addi rd,rs,imm  x6=x5+3
  p[2] = 0x00228313;  //addi rd,rs,imm  x6=x5+2
  p[3] = 0x00128313;  //addi rd,rs,imm  x6=x5+1
  p[4] = 0x00228313;  //addi rd,rs,imm  x6=x5+2
  p[5] = 0x00328313;  //addi rd,rs,imm  x6=x5+3
  p[6] = 0x00100073;  //ebreak
  //p[0x23fa] = 0x8000011c;
#endif
  //Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);    
}