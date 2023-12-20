#define SDL_malloc  malloc
#define SDL_free    free
#define SDL_realloc realloc

#define SDL_STBIMAGE_IMPLEMENTATION
#include "SDL_stbimage.h"
#include <fcntl.h>

SDL_Surface* IMG_Load_RW(SDL_RWops *src, int freesrc) {
  assert(src->type == RW_TYPE_MEM);
  assert(freesrc == 0);
  return NULL;
}

SDL_Surface* IMG_Load(const char *filename) {
  FILE* file = fopen(filename, "rb");
  assert(file != NULL);
  
  int fc = fseek(file, 0, SEEK_END);
  uint64_t size = ftell(file);
  uint8_t *buf = (uint8_t *)malloc(size);
  assert(buf);

  fseek(file, 0, SEEK_SET);
  size_t byteRead = fread(buf, 1, size, file);
  assert(byteRead == size);

  SDL_Surface *s = STBIMG_LoadFromMemory(buf, size);
  assert(s);
  fclose(file);
  free(buf);

  return s;
}

int IMG_isPNG(SDL_RWops *src) {
  return 0;
}

SDL_Surface* IMG_LoadJPG_RW(SDL_RWops *src) {
  return IMG_Load_RW(src, 0);
}

char *IMG_GetError() {
  return "Navy does not support IMG_GetError()";
}
