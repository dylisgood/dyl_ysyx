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
#include <memory/vaddr.h>
#include <memory/paddr.h>

#define PTESIZE 8
#define PGSIZE 4096


//int dayin = 0;
paddr_t isa_mmu_translate(vaddr_t vaddr, int len, int type) {
  uint64_t satp = cpu.sr[5];
  if(satp)
  {
    //printf( "The satp = %lx vaddr = %lx, type = %d \n" ,satp ,vaddr , type);

    uint64_t vpn = (uint64_t)vaddr / PGSIZE;

    //获取一级页表索引 二级页表索引 三级页表索引
    uint64_t pdx = ( vpn >> 18 ) & 0x1ff;   //vpn[2] 9bit
    uint64_t ptx = ( vpn >> 9 ) & 0x1ff;    //vpn[1] 
    uint64_t pgx = vpn & 0x1ff;
    //printf("pdx = 0x%lx, ptx = 0x%lx, pgx = 0x%lx \n" ,pdx ,ptx, pgx);
    //printf("offset: pdx = 0x%lx, ptx = 0x%lx, pgx = 0x%lx \n" ,pdx << 3 ,ptx << 3, pgx << 3);

    //一级页表地址 一级页表偏移
    uint64_t level1_page_table = (uint64_t )(satp << 12);
    uint64_t level1_page_offset = level1_page_table + pdx * PTESIZE;
    //printf("level1_page_table= %lx ,level1_page_offset = %lx \n" , level1_page_table, level1_page_offset);

    //二级页表地址 二级页表偏移
    uint64_t level2_page_table;
    level2_page_table = paddr_read(level1_page_offset, 8);
    uint64_t level2_page_offset = level2_page_table + ptx * PTESIZE;
    //printf("level2_page_table= %lx ,level2_page_offset = %lx \n" , level2_page_table, level2_page_offset);

    uint64_t level3_page_table;
    level3_page_table = paddr_read(level2_page_offset, 8);
    uint64_t level3_page_offset = level3_page_table + pgx * PTESIZE;
    //printf("level3_page_table= %lx ,level3_page_offset = %lx \n" , level3_page_table, level3_page_offset);

    uint64_t ppn;
    ppn = paddr_read(level3_page_offset, 8);

    //printf("ppn = %lx \n" ,ppn);

    uint32_t offset = vaddr & 0xfff;
    uint64_t paddr = offset | ( ppn << 12 );

/*     if(paddr != vaddr){
    printf("paddr = %lx, vaddr = %lx, type = %d\n",paddr, vaddr ,type);
  }
    assert(paddr == vaddr); */
/*     if(vaddr < 0x80000000){
      dayin = 1;
    }
    if(dayin) printf("vaddr =  %lx , paddr = %lx \n" ,vaddr ,paddr); */
    return paddr;
  }
  return MEM_RET_FAIL;
}
