#include <am.h>
#include <klib.h>
#include <NDL.h>
#include <string.h>

#define _KEYS(_) \
  _(ESCAPE) _(F1) _(F2) _(F3) _(F4) _(F5) _(F6) _(F7) _(F8) _(F9) _(F10) _(F11) _(F12) \
  _(GRAVE) _(1) _(2) _(3) _(4) _(5) _(6) _(7) _(8) _(9) _(0) _(MINUS) _(EQUALS) _(BACKSPACE) \
  _(TAB) _(Q) _(W) _(E) _(R) _(T) _(Y) _(U) _(I) _(O) _(P) _(LEFTBRACKET) _(RIGHTBRACKET) _(BACKSLASH) \
  _(CAPSLOCK) _(A) _(S) _(D) _(F) _(G) _(H) _(J) _(K) _(L) _(SEMICOLON) _(APOSTROPHE) _(RETURN) \
  _(LSHIFT) _(Z) _(X) _(C) _(V) _(B) _(N) _(M) _(COMMA) _(PERIOD) _(SLASH) _(RSHIFT) \
  _(LCTRL) _(APPLICATION) _(LALT) _(SPACE) _(RALT) _(RCTRL) \
  _(UP) _(DOWN) _(LEFT) _(RIGHT) _(INSERT) _(DELETE) _(HOME) _(END) _(PAGEUP) _(PAGEDOWN)

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  char buf[128];
  kbd->keydown = 0;
  if (NDL_PollEvent(buf, sizeof(buf))) {
    char *key, *value;
    key = strtok(buf, " ");
    value = strtok(NULL, "\n");
    //printf("keyyy = %s\n" ,key);
    //printf("value = %s\n" ,value);
    if(!strcmp(key,"kd")){
      kbd->keydown = 1;
      for(int i = 0; i < 83; i++)
      {
        if(!strcmp(keyname[i], value)){
          kbd->keycode = i;
        }
      } 
    }
    else if(!strcmp(key, "ku")){
      kbd->keydown = 0;      
      for(int i = 0; i < 83; i++)
      {
        if(!strcmp(keyname[i],value)){
          kbd->keycode = i;
        }
      }
    }
    else{
      kbd->keycode = 0;
    }
  }
  else{
    kbd->keydown = 0;
    kbd->keycode = 0;
  }

  //printf("kbd->keycode = %d\n" ,kbd->keycode);
}
