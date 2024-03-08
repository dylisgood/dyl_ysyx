#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

void __am_get_cur_as(Context *c);
void __am_switch(Context *c);

Context* __am_irq_handle(Context *c) {
  //printf("\nenter am_irq_handle \n");
  __am_get_cur_as(c); //将当前的地址空间描述符指针保存到上下文中 但此前上下文已经存入栈中

  if (user_handler) { 
    Event ev = {0};
    //printf("c->mcause = %lx GPR1 = %lx \n", c->mcause ,c->GPR1);
    switch (c->mcause) {
      case 0x8000000000000007:
        ev.event = EVENT_IRQ_TIMER;
        break;
      case 11: 
          if( c->GPR1 == -1 ){
              ev.event = EVENT_YIELD;
              c->mepc = c->mepc + 4;
          }
          else {
              ev.event = EVENT_SYSCALL;
              c->mepc = c->mepc + 4;
          }
          break;
      default: ev.event = EVENT_ERROR; printf("find error ,c->mcause = (%lx) \n" ,c->mcause); break;
    }

    c = user_handler(ev, c);  //pa4 中，如果是EVENT_YIELD nanos-lite返回的是另一个进程的上下文
    assert(c != NULL);
  }

  __am_switch(c); //切换地址空间, 将被调度进程的地址空间落实到MMU中
  //printf("out am_irq_handle \n\n");
  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));
  // register event handler
  user_handler = handler;
  return true;
}

//创建内核线程的上下文
Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {  //创建内核线程的上下文  其中kstack是栈的范围, entry是内核线程的入口, arg则是内核线程的参数
  Context* c = (Context*)kstack.end - 1;
  
  c->mepc = (uintptr_t)entry;
  c->GPR2 = (uintptr_t)arg;

  c->pdir = NULL; //在kcontext()中将上下文的地址空间描述符指针设置为NULL, 来进行特殊的标记, 等到将来在__am_irq_handle()中调用__am_switch()时, 如果发现地址空间描述符指针为NULL, 就不进行虚拟地址空间的切换.

  return c;
}

void yield() {
  asm volatile("li a7, -1; ecall");
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
  if(enable){
    asm volatile("csrsi mstatus, 8");   //mstatus_MIE
    asm volatile("csrs mie, %0" :: "r"(1 << 7)); //mie_MTIE
  }
  else {
    asm volatile("csrsi mstatus, 0");   //mstatus_MIE
    asm volatile("csrsi mie, 0");   //mstatus_MIE
  }
}