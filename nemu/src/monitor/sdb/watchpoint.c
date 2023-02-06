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
/*
typedef struct watchpoint {
  int NO;
  char expr[64];
  int last_value;
  int cur_value;
  struct watchpoint *next;

} WP;
*/

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
   if(free_ == NULL)
  {
    printf("The wp_pool is full!\n");
    assert(0);
  }
  if(head == NULL) {head = wp_pool;}
  return free_;
}

//return wp to free_
void free_wp(WP *wp){
   WP* pb;
   pb = wp;
   while(pb != free_)
   {
    strcpy(pb->expr,(pb+1)->expr);
    pb->last_value = (pb+1)->last_value;
    pb->cur_value = (pb+1)->cur_value;
    pb = pb->next;
   }
}

void print_wp(){
  if(head != NULL){
  WP *PB = head;
  bool *su=false;
  while(PB != free_)
  {
    printf("wp_pool.NO = %d  expr = %s  value = %ld\n",PB->NO,PB->expr,expr(PB->expr,su));
    PB = PB->next;
  }
  }
  else printf("There is no watchpoint! \n");
}

void set_wp(char *arg){
  WP* p_new;
  p_new = new_wp();
  strcpy(p_new->expr , arg);

  if(free_ == wp_pool + 31) {free_ = NULL;}
  else {free_ ++; };
  //print_wp();
}

void dele_wp(int NO){
  if(head == NULL){
    printf("The watchpoint pool is empty!\n");
  }
  else if(wp_pool + NO >= free_)
  {
    printf("This watchpoint is not exist!\n");
  }
  else
  {
   free_wp(wp_pool + NO);
   free_ --;
   if(free_ == wp_pool){
    head = NULL;
    printf("You delete all the watchpoint! \n");
   }
   if(head != NULL )print_wp();
  }
}

void wp_detect(){
  WP  *pb;
  bool *suc = false;
  pb = head;
  while(pb != free_)
  {
    pb->cur_value = expr(pb->expr,suc); 
    if(pb->cur_value != pb->last_value)
    {
      nemu_state.state = NEMU_STOP;
      printf("watchpoint change! \n");
    }
    pb->last_value = pb->cur_value;
  } 
}
