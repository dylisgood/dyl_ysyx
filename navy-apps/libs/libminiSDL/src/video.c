#include <NDL.h>
#include <sdl-video.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>

#include <stdio.h>

static int count = 0;
void SDL_BlitSurface(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect) {
  //printf("-----------------enter SDL_BlitSurface -------------------------- count = %d\n" ,count++);
  //printf("src->format->BytesPerPixel = %d, dst->format->BytesPerPixel = %d \n" ,src->format->BytesPerPixel,dst->format->BytesPerPixel);
  assert(dst && src);
  assert(dst->format->BitsPerPixel == src->format->BitsPerPixel);
  uint16_t w,h;
  int16_t x,y;
  int32_t srcrect_y,srcrect_x;
  if(srcrect == NULL){ w = src->w; h = src->h; srcrect_y = 0; srcrect_x = 0; }
  else{ w = srcrect->w; h = srcrect->h; srcrect_y = srcrect->y; srcrect_x = srcrect->x; }

  if(dstrect == NULL){ x = 0; y = 0; }
  else{ x = dstrect->x; y = dstrect->y; }

/*   printf("SDL_BlitSurface: src->w = %d ,src->h = %d, dst->w = %d, dst->h = %d \n", src->w, src->h, dst->w, dst->h);
  if(srcrect)
  printf("SDL_BlitSurface: srcrect->w = %d ,srcrect->h = %d, srcrect->x = %d, srcrect->y = %d \n",srcrect->w, srcrect->h, srcrect->x, srcrect->y);
  if(dstrect)
  printf("SDL_BlitSurface: dstrect->w = %d ,dstrect->h = %d, dstrect->x = %d, dstrect->y = %d \n",dstrect->w, dstrect->h, dstrect->x, dstrect->y);
  printf("SDL_BlitSurface: x = %d ,y = %d, w = %d, h = %d \n", x, y, w, h);
 */
  if(src->format->BytesPerPixel == 4){
    //assert(0);
    uint32_t *sptr = (uint32_t *)src->pixels;
    uint32_t *ptr = (uint32_t *)dst->pixels;
    int32_t srcrect_xt = srcrect_x;
    for(int j = y; j < y + h; j++){
      for(int i = x; i < x + w; i++){
        ptr[(j * dst->w + i)] = sptr[(srcrect_y * src->w + srcrect_xt)];
        srcrect_xt ++;
        if(srcrect_xt - srcrect_x >= src->w){
          srcrect_xt = srcrect_x;
          srcrect_y += 1;
        }
      }
    }
  }

  else if(src->format->BytesPerPixel == 1){
    uint8_t *sptr8 = src->pixels;
    uint8_t *ptr8 = dst->pixels;
    uint32_t srcrect_xt = srcrect_x;
    for(int j = y; j < y + h; j++){
      for(int i = x; i < x + w; i++){
        ptr8[(j * dst->w + i)] = sptr8[( srcrect_y * src->w + srcrect_xt )];
        srcrect_xt++;
        if(srcrect_xt - srcrect_x >= w){
          srcrect_y += 1;
          srcrect_xt = srcrect_x;
        }
      }
    }
  }
  else assert(0);
}

void SDL_FillRect(SDL_Surface *dst, SDL_Rect *dstrect, uint32_t color) {
  //printf("-----------------enter SDL_FillRect --------------------------\n");
  if(dst->format->BytesPerPixel != 4){
    printf("s->format->BytesPerPixel = %d \n" ,dst->format->BytesPerPixel);
    assert(0);
  }
  uint16_t h ,w;
  int16_t x , y;
  if(dstrect == NULL){
    h = dst->h;
    w = dst->w;
    x = 0;
    y = 0;
  }
  else {
    h = dstrect->h;
    w = dstrect->w;
    x = dstrect->x;
    y = dstrect->y;
  }
 
  if(dst->format->BytesPerPixel == 4){
    dst->pixels = (uint8_t *)malloc(w * h * 4); 
    assert(dst->pixels);
    uint32_t *ptr = (uint32_t *)dst->pixels;
    for(int i = 0; i < w * h; i++){
      ptr[i] = color;
    }
    NDL_DrawRect((uint32_t *)dst->pixels, x, y, w, h);
  }
}

void SDL_UpdateRect(SDL_Surface *s, int x, int y, int w, int h) {
  //printf("-----------------enter SDL_UpdateRect --------------------------\n");
  //printf("src->w = %d, src->h = %d \n" ,s->w , s->h);
  if(w == 0 && h == 0){
     w = s->w, h = s->h;
  }
  //printf("x = %d y = %d w = %d h = %d \n",x,y,w,h);
  int src_y = y;
  int src_x = x;
  uint32_t* pixels32 = (uint32_t *)malloc(w * h * sizeof(uint32_t));
  assert(pixels32);

  if(s->format->BytesPerPixel == 4){
    for(int i = 0; i < w * h; i++){
      pixels32[i] = *(((uint32_t *)s->pixels) + (src_y * s->w + src_x));
      src_x++;
      if(src_x - x >= w){
        src_y += 1;
        src_x = x;
      }
    }
    NDL_DrawRect(pixels32, x, y, w, h);
  }

  else if( s->format->BytesPerPixel == 1){
    SDL_Palette* palette = s->format->palette;
    int colors = palette->ncolors;
    for(int i = 0; i < w * h ; i++){
      uint8_t pixel8 = s->pixels[src_y * s->w + src_x];
      src_x++;
      if(src_x - x >= w){
        src_y += 1;
        src_x = x;
      }
      SDL_Color color = palette->colors[pixel8];
      uint32_t pixel32 = SDL_MapRGB(s->format, color.r, color.g, color.b, color.a);
      pixels32[i] = pixel32;
      }
    NDL_DrawRect(pixels32, x, y, w, h);
  }

  else assert(0);
  free(pixels32);
}

// APIs below are already implemented.

static inline int maskToShift(uint32_t mask) {
  switch (mask) {
    case 0x000000ff: return 0;
    case 0x0000ff00: return 8;
    case 0x00ff0000: return 16;
    case 0xff000000: return 24;
    case 0x00000000: return 24; // hack
    default: assert(0);
  }
}

SDL_Surface* SDL_CreateRGBSurface(uint32_t flags, int width, int height, int depth,
    uint32_t Rmask, uint32_t Gmask, uint32_t Bmask, uint32_t Amask) {
  //printf("---------------- SDL_CreateRGBSurface ----------------\n");
  assert(depth == 8 || depth == 32);
  SDL_Surface *s = malloc(sizeof(SDL_Surface));
  assert(s);
  s->flags = flags;
  s->format = malloc(sizeof(SDL_PixelFormat));
  assert(s->format);
  if (depth == 8) {
    s->format->palette = malloc(sizeof(SDL_Palette));
    assert(s->format->palette);
    s->format->palette->colors = malloc(sizeof(SDL_Color) * 256);
    assert(s->format->palette->colors);
    memset(s->format->palette->colors, 0, sizeof(SDL_Color) * 256);
    s->format->palette->ncolors = 256;
  } else {
    s->format->palette = NULL;
    s->format->Rmask = Rmask; s->format->Rshift = maskToShift(Rmask); s->format->Rloss = 0;
    s->format->Gmask = Gmask; s->format->Gshift = maskToShift(Gmask); s->format->Gloss = 0;
    s->format->Bmask = Bmask; s->format->Bshift = maskToShift(Bmask); s->format->Bloss = 0;
    s->format->Amask = Amask; s->format->Ashift = maskToShift(Amask); s->format->Aloss = 0;
  }

  s->format->BitsPerPixel = depth;
  s->format->BytesPerPixel = depth / 8;

  s->w = width;
  s->h = height;
  s->pitch = width * depth / 8;
  if (!(flags & SDL_PREALLOC)) {
    //printf("no prealloc , malloc s->pixels size = %d \n" ,s->pitch * height);
    s->pixels = malloc(s->pitch * height);
    assert(s->pixels);
  }

  return s;
}

SDL_Surface* SDL_CreateRGBSurfaceFrom(void *pixels, int width, int height, int depth,
    int pitch, uint32_t Rmask, uint32_t Gmask, uint32_t Bmask, uint32_t Amask) {
  SDL_Surface *s = SDL_CreateRGBSurface(SDL_PREALLOC, width, height, depth,
      Rmask, Gmask, Bmask, Amask);
  assert(pitch == s->pitch);
  s->pixels = pixels;
  return s;
}

void SDL_FreeSurface(SDL_Surface *s) {
  if (s != NULL) {
    if (s->format != NULL) {
      if (s->format->palette != NULL) {
        if (s->format->palette->colors != NULL) free(s->format->palette->colors);
        free(s->format->palette);
      }
      free(s->format);
    }
    if (s->pixels != NULL && !(s->flags & SDL_PREALLOC)) free(s->pixels);
    free(s);
  }
}

SDL_Surface* SDL_SetVideoMode(int width, int height, int bpp, uint32_t flags) {
  if (flags & SDL_HWSURFACE) NDL_OpenCanvas(&width, &height);
  return SDL_CreateRGBSurface(flags, width, height, bpp,
      DEFAULT_RMASK, DEFAULT_GMASK, DEFAULT_BMASK, DEFAULT_AMASK);
}

void SDL_SoftStretch(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect) {
  assert(src && dst);
  assert(dst->format->BitsPerPixel == src->format->BitsPerPixel);
  assert(dst->format->BitsPerPixel == 8);

  int x = (srcrect == NULL ? 0 : srcrect->x);
  int y = (srcrect == NULL ? 0 : srcrect->y);
  int w = (srcrect == NULL ? src->w : srcrect->w);
  int h = (srcrect == NULL ? src->h : srcrect->h);

  assert(dstrect);
  if(w == dstrect->w && h == dstrect->h) {
    /* The source rectangle and the destination rectangle
     * are of the same size. If that is the case, there
     * is no need to stretch, just copy. */
    SDL_Rect rect;
    rect.x = x;
    rect.y = y;
    rect.w = w;
    rect.h = h;
    SDL_BlitSurface(src, &rect, dst, dstrect);
  }
  else {
    assert(0);
  }
}

void SDL_SetPalette(SDL_Surface *s, int flags, SDL_Color *colors, int firstcolor, int ncolors) {
  assert(s);
  assert(s->format);
  assert(s->format->palette);
  assert(firstcolor == 0);

  s->format->palette->ncolors = ncolors;
  memcpy(s->format->palette->colors, colors, sizeof(SDL_Color) * ncolors);

  if(s->flags & SDL_HWSURFACE) {
    assert(ncolors == 256);
    for (int i = 0; i < ncolors; i ++) {
      uint8_t r = colors[i].r;
      uint8_t g = colors[i].g;
      uint8_t b = colors[i].b;
    }
    SDL_UpdateRect(s, 0, 0, 0, 0);
  }
}

static void ConvertPixelsARGB_ABGR(void *dst, void *src, int len) {
  int i;
  uint8_t (*pdst)[4] = dst;
  uint8_t (*psrc)[4] = src;
  union {
    uint8_t val8[4];
    uint32_t val32;
  } tmp;
  int first = len & ~0xf;
  for (i = 0; i < first; i += 16) {
#define macro(i) \
    tmp.val32 = *((uint32_t *)psrc[i]); \
    *((uint32_t *)pdst[i]) = tmp.val32; \
    pdst[i][0] = tmp.val8[2]; \
    pdst[i][2] = tmp.val8[0];

    macro(i + 0); macro(i + 1); macro(i + 2); macro(i + 3);
    macro(i + 4); macro(i + 5); macro(i + 6); macro(i + 7);
    macro(i + 8); macro(i + 9); macro(i +10); macro(i +11);
    macro(i +12); macro(i +13); macro(i +14); macro(i +15);
  }

  for (; i < len; i ++) {
    macro(i);
  }
}

SDL_Surface *SDL_ConvertSurface(SDL_Surface *src, SDL_PixelFormat *fmt, uint32_t flags) {
  assert(src->format->BitsPerPixel == 32);
  assert(src->w * src->format->BytesPerPixel == src->pitch);
  assert(src->format->BitsPerPixel == fmt->BitsPerPixel);

  SDL_Surface* ret = SDL_CreateRGBSurface(flags, src->w, src->h, fmt->BitsPerPixel,
    fmt->Rmask, fmt->Gmask, fmt->Bmask, fmt->Amask);

  assert(fmt->Gmask == src->format->Gmask);
  assert(fmt->Amask == 0 || src->format->Amask == 0 || (fmt->Amask == src->format->Amask));
  ConvertPixelsARGB_ABGR(ret->pixels, src->pixels, src->w * src->h);

  return ret;
}

uint32_t SDL_MapRGBA(SDL_PixelFormat *fmt, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
  assert(fmt->BytesPerPixel == 4);
  uint32_t p = (r << fmt->Rshift) | (g << fmt->Gshift) | (b << fmt->Bshift);
  if (fmt->Amask) p |= (a << fmt->Ashift);
  return p;
}

uint32_t SDL_MapRGB(SDL_PixelFormat *fmt, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
  assert(fmt->BytesPerPixel == 1);
  uint32_t p = ( ((uint32_t)r << 16) | (((uint32_t)g << 8)  ) | ((uint32_t)b) );
  //if (fmt->Amask) p |= ( ( (uint32_t)a << fmt->Ashift) & fmt->Amask);
  return p;
}

int SDL_LockSurface(SDL_Surface *s) {
  return 0;
}

void SDL_UnlockSurface(SDL_Surface *s) {
}
