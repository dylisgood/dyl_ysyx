/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <common.h>
#include <device/map.h>
#include <SDL2/SDL.h>
#include <unistd.h>
enum {
  reg_freq,
  reg_channels,
  reg_samples,
  reg_sbuf_size,
  reg_init,
  reg_count,
  nr_reg
};

static uint8_t *sbuf = NULL;
static uint32_t *audio_base = NULL;

int len_sbuf = 0;
int copied_size = 0;
static void audio_callback(void *userdata, uint8_t *stream, int len){  //SDL回调函数，提供缓冲区，要求回调函数往缓冲区写入音频数据
  len_sbuf ++;
  printf("NEMU: enter audio_callback! len = %d 第 %d 次 ",len,len_sbuf);
  Sint16* buffer = (Sint16*)stream;
  int buffer_size = len;

  // 从sbuf中读取音频数据
  int sbuf_size = CONFIG_SB_SIZE;
  int remaining_size = sbuf_size - copied_size; // 剩余未读的字节数
    if (remaining_size <= 0) {
        // 数据已经读取完毕
        SDL_memset(buffer, 0, len); // 设置缓冲区为0
        return;
    }
    int copy_size = buffer_size < remaining_size ? buffer_size : remaining_size;
    printf("copy_size = %d \n",copy_size);
    copied_size += copy_size;
    SDL_memcpy(buffer, sbuf + copied_size, copy_size); // 从sbuf中拷贝数据到缓冲区

/*     // 更新user_data指针
    userdata = (void*)((intptr_t)userdata + copy_size); */

    // 如果缓冲区未填满，则将其余部分设置为0
    if (copy_size < buffer_size) {
        SDL_memset(buffer + copy_size, 0, len - copy_size * 2);
    }
    SDL_PauseAudio(0);
}

static void audio_init(){
  SDL_AudioSpec s = {};
  s.format = AUDIO_S16SYS;  // 假设系统中音频数据的格式总是使用16位有符号数来表示
  s.userdata = NULL;        // 不使用
  s.freq = audio_base[reg_freq];
  //s.freq = 8000;
  //printf("s.freq = %d \n",s.freq);
  s.channels = audio_base[reg_channels];
  //s.channels = 1;
  s.samples = audio_base[reg_samples];
  //s.samples = 1024;
  s.callback = audio_callback;
  if(SDL_InitSubSystem(SDL_INIT_AUDIO)<0){
    printf("error\n");
  }
  if(SDL_OpenAudio(&s, NULL) < 0){
    printf("error\n");
  }
  SDL_PauseAudio(0);
}

static void audio_io_handler(uint32_t offset, int len, bool is_write) {  //回调函数 在每次写内存的时候被调用，用来管理队列？
  if(is_write)
  {
    if(offset == 8) audio_init();
  }
}

void init_audio() {
  uint32_t space_size = sizeof(uint32_t) * nr_reg;
  audio_base = (uint32_t *)new_space(space_size);
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map ("audio", CONFIG_AUDIO_CTL_PORT, audio_base, space_size, audio_io_handler);
#else
  add_mmio_map("audio", CONFIG_AUDIO_CTL_MMIO, audio_base, space_size, audio_io_handler);//包含6个32位寄存器
#endif

  sbuf = (uint8_t *)new_space(CONFIG_SB_SIZE);
  add_mmio_map("audio-sbuf", CONFIG_SB_ADDR, sbuf, CONFIG_SB_SIZE, NULL);  //流缓冲区 存放来自程序的音频数据
  //audio_init();
}
