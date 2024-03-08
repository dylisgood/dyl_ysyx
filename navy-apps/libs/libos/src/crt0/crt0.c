#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
//#include <stdio.h>

int main(int argc, char *argv[], char *envp[]);
extern char **environ;
void call_main(uintptr_t *args) {
  //printf("enter call main\n");
  int argc = *(args);

  //get argv 
  char **argv = (char **)malloc(argc * sizeof(char *));
  for(int i = 0; i < argc; i++){
    argv[i] = (char *)(*(args + i + 1));
  }

  //get env number
  int envc = 0;
  uintptr_t *env_addr_start = (uintptr_t *)((args + argc + 2)); //point to envp[0]
  while(*(env_addr_start++)){
    envc += 1;
  }
  //get env
  char **env = (char **)malloc(envc * sizeof(char *));
  for(int i = 0; i < envc; i++){
    env[i] = (char *)(*(args + i + 2 + argc));
  }

  char *empty[] =  { NULL };
  environ = empty;
  
  exit(main(argc, argv, env));
  assert(0);
}
