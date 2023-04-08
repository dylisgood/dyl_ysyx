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
  uint32_t pc;
} CPU_state;

extern CPU_state cpu;

void dump_gpr();
void (*ref_difftest_memcpy)(uint64_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

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

  printf("//////////////////////////////////////////////////////\n");
  ref_difftest_init(port);
  printf("+++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
  ref_difftest_memcpy(0x80000000, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  printf("------------------------------------------------------\n");
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

bool isa_difftest_checkregs(CPU_state *ref_r, uint32_t pc) {
  int i = 0;
  for(i = 0; i < 32; i++){
    if(ref_r->gpr[i] != cpu.gpr[i]){
      pc = cpu.pc;
      return false;
    }
  }
  return true;
}

static void checkregs(CPU_state *ref, uint32_t pc) {
  if (!isa_difftest_checkregs(ref, pc)) {
    printf("deffferent!!!!!!!!\n");
    dump_gpr();
    for(int i = 0; i < 32; i++){
      printf("ref[%d] = %lx\n" ,i,ref->gpr[i]);
    }
  }
}

void difftest_step(uint32_t pc, uint32_t npc) {
  CPU_state ref_r;

  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

  checkregs(&ref_r, pc);
}


