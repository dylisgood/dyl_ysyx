#include <am.h>
#include <klib.h>
#include <NDL.h>

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = 0, .height = 0,
    .vmemsz = 0
  };
/*   int width,height;
  NDL_OpenCanvas(&width, &height);
  printf("width = %d, height = %d \n",width, height); */
  cfg->width = 400;
  cfg->height = 300;
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  NDL_DrawRect(ctl->pixels, ctl->x, ctl->y, ctl->w, ctl->h);
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
