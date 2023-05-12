#include <am.h>
#include <nemu.h>
#include <klib.h>

#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t key_t = inl(KBD_ADDR);
  int KEY = key_t & ~KEYDOWN_MASK;
  kbd->keycode = KEY;
  if( (key_t & KEYDOWN_MASK) == 0) kbd->keydown = 0;
  else kbd->keydown = 1; 
}
