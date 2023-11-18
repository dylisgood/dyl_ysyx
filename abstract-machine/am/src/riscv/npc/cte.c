#include <am.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
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
          else{
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
