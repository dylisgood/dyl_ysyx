#include <dlfcn.h>
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <assert.h>
#include <stdio.h>

#include "utils.h"
#include "mem.h"
#include "dut.h"

typedef struct {
  uint64_t gpr[32];
  uint64_t pc;
} CPU_state;

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

extern CPU_state cpu;
extern uint64_t *cpu_gpr;
extern uint32_t inst_finishpc;
bool dut_find_difftest = false; //for debug
void dump_gpr();

void (*ref_difftest_memcpy)(uint64_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;


static bool is_skip_ref = false;

void difftest_skip_ref() {
  is_skip_ref = true;
}

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (void (*)(long unsigned int, void*, long unsigned int, bool))dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void*, bool))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint64_t))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = (void (*)(int))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

bool isa_difftest_checkregs(CPU_state *ref_r, uint32_t pc) {
  int i = 0;
  bool find_diff = false;
  for(i = 0; i < 32; i++){
    if(ref_r->gpr[i] != cpu_gpr[i]){
      Log("nemu_%s = %lx",regs[i],ref_r->gpr[i]);
      Log("npc_%s = %lx",regs[i],cpu_gpr[i]);

      if( (ref_r->pc) - 4 != inst_finishpc) {
        Log("nemu_pc = %lx",(ref_r->pc - 4) );
        Log("npc_pc =  %x",inst_finishpc);
      }
      pc = cpu.pc;
      find_diff = true;
    }
  }
  return find_diff;
}

static void checkregs(CPU_state *ref, uint32_t pc) {
  if (isa_difftest_checkregs(ref, pc)) {
    Log("!!!!!!!!!!!!!!!!!!!!!!   find deffferent at pc = %x  !!!!!!!!!!!!!!!!\n" ,pc);
    dut_find_difftest = true;
  }
}

void difftest_step(uint32_t pc, uint32_t npc) {
  CPU_state ref_r;
  if( is_skip_ref ){
    ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    //printf("difftest_step: skip this difftest\n");
    is_skip_ref = false;
    return ;
  }

  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

  checkregs(&ref_r, pc);
}


