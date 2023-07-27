#include <SDL2/SDL.h>
#include <stdbool.h>
#include <sys/time.h>
#include <time.h>
#include "utils.h"


#define TIMER_HZ 60

void send_key(uint8_t, bool);
void vga_update_screen();
extern bool npc_stop;

static uint64_t boot_time = 0;
static uint64_t get_time_internal() {
  struct timeval now;
  gettimeofday(&now, NULL);
  uint64_t us = now.tv_sec * 1000000 + now.tv_usec;
  return us;  
}

uint64_t get_time() {   //return 系统启动后经过的时间 单位 us
  if (boot_time == 0) boot_time = get_time_internal();
  uint64_t now = get_time_internal();
  return now - boot_time;
}

void device_update() {
  //printf("device update\n");
  static uint64_t last = 0;
  uint64_t now = get_time();
  if (now - last < 1000000 / TIMER_HZ) {
    return;
  }
  last = now;

  #ifdef CONFIG_HAS_VGA
    vga_update_screen();
  #endif

  SDL_Event event;
  while (SDL_PollEvent(&event))
  {
    //printf("get SDL_PollEvent, event.type = %d\n" ,event.type);
    switch (event.type) {
      case SDL_QUIT:
        npc_stop = true;
        break;
#ifdef CONFIG_HAS_KEYBOARD
      // If a key was pressed
      case SDL_KEYDOWN:
      case SDL_KEYUP: {
        uint8_t k = event.key.keysym.scancode;
        bool is_keydown = (event.key.type == SDL_KEYDOWN);
        send_key(k, is_keydown);
        break;
      }
#endif
      default: break;
    }
  }

}

void sdl_clear_event_queue() {
  SDL_Event event;
  while (SDL_PollEvent(&event));
}
