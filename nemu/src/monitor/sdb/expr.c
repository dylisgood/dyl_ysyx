/****************************************************************************************
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
//#include "local-include/reg.h"
/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <string.h>
#include <stdlib.h>
#include <regex.h>

//new add
#include <stdint.h>  //for uint64_t etc
#include <stdbool.h>  //for bool
#include <common.h>
#include <memory/vaddr.h> //for DEREF

#define false 0
#define true 1

enum {
  TK_NOTYPE = 2, TK_EQ = 1, NUM = 10,TK_UNIEQ = 0,
  TK_REG = 3,HEX_NUM=16,NEG_NUM = 4,DEREF = 5,
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus 43
  {"\\-", '-'},         // minus 45
  {"\\*", '*'},         // multip 42
  {"\\/", '/'},         // 47
  {"==", TK_EQ},        // equal 
  {"\\(", '('},
  {"\\)", ')'},
  {"0x[0-9,a-f,A-F]*", HEX_NUM},
  {"[0-9][0-9]*",NUM},
  {"!=", TK_UNIEQ},
  {"&&", '&'},
  {"\\$.{1,2}[0-9]*",TK_REG},
  
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[1000] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;
  int j=0;
  nr_token = 0;
  for(int i=0; i < 1000; i++){
    strcpy(tokens[i].str,"\0");
  }

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

       // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
       //    i, rules[i].regex, position, substr_len, substr_len, substr_start);
        position += substr_len;
        
        switch (rules[i].token_type) {
          case '+':
          case '-':
          case '*':
          case '/': 
          case '(':
          case ')':
                      tokens[j].type = rules[i].token_type; 
                      j++;
                      break;
          case NUM:
                      tokens[j].type = rules[i].token_type;
                      strncat(tokens[j].str,substr_start,substr_len);
                      j++;
                      break;
          case TK_EQ:
                      tokens[j].type = rules[i].token_type;
                      j++;
                      break;
          case TK_UNIEQ:
                      tokens[j].type = rules[i].token_type;
                      j++;
                      break;
          case '&':
                    tokens[j].type = rules[i].token_type;
                    j++;
                    break;
          case HEX_NUM:
                    tokens[j].type = rules[i].token_type;
                    strncpy(tokens[j].str,substr_start,substr_len);
                    j++;
                    break;
          case TK_REG:
                    tokens[j].type = rules[i].token_type;
                    strncat(tokens[j].str,substr_start+1,substr_len-1);
                    j++;
                    break;
          case TK_NOTYPE:break;
          default: printf("unknown operator!\n"); break;
      }

      } 
     

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
    } 
  }
   nr_token = j -1;
   
  //for(int h = 0;h < j; h++)
  //{ printf("j = %d, type = %d,  str= %s \n", h,tokens[h].type, tokens[h].str); }
  return true;
}

//to check the expr whether valid or not
//valid ---true    invalid---false
bool check_expr(int p, int q) {
  int c,i=0;
  for(c=p; c<=q; c++){
    if(tokens[c].type == '(') {i++; }
    if(tokens[c].type == ')') {i--; }
    if(i<0) {return false;}
  }
  if(i==0) {return true;}
  else {return false;}
}

//To check whether BNF or not
//BNF---true  no-BNF---false
bool check_parentheses(int p, int q){
  int c;
  int i=0;
    if(tokens[p].type == '(' && tokens[q].type == ')')  {
       for(c = p; c <= q; c++) {
        if(tokens[c].type == '(') {
           i++;
        }
        else if(tokens[c].type == ')') {
           i--;
       }
       if(c != p && c !=q && i ==0) {return false;}
       if(i < 0) {return false; }
       } 
       if(i != 0){return false;}
       else { return true; }
    }
    else { return false; }
}

//check tokens[].type is operator or not
bool check_op(int count){
  if(tokens[count].type == '+' || tokens[count].type == '-'\
   || tokens[count].type == '*' || tokens[count].type == '/'\
   || tokens[count].type == TK_EQ){
     return true;
  }
  else {return false; }
}

//check the count tokens whether in bracket or not
//in bracket----true   not---false
bool check_bracket(int p,int count , int q){
  int ii=0,jj=0;
  int cnt;
  for(cnt = p; cnt < count; cnt++){
    if(tokens[cnt].type == '('){ ii++; }
    if(tokens[cnt].type == ')'){ ii--; }
  }
  for(cnt = count+1; cnt <= q; cnt++) {
    if(tokens[cnt].type == '(') { jj--; };
    if(tokens[cnt].type == ')') { jj++; }; 
  }
  //printf("ii=%d,   jj=%d\n",ii,jj); 
  if(ii==jj && ii!=0 && jj!=0)  {  return true; }
  else if(ii==0 && jj==0) { return false;}
  else  {assert(0);}

}


//get main_operator_position
int first=1;
int first_FLAG=1;
int Main_position(int p, int q){
  int count;
  int op=0;
  for(count = p; count <= q; count ++){
    if(check_op(count)){   //首先是运算符+ - * /
      if(!check_bracket(p,count,q))  //且运算符不在括号内
       {
        // printf("count = %d\n",count);
         if(first_FLAG) { op=count; first_FLAG =0; }  //如果是第一次找到符合条件的运算符 先将其视为主运算符的位置
         if(!first_FLAG){          //之后再发现可能符合条件的运算符 进一步判断是不是主运算符  
          if(tokens[count].type == '+' || tokens[count].type == '-') { // + -的运算优先级小于 * /
            op = count;
          }
         }
       }
      }

    }
  first = 1;first_FLAG=1;
  return op;

}

//get expr's result
uint64_t eval(int p,int q){
    uint64_t val1,val2;
    char op_type;
    int op;
    bool *succ = false;
    if(p > q){
      printf("bad expression! \n");
      assert(0);
    }
    else if(p == q){
      if(tokens[p].type == TK_REG)
      {
        uint64_t reg_value = isa_reg_str2val(tokens[p].str,succ);
        return reg_value; 
        
      }        
      else if(tokens[p].type == HEX_NUM)
      {
        uint64_t dec = 0;
        sscanf(tokens[p].str,"%lx",&dec);
        return dec;
      }
      else 
      {
        return atoi(tokens[p].str);
      }
    }
    else if(check_parentheses(p,q) == true){
      return eval(p + 1, q - 1);
    }
    else {
      op = Main_position(p,q);
      if(op == 0) //若没找到主运算符 且p != q 则可能有解引用 或负数
      {
        if(tokens[p].type == DEREF)
        {
          return vaddr_read(eval(p+1,q),8);
        }
        else if(tokens[p].type == NEG_NUM)
        {
          return -eval(p+1,q);
        }
        else {printf("bad expression!\n"); return 0;}
      }
      else
      {
      val1 = eval(p, op - 1);
      val2 = eval(op+1, q);
      op_type = tokens[op].type;
      switch(op_type)
        {
          case '+':return val1 + val2;
          case '-':return val1 - val2;
          case '*':return val1 * val2;
          case '/':return val1 / val2;
          case TK_EQ:return val1 == val2;
          default: assert(0);
        }
      }
    }
}

void tokens_handle() {     //become reg and pointer to num
    //recognize * and become DEREF
   for(int i=0;i <= nr_token;i++){
    if(tokens[i].type == '*' && ((i == 0) || check_op(i-1) || tokens[i-1].type == '(')){
      tokens[i].type = DEREF;
    }
   }
    
   //negative num
   for(int i=0; i <= nr_token; i++)  {
    if(tokens[i].type == '-' && ((i == 0) || check_op(i-1) || tokens[i-1].type == '(')){
      tokens[i].type = NEG_NUM;
    }
   }
   
//  for(int i=0;i <= nr_token;i++)
//  { printf("after handle:  j = %d, type = %d,  str= %s \n", i,tokens[i].type, tokens[i].str); }

}

void init_tokens() {
  for(int i=0; i <= nr_token; i++){
    strcpy(tokens[i].str,"\0");
  }
}

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  tokens_handle();
 
  uint64_t result=0;
  if(check_expr(0,nr_token)){
     result = eval(0,nr_token);
     init_tokens();
  }
  else printf("the expr is false\n");
  
  return result;
}
