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

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ, NUM,

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus
  {"\\-", '-'},         // minus
  {"\\*", '*'},         // multip
  {"\\/", '/'},         //
  {"==", TK_EQ},        // equal
  {"\\(", '('},
  {"\\)", ')'},
  {"[0-9]",NUM},
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

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;
static int numofstr;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;
  int j=0;
  nr_token = 0;
  int  NUM_number = 0;
  int  NUM_FLAG = 0;
  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;
        char *substr_num;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);
        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
 
        if(rules[i].token_type != NUM ){  
            if(NUM_FLAG == 1){ 
               strncpy(tokens[j-1].str,substr_num,NUM_number);
               tokens[j-1].type = NUM;
               NUM_FLAG = 0;
               NUM_number =0;
              }
           
           tokens[j].type = rules[i].token_type;
           if(rules[i].token_type != TK_NOTYPE) { j++; }
        }
        else if(rules[i].token_type == NUM || e[position] == '\0')
        { 
            if(!NUM_FLAG && rules[i].token_type == NUM) { substr_num = substr_start; j++; }  
            if(e[position] == '\0' && rules[i].token_type == NUM ) {
                 strcpy(tokens[j-1].str,substr_num);
                 tokens[j-1].type = NUM;
                 printf("i enter ther\n");
              }
            else if((e[position] == '\0') &&(rules[i].token_type != NUM)) {
                tokens[j].type = rules[i].token_type;
               } 
             NUM_number ++;
             NUM_FLAG = 1;
        }
     
//        switch (rules[i].token_type) {
//          default: TODO();
//      }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }
  numofstr = j - 1;
  for(int h = 0;h < j; h++){
       printf("j = %d, type = %d,  str= %s \n", h,tokens[h].type, tokens[h].str); 
     }
  return true;
}
bool check_parentheses(int p, int q){
  int c;
  int i=0,j=0;
 // int kuohao_left[10],kuohao_right[10];
    if(tokens[p].type == '(' && tokens[q].type == ')')  {
       for(c = p; c <= q; c ++) {
        if(tokens[c].type == '(') {
         ///  kuohao_left[i] = c;
           i++;
        }
        else if(tokens[c].type == ')') {
         // kuohao_right[j] = c;
           j++;
        
        printf("i = %d, j = %d", i , j);
       }
       } 
       if(i != j){return false;}
       else { return true; }
    }
    else { return false; }
}
/*
int Main_position(int p, int q){
  return 0;
}
uint32_t eval(int p,int q){
     uint32_t val1,val2;
    if(p > q){
      printf("bad expression! \n");
    }
    else if(p == q){
      return atoi(tokens[p].str);
    }
    else if(check_parentheses(p,q) == true){
      return eval(p + 1, q - 1);
    }
    else {
     // op = Main_position();
      val1 = eval(p, op - 1);
      val2 = eval(op+1, q);

      switch(op_type){
        case '+':return val1 + val2;
        case '-':return val1 - val2;
        case '*':return val1 * val2;
        case '/':return val1 / val2;
        default: assert(0);
      }

    }

}
*/
word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  // TODO();
  bool FLAG;
  FLAG = check_parentheses(0,numofstr);
  if(FLAG == true){
    printf("the expr is true\n");
  }
  return 0;
}
