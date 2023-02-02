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

#include "sdb.h"

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  char expr[64];
  struct watchpoint *next;

  /* TODO: Add more members if necessary */

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

//get a idle wacthpoint from free_
WP* new_wp(){
  if(head == NULL)
      {head = wp_pool;}
  return free_;
}

//return wp to free_
void free_wp(WP *wp){
   WP* pb;
   pb = wp;
   while(pb != free_)
   {
    strcpy(pb->expr,(pb+1)->expr);
    pb = pb->next;
   }
}

void set_wp(char *arg){
  WP* p_new;
  WP* PB;
  p_new = new_wp();
  free_ ++;
  PB = head;
  strcpy(p_new->expr , arg);
  while(PB != free_)
  {
    printf("PB.NO = %d   PB.expr = %s\n",PB->NO,PB->expr);
    PB = PB->next;
  }
}

void dele_wp(int NO){
  if(head == NULL){
    printf("The watchpoint pool is empty!\n");
    //assert("0");
  }
  if(wp_pool + NO >= free_)
  {
    printf("The watchpoint pool is already empty!\n");
  }
  else
  {
   free_wp(wp_pool + NO);
   free_ --;
   if(free_ == wp_pool){
    head = NULL;
   }
   WP* pb;
   pb = head;
   while(pb != free_)
   {
    printf("wp_pool.NO = %d, expr = %s \n",pb->NO,pb->expr);
    pb = pb->next;
   }
  }
}

