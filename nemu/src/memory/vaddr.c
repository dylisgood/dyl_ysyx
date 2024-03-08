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
#include <memory/paddr.h>
//#include "../isa/riscv64/include/isa-def.h"

word_t vaddr_ifetch(vaddr_t addr, int len) {
  if( isa_mmu_check(addr, len, MEM_TYPE_IFETCH) == MMU_TRANSLATE )
  {
    if( cpu.sr[5] ){
      //printf("satp = %lx \n", cpu.sr[5]);
      paddr_t paddr = isa_mmu_translate(addr, len, MEM_TYPE_IFETCH);
/*       if(paddr != addr){
        printf("paddr = %x, addr = %lx, ifetch\n",paddr, addr);
      }
      assert(paddr == addr); */
      return paddr_read(paddr, len);
    }
    else
      return paddr_read(addr, len);
  }
  else
  {
    return paddr_read(addr, len);
  }
}

word_t vaddr_read(vaddr_t addr, int len) {
  if( isa_mmu_check(addr, len, MEM_TYPE_READ) == MMU_TRANSLATE )
  {
    if( cpu.sr[5] ){
      //printf("satp = %lx \n", cpu.sr[5]);
      paddr_t paddr = isa_mmu_translate(addr, len, MEM_TYPE_READ);
/*       if(paddr != addr){
        printf("paddr = %x, addr = %lx, read\n",paddr, addr);
      }
      assert(paddr == addr); */
      return paddr_read(paddr, len);
    }
    else
      return paddr_read(addr, len);
  }
  else
  {
    return paddr_read(addr, len);
  }
}

void vaddr_write(vaddr_t addr, int len, word_t data) {
  if( isa_mmu_check(addr, len, MEM_TYPE_WRITE) == MMU_TRANSLATE )
  {
    if( cpu.sr[5] )
    {
      //printf("satp = %lx \n", cpu.sr[5]);
      paddr_t paddr = isa_mmu_translate(addr, len, MEM_TYPE_WRITE);
/*       if(paddr != addr){
        printf("paddr = %x, addr = %lx, write\n",paddr, addr);
      }
      assert(paddr == addr); */
      return paddr_write(paddr, len, data);
    }
    else
    {
      return paddr_write(addr, len, data);
    }
  }
  else
    paddr_write(addr, len, data);
}
