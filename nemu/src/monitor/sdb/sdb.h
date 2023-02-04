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

#ifndef __SDB_H__
#define __SDB_H__

#include <common.h>
/*
#define NR_WP 32

typedef struct watchpoint {
  int NO;
  char expr[64];
  int last_value;
  int cur_value;
  struct watchpoint *next;


} WP;

static WP wp_pool[NR_WP] __attribute__((used))= {};
static WP *head __attribute__((used))= NULL, *free_ __attribute__((used))= NULL;
*/
word_t expr(char *e, bool *success);

#endif
