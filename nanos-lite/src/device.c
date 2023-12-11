#include <common.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  for(int i = 0; i < len; i++){
    putch(*(char *)buf);
    buf++;
  }
  return len;
}

static bool  has_kbd;
size_t events_read(void *buf, size_t offset, size_t len) {
  const char *down = "kd ";
  const char *up = "ku ";
  AM_INPUT_KEYBRD_T ev;
  ev.keycode = AM_KEY_NONE; 
  has_kbd  = io_read(AM_INPUT_CONFIG).present;
  if(has_kbd)
    ev = io_read(AM_INPUT_KEYBRD);

  if(ev.keycode != AM_KEY_NONE){
  //printf("Got  (kbd): %s (%d) %s\n", keyname[ev.keycode], ev.keycode, ev.keydown ? "DOWN" : "UP");
  size_t key_len = sizeof(keyname[ev.keycode]);
  if(ev.keydown){
    strcpy(buf,down);
    //memset(buf + 3, '\0' ,1);
    strcat(buf,keyname[ev.keycode]);
    strcat(buf,"\n");
  }
  else{
    strcpy(buf,up);
    //memset(buf + 3, '\0' ,1);
    strcat(buf,keyname[ev.keycode]);
    strcat(buf,"\n");
  }
  return 3 + key_len + 1;
  }
  else
    return 0;
}

size_t screen_w;
size_t screen_h;
size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  char str1[20];
  char str2[20]; 
  strcpy(str1, "WIDTH :");
  strcpy(str2, "HEIGHT  :");
  screen_w = io_read(AM_GPU_CONFIG).width;
  screen_h = io_read(AM_GPU_CONFIG).height;
  sprintf(str1 + strlen(str1), "%d", screen_w);
  sprintf(str2 + strlen(str2), "%d", screen_h);
  //printf("str1 = %s, str2 = %s, sizeof(str1)= %d, sizeof(str2) = %d, strlen(str1) = %d, strlen(str2) = %d\n",str1,str2,sizeof(str1),sizeof(str2),strlen(str1),strlen(str2));
  memcpy(buf, str1, sizeof(str1));
  memcpy(buf + strlen(str1), "\n", 1);
  memcpy(buf + strlen(str1) + 1, str2, sizeof(str2));
  return sizeof(str2);
}

size_t w_w, w_h;
size_t fb_write(const void *buf, size_t offset, size_t len) {
  //offset ----> x y 
  //printf("---------------nanos-lite : enter fb_write---------------\n");
  //offset = offset / 4;
  offset = offset >> 2;
  size_t len_t = len >> 2;
  size_t y = offset / 400;
  size_t x = offset % 400;
  io_write(AM_GPU_FBDRAW, x, y, (uint32_t *)buf, len_t, 1, true);
  return 0;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
