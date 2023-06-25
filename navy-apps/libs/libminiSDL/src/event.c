#include <NDL.h>
#include <SDL.h>
#include <string.h>

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  char buf[64];
  if (NDL_PollEvent(buf, sizeof(buf))) {
    char *key, *value;
    key = strtok(buf, " ");
    value = strtok(NULL, "\n");
    if(!strcmp(key,"kd")){
      ev->type = SDL_KEYDOWN;
      for(int i = 0; i < 83; i++)
      {
        if(!strcmp(keyname[i], value)){
          ev->key.keysym.sym = i;
        }
      } 
    }
    else if(!strcmp(key, "ku")){
      ev->type = SDL_KEYUP;      
      for(int i = 0; i < 83; i++)
      {
        if(!strcmp(keyname[i],value)){
          ev->key.keysym.sym = i;
        }
      }
    }
/*     printf("Key: %s\n", key);
    printf("Value: %s\n", value);
    printf("receive event: %s\n", buf); */
    return 1;
  }
  return 0;
}

int SDL_WaitEvent(SDL_Event *event) {
  char buf[64];
  while(1){
  if (NDL_PollEvent(buf, sizeof(buf))) {
    char *key, *value;
    key = strtok(buf, " ");
    value = strtok(NULL, "\n");
    if(!strcmp(key,"kd")){
      event->type = SDL_KEYDOWN;
      for(int i = 0; i < 83; i++)
      {
        if(!strcmp(keyname[i], value)){
          event->key.keysym.sym = i;
          break;
        }
      } 
    }
    else if(!strcmp(key, "ku")){
      event->type = SDL_KEYUP;      
      for(int i = 0; i < 83; i++)
      {
        if(!strcmp(keyname[i],value)){
          event->key.keysym.sym = i;
          break;
        }
      }
    }
/*     printf("Key: %s\n", key);
    printf("Value: %s\n", value);
    printf("receive event: %s\n", buf); */
    return 1;
  }
  }
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  return NULL;
}
