#include <stdio.h>
#include <stdlib.h>
#include <Vtop.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <getopt.h>

#include "mem.h"

#difine RESET_VECTOR 0x80000000
static char *img_file = NULL;

static long load_img() {
  if(img_file == NULL){
    printf("No image is given, Use the default build-in image.\n");
    return 1024;
  }

  FILE *fp = fopen(img_file,"rb");
  Assert(fp,"Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  printf("the image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

VerilatedContext* contextp = new VerilatedContext; //构造一个结构体以保持仿真时间
Vtop* top = new Vtop{contextp};  //构造一个verialted模型 来自于Vtop.h(产生于verialting top.v)
VerilatedVcdC* tfp = new VerilatedVcdC;

static void single_cycle(){
  top->clk = 0; sim_exit();
  top->clk = 1; sim_exit();
}

static void reset(int n){
  top->rst = 1;
  while (n -- > 0) single_cycle();
  top->rst = 0;
}

void sim_exit(){
  top->eval();
  contextp->timeInc(1); 
  tfp->dump(contextp->time());
}

static int parse_args(int argc, char *argv[]){
  const struct option table[] = {
   { 0      , 0          , NULL, 0},
  };
  int o;
  while( (o = getopt_long(argc,argv,"",table,NULL) ) != -1){
    switch (o) {
      case 1: img_file = optarg; return 0;
      default("no img_file");
    }
  }
  return 0;
}


int main(int argc, char** argv, char** env){
  parse_args(argc, argv);  
  contextp -> traceEverOn(true);
  contextp->commandArgs(argc, argv);  //传递参数以便于verilated可以看到    
  top->trace(tfp,0);
  tfp->open("wave.vcd");

  init_mem();
  top->rst = 0;
  top->clk = 0;
  reset(2);
  int last_clk=0;
  int num = 10;
  int pc = 0x80000000;
  while(!contextp->gotFinish()){
    if(top->ebreak) {break;} 
      last_clk = top->clk; 
      top->clk = !top->clk;
      if(!top->clk && last_clk && !top->rst)
      {
        top->inst = pmem_read(top->pc,4);
        pc += 4;
      }
      sim_exit();
      printf("pc = %x\n",top->pc);
      printf("inst = %x\n",top->inst);
      printf("x5 = %ld , x6 = %ld\n\n",top->x5,top->x6);  
  }
  delete top;
  tfp->close();
  delete contextp;
  return 0;
}

