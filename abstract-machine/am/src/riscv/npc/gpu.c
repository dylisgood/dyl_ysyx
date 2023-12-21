#include <am.h>
#include "../riscv.h"
#include <stdio.h>
#include <klib.h>
#define MMIO_BASE 0xa0000000
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
#define DEVICE_BASE 0xa0000000
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
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
  uint32_t *pix = ctl->pixels;
  for(uint32_t y = ctl->y; y < (ctl->y + ctl->h); y++){
    uint32_t y_offset = ( y << 8 ) + ( y << 7 ) + ( y << 4 ); //y * 400
    uint32_t *fb_row = &fb[y_offset + ctl->x];
    for(int x = ctl->x; x < ( ctl->x + ctl->w ); x++){
      *(fb_row++) = *((pix++));
    }
  }

  if(ctl->sync) { 
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}