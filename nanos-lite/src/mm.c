#include <memory.h>
#include <proc.h>

static void *pf = NULL;

extern PCB *current;

void* new_page(size_t nr_page) {
  pf = pf + nr_page * PGSIZE;
  return pf;
}

#ifdef HAS_VME
static void* pg_alloc(int n) {
  void *pg_ptr;
  int pg_num = n >> 12;  //one page = 4 KBytes
  pg_ptr = new_page(pg_num);
  memset(pf,0,n);
  return pg_ptr;
}
#endif

void free_page(void *p) {
  panic("not implement yet");
}

/* The brk() system call handler. *///我们还需要在mm_brk()中把新申请的堆区映射到虚拟地址空间中,
int mm_brk(uintptr_t brk) {
  uint64_t brk_algin = brk & ~0xfff;
  for(uintptr_t va = current->max_brk + PGSIZE; va <= brk_algin; va += PGSIZE )
  {
    void *ptr = new_page(1);
    map(&current->as, (void *)va, ptr, 1);
  }
  current->max_brk = brk_algin;
  return 0;
}

void init_mm() {
  //将TRM提供的堆区起始地址作为空闲物理页的首地址, 这样以后, 将来就可以通过new_page()函数来分配空闲的物理页了.
  
  pf = (void *)ROUNDUP(heap.start, PGSIZE);       //find heap_start 4KB align next address
  printf("heap.start = %x, pf = %x \n" ,heap.start ,pf);
  Log("free physical pages starting from %x", pf);

#ifdef HAS_VME
  vme_init(pg_alloc, free_page); //
#endif
}
