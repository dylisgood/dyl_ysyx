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

#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <locale.h>
#include <../src/monitor/sdb/sdb.h> 
#include <elf.h>

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */
#define MAX_INST_TO_PRINT 21
#define CONFIG_FTRACE 1
char iringbuf[10][128] = {};
CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static bool g_print_step = false;

Elf64_Sym *symbols = NULL;
char *strtab1 = NULL;


void device_update();

void print_iringbuf(){
  for(int x = 0; x < 10; x++){
    puts(iringbuf[x]);
  }
}

int jj = 0;
extern char *elf_file;
void init_ftrace() {
  
  if(elf_file == NULL) {
    Log("No elf is given. Can't trace function.");
    return;
  }
  else{
    Elf64_Ehdr elf_header;
    FILE *fp = fopen(elf_file, "rb");
    if (!fp) {
        perror("Failed to open file");
        return;
    }

    jj=fread(&elf_header, sizeof(Elf64_Ehdr), 1, fp);
    if (memcmp(elf_header.e_ident, ELFMAG, SELFMAG) != 0) {
        fprintf(stderr, "Not an ELF file: %s\n", elf_file);
        return;
    }

    Elf64_Shdr *sh_table = malloc(sizeof(Elf64_Shdr) * elf_header.e_shnum);
    fseek(fp, elf_header.e_shoff, SEEK_SET);
    jj=fread(sh_table, sizeof(Elf64_Shdr), elf_header.e_shnum, fp);

    Elf64_Shdr *strtab = &sh_table[elf_header.e_shstrndx];
    char *sh_strtab = malloc(strtab->sh_size);
    fseek(fp, strtab->sh_offset, SEEK_SET);
    jj=fread(sh_strtab, strtab->sh_size, 1, fp);

    Elf64_Shdr *symtab = NULL;
    Elf64_Shdr *strtab_hdr = NULL;

    for (int i = 0; i < elf_header.e_shnum; i++) {
        if (sh_table[i].sh_type == SHT_SYMTAB) {
            symtab = &sh_table[i];
        } else if (sh_table[i].sh_type == SHT_STRTAB &&
                   strcmp(&sh_strtab[sh_table[i].sh_name], ".strtab") == 0) {
            strtab_hdr = &sh_table[i];
        }
    }

    if (!symtab) {
        fprintf(stderr, "No symbol table found\n");
        return;
    }
    symbols = malloc(symtab->sh_size);
    fseek(fp, symtab->sh_offset, SEEK_SET);
    jj=fread(symbols, symtab->sh_size, 1, fp);

    if (!strtab_hdr) {
        fprintf(stderr, "No string table found\n");
        return;
    }
    strtab1 = malloc(strtab_hdr->sh_size);
    fseek(fp, strtab_hdr->sh_offset, SEEK_SET);
    jj=fread(strtab1, strtab_hdr->sh_size, 1, fp);
/* 
    printf("%-20s %-20s %-20s %-20s\n", "Name", "Address", "Size", "Type");
    for (int i = 0; i < symtab->sh_size / sizeof(Elf64_Sym); i++) {
        Elf64_Sym *sym = &symbols[i];
        printf("%-20s %-20p %-20lu %-20d\n",
               &strtab1[sym->st_name], (void *) sym->st_value, (unsigned long) sym->st_size, sym->st_info); 
    }*/

    jj = symtab->sh_size / sizeof(Elf64_Sym);
    fclose(fp);
    free(sh_table);
    free(sh_strtab);
    return;
  }
}

void close_ftrace(){
    free(symbols);
    free(strtab1);
}

static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {
#ifdef CONFIG_ITRACE_COND
  if (ITRACE_COND) { log_write("%s\n", _this->logbuf); }
#endif
  if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(_this->logbuf)); }
  IFDEF(CONFIG_DIFFTEST, difftest_step(_this->pc, dnpc));

#ifdef CONFIG_WATCHPOINT
  if(CONFIG_WATCHPOINT) {wp_detect();}
#endif
}

static void exec_once(Decode *s, vaddr_t pc) {
  s->pc = pc;
  s->snpc = pc;
  isa_exec_once(s);
  cpu.pc = s->dnpc;
#ifdef CONFIG_FTRACE
  
  if((s->isa.inst.val & 0x6f) == 0x6f){
    //printf("s->snpc = %lx\n",s->dnpc);
    printf("find jal!\n");
    for (int i = 0; i < jj; i++) {
        Elf64_Sym *sym = &symbols[i];
        if(sym->st_info == 18){
        if(s->dnpc == sym->st_value)
         printf("call %-20s[@%p] \n",&strtab1[sym->st_name],(void *) sym->st_value);
/*        printf("%-20s %-20p %-20lu %-20d\n",
               &strtab1[sym->st_name], (void *) sym->st_value, (unsigned long) sym->st_size, sym->st_info); */
        }
    }
  }
  else if((s->isa.inst.val & 0x67) == 0x67){
    printf("find jalr!\n");
    for (int i = 0; i < jj; i++) {
        Elf64_Sym *sym = &symbols[i];
        if(sym->st_info == 18){
        if(s->pc >= sym->st_value && s->pc <= sym->st_value)
         printf("ret %-20s[@%p] \n",&strtab1[sym->st_name],(void *) sym->st_value);
        }
    }
  }  
#endif

#ifdef CONFIG_ITRACE
  char *p = s->logbuf;
  p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":", s->pc); //16进制PC 64位 
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&s->isa.inst.val;
  for (i = ilen - 1; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", inst[i]); 
  }
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, s->logbuf + sizeof(s->logbuf) - p,
      MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&s->isa.inst.val, ilen);
#endif
  for(int x = 0; x < 9; x++){
    strcpy(iringbuf[x],iringbuf[x+1]);
  }
  strcpy(iringbuf[9],s->logbuf);
}

static void execute(uint64_t n) {
  Decode s;
  for (;n > 0; n --) {
    exec_once(&s, cpu.pc);
    g_nr_guest_inst ++;
    trace_and_difftest(&s, cpu.pc);
    if (nemu_state.state != NEMU_RUNNING) {break; }
    IFDEF(CONFIG_DEVICE, device_update());
  }
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

void assert_fail_msg() {
  isa_reg_display();
  statistic();
}

/* Simulate how the CPU works. */
void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);
  switch (nemu_state.state) {
    case NEMU_END: case NEMU_ABORT:
      printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
      return;
    default: nemu_state.state = NEMU_RUNNING;
  }

  
  uint64_t timer_start = get_time();

  execute(n);

  uint64_t timer_end = get_time();
  g_timer += timer_end - timer_start;
  close_ftrace();
  switch (nemu_state.state) {
    case NEMU_RUNNING: nemu_state.state = NEMU_STOP; break;

    case NEMU_END: case NEMU_ABORT:
      Log("nemu: %s at pc = " FMT_WORD,
          (nemu_state.state == NEMU_ABORT ? (print_iringbuf(), ANSI_FMT("ABORT", ANSI_FG_RED)) :
           (nemu_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          nemu_state.halt_pc);
      // fall through
    case NEMU_QUIT: statistic();
  }
}
