#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

//c 是从哪来的，返回到哪里去？ 这个函数是由trap.s调用的  但是汇编语言怎么传递参数
Context* __am_irq_handle(Context *c) {
 // printf("---------------AM : enter am_irq_handle------------\n");

  if (user_handler) {
    Event ev = {0};
    //printf("AM: c->mcause = %d \n", c->mcause);
    switch (c->mcause) {  //执行流切换的原因打包成事件
      case -1: ev.event = EVENT_YIELD; break;
      case  0: ev.event = EVENT_SYSCALL; break;
      case  1: ev.event = EVENT_SYSCALL; break;
      case  2: ev.event = EVENT_SYSCALL; break;
      case  3: ev.event = EVENT_SYSCALL; break;
      case  4: ev.event = EVENT_SYSCALL; break;
      case  7: ev.event = EVENT_SYSCALL; break;
      case  8: ev.event = EVENT_SYSCALL; break;
      case  9: ev.event = EVENT_SYSCALL; break;
      case 13: ev.event = EVENT_SYSCALL; break;
      case 19: ev.event = EVENT_SYSCALL; break;
      default: ev.event = EVENT_ERROR; break;
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
