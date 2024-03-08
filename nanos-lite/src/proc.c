#include <proc.h>
#include "fs.h"

#define MAX_NR_PROC 4

void naive_uload(PCB *pcb, const char *filename);
uintptr_t loader(PCB *pcb, const char *filename);
void* new_page(size_t nr_page);

PCB pcb[MAX_NR_PROC] __attribute__((used)) = {};
static PCB pcb_boot = {};
PCB *current = NULL;

#define USER_SPACE RANGE(0x40000000, 0x80000000)

void switch_boot_pcb() {
  printf("Call switch_boot_pcb\n");
  if( current == NULL)
  {
    current = &pcb_boot;
  }
  yield();
}

void hello_fun(void *arg) {
  printf("hello fun");
  int j = 1;
  while (1) {
    //putch("?AB"[(uintptr_t)arg > 2 ? 0 : (uintptr_t)arg]);
    Log("Hello World from Nanos-lite with arg '%d' for the %dth time!", (uintptr_t)arg ,j);
    j ++;
    yield();
  }
}

//create kernel thread context
void context_kload(PCB *pcb, void (*entry)(void *), void *arg){
  pcb->cp = kcontext( (Area) { pcb->stack, pcb + 1 } , entry, arg );
}

//create user process context
void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]){
  //printf("\nenter context_uload\n");
  protect(&pcb->as);//创建用户地址空间
  uintptr_t entry = loader(pcb, filename);
  pcb->cp = ucontext( &pcb->as , (Area) { pcb->stack, pcb + 1 }, (void *)entry );
  //asm volatile("fence.i"); //for npc, nemu have no cache 2024.3.5
  
  //printf("&pcb->as.area.end = %x\n" ,pcb->as.area.end);
  //assert(0);
  void *ustack = new_page(8); //32KB user stack
  void *pa = ustack;
  for(int i = 1; i < 9; i++){
    map(&pcb->as,  pcb->as.area.end - (i * PGSIZE), pa, 1);  //map user stack
    pa -= PGSIZE;
  }

  //assert(0);
  
  char *ptr = (char *)(uintptr_t)( ustack - 1);
  ptr-=4;  //unspecified area 4 bytes

  //get argc 
  int envpc = 0, argc = 0;
  while( envp[envpc++] != NULL);
  while( argv[argc++] != NULL );
  argc -= 1;
  envpc -=1;
  if(envpc > 10) { envpc = 0; }
  uintptr_t envp_address[envpc];
  uintptr_t argv_address[argc];
  //printf("argc = %d, envpc = %d\n" ,argc , envpc);

  //store envp
  for(int i = 0; i < envpc; i++){
    ptr -= ( strlen(envp[i]) + 1);
    strcpy(ptr, envp[i]);
    //printf("envp[%d] = %s \n",i ,envp[i]);
    envp_address[i] = (uintptr_t)ptr;
  }

  //store argv
  for(int i = 0; i < argc; i++){
    ptr -= ( strlen(argv[i]) + 1 );
    strcpy(ptr,argv[i]);
    //printf("argv[%d] = %s \n",i ,argv[i]);
    argv_address[i] = (uintptr_t)ptr;
  }

  //store pointer
  ptr-=8;
  uintptr_t *ptr2 = (uintptr_t *)ptr;
  uintptr_t *ptr3 = ptr2 - 1;
  ptr2 = NULL;

  //get envp address
  for(int i = envpc - 1; i >= 0; i--){
    *ptr3 = envp_address[i];
    ptr3--;
  }
  ptr3--;

  //get argc address
  for(int i = argc - 1; i >= 0; i--){
    *ptr3 = argv_address[i];
    ptr3--;
  }
  *ptr3 = (uintptr_t)argc;

  pcb->cp->GPRx = (uintptr_t)ptr3; //return stack pointer  via a0

  //printf("out context_uload\n\n");
}

void init_proc() {
  Log("Initializing process...");
  context_kload(&pcb[0], hello_fun, (void *)1L);
  //context_kload(&pcb[1], hello_fun, (void *)2L);

/*   const char str1[] = "--skp";
  char *const argv[] = { (char *)str1,"--lol", NULL };
  char *const envp[] = { "abc=xyz", "ddl=666", NULL }; */
  char *const argv[] = { "--skip" };
  char *const envp[] = { NULL };
  //pcb[0].as.ptr = new_page(1);
  context_uload(&pcb[1], "/bin/pal", argv, envp);

  switch_boot_pcb();

  // load program here
  //naive_uload(NULL, "/bin/hello");

}

uintptr_t sys_execve(const char *fname, char * const argv[], char *const envp[]){
  printf("\nCall sys_execve: fname = %s\n\n" ,fname);
  int fd = fs_open(fname, 0, 0);
  if(fd == -1){
    return -1;
  }
  fs_close(fd);
  
  //create user context
  PCB *pcb_new;
  pcb_new = current == &pcb[0] ? &pcb[1] : &pcb[0];
  context_uload(pcb_new, fname, argv, envp);
  //switch process
  switch_boot_pcb();

  return 0;
}

Context* schedule(Context *prev) {
  printf("enter schedule \n");
  current->cp = prev;                                    //current process
  current = ( current == &pcb[0] ? &pcb[1] : &pcb[0] );  //next process
  //current = ( current == &pcb[0] ? &pcb_boot : &pcb[0] );  //next process
  return current->cp;
}
