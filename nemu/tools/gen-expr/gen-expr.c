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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

void gen_num(){
  int num;
  char s[10];
  num =rand() % 10 + 1;
  sprintf(s,"%d",num);
  strcat(buf,s);
  /*
  switch(num){
    case 10:strcat(buf,"10\0");break;
    case 1:strcat(buf,"1\0");break;
    case 2:strcat(buf,"2\0");break;
    case 3:strcat(buf,"3\0");break;
    case 4:strcat(buf,"4\0");break;
    case 5:strcat(buf,"5\0");break;
    case 6:strcat(buf,"6\0");break;
    case 7:strcat(buf,"7\0");break;
    case 8:strcat(buf,"8\0");break;
    case 9:strcat(buf,"9\0");break;
  }
  */
}

void gen_rand_op() {
 // printf("enter gen_rand_op\n");
  int number = rand() % 3;
  switch(number) {
   case 0:strcat(buf,"+\0"); break;
   case 1:strcat(buf,"-\0"); break;
   case 2:strcat(buf,"*\0"); break;
 //  case 3:strcat(buf,"/\0"); break;
   default: strcat(buf,"+\0");  break;
  }
}

uint32_t choose(uint32_t n) {
  //srand(time(0));
  int a = rand() % n;
  //printf("choose = %d\n",a);
  return a;
}

void gen(char x){
  if(x == '('){
  strcat(buf,"(\0");}
  else if(x == ')') {
  strcat(buf,")\0");}
}

uint32_t count_gen;
static void gen_rand_expr() {
 // printf("I enter gen_rand_expr!\n ");
  count_gen++;
  if(count_gen < 100){
  switch(choose(3)) {
    case 0: gen_num(); break;
    case 1: gen('(');  gen_rand_expr(); gen(')'); break;
    case 2: gen_rand_expr(); gen_rand_op();gen_rand_expr(); break;
  }
  }
 // printf("buf = %s\n", buf);
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {              //if have argument,change loop
    sscanf(argv[1], "%d", &loop);
  }
 // printf("begin get expr\n");
  int i;
  for (i = 0; i < loop; i ++) {     //will generate loop expr(in buf)
    buf[0] = '\0';
    count_gen = 0;
    gen_rand_expr();
    //printf("i get the buf :  %s\n",buf);
    if(count_gen >= 100) { strcpy(buf,"1+1");}
    sprintf(code_buf, code_format, buf);    //put buf to format

    FILE *fp = fopen("/tmp/.code.c", "w");  //open code.c allow write file
    assert(fp != NULL);
    fputs(code_buf, fp); //write code_buf to fp
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    uint32_t result;
    fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%d %s\n", result, buf);
  }
  return 0;
}
