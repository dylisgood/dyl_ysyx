#include "sim_main.h"
#include "utils.h"
#include "mem.h"
#include <sys/time.h>

struct timeval currentTime;
static int us;
bool uptime_first = true;
uint64_t *cpu_gpr = NULL;
extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

uint32_t verilog_pc = 0;
extern "C" void get_pc_value(int data)
{
  verilog_pc = data;
}

uint32_t verilog_inst = 0;
extern "C" void get_inst_value(int data)
{
  verilog_inst = data;
}

extern "C" void v_pmem_read(long long raddr, long long *rdata) {
  //printf("the orign raddr is %lx \n ",raddr);
  //总是读取地址为`raddr & ~0x7ull`的8字节返回给`rdata`
  if(raddr == 0xa0000048)  //时钟
  {
    if(uptime_first)
    {
      gettimeofday(&currentTime,NULL);
      us = currentTime.tv_sec * 1000000 + currentTime.tv_usec;
      uptime_first = false;
    }
    
    gettimeofday(&currentTime,NULL);
    uint64_t time_pass = currentTime.tv_sec *1000000 + currentTime.tv_usec - us;
    *rdata = time_pass; 
  }
  else if(raddr >= 0x80000000 && raddr <= 0x87ffffff)
  { 
    *rdata = pmem_read(raddr & ~0x7ull, 8);
  }
  else
  {
   // printf("the read address %lx  is invalid! \n",raddr);
    *rdata = 404;
  }
}

extern "C" void v_pmem_write(long long waddr, long long wdata, long long wmask) {
  // 总是往地址为`waddr & ~0x7ull`的8字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  int n = waddr - (waddr & ~0x7ull);
  wdata = wdata & wmask;//取出要读的数，其他的置0
  wmask = wmask << (n << 3);
  if( waddr == 0xa00003f8 )  //串口
  {
    putchar(wdata);
  }
  else if(waddr >= 0x80000000 && waddr <= 0x8fffffff) //内存
  {
    pmem_write(waddr & ~0x7ull, 8, (wdata << (n << 3)),wmask);
  }
/*   else{
    printf("the write addr:%lx is invalid \n",waddr);
  } */
}

extern const char *regs[];
// 一个输出RTL中通用寄存器的值的示例
void dump_gpr() {
  int i;
  for (i = 0; i < 32; i++) {
    printf("%s = 0x%lx\n", regs[i], cpu_gpr[i]);
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
//printf("alu_src1 = 0x%lx ,alusrc2 = 0x%lx, alu_out = 0x%lx top->x10 = %lx  \n",top->alu_src1,top->alu_src2,top->alu_out,top->x10);
static void reset(int n){
  top->rst = 1;
  while (n -- > 0) single_cycle();
  top->rst = 0;
}
void cpu_exec(int n){
  while(n || Execute){  //!contextp->gotFinish()
    if(top->ebreak || (n-- == 0 && !Execute)) {break;}
    top->clk = 0; sim_exit();
    uint64_t top_pc = verilog_pc;
    uint32_t top_inst = verilog_inst;
    top->clk = 1; sim_exit();

    #ifdef CONFIG_ITRACE
    char logbuf[127];
    char *p = logbuf;
    
    p += snprintf(p, sizeof(logbuf), "0x%016" PRIx64 ":", top_pc); //16进制PC 64位 
    int ilen = 4;
    int i;
    uint8_t *inst = (uint8_t *)(&top_inst);
    for (i = ilen - 1; i >= 0; i --) {
      p += snprintf(p, 4, " %02x", inst[i]); 
    }
    writeIringbuf(iringbuf,logbuf);
    memset(p, ' ', 1); 
    p += 1; 
    disassemble(p, logbuf + sizeof(logbuf) - p, top_pc, (uint8_t *)&top_inst, 4);
    if(!Execute && instr_num < 21) { puts(logbuf);printf("\n"); }
    #endif

    #ifdef CONFIG_WATCHPOINT 
    wp_detect();
    #endif

    #ifdef CONFIG_FTRACE
    static int kong = 0;
    int j = 0;
    if( ((verilog_inst & 0x0ef) == 0x0ef) || ((verilog_inst & 0x0e7) == 0x0e7) \
          || ((verilog_inst & 0x00078067) == 0x00078067) )  //jal && x1 || jalr && !x1
    {
        for (int i = 0; i < func_num; i++) 
        {
          if(verilog_pc >= func_trace[i].address && verilog_pc < (func_trace[i].address + func_trace[i].size) )
          {
            printf("0x%x: ",verilog_pc);
            for(j = 0; j < kong; j++) printf(" ");
            kong++;
            printf("call %s[@%lx] \n",func_trace[i].name,func_trace[i].address);
          }
        }
    }
    else if( ((verilog_inst & 0x00008067) == 0x00008067)  ) //jalr && x0 || jal && x0 
    {
      for (int i = 0; i < func_num; i++) 
      {
        if(verilog_pc >= func_trace[i].address && verilog_pc < (func_trace[i].address + func_trace[i].size))
          {
            printf("0x%x: ",verilog_pc);
            for(j = 0; j< kong; j++) printf(" ");
            kong--;
            printf("ret %s \n",func_trace[i].name);
          }
      }
    }
    #endif
    
    #ifdef CONFIG_DIFFTEST
      difftest_step(verilog_pc,verilog_pc);
    #endif
  }

  if( !top->x10 && top->ebreak ){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN),verilog_pc);
  }
  else if ( top->ebreak && top->x10 != 0 ){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED),verilog_pc); 
    #ifdef CONFIG_ITRACE 
      printIringbuf(iringbuf);
    #endif
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

  top->rst = 0;
  top->clk = 0;
  reset(2);

  cpu.pc = (uint32_t)0x800000000;
  init_monitor(argc,argv);
  sdb_mainloop();
  
  delete contextp;
  return 0;
}

