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
word_t expr(char *e, bool *success);
int is_exit_status_bad();

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif
   char buf[1000];
   int count;
   word_t result=0;
   char buff[1000];
   bool* success = false;
   FILE *fp = fopen("/home/ysyx/ysyx-workbench/nemu/tools/gen-expr/input","r");
   
   for(int i=0; i < 10; i++){
   count = fscanf(fp,"%s",buff);
  // printf("the count = %d, the buff = %s\n",count,buff);
   count = fscanf(fp,"%s",buf);
   //printf("the count = %d, the buf = %s\n",count,buf); 
   //buff = fgets(buf,1000,(FILE *)fp);
    result = expr(buf,success);
    if(result == atoi(buff) && count >=0){
      printf("%dst test pass!\n",i);
    }
    else printf("test fail!\n");
  //printf("the result = %ld, count = %d\n",result,count);
   //printf("the count = %s,the buff is%s",buf,buff);
   }
  /* Start engine. */
  engine_start();

  return is_exit_status_bad();
}
