#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>
#include <assert.h>
#include <fcntl.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
uint32_t NDL_start_time = 0;

uint32_t NDL_GetTicks() { //return ms
  struct timeval now;
  gettimeofday(&now, NULL);
  uint32_t now_time = now.tv_sec * 1000000 + now.tv_usec;
  return (now_time - NDL_start_time) / 1000;
}

int NDL_PollEvent(char *buf, int len) {
  int fp = open("/dev/events", O_RDONLY);
  assert( fp != -1 );
  int i = read(fp, buf, len);
  //printf("fp = %d, i = %d \n" ,fp,i);
  close(fp);
  return i;
}

void NDL_OpenCanvas(int *w, int *h) {
  int fp = open("/proc/dispinfo", O_RDONLY);
  assert( fp != -1 );
  char buf[64];
  int len = 32;
  int ret = read(fp, buf, len);
/*   printf("NDL_OpenCanvas : buf = \n%s \n",buf); */
  const char* delimiter = ":";
  char *token;
  char* numbers[2];
  int i = 0;
  token = strtok((char *)buf, delimiter);

  while(token != NULL){
    token = strtok(NULL, delimiter);
    if(token != NULL){
      numbers[i] = malloc(strlen(token) + 1);
      strcpy(numbers[i], token);
      i++;
    }
  }
  int s_w = atoi(numbers[0]);
  int s_h = atoi(numbers[1]);
  if(*w == 0 && *h == 0){
    *w = s_w;
    *h = s_h;
  }
/*   printf("screen_w :%d \n", s_w);
  printf("screen_h :%d \n", s_h); */

  for(int j = 0; j < 2; j++){
    free(numbers[j]);
  }
  close(fp);
  
  if (getenv("NWM_APP")) {
    printf("find NWM_APP");
    int fbctl = 4;
    fbdev = 5;
    screen_w = *w; screen_h = *h;
    char buf[64];
    int len = sprintf(buf, "%d %d", screen_w, screen_h);
    // let NWM resize the window and create the frame buffer
    write(fbctl, buf, len);
    while (1) {
      // 3 = evtdev
      int nread = read(3, buf, sizeof(buf) - 1);
      if (nread <= 0) continue;
      buf[nread] = '\0';
      if (strcmp(buf, "mmap ok") == 0) break;
    }
    close(fbctl);
  }
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  //printf("----------------navy-apps: enter NDL_DrawRect----------------\n");
  int fd = open("/dev/fb", O_WRONLY);
  //printf("fd = %d x = %d. y = %d, w = %d, h = %d \n" ,fd ,x ,y ,w ,h);
  assert(fd != -1);
  int fc = 0;
  int len = 0;
  for(int i = 0; i < h; i++){
      fc = lseek(fd, ((y + i) * 400 + x) * 4, SEEK_SET);
      assert(fc != -1);
      len = write( fd, pixels + i * w, w * sizeof(uint32_t));
      //printf("len = %d \n" ,len);
  }
/*   fc = lseek(fd, 0, SEEK_SET);
  assert(fc != -1);
  int result = close(fd);
  assert(result != -1); */
}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  struct timeval start;
  gettimeofday(&start, NULL);
  NDL_start_time = start.tv_sec * 1000000 + start.tv_usec;
  return 0;
}

void NDL_Quit() {
}
