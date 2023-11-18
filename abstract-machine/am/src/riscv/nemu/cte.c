#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

//c 是从哪来的，返回到哪里去？ 这个函数是由trap.s调用的  但是汇编语言怎么传递参数
Context* __am_irq_handle(Context *c) {
 // printf("---------------AM : enter am_irq_handle------------\n");

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
    c = user_handler(ev, c);
    assert(c != NULL);
  }

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

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  return NULL;
}

void yield() {
  printf("AM: ready to yield! \n");
  asm volatile("li a7, -1; ecall");
  printf("AM: finish yield! \n");
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
