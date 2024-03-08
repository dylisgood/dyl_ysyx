#include <common.h>

void do_syscall(Context* c);
Context* schedule(Context *prev);

//Event handler callback function
static Context* do_event(Event e, Context* c) {
  switch (e.event) {
    case 1: //printf("nanos-lite: find EVENT_YIELD  e.event = %d call schedule\n", e.event);
            //printf("before c = %x  ",c); 
            c = schedule(c);
            //printf("after c = %x \n",c);
            break;
    case 2: //printf("nanos-lite: find EVENT_SYSCALL  e.event = %d call do_syscall\n", e.event); 
            do_syscall(c);
            break;
    case 4: printf("nanos-lite: find EVENT_ERROR  e.event = %d \n",e.event); break;
    default: { printf("nanos-lite: e.event = %d \n",e.event ); \
                panic("Unhandled event ID = %d", e.event); }
  }
  return c;
}

void init_irq(void) {
  Log("Initializing interrupt/exception handler...");
  cte_init(do_event);
}
