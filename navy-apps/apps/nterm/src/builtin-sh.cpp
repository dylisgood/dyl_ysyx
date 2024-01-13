#include <nterm.h>
#include <stdarg.h>
#include <unistd.h>
#include <SDL.h>
#include <string.h>

char handle_key(SDL_Event *ev);

struct MenuItem {
  const char *name, *bin, *arg1;
} items[] = {
  {"NJU Terminal", "/bin/nterm", NULL},
  {"NSlider", "/bin/nslider", NULL},
  {"FCEUX (Super Mario Bros)", "/bin/fceux", "/share/games/nes/mario.nes"},
  {"FCEUX (100 in 1)", "/bin/fceux", "/share/games/nes/100in1.nes"},
  {"Flappy Bird", "/bin/bird", NULL},
  {"PAL - Xian Jian Qi Xia Zhuan", "/bin/pal", NULL},
  {"NPlayer", "/bin/nplayer", NULL},
  {"coremark", "/bin/coremark", NULL},
  {"dhrystone", "/bin/dhrystone", NULL},
  {"typing-game", "/bin/typing-game", NULL},
  {"ONScripter", "/bin/onscripter", NULL},
};

static void sh_printf(const char *format, ...) {
  static char buf[256] = {};
  va_list ap;
  va_start(ap, format);
  int len = vsnprintf(buf, 256, format, ap);
  va_end(ap);
  term->write(buf, len);
}

static void sh_banner() {
  sh_printf("Built-in Shell in NTerm (NJU Terminal)\n\n");
}

static void sh_prompt() {
  sh_printf("sh> ");
}

static void sh_handle_cmd(const char *cmd) {
  //printf("cmd = %s" ,cmd);

  char cmdcopy[100];
  strcpy(cmdcopy,cmd);
  char *command = strtok(cmdcopy," ");
  char *disp = strtok(NULL,"\n");
  if(!strcmp(command,"echo")){
    sh_printf(disp);
    sh_printf("\n");
  }
  else if(!strcmp(command,"list\n")){
    for(int i = 0; i < sizeof(items) / sizeof(items[0]); i++){
    sh_printf(items[i].name);
    sh_printf("\n");
    }
  }

  else if(strlen(cmd) == strlen(command)){  //means just one command
    char cc2[32];
    strcpy(cc2,cmd);
    char *bin_to_exec = strtok(cc2,"\n");  
    setenv("PATH","/bin",0);
    //setenv("PATH","/home/dyl/ysyx-workbench/navy-apps/fsimg/bin",0);
    //sh_printf("sh> ");
    if( execvp(bin_to_exec,NULL) == -1 ){
      sh_printf("Cannot find %s\n",bin_to_exec);
    }
  }
/*   for(int i = 0; i < sizeof(items) / sizeof(items[0]); i++){
    if(!strcmp(bin,items[i].bin)){
      execve(items[i].bin, NULL, NULL);
    }
  } */
}

void builtin_sh_run() {
  //printf("--------------------- builtin_sh_run -------------------\n");
  sh_banner();
  sh_prompt();

  while (1) {
    SDL_Event ev;
    if (SDL_PollEvent(&ev)) {
      if (ev.type == SDL_KEYUP || ev.type == SDL_KEYDOWN) {
        const char *res = term->keypress(handle_key(&ev));
        if (res) {
          sh_handle_cmd(res);
          sh_prompt();
        }
      }
    }
    refresh_terminal();
  }
}
