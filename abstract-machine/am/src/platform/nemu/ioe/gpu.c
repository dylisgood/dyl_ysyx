#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = 0, .height = 0,
    .vmemsz = 0
  };
  uint32_t size_reg = inl(VGACTL_ADDR);
  uint16_t width = (size_reg & 0xffff0000) >> 16;
  uint16_t height = size_reg & 0x0000ffff;
  cfg->width = width;
  cfg->height = height ;
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {   //每次往x,y处写w*h个像素点 实际是要写入FB_ADDR内存中
  uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
  int y_t = ctl->y;
  int x_t = ctl->x;
  uint32_t *pix = ctl->pixels;
  for(int y = ctl->y; y < (y_t + ctl->h); y++){
    for(int x = ctl->x; x < ( x_t + ctl->w); x++){
      fb[x + y*400] = *((pix));  //outl
      pix++;
    }
  }
  if(ctl->sync) { 
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
