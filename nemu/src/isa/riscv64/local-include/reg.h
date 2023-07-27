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

#ifndef __RISCV64_REG_H__
#define __RISCV64_REG_H__

#include <common.h>

static inline int check_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < 32));
  return idx;
}

static inline int change_reg_sr_idx(int idx) {
  if(idx == 0x305) return 0;         //mtvec
  else if( idx == 0x300) return 2;   //mstatus
  else if( idx == 0x341 ) return 1; //mepc
  else if(idx == 0x342 ) return 3;  //mcause
  else{
    panic("sorry this sr is not implement!\n");
  }
}

#define gpr(idx) (cpu.gpr[check_reg_idx(idx)])
#define sr(idx) (cpu.sr[change_reg_sr_idx(idx)])

static inline const char* reg_sr_name(int idx) {
  extern const char* regs_sr[];
  return regs_sr[check_reg_idx(idx)];
}

static inline const char* reg_name(int idx, int width) {  //according idx return reg_name
  extern const char* regs[];
  return regs[check_reg_idx(idx)];
}

#endif
