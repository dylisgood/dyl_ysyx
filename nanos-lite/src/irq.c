#include <common.h>

//Event handler callback function
static Context* do_event(Event e, Context* c) {
  printf("--------nanos-lite: enter do_event------------ \n");
  switch (e.event) {
    case 1: printf("nanos-lite: find EVENT_YIELD  e.event = %d \n", e.event); break;
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
