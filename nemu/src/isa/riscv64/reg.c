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
#include "local-include/reg.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

const char *regs_sr[] = {
  "mtvec", "mepc", "mstatus", "mcause", "mie"
};

void isa_reg_display(void) {
  for (int i=0; i < 32; i++){
    printf("reg[%d]: %s = 0x%lx\n",i ,reg_name(i,64) ,gpr(i));
}
}

void isa_reg_sr_display(void) {
  for(int i =0; i < 4; i++){
    printf("reg_sr[%d]: %s = 0x%lx\n",i,reg_sr_name(i),cpu.sr[i]);
  }
}

word_t isa_reg_str2val(const char *s, bool *success) {  //accroding reg name return reg value
  int i;
  for(i=0; i < 32; i++){
    if( !strcmp(s ,reg_name(i,64))) { return gpr(i);}
  }
  if(i == 32) {printf("unknown reg !\n");}
  return 404;
}

word_t reg_sr_idx(char *sr_name){
  int i;
  for(i = 0; i < 4;i++){
    if( !strcmp(sr_name,regs_sr[i]) ){
      return i;
    }
  }
  printf("sr not exist! \n");
  assert(0);
}