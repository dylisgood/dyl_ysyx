#include <SDL2/SDL.h>
#include <string.h>

#define SCREEN_W 400
#define SCREEN_H 300

// for AM IOE
#define io_read(reg) \
  ({ reg##_T __io_param; \
    ioe_read(reg, &__io_param); \
    __io_param; })

#define io_write(reg, ...) \
  ({ reg##_T __io_param = (reg##_T) { __VA_ARGS__ }; \
    ioe_write(reg, &__io_param); })

static uint32_t screen_width() {
  return SCREEN_W;
}

static uint32_t screen_height() {
  return SCREEN_H;
}

static uint32_t screen_size() {
  return screen_width() * screen_height() * sizeof(uint32_t);
}

uint8_t vmem[400 * 300 * 4];              //显存
//uint32_t vmem[400 * 300];
static uint32_t *vgactl_port_base = NULL; //vga端口控制器
uint32_t sync_vmem = 0;

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

void init_screen() {
  //vmem = malloc(screen_size());
  memset(vmem, 0, screen_size());

  SDL_Window *window = NULL;
  char title[128];
  sprintf(title, "%s-NPC", "RISCV");
  SDL_Init(SDL_INIT_VIDEO);
  int a = SDL_CreateWindowAndRenderer(
      SCREEN_W * 2,
      SCREEN_H * 2,
      0, &window, &renderer);
  SDL_SetWindowTitle(window, title);
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
}

static inline void update_screen() {
  SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}

void vga_update_screen() {
  // TODO: call `update_screen()` when the sync register is non-zero,
  // then zero out the sync register
  update_screen();
  if(sync_vmem){
    sync_vmem = 0;
    //update_screen();
  }
}