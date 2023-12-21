#include <am.h>
#include "../riscv.h"
#include <klib.h>
//#include <stdio.h>
#define DEVICE_BASE 0xa0000000
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)

#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t key_t = inl(KBD_ADDR);
  int KEY = key_t & ~KEYDOWN_MASK;
  kbd->keycode = KEY;
  if( (key_t & KEYDOWN_MASK) == 0) kbd->keydown = 0;
  else kbd->keydown = 1; 
}
