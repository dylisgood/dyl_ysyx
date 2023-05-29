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
  static int sbuf_rear = 0;
  int i = 0;
  int count_t = inl(AUDIO_COUNT_ADDR);
  for(uint8_t *fb = (uint8_t *)(ctl->buf.start);fb < (uint8_t *)(ctl->buf.end);fb++){
    if( (sbuf_rear + i) >= 0x10000){
      if(count_t < 0x10000){
        sbuf_rear = 0;
        i=0;
      }
      else {
        printf("error ! the queue is full !\n");
        assert(0);
      }
    }
    outb(AUDIO_SBUF_ADDR + sbuf_rear + i,*fb);
    i++;
  }
  sbuf_rear += i;
  count_t = inl(AUDIO_COUNT_ADDR);
  outl(AUDIO_COUNT_ADDR, count_t + i);
}
