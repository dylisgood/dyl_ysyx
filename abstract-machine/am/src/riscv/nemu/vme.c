#include <am.h>
#include <nemu.h>
#include <klib.h>

static AddrSpace kas = {};
static void* (*pgalloc_usr)(int) = NULL;
static void (*pgfree_usr)(void*) = NULL;
static int vme_enable = 0;

static Area segments[] = {      // Kernel memory mappings
  NEMU_PADDR_SPACE             //Area1(memory)  Area2(fb)  Area3(device)
};

#define USER_SPACE RANGE(0x40000000, 0x80000000)
#define PTE_COUNT 512

static inline void set_satp(void *pdir) {
  uintptr_t mode = 1ul << (__riscv_xlen - 1);
  asm volatile("csrw satp, %0" : : "r"(mode | ((uintptr_t)pdir >> 12))); //存放根页表的物理页号  也就是根页表物理地址/4Kb
}

static inline uintptr_t get_satp() {
  uintptr_t satp;
  asm volatile("csrr %0, satp" : "=r"(satp));
  return satp << 12;
}


typedef struct {
  PTE pte[PTE_COUNT];
}page_table;

//vme_init()将设置页面分配和回收的回调函数, 然后调用map()来填写内核虚拟地址空间(kas)的页目录和页表, 最后设置一个叫satp(Supervisor Address Translation and Protection)的CSR寄存器来开启分页机制. 
bool vme_init(void* (*pgalloc_f)(int), void (*pgfree_f)(void*)) {
  pgalloc_usr = pgalloc_f;
  pgfree_usr = pgfree_f;

  kas.ptr = pgalloc_f(PGSIZE);  //开辟4KB 作为内核页表 页目录
  printf("kas.ptr = %x \n" ,kas.ptr);

  int i;
  for (i = 0; i < LENGTH(segments); i ++) {
    void *va = segments[i].start;
    for (; va < segments[i].end; va += PGSIZE) { //1页1页的映射
      //对于x86和riscv32, vme_init()会通过map()来填写内核虚拟地址空间的映射. 这些映射十分特殊, 它们的va和pa是相同的, 我们将它们称为"恒等映射"(identical mapping).
      map(&kas, va, va, 0);
    }
  }

  set_satp(kas.ptr);
  vme_enable = 1;

  return true;
}
//本质上虚存管理要做的事情, 就是在维护这个映射. 但这个映射应该是每个进程都各自维护一份
//创建一个默认的地址空间
void protect(AddrSpace *as) {
  PTE *updir = (PTE*)(pgalloc_usr(PGSIZE));
  as->ptr = updir;
  as->area = USER_SPACE;
  as->pgsize = PGSIZE;
  // map kernel space
  memcpy(updir, kas.ptr, PGSIZE);  
}

//销毁指定的地址空间
void unprotect(AddrSpace *as) {
}

void __am_get_cur_as(Context *c) {
  c->pdir = (vme_enable ? (void *)get_satp() : NULL);
}

void __am_switch(Context *c) {
  if (vme_enable && c->pdir != NULL) {
    set_satp(c->pdir);
  }
}

//它用于将地址空间as中虚拟地址va所在的虚拟页, 以prot的权限映射到pa所在的物理页.当prot中的present位为0时, 表示让va的映射无效. 由于我们不打算实现保护机制, 因此权限prot暂不使用.
//map()是VME中的核心API, 它需要在虚拟地址空间as的页目录和页表中填写正确的内容, 使得将来在分页模式下访问一个虚拟页(参数va)时, 硬件进行page table walk后得到的物理页, 正是之前在调用map()时给出的目标物理页(参数pa).
void map(AddrSpace *as, void *va, void *pa, int prot) {
  //将虚拟地址和物理地址转换为页号
  uint64_t vpn = (uint64_t)va / PGSIZE;
  uint64_t ppn = (uint64_t)pa / PGSIZE;

  //获取一级页表索引 二级页表索引 三级页表索引
  uint64_t pdx = ( vpn >> 18 ) & 0x1ff;   //vpn[2]
  uint64_t ptx = ( vpn >> 9 ) & 0x1ff;    //vpn[1] 
  uint64_t pgx = vpn & 0x1ff;

  assert(as->ptr != NULL);
  PTE ***dir = (PTE ***)(as->ptr);

  //根据一级页表 找到二级页表 如果二级页表为空 则需要重新开辟
  if(dir[pdx] == NULL){
    dir[pdx] = (PTE** )pgalloc_usr(PGSIZE);
  }
  //根据二级页表 找到三级页表 如果三级页表为空 则需要重新开辟
  if(dir[pdx][ptx] == NULL){
    //printf("ptx = %lx \n" ,ptx);
    dir[pdx][ptx] = (PTE *)pgalloc_usr(PGSIZE);
    //printf("dir[pdx][ptx] = %lx \n",dir[pdx][ptx]);
  }
  //为三级页表的PTE赋值
  dir[pdx][ptx][pgx] = (PTE)ppn;
  
}

//创建用户进程的上下文
Context *ucontext(AddrSpace *as, Area kstack, void *entry) {
  Context* c = (Context *)(kstack.end) - 1;
  c->mepc = (uintptr_t)entry;
  c->pdir = as->ptr;
  return c;
}
