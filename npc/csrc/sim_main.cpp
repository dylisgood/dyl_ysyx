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

uint32_t PC_JUMP_Suspend = 0;
extern "C" void get_PC_JUMP_Suspend_value(int data)
{
  PC_JUMP_Suspend = data;
}

uint32_t ret_valid_32 = 0;
extern "C" void get_ret_valid_32_value(int data)
{
  ret_valid_32 = data;
}

uint32_t ret_last_32 = 0;
extern "C" void get_ret_last_32_value(int data)
{
  ret_last_32 = data;
}

uint32_t ret_data_32 = 0;
extern "C" void get_ret_data_32_value(int data)
{
  ret_data_32 = data;
}

uint32_t cache_rdata_32 = 0;
extern "C" void get_cache_rdata_32_value(int data)
{
  cache_rdata_32 = data;
}

uint32_t rd_req_32 = 0;
extern "C" void get_rd_req_32_value(int data)
{
  rd_req_32 = data;
}

uint32_t Data_OK_32 = 0;
extern "C" void get_Data_OK_32_value(int data)
{
  Data_OK_32 = data;
}

uint32_t Suspend_IFU_32 = 0;
extern "C" void get_Suspend_IFU_value(int data)
{
  Suspend_IFU_32 = data;
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
}

uint32_t verilog_inst = 0;
extern "C" void get_inst_value(int data)
{
  verilog_inst = data;
}

uint32_t verilog_IDinst = 0;
extern "C" void get_IDreginst_value(int data)
{
  verilog_IDinst = data;
}

uint32_t verilog_IDpc = 0;
extern "C" void get_IDregpc_value(int data)
{
  verilog_IDpc = data;
}

uint32_t jump = 0;
extern "C" void get_jump_value(int data)
{
  jump = data;
}

uint32_t EXEreg_pc = 0;
extern "C" void get_EXEreg_pc_value(int data)
{
  EXEreg_pc = data;
}

uint32_t MEMreg_pc = 0;
extern "C" void get_MEMreg_pc_value(int data)
{
  MEMreg_pc = data;
}

uint32_t WBreg_pc = 0;
extern "C" void get_WBreg_pc_value(int data)
{
  WBreg_pc = data;
}

uint32_t verilog_EXEinst = 0;
extern "C" void get_EXEreginst_value(int data)
{
  verilog_EXEinst = data;
}

uint32_t verilog_WBinst = 0;
extern "C" void get_WBreginst_value(int data)
{
  verilog_WBinst = data;
}

uint32_t verilog_MEMinst = 0;
extern "C" void get_MEMreginst_value(int data)
{
  verilog_MEMinst = data;
}

uint32_t MEMreg_aluout = 0;
extern "C" void get_MEMreg_aluout_value(uint32_t data)
{
  MEMreg_aluout = data;
}

uint32_t WBreg_aluout = 0;
extern "C" void get_WBreg_aluout_value(uint32_t data)
{
  WBreg_aluout = data;
}

uint32_t WBreg_rd = 0;
extern "C" void get_WBreg_rd_value(uint32_t data)
{
  WBreg_rd = data;
}

uint32_t EXEreg_alusrc1 = 0;
extern "C" void get_EXEreg_alusrc1_value(uint32_t data)
{
  EXEreg_alusrc1 = data;
}

uint32_t EXEreg_alusrc2 = 0;
extern "C" void get_EXEreg_alusrc2_value(uint32_t data)
{
  EXEreg_alusrc2 = data;
}

uint32_t MEMreg_memwr = 0;
extern "C" void get_MEMreg_memwr_value(uint32_t data)
{
  MEMreg_memwr = data;
}

uint32_t MEMreg_writememdata = 0;
extern "C" void get_MEMreg_writememdata_value(uint32_t data)
{
  MEMreg_writememdata = data;
}

uint32_t EXEreg_writememdata = 0;
extern "C" void get_EXEreg_writememdata_value(uint32_t data)
{
  EXEreg_writememdata = data;
}

uint32_t real_readmemdata_right = 0;
extern "C" void get_real_readmemdata_right_value(uint32_t data)
{
  real_readmemdata_right = data;
}

uint32_t dsram_rresp = 0;
extern "C" void get_dsram_rresp_value(uint32_t data)
{
  dsram_rresp = data;
}

uint32_t wr_reg_data = 0;
extern "C" void get_wr_reg_data_value(uint32_t data)
{
  wr_reg_data = data;
}

uint32_t rdata = 0;
extern "C" void get_rdata_value(uint32_t data)
{
  rdata = data;
}


uint32_t  next_pc= 0;
extern "C" void get_next_pc_value(uint32_t data)
{
  next_pc = data;
}

uint32_t Data_Conflict = 0;
extern "C" void get_Data_Conflict_value(uint32_t data)
{
  Data_Conflict = data;
}

uint32_t WBreg_valid = 0;
extern "C" void get_WBreg_valid_value(uint32_t data)
{
  WBreg_valid = data;
}

uint32_t IDreg_valid = 0;
extern "C" void get_ID_reg_valid_value(uint32_t data)
{
  IDreg_valid = data;
}

uint32_t EXEreg_valid = 0;
extern "C" void get_EXEreg_valid_value(uint32_t data)
{
  EXEreg_valid = data;
}

uint32_t MEMreg_valid = 0;
extern "C" void get_MEMreg_valid_value(uint32_t data)
{
  MEMreg_valid = data;
}

uint32_t inst_finish = 0;
extern "C" void get_inst_finish_value(uint32_t data)
{
  inst_finish = data;
}

uint32_t instruction_finsh = 0;
extern "C" void get_instruction_finsh_value(uint32_t data)
{
  instruction_finsh = data;
}

uint32_t is_device = 0;
extern "C" void get_is_device_value(uint32_t data)
{
  is_device = data;
}

uint32_t inst_finishpc = 0;
extern "C" void get_inst_finishpc_value(uint32_t data)
{
  inst_finishpc = data;
}

uint32_t Suspend_alu = 0;
extern "C" void get_Suspend_alu_value(uint32_t data)
{
  Suspend_alu = data;
}

uint32_t div_doing = 0;
extern "C" void get_div_doing_value(uint32_t data)
{
  div_doing = data;
}

uint32_t dividend = 0;
extern "C" void get_dividend_value(uint32_t data)
{
  dividend = data;
}

uint32_t divisor = 0;
extern "C" void get_divisor_value(uint32_t data)
{
  divisor = data;
}

extern "C" void v_printf(int data)
{
  printf("data = %x \n" ,data);
}

uint32_t cache_state_32 = 0;
extern "C" void get_cache_state_32_value(uint32_t data)
{
  cache_state_32 = data;
}

uint32_t araddr_pc = 0;
extern "C" void get_araddr_pc(uint32_t data)
{
  araddr_pc = data;
}

uint32_t rd_addr = 0;
extern "C" void get_rd_addr_value(uint32_t data)
{
  rd_addr = data;
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

static uint64_t inst_start_time;
static uint64_t inst_over_time;
int last_inst_ex = 0;
void cpu_exec(int n){
  int this_cycle_inst = n;
  gettimeofday(&currentTime,NULL);
  inst_start_time = currentTime.tv_sec * 1000000 + currentTime.tv_usec;

  while((n || Execute) && !npc_stop){  //!contextp->gotFinish()
    //如果执行到了ebreak 或指令条数 或发现差异 就停
    if( top->ebreak || (n-- == 0 && !Execute) || dut_find_difftest ) { break; }

    top->clk = 0; sim_exit();
    uint64_t top_pc = verilog_pc;
    uint32_t top_inst = verilog_inst;
    top->clk = 1; sim_exit();
    top_pc = WBreg_pc;
    top_inst = verilog_WBinst;
    total_cycle = total_cycle + 1; 
    if(inst_finish) total_inst_num += 1;

/*     printf("inst = %x, pc_real = %lx,hit_cache = %d, IFU_valid = %d,PC_JUMP_Suspend = %x\n,\
cache_state = %x , rd_req = %d, rd_addr = %x, araddr_pc = %x,ret_valid = %d,ret_last = %x, ret_data_32= %x,Data_OK = %d,cache_rdata_32 = %x,Suspend_IFU = %d\n,\
IDreg_inst = %x ,IDreg_pc = %x ,next_pc = %x,jump = %d,Data_Conflict = %d,real_readmemdata_right=%lx,IDreg_valid = %d\n,\
EXEreg_inst = %x ,EXEreg_pc = %x, EXEreg_alusrc1 = 0x%lx ,EXEreg_alusrc2 = 0x%lx,EXEreg_writememdata = %lx,Suspend_alu = %d,,div_doing = %d,dividend = %x,divisor = %x,EXEreg_valid = %d\n,\
MEMreg_inst = %x,MEMreg_pc = %x, MEMreg_aluout = 0x%lx, MEMreg_memwr = %d,MEMreg_writememdata = 0x%lx,dsram_rresp = %d,rdata=0x%lx,MEMreg_valid=%d\n,\
WBreg_inst = %x,WBreg_pc = %x, WBreg_aluout = 0x%lx ,WBreg_rd = %d ,wr_reg_data = 0x%lx,WBreg_valid = %d\n\n" \
     ,top_inst, verilog_pc, hit_32 ,IFU_valid_32,PC_JUMP_Suspend\
     ,cache_state_32, rd_req_32, rd_addr, araddr_pc, ret_valid_32,ret_last_32,ret_data_32,Data_OK_32,cache_rdata_32,Suspend_IFU_32\
     ,verilog_IDinst,verilog_IDpc,next_pc,jump,Data_Conflict,real_readmemdata_right,IDreg_valid\
     ,verilog_EXEinst,EXEreg_pc,EXEreg_alusrc1 ,EXEreg_alusrc2,EXEreg_writememdata,Suspend_alu,div_doing,dividend,divisor,EXEreg_valid\ 
     ,verilog_MEMinst,MEMreg_pc,MEMreg_aluout ,MEMreg_memwr,MEMreg_writememdata,dsram_rresp,rdata,MEMreg_valid\
     ,verilog_WBinst,WBreg_pc,WBreg_aluout ,WBreg_rd,wr_reg_data,WBreg_valid); */
  
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
    if(inst_finish)
    {
    //printf("begin difftest\n");
    //copy rtl gpr status to cpu  for difftest
    for (int i = 0; i < 32; i++) {
      cpu.gpr[i] = cpu_gpr[i];
    }
    cpu.pc = inst_finishpc; //用于比较，如果跳过比较，则需要让nemu 的 pc + 4
    //异常指令跳过
/*     if( (instruction_finsh & 0x707f) == 0x1073 || (instruction_finsh & 0x707f) == 0x73 || \
        (instruction_finsh & 0x707f) == 0x2073 || (instruction_finsh & 0x707f) == 0x3073 ){
        difftest_skip_ref();
        cpu.pc = inst_finishpc + 4;
    } */

    //访问设备指令跳过
    if(is_device)  { cpu.pc = inst_finishpc+4; difftest_skip_ref(); }
    //检测
    difftest_step(inst_finishpc,inst_finishpc);
    //printf("difftest over\n");
    }
    #endif
  }

  //printf("cpu_exec while over!\n");
  gettimeofday(&currentTime,NULL);
  inst_over_time = currentTime.tv_sec *1000000 + currentTime.tv_usec - inst_start_time;
  inst_over_time = inst_over_time / 1000000;
  double inst_frequency = (double)total_inst_num / (double)inst_over_time;
  double IPC = (double)total_inst_num / (double)total_cycle;

  if( (!top->x10 && top->ebreak) || (npc_stop)){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN),verilog_pc);
    Log("total guest instructions = %d, total cycle = %ld, IPC = %.2f " ,total_inst_num ,total_cycle,IPC);
    //Log("simulation frequency = %d inst/s, total time: %ld s \n" ,inst_frequency ,inst_over_time );
  }
  else if ( top->ebreak && top->x10 != 0 ){
    Log("npc = %s at pc = 0x%x" ,ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED),verilog_pc);
    Log("total guest instructions = %ld, total cycle = %ld" , total_inst_num,total_cycle); 
    #ifdef CONFIG_ITRACE 
      printIringbuf(iringbuf);
    #endif
  }
  else if( dut_find_difftest ){
    printf("verilog_pc = %x , total_cycle = %x\n" ,verilog_pc ,total_cycle);
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

