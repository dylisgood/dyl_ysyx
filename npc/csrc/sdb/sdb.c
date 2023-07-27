#include <readline/readline.h>
#include <readline/history.h>

#include "sdb.h"

extern int instr_num;
extern bool Execute;

void cpu_exec(int n);
uint64_t expr(char *arg);
void init_regex();   //expr.c
void init_wp_pool();  //watchpoint.c
uint64_t pmem_read(uint32_t addr,int len);
void dump_gpr();
void dump_csr();
void set_wp(char *arg);
void print_wp();
void dele_wp(int NO);

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npu) ");

  if (line_read && *line_read) {  
    add_history(line_read);
  }

  return line_read;
}

static int cmd_help(char *args);

static int cmd_c(char *args) {
    Execute = true;
    cpu_exec(-1);
    return 0;
}

static int cmd_q(char *args) {
    return -1;
}

static int cmd_si(char *args) {
    char *arg = strtok(NULL," ");
    int n;
    if(arg == NULL) { n = 1; }
    else {n = atoi(arg); }
    cpu_exec(n);
    return 0;
}

static int cmd_p(char *args) {
    char *arg = strtok(NULL, "\0");
    if(arg == NULL) {printf("please add expresion to evalation\n");}
    else {
        uint64_t value = expr(arg);
        printf("result = %lx \n", value);
    }
    return 0;
}

static int cmd_x(char *args) {
    char *arg = strtok(NULL," ");
    if(arg == NULL) { printf("please add N and exp\n"); }
    else{
        int N = atoi(arg);
        arg = strtok(NULL, "\0");
        uint64_t addr = expr(arg);
        for(int i = 0; i < N; i++){
            printf("mem[0x%lx] = %lx \n", addr + i*4, pmem_read(addr + i * 4 , 4) );
        }
    }
    return 0;
}

static int cmd_info(char *args) {
    char *arg = strtok(NULL, " ");
    if( arg == NULL ) { printf("please choose to print r-regs or w-watchpoints \n"); }
    else{
        if( *arg == 'r' ) { dump_gpr(); }
        else if( *arg == 'c') { dump_csr(); }
        else if( *arg == 'w') { print_wp(); }
        else { printf("Unknown command\n"); }
    }
    return 0;
}

static int cmd_w(char *args) {
    char *arg = strtok(NULL, " ");
    if( arg == NULL ) { printf("please add your watchpoint\n "); }
    else { set_wp(arg); }
    return 0;
}

static int cmd_d(char *args) {
    char *arg = strtok(NULL, " ");
    if(arg == NULL) {printf("please add the number of watchpoint to delete!\n");}
    else
    {
    int wp_num = atoi(arg);
    if(wp_num < 32) {dele_wp(wp_num);}
    else printf("there is no NO.%d watchpoint!\n",wp_num);
    }
    return 0;
}

static struct {
    const char *name;
    const char *description;
    int (*handler) (char *);
} cmd_table []= {
    { "help", "Display information about all supported commands", cmd_help },
    { "c", "Continue the execution of the program", cmd_c },
    { "q", "Exit npc", cmd_q },   
    { "si", "execute a step", cmd_si },
    { "p", "expr evaluation", cmd_p },
    { "x", "Scan memory", cmd_x },
    { "info", "print reg", cmd_info },
    { "w", "set watchpoint", cmd_w },
    { "d", "delete watchpoint", cmd_d },
};

#define NR_CMD ARRLEN(cmd_table)

//enter sdb loop, get command in command line, press q stop loop
void sdb_mainloop(){
  if (Execute) {
    cmd_c(NULL);
    return;
  }
    for (char *str; (str = rl_gets()) != NULL; ){
        char *str_end = str + strlen(str);

        char *cmd = strtok(str," ");
        if(cmd == NULL) { continue; }

        char *args = cmd + strlen(cmd) + 1;
        if(args >= str_end){
            args = NULL;
        }
        int i;
        for(i = 0; i < NR_CMD; i++){
            if(strcmp(cmd, cmd_table[i].name) == 0){
                if(cmd_table[i].handler(args) < 0) { return; }
                break;
            }
        }
        if(i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
}
}

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void init_sdb(){
  init_regex();
  init_wp_pool();
}
