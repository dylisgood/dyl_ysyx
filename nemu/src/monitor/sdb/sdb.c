/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"
#include <memory/vaddr.h>

static int is_batch_mode = true;

void init_regex();
void init_wp_pool();
void set_wp();
void dele_wp();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {  
    add_history(line_read);
  }

  return line_read;
}

static int cmd_si(char *args){
  char *arg = strtok(NULL , " ");
  int N;
  if(arg == NULL) { N = 1; }
  else { N = atoi(arg);} 
  cpu_exec(N);
  return 0;
}

static int cmd_info(char *args){
  char *arg = strtok(NULL , " ");
  if( arg == NULL) { printf("please choose to print r-regs or w-watchpoints\n"); }
  else 
  {
    if( *arg == 'r' ){ isa_reg_display(); }
    else if( *arg == 'w') { print_wp(); }
    else { printf("Unknown command\n"); }
  }
  return 0;
}

static int cmd_x(char *args) {
  char *arg = strtok(NULL , " ");
  if( arg == NULL ) {printf("please add N and exp");  }
  else {
    int N = atoi(arg);
    arg = strtok(NULL , "\0");
    bool *success = false;
    uint64_t addr = expr(arg,success);
    for(int i=0; i < N; i++) {
    printf("mem[0x%lx] = 0x%lx\n",addr + i*8,vaddr_read(addr + i*8,8)); }
  }
  return 0;
}

static int cmd_p(char *args){
  char *arg = strtok(NULL, "\0");
  if(arg == NULL) {printf("please add expr to evalation\n");} 
  else {
    bool *success = false;
    uint64_t value = expr(arg,success);
    printf("result = %lx\n",value);
  }
  return 0;
}

static int cmd_w(char *args){
  char *arg = strtok(NULL,"\0");
  if(arg == NULL) {printf("please add watchpoint expression!\n");}
  else
  {
    set_wp(arg);
  }
  return 0;
}

static int cmd_d(char *args){
  char *arg = strtok(NULL,"\0");
  if(arg == NULL) {printf("please add the number of watchpoint to delete!\n");}
  else
  {
    int wp_num = atoi(arg);
    if(wp_num < 32) {dele_wp(wp_num);}
    else printf("there is no NO.%d watchpoint!\n",wp_num);
  }
  return 0;
}

static int cmd_b(char *args){
  char *arg = strtok(NULL,"\0");
  if(arg == NULL) {printf("please add the address of breakpoint! \n");}
  else
  {
    //set_bp();
  }
  return 0;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },

  /* TODO: Add more commands */
  { "si","execute n steps",cmd_si },
  { "info" , "print reg ", cmd_info },
  { "x" , "Scan memory" ,cmd_x}, 
  { "p", "expr evaluation", cmd_p},
  { "w", "set watchpoint", cmd_w},
  { "d", "delete watchpoint", cmd_d},
  { "b", "set breakpoint", cmd_b},
};

#define NR_CMD ARRLEN(cmd_table)

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

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
