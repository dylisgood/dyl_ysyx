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
#include <difftest-def.h>
#include <memory/paddr.h>
typedef struct Decode {
  vaddr_t pc;
  vaddr_t snpc; // static next pc
  vaddr_t dnpc; // dynamic next pc
  ISADecodeInfo isa;
  IFDEF(CONFIG_ITRACE, char logbuf[128]);
} Decode;

struct diff_context_t {
  word_t gpr[32];
  word_t pc;
};

void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if(direction == DIFFTEST_TO_REF){ //npc -> nemu
    for(size_t i = 0; i < n; i++){
      paddr_write(RESET_VECTOR + i, 1, *((uint8_t *)(buf+i)) );
    }
  } 
  else { 
    assert(0);
  }
}

void difftest_regcpy(void *dut, bool direction) {
  if(direction == DIFFTEST_TO_REF ){   //npc -> nemu
    struct diff_context_t* ctx = (struct diff_context_t*)dut;
    for(int i = 0; i < 32; i++){
      cpu.gpr[i] = ctx->gpr[i];
    }
    cpu.pc = ctx->pc;
  }

  else if(direction == DIFFTEST_TO_DUT){ //nemu -> npc_temp   for compare
    struct diff_context_t* ctx = (struct diff_context_t*)dut;
    for(int i = 0; i < 32; i++){
      ctx->gpr[i] = cpu.gpr[i];
    }
      ctx->pc = cpu.pc;
  }
}

static void execonce(Decode *s, vaddr_t pc){
    s->pc = cpu.pc;
    s->snpc = cpu.pc;
    isa_exec_once(s);
    cpu.pc = s->dnpc;
}

void difftest_exec(uint64_t n) {
  Decode s;
  for(uint64_t i = 0; i < n; i++){
    execonce(&s,cpu.pc);
  }
}

void difftest_raise_intr(word_t NO) {
  //isa_raise_intr(gpr(17), s->snpc);
  assert(0);
}

void difftest_init(int port) {
  /* Perform ISA dependent initialization. */
  init_isa();
}
