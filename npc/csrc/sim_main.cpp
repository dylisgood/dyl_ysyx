#include "sim_main.h"
#include "utils.h"
#include "mem.h"



uint64_t *cpu_gpr = NULL;
extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

uint32_t verilog_pc = 0;
extern "C" void get_pc_value(int data)
{
  verilog_pc = data;
}


// 一个输出RTL中通用寄存器的值的示例
void dump_gpr() {
  int i;
  for (i = 0; i < 32; i++) {
    printf("gpr[%d] = 0x%lx\n", i, cpu_gpr[i]);
  }
}

int instr_num = 0;
bool Execute = false;
extern struct func_struct func_trace[10];
extern int func_num;

void init_monitor(int argc, char** argv);
void sdb_mainloop(); //sdb.c
void wp_detect();    //watchpoint.c
extern "C" void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
void difftest_step(uint32_t pc, uint32_t npc);

VerilatedContext* contextp = new VerilatedContext; //构造一个结构体以保持仿真时间
Vtop* top = new Vtop{contextp};  //构造一个verialted模型 来自于Vtop.h(产生于verialting top.v)
VerilatedVcdC* tfp = new VerilatedVcdC;


void sim_exit(){
  top->eval();
  contextp->timeInc(1); 
  tfp->dump(contextp->time());
}

static void single_cycle(){
  top->clk = 0; sim_exit();
  top->clk = 1; sim_exit();
}

static void reset(int n){
  top->rst = 1;
  while (n -- > 0) single_cycle();
  top->rst = 0;
}

void cpu_exec(int instr_num){
  int n = instr_num * 2;
  static int last_clk=0;

  while(n || Execute){  //!contextp->gotFinish()
    if(top->ebreak) {break;}
    if(n-- == 0 && !Execute) { break; } 
    last_clk = top->clk; 
    top->clk = !top->clk;
    if(!top->clk && last_clk && !top->rst)
    { top->inst = pmem_read(top->pc,4); }
    if(top->clk){
      difftest_step(top->pc,top->pc);
    }
    sim_exit();
    
    if(!top->clk)
    {
    #ifdef CONFIG_WATCHPOINT 
    wp_detect();
    #endif

    #ifdef CONFIG_ITRACE
    char logbuf[127];
    char *p = logbuf;
    uint64_t top_pc = verilog_pc;
    p += snprintf(p, sizeof(logbuf), "0x%016" PRIx64 ":", top_pc); //16进制PC 64位 
    int ilen = 4;
    int i;
    uint8_t *inst = (uint8_t *)(&top->inst);
    for (i = ilen - 1; i >= 0; i --) {
      p += snprintf(p, 4, " %02x", inst[i]); 
    }
    writeIringbuf(iringbuf,logbuf);
    memset(p, ' ', 1); 
    p += 1; 
    disassemble(p, logbuf + sizeof(logbuf) - p, top->pc, (uint8_t *)&top->inst, 4);
    #endif
    
    #ifdef CONFIG_FTRACE
    static int kong = 0;
    int j = 0;
    if( ((top->inst & 0x0ef) == 0x0ef) || ((top->inst & 0x0e7) == 0x0e7) \
          || ((top->inst & 0x00078067) == 0x00078067) )  //jal && x1 || jalr && !x1
    {
        for (int i = 0; i < func_num; i++) 
        {
          if(top->pc >= func_trace[i].address && top->pc <= (func_trace[i].address + func_trace[i].size) )
          {
            printf("0x%x: ",top->pc);
            for(j = 0; j < kong; j++) printf(" ");
            kong++;
            printf("call %s[@%lx] \n",func_trace[i].name,func_trace[i].address);
            //printf("kong = %d\n",kong); 
          }
        }
    }
    else if( ((top->inst & 0x00008067) == 0x00008067)  ) //jalr && x0 || jal && x0 
    {
      for (int i = 0; i < func_num; i++) 
      {
        if(top->pc >= func_trace[i].address && top->pc <= (func_trace[i].address + func_trace[i].size))
          {
            printf("0x%x: ",top->pc);
            for(j = 0; j< kong; j++) printf(" ");
            kong--;
            printf("ret %s \n",func_trace[i].name);
            //printf("kong = %d\n",kong);
          }
      }
    }
    #endif
  
    if(!Execute) puts(logbuf);
    //printf("pc = %x   inst = %x \n",verilog_pc,top->inst);
    }
  }
  if( top->x10 == 0 && top->ebreak == 1 ){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN),top->pc);
  }
  else if ( top->ebreak == 1 && top->x10 != 0 ){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED),top->pc); 
    printIringbuf(iringbuf);
  }
  tfp->close();
  return;
}

CPU_state cpu = {};
int main(int argc, char** argv, char** env){
  contextp -> traceEverOn(true);
  contextp -> commandArgs(argc, argv);  //传递参数以便于verilated可以看到    
  top->trace(tfp,0);
  tfp->open("wave.vcd");

  init_monitor(argc,argv);
  
  top->rst = 0;
  top->clk = 0;
  reset(2);
  dump_gpr();
  cpu.gpr = cpu_gpr;
  cpu.pc = verilog_pc;
  sdb_mainloop();
  
  delete contextp;
  return 0;
}

