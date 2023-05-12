#include <am.h>
#include <nemu.h>
#include <klib.h>

#define AUDIO_FREQ_ADDR      (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR  (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR   (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR      (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR     (AUDIO_ADDR + 0x14)

void __am_audio_init() {
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
  cfg->present = false;
  cfg->bufsize = inl(AUDIO_SBUF_SIZE_ADDR);
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
  outl(AUDIO_FREQ_ADDR,ctrl->freq);
  outl(AUDIO_CHANNELS_ADDR,ctrl->channels);
  outl(AUDIO_SAMPLES_ADDR,ctrl->samples);
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
  stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
  //static uint8_t *fr = (uint8_t *)(uintptr_t)AUDIO_SBUF_ADDR;
  int i = 0;
  static int len = 0;
  for(uint8_t *fb = (uint8_t *)(ctl->buf.start);fb < (uint8_t *)(ctl->buf.end);fb++){
    //*fr = *fb;
    //fr++;
    outb(AUDIO_SBUF_ADDR + i,*fb);
/*     printf("* fb = %d", 1); */
/*     printf("* fb = %d", 2);
    printf("* fb = %d ", 3); */
    i++;
  }
  len+=1;
  printf("AM: write %d bytes, 第 %d 次\n",i,len);
}
