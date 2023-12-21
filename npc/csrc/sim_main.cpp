#include "sim_main.h"
#include "utils.h"
#include "mem.h"
#include <sys/time.h>

struct timeval currentTime;
static uint32_t system_start_us;

//for cache shoot rate 
/* uint32_t IDreg_valid = 0;
extern "C" void get_IDreg_valid_value(uint32_t data)
{
  IDreg_valid = data;
}

uint32_t Dcache_Hitway = 0;
extern "C" void get_Dcache_Hitway_value(int data)
{
  Dcache_Hitway = data;
}

uint32_t Dcache_valid = 0;
extern "C" void get_Data_cache_valid_value(int data)
{
  Dcache_valid = data;
}

uint32_t hit_32 = 0;
extern "C" void get_hit_32_value(int data)
{
  hit_32 = data;
}

uint32_t IFU_valid_32 = 0;
extern "C" void get_IFU_valid_value(int data)
{
  IFU_valid_32 = data;
}  */ 

//difftest
uint32_t is_device = 0;
extern "C" void get_is_device_value(uint32_t data)
{
  is_device = data;
}

//necessary
uint64_t *cpu_gpr = NULL;
extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

uint32_t inst_finish = 0;
extern "C" void get_inst_finish_value(uint32_t data)
{
  inst_finish = data;
}

uint32_t inst_finishpc = 0; //dut alse use
extern "C" void get_inst_finishpc_value(uint32_t data)
{
  inst_finishpc = data;
} 

uint32_t instruction_finsh = 0;
extern "C" void get_instruction_finsh_value(uint32_t data)
{
  instruction_finsh = data;
}

uint32_t ebreak_cpu = 0;
extern "C" void get_ebreak_value(uint32_t data)
{
  ebreak_cpu = data;
}

uint32_t x10_cpu = 0;
extern "C" void get_x10_value(uint32_t data)
{
  x10_cpu = data;
}

static bool access_device = false;
uint32_t key_dequeue();
void init_screen();
extern uint32_t vmem[400 * 300];
extern "C" void v_pmem_read(long long raddr, long long *rdata) {
  //printf("the orign raddr is %lx \n ",raddr);
  //总是读取地址为`raddr & ~0x7ull`的8字节返回给`rdata`
  if(raddr == 0xa0000048)                             //clock
  {
    access_device = true;
    gettimeofday(&currentTime,NULL);
    uint64_t time_pass = currentTime.tv_sec *1000000 + currentTime.tv_usec - system_start_us;
    *rdata = time_pass; 
  }
  else if( raddr == 0xa00003f8 )                      //serial port
  {
    access_device = true;
    *rdata = 0;
  }
  else if(raddr >= 0x80000000 && raddr <= 0x87ffffff) //memory
  { 
    access_device = false;
    *rdata = pmem_read(raddr & ~0x7ull, 8);
  }
  else if(raddr == 0xa0000060){                       //keyboard
    access_device = true;
    uint64_t kbd_code = key_dequeue();
    *rdata = kbd_code;
  }
  else if(raddr == 0xa0000100){         //vga
    access_device = true;
    *rdata = 0x0190012c;
  }
  else                                 //invalid address
  {
    Log("The read address %lx  is invalid! \n",raddr);
    *rdata = 0x4444444466666666;
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
  if( waddr == 0xa00003f8 ||  waddr == 0xa00003f0)  //serial port
  {
    access_device = true;
    putchar(wdata);
  }
  else if(waddr >= 0x80000000 && waddr <= 0x8fffffff) //memory
  {
    access_device = false;
    pmem_write(waddr & ~0x7ull, 8, (wdata << (n << 3)),wmask);
  }
  else if( ( waddr >= 0xa1000000 )  && ( waddr < ( 0xa1000000 + 400 * 300 * 4)) ){      //vga
    uint32_t vmem_addr = ( waddr - 0xa1000000 ) >> 2;
    vmem[vmem_addr] = (uint32_t)vmem_data;
  }
  else if( waddr == 0xa0000104){
    sync_vmem = 1;
  }
  else Log("the write addr:%llx is invalid \n",waddr);

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
    printf("sorry not surropt csr\n");
    //printf("%d = 0x%lx\n", i, cpu_csr[i]);
  }
}

int instr_num = 51;
bool Execute = false;
extern struct func_struct func_trace[10];
extern int func_num;
static uint64_t total_inst_num = 0;
static uint64_t total_cycle = 0;
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
#ifdef USE_TRACE
VerilatedVcdC* tfp = new VerilatedVcdC;
#endif

void sim_exit(){
  top->eval();
  contextp->timeInc(1);
  #ifdef USE_TRACE
  tfp->dump(contextp->time());
  #endif
}

static void single_cycle(){
  top->clock = 0; sim_exit();
  top->clock = 1; sim_exit();
}

static void reset(int n){
  top->reset = 1;
  while (n -- > 0) single_cycle();
  top->reset = 0;
}

static uint64_t inst_start_time;
static uint64_t inst_over_time;
static uint64_t inst_last_time;
uint32_t Access_Dcache_count = 0;
uint32_t Access_Icache_count = 0;
uint32_t Dcache_shoot_count = 0;
uint32_t Icache_shoot_count = 0;

void cpu_exec(int n){
  int this_cycle_inst = n;
  gettimeofday(&currentTime,NULL);

  //inst_start_time = currentTime.tv_sec * 1000000 + currentTime.tv_usec;
  inst_start_time = currentTime.tv_sec;

  while((n || Execute) && !npc_stop){        //!contextp->gotFinish()

    // 如果执行到了ebreak 或指定指令书目 或发现差异 就停止运行
    if( ebreak_cpu || (n-- == 0 && !Execute) || dut_find_difftest ) { break; }

    //go one cycle and get data
    top->clock = 0; sim_exit();
    top->clock = 1; sim_exit();

    // record total cycle count and instruction count
    total_cycle = total_cycle + 1;
    if(inst_finish) total_inst_num += 1;
    if(total_inst_num % 10000000 == 0)  {printf("Instruction = %d, Cycle = %d, IPC = %.3f\n",total_inst_num++,total_cycle, (double)total_inst_num / (double)(total_cycle) );}

    //cache shoot rate  
/*     if(IFU_valid_32) Access_Icache_count += 1;
    if(hit_32) Icache_shoot_count += 1;
    if(IDreg_valid && Dcache_valid) Access_Dcache_count += 1;
    if(Dcache_Hitway) Dcache_shoot_count += 1;   */

#ifdef CONFIG_HAS_VGA
    //if(total_inst_num % 250 == 0) 
    device_update();
#endif

#ifdef CONFIG_ITRACE
    char logbuf[127];
    char *p = logbuf;
    if(inst_finish){
      p += snprintf(p, sizeof(logbuf), "0x%016" PRIx64 ":", inst_finishpc); //16进制PC 64位 
      int ilen = 4;
      int i;
      uint8_t *inst = (uint8_t *)(&instruction_finsh);
      for (i = ilen - 1; i >= 0; i --) {
        p += snprintf(p, 4, " %02x", inst[i]); 
      }
      memset(p, ' ', 1);
      p += 1; 
      disassemble(p, logbuf + sizeof(logbuf) - p, inst_finishpc, (uint8_t *)&instruction_finsh, 4);
      writeIringbuf(iringbuf,logbuf);
      if(!Execute && (this_cycle_inst < instr_num)) { puts(logbuf); printf("\n"); }
    }
#endif

#ifdef CONFIG_WATCHPOINT 
    wp_detect();
#endif

#ifdef CONFIG_FTRACE
  static int kong = 0;
  int kong_j = 0;
  //call function
  if(inst_finish)
  {
    if( (( (instruction_finsh & 0x0ef) == 0x0ef) || ((instruction_finsh & 0x0e7) == 0x0e7) \
          || ((instruction_finsh & 0x00078067) == 0x00078067)) )   //jal && x1 || jalr && !x1
    {
        for (int i = 0; i < func_num; i++) 
        {
          if(inst_finishpc >= func_trace[i].address && inst_finishpc < (func_trace[i].address + func_trace[i].size) )
          {
            printf("0x%x: ",inst_finishpc);
            for(kong_j = 0; kong_j < kong; kong_j++) printf(" ");
            kong++;
            printf("call %s[@%lx] \n",func_trace[i].name,func_trace[i].address);
          }
        }
    }
  //return from function
    else if( ( (instruction_finsh & 0x00008067) == 0x00008067 ) ) //jalr && x0 || jal && x0 
    {
      for (int i = 0; i < func_num; i++) 
      {
        if(inst_finishpc >= func_trace[i].address && inst_finishpc < (func_trace[i].address + func_trace[i].size))
          {
            printf("0x%x: ",inst_finishpc);
            for(kong_j = 0; kong_j< kong; kong_j++) printf(" ");
            kong--;
            printf("ret %s \n",func_trace[i].name);
          }
      }
    }
  }
#endif
    
#ifdef CONFIG_DIFFTEST
    if(inst_finish) 
    {
      cpu.pc = inst_finishpc; //用于比较，如果跳过比较，则需要让nemu 的 pc + 4

      //跳过访问设备指令
      if(is_device)  {
        for (int i = 0; i < 32; i++) { //copy npc gpr to nemu
          cpu.gpr[i] = cpu_gpr[i];
        }
        cpu.pc = inst_finishpc + 4; 
        difftest_skip_ref(); 
      }

      //检测
      difftest_step(inst_finishpc,inst_finishpc);
    }
#endif

  }

  //record time
  gettimeofday(&currentTime,NULL);
  inst_over_time = currentTime.tv_sec;
  inst_last_time = inst_over_time - inst_start_time;
  uint32_t time_min = inst_last_time / 60;

  //get simulation frequency
  double inst_frequency = (double)total_inst_num / (double)inst_last_time;
  double Cycle_frequency = (double)total_cycle / (double)inst_last_time;
  double IPC = (double)total_inst_num / (double)total_cycle;

  //caculate cache shoot rate
  //double Icache_shoot_rate =(double)Icache_shoot_count / (double)Access_Icache_count;
  //double Dcache_shoot_rate = (double)Dcache_shoot_count / (double)Access_Dcache_count;

  if( (!x10_cpu && ebreak_cpu) || (npc_stop)){
    //printf("Access_Icache_count = %d, Icache_shoot_count = %d\n",Access_Icache_count,Icache_shoot_count);
    //printf("Access_Dcache_count = %d, Dcache_shoot_count = %d\n",Access_Dcache_count,Dcache_shoot_count);
    Log("NPC = %s at PC = 0x%x" ,ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN),inst_finishpc);
    Log("Total guest Instructions = %d, total cycle = %ld, IPC = %.2f " ,total_inst_num ,total_cycle,IPC);
    Log("Instruction Frequency = %.2f inst/s, Simulation frequency = %.2f K cycle/s, total time: %d s (%d min)" ,inst_frequency, Cycle_frequency/1000, inst_last_time, time_min );
    //Log("Icache_shoot_rate = %.2f%%, Dcache_shoot_rate = %.2f%%\n" ,Icache_shoot_rate*100, Dcache_shoot_rate*100);
  }
  else if ( ebreak_cpu && x10_cpu != 0 ){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED),inst_finishpc);
    Log("total guest instructions = %ld, total cycle = %ld" , total_inst_num,total_cycle); 
    #ifdef CONFIG_ITRACE 
      printIringbuf(iringbuf);
    #endif
  }
  else if( dut_find_difftest ){
    printf("inst_finishpc = %x , total_cycle = %d\n" ,inst_finishpc ,total_cycle);
#ifdef CONFIG_ITRACE 
    printIringbuf(iringbuf);
#endif
    dut_find_difftest = false;
  }

#ifdef USE_TRACE
  tfp->close();
#endif
  return;
}

int main(int argc, char** argv, char** env){
#ifdef USE_TRACE
  contextp -> traceEverOn(true);
  top->trace(tfp,0);
  tfp->open("wave.vcd");
#else
  contextp -> traceEverOn(false);
#endif

  contextp -> commandArgs(argc, argv);  //传递参数以便于verilated可以看到    

  top->reset = 0;
  top->clock = 0;
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

