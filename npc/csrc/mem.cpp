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
    Log("read memory, read_addr = %x ,read data = %lx\n",addr,ret);
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
  int i;2
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
#else
  uint32_t *p = (uint32_t *)pmem;
  p[0] = 0x00600293;  //t0 = x0 + 6;
  p[1] = 0x00000117;  //auipc   sp,0x0
  p[2] = 0x00600993;  //s3 = x0 + 6;
  p[3] = 0x00500b93;  //s7 = x0 + 5;
  p[4] = 0x00400293;  //t0 = x0 + 4;
  p[5] = 0x00400293;  //t0 = x0 + 4;
  p[6] = 0x000b8413;  //mv    s0,s7
  p[7] = 0x00700a13;  //s4 = x0 + 7;
  p[8] = 0x024100e7;  //jalr (36)sp
  p[9] = 0x00500b93;  //s7 = x0 + 5;
  p[10] = 0x00200413;  //li      s0,2
  p[11] = 0x00400293;  //t0 = x0 + 4
  p[12] = 0x00400293;  //t0 = x0 + 4;
  p[13] = 0x00500b93;  //s7 = x0 + 5;
  p[14] = 0x00400293;  //t0 = x0 + 4;
  p[15] = 0x00600993;  //s3 = x0 + 6;
  p[16] = 0x00400293;  //t0 = x0 + 4;
  p[17] = 0x00400293;  //t0 = x0 + 4
  p[18] = 0x00400293;  //t0 = x0 + 4
  p[19] = 0x00400293;  //t0 = x0 + 4;
  p[20] = 0x00400293;  //t0 = x0 + 4;
  p[21] = 0x00400293;  //t0 = x0 + 4;
  p[22] = 0x00328313;  //addi rd,rs,imm  t1=t0+3
  p[23] = 0x00400293;  //t0 = x0 + 4;
  p[24] = 0x00400293;  //t0 = x0 + 4;
  p[25] = 0x00400293;  //t0 = x0 + 4;
  p[26] = 0x00400293;  //t0 = x0 + 4;
  p[27] = 0x00400293;  //t0 = x0 + 4;
  p[28] = 0x00413303;  //ld      t1,32(sp)
  p[29] = 0x00630293;  //t0 = t1 + 6;
  p[30] = 0x01413403;  //ld      s0,8(sp)
  p[31] = 0x01413483;  //ld      s1,8(sp)
  p[32] = 0x00000513;  //li      a0,0
  p[33] = 0x00100073;  //ebreak
#endif
  //Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
  /*   p[19] = 0x03313423;  //sd      s3,40(sp)
  p[20] = 0x01713423;  //sd      s7,8(sp)
  0x005b8263;  //beq s7 t0 pc + 8
  p[21] = 0x03413023;  //sd      s4,32(sp) */
}