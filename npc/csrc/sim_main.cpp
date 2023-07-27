#include "sim_main.h"
#include "utils.h"
#include "mem.h"
#include <sys/time.h>

struct timeval currentTime;
static uint32_t system_start_us;

uint64_t *cpu_gpr = NULL;
extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

uint64_t *cpu_csr = NULL;
extern "C" void set_csr_ptr(const svOpenArrayHandle r){
  cpu_csr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
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

extern "C" void v_printf(int data)
{
  printf("data = %x \n" ,data);
}

static bool access_device = false;
uint32_t key_dequeue();
void init_screen();
extern uint8_t vmem[400 * 300 * 4];
extern "C" void v_pmem_read(long long raddr, long long *rdata) {
  //printf("the orign raddr is %lx \n ",raddr);
  //总是读取地址为`raddr & ~0x7ull`的8字节返回给`rdata`
  if(raddr == 0xa0000048)  //时钟
  {
    access_device = true;
    
    gettimeofday(&currentTime,NULL);
    uint64_t time_pass = currentTime.tv_sec *1000000 + currentTime.tv_usec - system_start_us;
    *rdata = time_pass; 
  }
  //内存
  else if(raddr >= 0x80000000 && raddr <= 0x87ffffff)
  { 
    access_device = false;
    *rdata = pmem_read(raddr & ~0x7ull, 8);
  }
  //键盘
  else if(raddr == 0xa0000060){  
    //printf("%d this a access kbd inst\n" ,i);
    access_device = true;
    uint64_t kbd_code = key_dequeue();
    static bool last_check_kbd = false;
    static uint64_t last_kbd_code;
    if(last_check_kbd) { //检测上一次是不是按键 
      *rdata = last_kbd_code; //如果是 就存上一次的
      last_check_kbd = false;
    } 
    else   // 如果上一次没有按键
    {
      if(kbd_code != 0){ //第一条指令检测到键盘
      last_check_kbd = true;
      last_kbd_code = kbd_code;
      }
      *rdata = kbd_code;
    }
  }
  //vga
  else if(raddr == 0xa0000100){
    access_device = true;
    *rdata = 0x0190012c;
  }
  //无效地址
  else
  {
    //printf("The read address %lx  is invalid! \n",raddr);
    *rdata = 0x44;
  }
}

extern uint32_t sync_vmem;
extern "C" void v_pmem_write(long long waddr, long long wdata, long long wmask) {
  // 总是往地址为`waddr & ~0x7ull`的8字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  int n = waddr - ( waddr & ~0x7ull );
  uint64_t vmem_data = wdata;
  wdata = wdata & wmask;//取出要读的数，其他的置0
  wmask = wmask << (n << 3);
  if( waddr == 0xa00003f8 )  //串口
  {
    access_device = true;
    putchar(wdata);
  }
  else if(waddr >= 0x80000000 && waddr <= 0x8fffffff) //内存
  {
    access_device = false;
    pmem_write(waddr & ~0x7ull, 8, (wdata << (n << 3)),wmask);
  }
  else if( ( waddr >= 0xa1000000 )  && ( waddr < ( 0xa1000000 + 400 * 300 * 4)) ){
    uint32_t vmem_addr = waddr - 0xa1000000;
    //printf("vmem_addr = %x, vmem_data = %lx, wmask = %lx \n",vmem_addr ,vmem_data, wmask);
    vmem[vmem_addr + 0] = (uint8_t) ( (uint32_t)wdata & 0x000000ff );
    vmem[vmem_addr + 1] = (uint8_t) ( ( (uint32_t)wdata & 0x0000ff00 ) >> 8 ); 
    vmem[vmem_addr + 2] = (uint8_t) ( ( (uint32_t)wdata & 0x00ff0000 ) >> 16 ); 
    vmem[vmem_addr + 3] = (uint8_t) ( ( (uint32_t)wdata & 0xff000000 ) >> 24 ); 
  }
  else if( waddr == 0xa0000104){
    //printf("find sync\n");
    sync_vmem = 1;
  }
  else printf("the write addr:%llx is invalid \n",waddr);

}

extern const char *regs[];
// 一个输出RTL中通用寄存器的值的示例
void dump_gpr() {
  int i;
  for (i = 0; i < 32; i++) {
    printf("%s = 0x%lx\n", regs[i], cpu_gpr[i]);
  }
}

void dump_csr() {
  int i = 0;
  for( i = 0; i < 4; i++){
    printf("%d = 0x%lx\n", i, cpu_csr[i]);
  }
}

int instr_num = 21;
bool Execute = false;
extern struct func_struct func_trace[10];
extern int func_num;
static uint32_t total_inst_num = 0;
extern bool dut_find_difftest;
CPU_state cpu = {};
bool npc_stop = false;

void init_monitor(int argc, char** argv);
void sdb_mainloop(); //sdb.c
void wp_detect();    //watchpoint.c
extern "C" void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
void difftest_skip_ref();
void difftest_step(uint32_t pc, uint32_t npc);
void device_update();
void init_keymap();

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

static uint32_t inst_start_time;
static uint32_t inst_over_time;
uint64_t last_top_pc = 0x80000000;
//int dyl_a = 200;
bool first_inst = true;

void cpu_exec(int n){
  int this_cycle_inst = n;
  gettimeofday(&currentTime,NULL);
  inst_start_time = currentTime.tv_sec * 1000000 + currentTime.tv_usec;

  while((n || Execute) && !npc_stop){  //!contextp->gotFinish()
    //如果执行到了ebreak 或指令条数 或发现差异 就停
    if( top->ebreak || (n-- == 0 && !Execute) || dut_find_difftest ) { break; }

    //if(total_inst_num % 2 == 1) top->suspend = 1;
    //else top->suspend = 0;
    top->clk = 0; sim_exit();
    uint64_t top_pc = verilog_pc;
    uint32_t top_inst = verilog_inst; //
    //printf("clk = 0: inst = %x, pc = %lx, top->rd = %d \n" ,top_inst ,top_pc, top->rd );
    top->clk = 1; sim_exit();
    top_pc = verilog_pc;
    top_inst = verilog_inst; 
    //if(top->ecall_or_mret) printf("inst = %x, pc = %lx, csr_wdata1 = %lx\n" ,top_inst ,top_pc ,top->csr_wdata1);
    //printf("clk = 1: inst = %x, pc = %lx\n" ,top_inst ,top_pc );

    //if(last_top_pc == top_pc){
  //printf("the pc is not change current inst = %x, pc = %lx\n" ,top_inst ,top_pc);
/*     }
    last_top_pc = top_pc; */
   
    
    #ifdef CONFIG_HAS_VGA
      device_update();
    #endif

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
    memset(p, ' ', 1);
    p += 1; 
    disassemble(p, logbuf + sizeof(logbuf) - p, top_pc, (uint8_t *)&top_inst, 4);
    writeIringbuf(iringbuf,logbuf);
    if(!Execute && (this_cycle_inst < instr_num)) { puts(logbuf); printf("\n"); }
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
    //copy rtl gpr status to cpu  for difftest
    if(top->isram_rresp ){   //只有在取到一条新指令后，才会运行上一条指令，并进行检测，而且第一次取到不检测
    if(first_inst)
      first_inst = false;
    else {
      printf("begin difftest\n");
    for (int i = 0; i < 32; i++) {
      cpu.gpr[i] = cpu_gpr[i];
    }
    cpu.pc = verilog_pc;
    if( (top_inst & 0x707f) == 0x1073 || (top_inst & 0x707f) == 0x73 || \
        (top_inst & 0x707f) == 0x2073 || (top_inst & 0x707f) == 0x3073 ){
        difftest_skip_ref();
    }
    
    if(access_device)  { difftest_skip_ref(); }
    difftest_step(verilog_pc,verilog_pc);
    printf("difftest over\n");
    }
    }
    #endif
    
    total_inst_num = total_inst_num + 1;

  }

  //printf("cpu_exec while over!\n");
  gettimeofday(&currentTime,NULL);
  inst_over_time = currentTime.tv_sec *1000000 + currentTime.tv_usec - inst_start_time;
  inst_over_time = inst_over_time / 1000000;
  uint32_t inst_frequency = total_inst_num / inst_over_time;

  if( (!top->x10 && top->ebreak) || (npc_stop)){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN),verilog_pc);
    Log("total guest instructions = %d" , total_inst_num);
    //Log("simulation frequency = %d inst/s, total time: %d s" ,inst_frequency ,inst_over_time);
  }
  else if ( top->ebreak && top->x10 != 0 ){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED),verilog_pc);
    Log("total guest instructions = %d" , total_inst_num); 
    #ifdef CONFIG_ITRACE 
      printIringbuf(iringbuf);
    #endif
  }
  else if( dut_find_difftest ){
    printf("verilog_pc = %x \n" ,verilog_pc);
    #ifdef CONFIG_ITRACE 
      printIringbuf(iringbuf);
    #endif
    dut_find_difftest = false;
  }

  //tfp->close();
  return;
}

int main(int argc, char** argv, char** env){
  //contextp -> traceEverOn(true);
  contextp -> commandArgs(argc, argv);  //传递参数以便于verilated可以看到    
  //top->trace(tfp,0);
  //tfp->open("wave.vcd");

  top->rst = 0;
  top->clk = 0;
  reset(2);

  cpu.pc = (uint64_t)0x80000000;
  init_monitor(argc,argv);

  #ifdef CONFIG_HAS_KEYBOARD
    init_keymap();
  #endif
  #ifdef CONFIG_HAS_VGA
    init_screen();
  #endif

  //获得系统初始时间
  gettimeofday(&currentTime,NULL);
  system_start_us = currentTime.tv_sec * 1000000 + currentTime.tv_usec;

  sdb_mainloop();

  delete contextp;
  return 0;
}

