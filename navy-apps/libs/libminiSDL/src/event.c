#include <NDL.h>
#include <SDL.h>
#include <string.h>
#include <assert.h>

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

static uint8_t keyStates[83];

int SDL_PushEvent(SDL_Event *ev) {
  assert(0);
  return 0;
}

//check if have key
int SDL_PollEvent(SDL_Event *ev) {
  char buf[128];
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
          keyStates[i] = 1;
        }
      } 
    }
    else if(!strcmp(key, "ku")){
      ev->type = SDL_KEYUP;      
      for(int i = 0; i < 83; i++)
      {
        if(!strcmp(keyname[i],value)){
          ev->key.keysym.sym = i;
          keyStates[i] = 0;
        }
      }
    }
    return 1;
  }
  return 0;
}

//wait a key
int SDL_WaitEvent(SDL_Event *event) {
  char buf[64];
  while(1){
    if(NDL_PollEvent(buf, sizeof(buf))) {
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
      return 1;
    }
  }
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  assert(0);
  return 0;
}

//return key's number
uint8_t* SDL_GetKeyState(int *numkeys) {
  int num = sizeof(keyname) / sizeof(keyname[0]);
  if(numkeys != NULL)  *numkeys = num;
  return keyStates;
}
