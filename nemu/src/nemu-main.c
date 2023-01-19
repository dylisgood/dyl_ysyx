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

#include <common.h>

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
uint32_t expr(char *e, bool *success);
int is_exit_status_bad();

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif
   uint32_t result=0;
   bool* success = false;
   
  char buf_answer[1000];
  int count;
  char buf_expr[1000];
   
   FILE *fp = fopen("/home/ysyx/ysyx-workbench/nemu/tools/gen-expr/input","r");
   
   for(int i=0; i < 1000; i++){
   count = fscanf(fp,"%s",buf_answer);
  // printf("the count = %d, the buff = %s\n",count,buff);
   count = fscanf(fp,"%s",buf_expr);
  // printf("the buf = %s\n",buf); 
   //buff = fgets(buf,1000,(FILE *)fp);
    result = expr(buf_expr,success);
    if(result == atoi(buf_answer) && count !=10000){
      printf("%dst test pass!\n",i+1);
    }
    else {
      printf("%dst test fail!\n",i+1);
      printf("the expr is %s\n",buf_expr);
      printf("your result is %d, the answer is %d\n",result,atoi(buf_answer));
      //assert(0);
    }
  //printf("the result = %ld, count = %d\n",result,count);
   //printf("the count = %s,the buff is%s",buf,buff);
   }
   
  /*/ 
   for(int i=0;i<100;i++){
   result = expr("1+1",success);
   printf("result = %d\n",result);
   }
   */
  /* Start engine. */
  engine_start();

  return is_exit_status_bad();
}
