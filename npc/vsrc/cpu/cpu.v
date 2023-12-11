//`include <defines.v>
`define ysyx_22050854_FLASH_START_ADDR 32'h30000000
`define ysyx_22050854_FLASH_END_ADDR 32'h37ffffff
`define ysyx_22050854_MEMORY_START_ADDR 32'h80000000

`ifdef SOC_SIMULATION
`define ysyx_22050854_MEMORY_END_ADDR 32'hfbffffff
`define ysyx_22050854_START_PC 32'h30000000
`else
`define ysyx_22050854_MEMORY_END_ADDR 32'h87ffffff
`define ysyx_22050854_START_PC 32'h80000000
`endif

`define FLASH_AXI4_ID 4'b0000
`define Dcache_AXI4_ID 4'b0001
`define Device_AXI4_ID 4'b0010
`define Icache_AXI4_ID 4'b0011
module ysyx_22050854 (
    input clock,
    input reset,
    input io_interrupt,
    input io_master_awready,
    output io_master_awvalid, 
    output [3:0] io_master_awid, 
    output [31:0] io_master_awaddr, 
    output [7:0] io_master_awlen,
    output [2:0] io_master_awsize,
    output [1:0] io_master_awburst,
    input io_master_wready,
    output  io_master_wvalid,
    output [63:0] io_master_wdata,
    output [7:0] io_master_wstrb,
    output  io_master_wlast,
    output  io_master_bready,
    input  io_master_bvalid,
    input [3:0] io_master_bid,
    input [1:0] io_master_bresp,
    input  io_master_arready,
    output  io_master_arvalid,
    output [3:0] io_master_arid,
    output [31:0] io_master_araddr,
    output [7:0] io_master_arlen,
    output [2:0] io_master_arsize,
    output [1:0] io_master_arburst,
    output  io_master_rready,
    input  io_master_rvalid,
    input [3:0] io_master_rid,
    input [1:0] io_master_rresp,
    input [63:0] io_master_rdata,
    input  io_master_rlast,
    output io_slave_awready,
    input  io_slave_awvalid, 
    input [3:0] io_slave_awid, 
    input [31:0] io_slave_awaddr, 
    input [7:0] io_slave_awlen,
    input [2:0] io_slave_awsize,
    input [1:0] io_slave_awburst,
    output io_slave_wready,
    input  io_slave_wvalid,
    input [63:0] io_slave_wdata,
    input [7:0] io_slave_wstrb,
    input  io_slave_wlast,
    input  io_slave_bready,
    output  io_slave_bvalid,
    output [3:0] io_slave_bid,
    output [1:0] io_slave_bresp,
    output  io_slave_arready,
    input  io_slave_arvalid,
    input [3:0] io_slave_arid,
    input [31:0] io_slave_araddr,
    input [7:0] io_slave_arlen,
    input [2:0] io_slave_arsize,
    input [1:0] io_slave_arburst,
    input  io_slave_rready,
    output  io_slave_rvalid,
    output [3:0] io_slave_rid,
    output [1:0] io_slave_rresp,
    output [63:0] io_slave_rdata,
    output  io_slave_rlast,
    output [5:0] io_sram0_addr,
    output  io_sram0_cen,
    output  io_sram0_wen,
    output [127:0] io_sram0_wmask,
    output [127:0] io_sram0_wdata,
    input [127:0] io_sram0_rdata,
    output [5:0] io_sram1_addr,
    output  io_sram1_cen,
    output  io_sram1_wen,
    output [127:0] io_sram1_wmask,
    output [127:0] io_sram1_wdata,
    input [127:0] io_sram1_rdata,
    output [5:0] io_sram2_addr,
    output  io_sram2_cen,
    output  io_sram2_wen,
    output [127:0] io_sram2_wmask,
    output [127:0] io_sram2_wdata,
    input [127:0] io_sram2_rdata,
    output [5:0] io_sram3_addr,
    output  io_sram3_cen,
    output  io_sram3_wen,
    output [127:0] io_sram3_wmask,
    output [127:0] io_sram3_wdata,
    input [127:0] io_sram3_rdata,
    output [5:0] io_sram4_addr,
    output  io_sram4_cen,
    output  io_sram4_wen,
    output [127:0] io_sram4_wmask,
    output [127:0] io_sram4_wdata,
    input [127:0] io_sram4_rdata,
    output [5:0] io_sram5_addr,
    output  io_sram5_cen,
    output  io_sram5_wen,
    output [127:0] io_sram5_wmask,
    output [127:0] io_sram5_wdata,
    input [127:0] io_sram5_rdata,
    output [5:0] io_sram6_addr,
    output  io_sram6_cen,
    output  io_sram6_wen,
    output [127:0] io_sram6_wmask,
    output [127:0] io_sram6_wdata,
    input [127:0] io_sram6_rdata,
    output [5:0] io_sram7_addr,
    output  io_sram7_cen,
    output  io_sram7_wen,
    output [127:0] io_sram7_wmask,
    output [127:0] io_sram7_wdata,
    input [127:0] io_sram7_rdata
); 
    //No use, set 0
    assign io_slave_awready = 1'b0;
    assign io_slave_wready = 1'b0;
    assign io_slave_bvalid = 1'b0;
    assign io_slave_bid = 4'b0;
    assign io_slave_bresp = 2'b0;
    assign io_slave_arready = 1'b0;
    assign io_slave_rvalid = 1'b0;
    assign io_slave_rid = 4'b0;
    assign io_slave_rresp = 2'b0;
    assign io_slave_rdata = 64'b0;
    assign io_slave_rlast = 1'b0;

    wire rst_n;
    assign rst_n = ~reset;

    //-------------------------------------- IFU --------------------------------------------------------//
    //when IFU_suspend 1->0. the instruction is already at IDreg
    reg [31:0]pc_test;
    always @(posedge clock)begin
        if(reset)
            pc_test <= `ysyx_22050854_START_PC;
/*      
        else if( ( next_pc == 32'h80000000 )  &&  IDreg_valid )  //For Soc simulation
            pc_test <= 32'h80000004; 
*/
        else if( jump | Data_Conflict_block | last_JumpAndDataBlock ) //If find jump, Datablock or last cycle is jumpAndDatablock
            pc_test <= next_pc + 32'd4;
        else if( last_Suspend_LSU & ~Suspend_LSU )begin  //When LSU suspend over and no other exception
            pc_test <= EXEreg_pc + 32'd8;
        end
        else if ( last_Suspend_IFU & ~Suspend_IFU & IFUsuspend_with_Others ) begin //While IFU suspend over and no other Exception   //当IFU从暂停到结束且 期间没发生其他异常 共五组异常 有跳转，阻塞，阻塞且跳转，ALU提前结束暂停，LSU提前结束暂停
            pc_test <= next_pc + 32'd4;
        end
        else if( Last_Jump_Suspend & ~Suspend_IFU)begin      //While IFU suspend, find jump
            pc_test <= PC_Jump_Suspend + 32'd4;
            Last_Jump_Suspend <= 1'b0;
        end
        else if( Last_DataBlock_Suspend & ~Suspend_IFU)begin   //While IFU suspend, find Datablock
            pc_test <= PC_DataBlock_Suspend + 32'd4;
            Last_DataBlock_Suspend <= 1'b0;
        end
        else if( Last_JumpAndBlock_Suspend & ~Suspend_IFU)begin  //While IFU suspend, find JumpandDatablock
            pc_test <= PC_JumpAndBlock_Suspend + 32'd4;
            Last_JumpAndBlock_Suspend <= 1'b0;
        end
        else if( last_Suspend_ALU & ~Suspend_ALU & ~Suspend_IFU )begin  //While IFU suspend, find ALU suspend, And when ALU suspend over, IFU suspend already over
            pc_test <= EXEreg_pc + 32'd8;
            Last_ALUsuspend_IFUsuspend <= 1'b0;   //***
        end
        else if( Last_ALUsuspend_IFUsuspend & ~Suspend_IFU)begin  //While IFU suspend, find ALU suspend, And When ALU suspend over, IFU suspend still exist. This must prior ALU over
            pc_test <= PC_ALUsuspend_IFUsuspend + 32'd4;
            Last_ALUsuspend_IFUsuspend <= 1'b0;
        end
        else if( Last_LSU_IFU_Suspend & ~Suspend_IFU)begin  //While IFU suspend, find LSU suspend, when LSU suspend over, IFU suspend still exist
            pc_test <= PC_LSU_IFU_Suspend + 32'd4;
            Last_LSU_IFU_Suspend <= 1'b0;
        end
        else if( ~Suspend_IFU )  //&& Fench_from_mem (Soc Simulation)
            pc_test <= pc_test + 32'd4;
    end

    //如果译码阶段发现是jump 但不阻塞 则可根据next_pc取指 
    //如果译码阶段发现阻塞 但不是jump 则可根据next_pc取指 因为pc_test早两拍 而此后第一拍取到的指令不变 第二拍无效
    //如果译码阶段发现既是jump又是阻塞，则不能取指，因为阻塞产生的jump并不准确 (取指的有效信号为0)
    //如果上周期既是jump又是阻塞，则可以取指，因为本周期能计算出是否真正jump (arvalid_n_t)
    //如果ALU发起了暂停，则下周期不取指，直到暂停取消 (t)
    //如果IFU发起暂停，然后暂停取消后，指令已经放到了IDreg，根据译码出来的next_pc取指即可
    //如果在译码阶段发现是jump且此时IFU发起了暂停，则需要记录正确的PC，并在IFU的暂停结束后重新取指
    //如果在译码阶段发现是 单纯的数据阻塞，且此时IFU发起了暂停，则没关系，直接等取回来就好
    //如果在译码阶段发现是 跳转的数据阻塞 则会等待一周期，之后判断是否为跳转 在等待的这一阶段不会发生取指 
    //如果在执行阶段需要暂停，且此时IFU发起了暂停
    reg [31:0]pc_real;
    always @(*)begin
        if(reset)
            pc_real = `ysyx_22050854_START_PC;
/*            
        else if( ( next_pc == `ysyx_22050854_MEMORY_START_ADDR )  &&  IDreg_valid ) // must before FLASH_PC
            pc_real = `ysyx_22050854_MEMORY_START_ADDR + 32'h4;
        else if( ( Flash_PC >= 32'h30000000 ) && ( Flash_PC <= 32'h3fffffff ) ) 
            pc_real = Flash_PC; 
*/
        else if( jump | Data_Conflict_block | last_JumpAndDataBlock )
            pc_real = next_pc;
        else if( last_Suspend_LSU & ~Suspend_LSU )
            pc_real = EXEreg_pc + 32'd4;
        else if( last_Suspend_IFU & !Suspend_IFU & IFUsuspend_with_Others ) //当SuspendLSU为0时，指令刚好进入IDreg
            pc_real = next_pc;
        else if(  Last_Jump_Suspend & ~Suspend_IFU)
            pc_real = PC_Jump_Suspend;
        else if( Last_DataBlock_Suspend & ~Suspend_IFU)
            pc_real = PC_DataBlock_Suspend;
        else if( Last_JumpAndBlock_Suspend & ~Suspend_IFU)
            pc_real = PC_JumpAndBlock_Suspend;
        else if( last_Suspend_ALU & ~Suspend_ALU )
            pc_real = EXEreg_pc + 32'd4;
        else if( Last_ALUsuspend_IFUsuspend & ~Suspend_IFU)
            pc_real = PC_ALUsuspend_IFUsuspend;
        else if( Last_LSU_IFU_Suspend & ~Suspend_IFU )
            pc_real = PC_LSU_IFU_Suspend;
        else
            pc_real = pc_test; 
    end

    wire Fench_from_mem;
    wire Fench_from_flash;
    assign Fench_from_mem = ( Flash_PC >= `ysyx_22050854_MEMORY_START_ADDR && Flash_PC <= `ysyx_22050854_MEMORY_END_ADDR );
    assign Fench_from_flash = ( Flash_PC >= `ysyx_22050854_FLASH_START_ADDR && Flash_PC <= `ysyx_22050854_FLASH_END_ADDR );

    reg First_Flash_inst;
    reg IFU_Flash_valid;
    always @(posedge clock)begin
        if(reset)begin
            IFU_Flash_valid <= 1'b0;
            First_Flash_inst <= 1'b1;
        end
        else if( ( ( WBreg_valid || EXEreg_handle_interrupt)  && Fench_from_flash ) || First_Flash_inst ) begin
            IFU_Flash_valid <= 1'b0; //1'b1
            First_Flash_inst <= 1'b0;
        end
        else begin
            IFU_Flash_valid <= 1'b0;
            First_Flash_inst <= 1'b0;
        end
    end

    reg [31:0]Flash_PC;
    always @(posedge clock)begin
        if(reset)
            Flash_PC <= `ysyx_22050854_FLASH_START_ADDR;
        else if( IDreg_valid )
            Flash_PC <= next_pc;
    end

//IFU暂停时发生的异常，用于无效IFU取消暂停后的指令，并且指示下一个PC

    //如果发现jump的时候 IFU没有命中 那么原先的置后两个周期的指令无效不起作用
    //需要等到IFU取到指令无效（具体周期不确定），定义以下寄存器来确定
    reg [31:0]PC_Jump_Suspend;
    reg Last_Jump_Suspend;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg0 (clock, reset, next_pc, PC_Jump_Suspend, jump & Suspend_IFU & ~last_JumpAndDataBlock);
    ysyx_22050854_Reg #(1,1'b0) Inst_Reg1 (clock, reset, 1'b1, Last_Jump_Suspend, jump & Suspend_IFU & ~last_JumpAndDataBlock);

    //如果发现Datablock的时候 且该指令的第二个指令IFU没有命中 那么原先的置后两个周期的指令无效不起作用 且会损失一个指令
    //需要等到IFU取到指令无效（具体周期不确定），定义以下寄存器来确定
    reg [31:0]PC_DataBlock_Suspend;
    reg Last_DataBlock_Suspend;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg2 ( clock, reset, next_pc, PC_DataBlock_Suspend, Data_Conflict_block & ~JumpAndDataBlock & Suspend_IFU );
    ysyx_22050854_Reg #(1,1'b0) Inst_Reg3 ( clock, reset, 1'b1, Last_DataBlock_Suspend, Data_Conflict_block & ~JumpAndDataBlock & Suspend_IFU );

    //如果发现Datablock并且是跳转指令时，当前周期不保存，等下一周期不冲突后，再保存正确的跳转地址
    //并且当前周期不存在于DataBlock中，下一周期也不存在于jump中，保证标记的唯一性
    reg [31:0]PC_JumpAndBlock_Suspend;
    reg Last_JumpAndBlock_Suspend;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg4 ( clock, reset, next_pc, PC_JumpAndBlock_Suspend, last_JumpAndDataBlock & Suspend_IFU );
    ysyx_22050854_Reg #(1,1'b0) Inst_Reg5 ( clock, reset, 1'b1, Last_JumpAndBlock_Suspend, last_JumpAndDataBlock & Suspend_IFU );

    //如果ALU发起暂停的时候 IFU没有命中,正在寻找，而在ALU结束暂停之后，IFU取到指令，那么这个指令应当无效,当之前的逻辑只是ALU暂停时无效
    //应该记录下来ALU暂停且IFU也暂停时的指令，等到IFU结束暂停之后，用这个指令取指
    reg [31:0]PC_ALUsuspend_IFUsuspend;
    reg Last_ALUsuspend_IFUsuspend;
    always @(posedge clock)begin
        if(reset)
        begin
            Last_ALUsuspend_IFUsuspend <= 1'b0;
            PC_ALUsuspend_IFUsuspend <= 32'h80000000;
        end
        else if(Suspend_ALU & Suspend_IFU)begin
            Last_ALUsuspend_IFUsuspend <= 1'b1;
            PC_ALUsuspend_IFUsuspend  <= EXEreg_pc + 32'd4;
            if(Last_DataBlock_Suspend)
                Last_DataBlock_Suspend <= 1'b0;     //*** 如果有DtaBlock，要置0 不然会重复
        end
    end

    //如果IFU和LSU同时发起暂停，但是LSU提前结束暂停，那么需要记录一个触发器使其在IFU取消暂停后令取到的指令无效，并使用使LSU暂停的指令的下一条指令作为PC
    //但是如果LSU比IFU提前一个周期结束，这个就不管用了,所以我又加了一个不是Data_ok的选项 这样IFU结束暂停后得到的信号依然有效，但是不会生成last信号
    reg [31:0]PC_LSU_IFU_Suspend;
    reg Last_LSU_IFU_Suspend;
    ysyx_22050854_Reg #(32,32'b0) Inst_Reg6 ( clock, reset, EXEreg_pc + 32'd4, PC_LSU_IFU_Suspend, last_Suspend_LSU & ~Suspend_LSU & Suspend_IFU & ~Icache_data_ok); 
    ysyx_22050854_Reg #(1,1'b0) Inst_Reg7 ( clock, reset, 1'b1, Last_LSU_IFU_Suspend, last_Suspend_LSU & ~Suspend_LSU & Suspend_IFU & ~Icache_data_ok );

//

    reg [31:0]pc_record_1;
    reg [31:0]pc_record_2;
    always@(posedge clock)begin
        if(reset)
            pc_record_1 <= 32'b0;
        else 
            pc_record_1 <= pc_real; 
    end
    always@(posedge clock)begin
        if(reset)
            pc_record_2 <= 32'b0;
        else if( Icache_addr_ok )
            pc_record_2 <= pc_record_1;
    end

    wire [31:0]pc_record;
    assign pc_record = jump ? next_pc : pc_record_2;

    //如果当前周期下是jalr 或者 beq指令 且发生了阻塞，则无法产生正确的next_pc,本周期不取指
    wire JumpAndDataBlock;
    assign JumpAndDataBlock = ( ( IDreg_inst[6:0] == 7'b1100011) | (IDreg_inst[6:0]) == 7'b1100111) & Data_Conflict_block;
    reg last_JumpAndDataBlock;
    ysyx_22050854_Reg #(1,1'b0) jumpandblock (clock, reset, JumpAndDataBlock, last_JumpAndDataBlock, 1'b1);
    reg last_Suspend_ALU;
    ysyx_22050854_Reg #(1,1'b0) record_lastSuspend (clock, reset, Suspend_ALU, last_Suspend_ALU, 1'b1);
    reg last_Suspend_IFU;
    ysyx_22050854_Reg #(1,1'b0) record_last_Suspend_IFU (clock, reset, Suspend_IFU, last_Suspend_IFU, 1'b1);
    reg last_Suspend_LSU;
    ysyx_22050854_Reg #(1,1'b0) record_last_Suspend_LSU (clock, reset, Suspend_LSU, last_Suspend_LSU, 1'b1);


    wire SuspendCPU;
    assign SuspendCPU = Suspend_ALU | Suspend_IFU | Suspend_LSU;
    reg IFU_Icache_valid;
    always @(*)begin
        if(reset)
            IFU_Icache_valid = 1'b0;
        else
            IFU_Icache_valid = ~JumpAndDataBlock & ~SuspendCPU ; //( Fench_from_mem | ( pc_real == 32'h80000000 && WBreg_valid ) );  // IF Soc simulation, use Fench_from_mem
    end
    wire [6:0]Icache_index;
    wire [20:0]Icache_tag;
    wire [3:0]Icache_offset;
    assign Icache_offset = pc_real[3:0];
    assign Icache_tag = pc_real[31:11];
    assign Icache_index = pc_real[10:4];
    wire Icache_addr_ok;
    wire Icache_data_ok;
    wire [63:0]Icache_ret_data;
    wire Suspend_IFU;

    wire AXI_Icache_rd_req;
    wire [31:0]AXI_Icache_rd_addr;
    wire AXI_Icache_ret_valid;
    wire AXI_Icache_ret_last;
    wire [63:0]AXI_Icache_ret_data;
    assign AXI_Icache_ret_valid = io_master_rvalid && ( io_master_rid == `Icache_AXI4_ID ); // && ( io_master_rresp  == 2'b10 ) ;
    assign AXI_Icache_ret_last = io_master_rlast;
    assign AXI_Icache_ret_data = io_master_rdata;
    ysyx_22050854_Icache icache_inst(
        .clock(clock),
        .reset(reset),
        .valid(IFU_Icache_valid),
        .op(1'b0), 
        .index(Icache_index),
        .tag(Icache_tag), 
        .offset(Icache_offset), 
        .addr_ok(Icache_addr_ok), 
        .data_ok(Icache_data_ok),
        .rdata(Icache_ret_data),
        .unshoot(Suspend_IFU),

        .rd_req(AXI_Icache_rd_req), 
        .rd_addr(AXI_Icache_rd_addr),
        .rd_rdy(1'b1),
        .ret_valid(AXI_Icache_ret_valid),
        .ret_last(AXI_Icache_ret_last),
        .ret_data(AXI_Icache_ret_data),

        .sram0_addr(io_sram0_addr),
        .sram0_cen(io_sram0_cen),
        .sram0_wen(io_sram0_wen),
        .sram0_wmask(io_sram0_wmask),
        .sram0_wdata(io_sram0_wdata),
        .sram0_rdata(io_sram0_rdata),

        .sram1_addr(io_sram1_addr),
        .sram1_cen(io_sram1_cen),
        .sram1_wen(io_sram1_wen),
        .sram1_wmask(io_sram1_wmask),
        .sram1_wdata(io_sram1_wdata),
        .sram1_rdata(io_sram1_rdata),

        .sram2_addr(io_sram2_addr),
        .sram2_cen(io_sram2_cen),
        .sram2_wen(io_sram2_wen),
        .sram2_wmask(io_sram2_wmask),
        .sram2_wdata(io_sram2_wdata),
        .sram2_rdata(io_sram2_rdata),

        .sram3_addr(io_sram3_addr),
        .sram3_cen(io_sram3_cen),
        .sram3_wen(io_sram3_wen),
        .sram3_wmask(io_sram3_wmask),
        .sram3_wdata(io_sram3_wdata),
        .sram3_rdata(io_sram3_rdata)
    );

    wire AXI_Flash_ret_valid;
    wire [31:0]inst_from_flash;
    assign AXI_Flash_ret_valid = io_master_rvalid && io_master_rlast && ( io_master_rid == `FLASH_AXI4_ID );
    assign inst_from_flash = io_master_rdata[31:0];
    wire [63:0]inst_64;
    wire [31:0]inst;
    assign inst_64 = (Icache_data_ok == 1'b1) ? Icache_ret_data : 64'h6666666666666666;
    assign inst = Icache_data_ok ? ( ( pc_record_2[2:0] == 3'b000 ) ? inst_64[31:0] : inst_64[63:32] ) : ( AXI_Flash_ret_valid ? inst_from_flash : 32'b0 );

    //---------------------------------------------                      ID_reg                             -----------------------------------------//
    reg IDreg_valid;
    reg [31:0]IDreg_inst;
    reg [31:0]IDreg_pc;
    wire IDreg_inst_enable;
    wire IDreg_pc_enable;
    //如果更新前发现需要阻塞，就不更新了 如果ALU发起了暂停，IDreg也应该保持不变 //后来改了，ALU结束后重新取指，不过改不改不影响
    assign IDreg_inst_enable = ( Icache_data_ok & (~Data_Conflict_block) & ~Suspend_ALU ) | AXI_Flash_ret_valid; 
    assign IDreg_pc_enable = ( Icache_data_ok & (~Data_Conflict_block) & ~Suspend_ALU ) | AXI_Flash_ret_valid;
    wire IFUsuspend_with_Others;
    assign IFUsuspend_with_Others = (~Last_Jump_Suspend) & (~Last_DataBlock_Suspend) & (~Last_ALUsuspend_IFUsuspend) & (~Last_JumpAndBlock_Suspend) & ~Last_LSU_IFU_Suspend;
    always@(posedge clock)begin
        if(reset)
            IDreg_valid <= 1'b0;
        else
            IDreg_valid <=  ( Icache_data_ok & (~jump) & (~EXEreg_jump) & (~EXEreg_Datablock) & (~Suspend_ALU) & IFUsuspend_with_Others & ~Suspend_LSU ) | Data_Conflict_block | AXI_Flash_ret_valid;
    end                                                                                                          

    ysyx_22050854_Reg #(32,32'b0) IDreg_gen0 (clock, (reset), inst, IDreg_inst, IDreg_inst_enable);
    always @(posedge clock)begin
        if(reset)
            IDreg_pc <= 32'h0;
        else if(IDreg_pc_enable && Icache_data_ok)
            IDreg_pc <= pc_record;
        else if(IDreg_pc_enable && AXI_Flash_ret_valid)
            IDreg_pc <= Flash_PC;
    end

    //----------------------------------          ID           -----------------------//
    wire [4:0]rs1,rs2;
    wire [4:0]rd;
    wire [2:0]ExtOP;
    wire RegWr;
    wire [2:0]Branch;
    wire No_branch;
    wire MemtoReg;
    wire MemWr;
    wire MemRd;
    wire [2:0]MemOP;
    wire ALUsrc1;
    wire [1:0]ALUsrc2;
    wire [3:0]ALUctr;
    wire [2:0]ALUext;
    wire [3:0]MULctr;
    ysyx_22050854_IDU instr_decode(
        .instr(IDreg_inst),
        .rs1(rs1),                          
        .rs2(rs2),
        .rd(rd),
        .ExtOP(ExtOP),
        .RegWr(RegWr),
        .Branch(Branch),
        .No_branch(No_branch),
        .MemtoReg(MemtoReg),
        .MemWr(MemWr),
        .MemRd(MemRd),
        .MemOP(MemOP),
        .ALUsrc1(ALUsrc1),
        .ALUsrc2(ALUsrc2),
        .ALUctr(ALUctr),
        .ALUext(ALUext),
        .MULctr(MULctr)     
    );   

    wire [63:0]imm;
    ysyx_22050854_imm_gen gen_imm(
    .instr(IDreg_inst),
    .ExtOP(ExtOP),
    .imm(imm)
);

    wire [63:0]src1;
    wire [63:0]src2;
    ysyx_22050854_RegisterFile regfile_inst(
    .clock(clock),
    .wdata(wr_reg_data),
    .waddr(WBreg_rd),
    .wen(WBreg_regwr & WBreg_valid),
    .raddra(rs1),
    .raddrb(rs2),
    .rdata1(src1),
    .rdata2(src2)  
    );

    wire [63:0]alu_src1;
    wire [63:0]alu_src2;
    ysyx_22050854_src_gen gen_src(
        .ALUsrc1(ALUsrc1),
        .ALUsrc2(ALUsrc2),
        .pc(IDreg_pc),
        .imm(imm),
        .src1(New_src1),
        .src2(New_src2),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2)
    );

    //-------------------------------------  CSR 相关 ----------------------------------------------//
    //CSR 读控制字
    wire CSRrd;
    wire CSR_read;
    assign CSRrd = ( IDreg_inst[6:0] == 7'b1110011 | handle_timer_intr ) ? (Insrtuction_ebreak ? 1'b0 : 1'b1) : 1'b0; //ebreak not read
    assign CSR_read = CSRrd & IDreg_valid & ~Suspend_ALU & ~Suspend_LSU & ~Data_Conflict_block;
    //CSR 读寄存器地址
    wire [11:0]csr_raddr;
    assign csr_raddr = ( Insrtuction_ecall | handle_timer_intr ) ? 12'h305 : ( Insrtuction_mret ? 12'h341 : IDreg_inst[31:20] ); //ecall-mtvec(305) mret-mepc(341)

    //CSR 写控制字
    wire CSRwr1;
    wire CSRwr2;
    wire CSRwr_t;
    wire CSR_Write1;
    wire CSR_Write2;
    assign CSRwr_t = ( IDreg_inst[6:0] == 7'b1110011 ) && ( IDreg_inst[14:12] != 3'b000 ); //bug: 100 

    assign CSRwr1 = ( Insrtuction_ecall | handle_timer_intr ) ? 1'b1 : CSRwr_t; //mret and ebreak
    assign CSRwr2 = ( Insrtuction_ecall | handle_timer_intr ) ? 1'b1 : 1'b0;   //only ecall/time_intr need to write two csr
    assign CSR_Write1 = CSRwr1 & IDreg_valid & ~Suspend_ALU & ~Suspend_LSU & ~Data_Conflict_block;
    assign CSR_Write2 = CSRwr2 & IDreg_valid & ~Suspend_ALU & ~Suspend_LSU & ~Data_Conflict_block;
    //CSR   写地址
    wire [11:0]csr_waddr1,csr_waddr2;
    assign csr_waddr1 = ( Insrtuction_ecall | handle_timer_intr ) ? 12'h341 : IDreg_inst[31:20]; //if ecall, mepc
    assign csr_waddr2 = ( Insrtuction_ecall | handle_timer_intr ) ? 12'h342 : IDreg_inst[31:20]; //if ecall, mcause
    //写数据
    wire [63:0]csr_wdata1,csr_wdata2;
    reg [63:0]csrwdata_t;

    always @(*) begin
        if(reset)
            csrwdata_t = 64'd0;
        else begin
            case({IDreg_valid,IDreg_inst[14:12],IDreg_inst[6:0]})
                11'b10011110011: csrwdata_t = New_src1;
                11'b10101110011: csrwdata_t = csr_rdata | New_src1;
                11'b10111110011: csrwdata_t = csr_rdata & ~New_src1;
                11'b11011110011: csrwdata_t = {59'd0,IDreg_inst[19:15]};
                11'b11101110011: csrwdata_t = csr_rdata | {59'd0,IDreg_inst[19:15]};
                11'b11111110011: csrwdata_t = csr_rdata & ~{59'd0,IDreg_inst[19:15]};
                default: csrwdata_t = 64'd0;
            endcase    
        end
    end
    assign csr_wdata1 = ( Insrtuction_ecall | handle_timer_intr ) ? ( { 32'd0, IDreg_pc } ) : csrwdata_t; //ecall->mepc
    assign csr_wdata2 = handle_timer_intr ? 64'h8000000000000007 : Insrtuction_ecall ? 64'd11 :  64'h0;  //ecall->mcause

    wire Insrtuction_mret;
    wire Insrtuction_ecall;
    wire Insrtuction_ebreak; 
    assign Insrtuction_mret = ( IDreg_inst == 32'h30200073 ) && IDreg_valid;  //mret need wirte mtatus
    assign Insrtuction_ecall = ( IDreg_inst == 32'h73 ) && IDreg_valid;
    assign Insrtuction_ebreak = ( ( WBreg_inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011 ) &  WBreg_valid ) ? 1'b1 : 1'b0;
    wire [63:0]csr_rdata;
    wire timer_interrupt;
    ysyx_22050854_CSRegister CSRfile_inst (
    .clock(clock),
    .reset(reset),
    .waddr1(csr_waddr1),
    .waddr2(csr_waddr2),
    .wdata1(csr_wdata1),
    .wdata2(csr_wdata2),
    .mret(Insrtuction_mret),
    .ecall(Insrtuction_ecall),
    .wen(CSR_Write1),
    .wen2(CSR_Write2),
    .ren(CSR_read),
    .raddr(csr_raddr),
    .mtime_bigger_mtimecmp(mtime_bigger_mtimecmp),
    .rdata(csr_rdata),
    .timer_interrupt(timer_interrupt),
    .handle_timer_intr(handle_timer_intr)
    );
    
    wire CSR_gprRd;  //for conflict judge  CSR inst and read gpr
    assign CSR_gprRd = ( {IDreg_inst[14:12],IDreg_inst[6:0]} == 10'b0011110011 ) | ( {IDreg_inst[14:12],IDreg_inst[6:0]} == 10'b0101110011 ) | ( {IDreg_inst[14:12],IDreg_inst[6:0]} == 10'b0111110011 );

    //handle timer interrupt
    wire handle_timer_intr;
    //assign handle_timer_intr = 1'b0;
    assign handle_timer_intr = timer_interrupt && IDreg_valid && ~Suspend_ALU && ~Suspend_LSU & ~Data_Conflict_block;  //only when IDreg_valid can handle timer_interrupt

    //-------------------       判断数据冲突       --------------------------------//
    wire rs1_conflict_EXE;
    wire rs2_conflict_EXE;
    wire reg_Conflict_EXE;
    wire store_conflict_EXE; //还有一种冲突是当store指令的源操作数(要写入内存的数据)与之前指令的目的寄存器重合时（如ld 之后 sd / add 之后 sd）
    wire ret_conflict_EXE;
    assign rs1_conflict_EXE = (( ALUsrc1 == 1'b0 ) & ( rs1 == EXEreg_Rd ) & ( EXEreg_Rd != 0)); //当且仅当alu操作数是寄存器，且前一条指令要写回， 且写回地址不是x0时 ,rd = rs 才冲突
    assign rs2_conflict_EXE = (( ALUsrc2 == 2'b00 ) & ( rs2 == EXEreg_Rd) & ( EXEreg_Rd != 0));
    assign reg_Conflict_EXE = IDreg_valid & EXEreg_valid & EXEreg_regWr  & ( rs1_conflict_EXE | rs2_conflict_EXE ); //与前一条指令冲突
    assign store_conflict_EXE = IDreg_valid & MemWr & (rs2 == EXEreg_Rd) & (EXEreg_Rd != 0) & (EXEreg_valid) & (EXEreg_regWr);
    assign ret_conflict_EXE = IDreg_valid & (IDreg_inst[6:0] == 7'b1100111) & (rs1 == EXEreg_Rd) & EXEreg_regWr & EXEreg_valid & (EXEreg_Rd != 0);

    wire rs1_conflict_MEM;
    wire rs2_conflict_MEM;
    wire reg_Conflict_MEM;
    wire store_conflict_MEM;
    wire ret_conflict_MEM;
    assign rs1_conflict_MEM = (( ALUsrc1 == 1'b0 ) & ( rs1 == MEMreg_rd) & (MEMreg_rd != 0));
    assign rs2_conflict_MEM = (( ALUsrc2 == 2'b00) & ( rs2 == MEMreg_rd) & (MEMreg_rd != 0));
    assign reg_Conflict_MEM = IDreg_valid & MEMreg_valid & MEMreg_regwr & (rs1_conflict_MEM | rs2_conflict_MEM); //与前两条指令冲突
    assign store_conflict_MEM = IDreg_valid & MemWr & (rs2 == MEMreg_rd) & (MEMreg_rd != 0) & (MEMreg_valid) & (MEMreg_regwr);
    assign ret_conflict_MEM = IDreg_valid & (IDreg_inst[6:0] == 7'b1100111) & (rs1 == MEMreg_rd) & MEMreg_regwr & MEMreg_valid & (MEMreg_rd != 0);

    wire rs1_conflict_WB;
    wire rs2_conflict_WB;
    wire ret_conflict_WB;
    wire reg_Conflict_WB;
    wire store_conflict_WB;
    wire ret_conflict_WB;
    //按理说内存数据冲突 应该不会发生在这，因为发现冲突后的上升沿就写回数据了，而此时当前指令刚发起访问请求
    assign rs1_conflict_WB = (( ALUsrc1 == 1'b0 ) & (rs1 == WBreg_rd) & (WBreg_rd != 0));
    assign rs2_conflict_WB = (( ALUsrc2 == 2'b00) & (rs2 == WBreg_rd) & (WBreg_rd != 0));
    assign reg_Conflict_WB = IDreg_valid & WBreg_valid & WBreg_regwr & ( rs1_conflict_WB | rs2_conflict_WB);   //与前三条指令冲突
    assign store_conflict_WB = IDreg_valid & MemWr & (rs2 == WBreg_rd) & (WBreg_rd != 0) & (WBreg_valid) & (WBreg_regwr);
    assign ret_conflict_WB = IDreg_valid & (IDreg_inst[6:0] == 7'b1100111) & (rs1 == WBreg_rd) & WBreg_regwr & WBreg_valid & (WBreg_rd != 0);

    wire CSRsrc1_conflict_EXE;
    wire CSRsrc1_conflict_MEM;
    wire CSRsrc1_conflict_WB;
    assign CSRsrc1_conflict_EXE = IDreg_valid & CSR_gprRd & (rs1 == EXEreg_Rd) & ( EXEreg_Rd != 0 ) & (EXEreg_valid) & (EXEreg_regWr);
    assign CSRsrc1_conflict_MEM = IDreg_valid & CSR_gprRd & (rs1 == MEMreg_rd) & ( MEMreg_rd != 0 ) & MEMreg_valid & MEMreg_regwr;
    assign CSRsrc1_conflict_WB = IDreg_valid & CSR_gprRd & (rs1 == WBreg_rd) & ( WBreg_rd != 0) & WBreg_valid & WBreg_regwr;
    //only ecall use src2
    wire CSRsrc2_conflict_EXE;
    wire CSRsrc2_conflict_MEM;
    wire CSRsrc2_conflict_WB;
    assign CSRsrc2_conflict_EXE = IDreg_valid & ( IDreg_inst == 32'h73 ) & (rs2 == EXEreg_Rd) & (EXEreg_valid) & (EXEreg_regWr);
    assign CSRsrc2_conflict_MEM = IDreg_valid & ( IDreg_inst == 32'h73 ) & (rs2 == MEMreg_rd) & (MEMreg_valid) & (MEMreg_regwr);
    assign CSRsrc2_conflict_WB = IDreg_valid & ( IDreg_inst == 32'h73 ) & (rs2 == WBreg_rd) & WBreg_valid & WBreg_regwr;
    wire CSRsrc_confilct_EXE;
    assign CSRsrc_confilct_EXE = CSRsrc1_conflict_EXE | CSRsrc2_conflict_EXE;

    //需要阻塞的情况
    wire Data_Conflict_block;
    assign Data_Conflict_block = ( reg_Conflict_EXE | store_conflict_EXE | ret_conflict_EXE | CSRsrc_confilct_EXE ) & EXEreg_memRd & ~Suspend_LSU; //目前是只有上一条指令是load的情况才需要阻塞

    wire src1_conflict_EXE;
    wire src1_conflict_MEM;
    wire src1_conflict_WB;
    assign src1_conflict_EXE = ( reg_Conflict_EXE & rs1_conflict_EXE ) | ret_conflict_EXE | CSRsrc1_conflict_EXE;
    assign src1_conflict_MEM = ( reg_Conflict_MEM & rs1_conflict_MEM ) | ret_conflict_MEM | CSRsrc1_conflict_MEM;
    assign src1_conflict_WB = ( reg_Conflict_WB & rs1_conflict_WB ) | ret_conflict_WB | CSRsrc1_conflict_WB;

    wire src2_conflict_EXE;
    wire src2_conflict_MEM;
    wire src2_conflict_WB;
    assign src2_conflict_EXE = ( reg_Conflict_EXE & rs2_conflict_EXE ) | store_conflict_EXE | CSRsrc2_conflict_EXE;
    assign src2_conflict_MEM = ( reg_Conflict_MEM & rs2_conflict_MEM ) | store_conflict_MEM | CSRsrc2_conflict_MEM;
    assign src2_conflict_WB = ( reg_Conflict_WB & rs2_conflict_WB ) | store_conflict_WB | CSRsrc2_conflict_WB;

    // --------------------------------         流水线前递          ----------------------------------//
    reg [63:0]New_src1;
    reg [63:0]New_src2;
    always @(*)begin
        if(reset)
            New_src1 = 64'b0;
        else if( src1_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            New_src1 = alu_out;
        else if( src1_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            New_src1 = EXEreg_CSRrdata; //****
        else if(src1_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            New_src1 = MEMreg_aluout;
        else if(src1_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            New_src1 = MEMreg_CSRrdata;
        else if(src1_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            New_src1 = MEMreg_read_CLINT ? MEMreg_CLINT_value : read_mem_data;
        else if( src1_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            New_src1 = WBreg_aluout;
        else if( src1_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            New_src1 = WBreg_CSRrdata;
        else if( src1_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            New_src1 = WBreg_read_CLINT ? WBreg_CLINT_value : WBreg_readmemdata; //keng  //**
        else                                                                        //不冲突
            New_src1 = src1;
    end

    always @(*)begin
        if(reset)
            New_src2 = 64'b0;
        else if( src2_conflict_EXE & (~EXEreg_memRd) & (~EXEreg_CSRrd) )  //与前一条冲突，且不是load,且不是CSRW
            New_src2 = alu_out;
        else if( src2_conflict_EXE & (~EXEreg_memRd) & EXEreg_CSRrd )  //与前一条冲突，且不是load,但是CSRW
            New_src2 = EXEreg_CSRrdata; //****
        else if(src2_conflict_MEM & (~MEMreg_memrd) & (~MEMreg_CSRrd) ) //与前二条冲突，且不是load,也不是CSRW
            New_src2 = MEMreg_aluout;
        else if(src2_conflict_MEM & (~MEMreg_memrd) & MEMreg_CSRrd ) //与前二条冲突，且不是load,但是CSRW
            New_src2 = MEMreg_CSRrdata;
        else if(src2_conflict_MEM & MEMreg_memrd & (~MEMreg_CSRrd) )  //与前二条冲突，且是load ,如果是load 还得判断这个ld指令是不是有内存数据冲突,---现在就算有也是放到读出数据一块得到了
            New_src2 = MEMreg_read_CLINT ? MEMreg_CLINT_value : read_mem_data;
        else if( src2_conflict_WB & (~WBreg_memRd) & (~WBreg_CSRrd) ) //与前三条冲突，且不是load,也不是CSR
            New_src2 = WBreg_aluout;
        else if( src2_conflict_WB & (~WBreg_memRd) & WBreg_CSRrd ) //与前三条冲突，且不是load,也不是CSR
            New_src2 = WBreg_CSRrdata;
        else if( src2_conflict_WB & WBreg_memRd & (~WBreg_CSRrd) ) //与前三条冲突，且是Load
            New_src2 = WBreg_read_CLINT ? WBreg_CLINT_value : WBreg_readmemdata; //keng
        else                                                                        //不冲突
            New_src2 = src2;
    end   

    //-------------- GEN readmemaddr -----------//在译码级就计算出load的地址
    wire [31:0]readmemaddr;
    assign readmemaddr = MemRd | MemWr ? ( alu_src1[31:0] + alu_src2[31:0] ) : 32'd0;

    wire Is_access_mem;
    assign Is_access_mem = (readmemaddr >= `ysyx_22050854_MEMORY_START_ADDR && readmemaddr <= `ysyx_22050854_MEMORY_END_ADDR ) ? 1'b1 : 1'b0;   // npc
    wire LSU_access_valid;
    assign LSU_access_valid =  ( MemRd | MemWr ) & IDreg_valid & ~Suspend_ALU & ~Suspend_LSU & ~Data_Conflict_block & ~handle_timer_intr;  //
    wire Data_cache_valid;
    assign Data_cache_valid =  LSU_access_valid & Is_access_mem;
    wire Data_cache_op;
    assign Data_cache_op = ( MemWr & IDreg_valid & ~Suspend_ALU & ~Data_Conflict_block );
    wire AXI_device_rd_req;
    assign AXI_device_rd_req = LSU_access_valid & MemRd & ~( Is_access_mem | Read_CLINT );
    wire AXI_device_wr_req;
    assign AXI_device_wr_req = LSU_access_valid  & MemWr & ~( Is_access_mem | Write_mtime | Write_mtimecmp );
    wire Read_mtime;
    wire Write_mtime;
    wire Read_mtimecmp;
    wire Write_mtimecmp;
    assign Read_mtime = LSU_access_valid && MemRd && ( readmemaddr == 32'h200BFF8 );
    assign Write_mtime = LSU_access_valid && MemWr && ( readmemaddr == 32'h200BFF8 );
    assign Read_mtimecmp = LSU_access_valid && MemRd && ( readmemaddr == 32'h2004000 );
    assign Write_mtimecmp = LSU_access_valid && MemWr && ( readmemaddr == 32'h2004000 );
    wire Read_CLINT;
    assign Read_CLINT = Read_mtime | Read_mtimecmp;

    // ---------- CLINT ----------//
    reg [63:0]mtime;
    reg [63:0]mtimecmp;
    reg [7:0]tick_count; //mtime self-increment frequency
    always @(posedge clock ) begin
        if(reset)
            tick_count <= 8'b0;
        else if( tick_count == 8'd10 )
            tick_count <= 8'b0;
        else
            tick_count <= tick_count + 8'd1;
    end
    always @(posedge clock) begin
        if(reset)
            mtime <= 64'b0;
        else if(Write_mtime)
            mtime <= New_src2;
        else if( tick_count == 8'd10 )
            mtime <= mtime + 64'd1;
    end
    always @(posedge clock) begin
        if(reset)
            mtimecmp <= 64'h10000;
        else if(Write_mtimecmp)
            mtimecmp <= New_src2;
    end
    wire mtime_bigger_mtimecmp;
    assign mtime_bigger_mtimecmp = ( mtime >= mtimecmp ) ? 1'b1 : 1'b0;
    wire [63:0]CLINT_value;
    assign CLINT_value = Read_mtime ? mtime : ( Read_mtimecmp ? mtimecmp : 64'b0 );

    //----------------- GEN PC -----------------//
    wire [31:0]next_pc;
    wire jump;
    wire ecall_or_mret;
    assign ecall_or_mret = ( IDreg_inst == 32'h73 || handle_timer_intr || IDreg_inst == 32'h30200073 ) ? 1'b1 : 1'b0; //ecall mret timer_interrupt
    ysyx_22050854_pc gen_pc(
    .reset(reset),
    .clock(clock),
    .IDreg_valid(IDreg_valid),
    .Data_Conflict(Data_Conflict_block),
    .suspend(Suspend_ALU | Suspend_LSU),
    .Branch(Branch),
    .No_branch(No_branch),
    .is_csr_pc(ecall_or_mret),
    .csr_pc(csr_rdata[31:0]),
    .unsigned_compare(ALUctr[3]),
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .src1(New_src1[31:0]),
    .imm(imm[31:0]),
    .jump(jump),
    .next_pc(next_pc)
    );

    //----------------------------------------------- EXE_reg ------------------------------------------------//
    reg EXEreg_valid;
    wire EXEreg_inst_enable;
    reg [31:0]EXEreg_inst;
    wire EXEreg_pc_enable;
    reg [31:0]EXEreg_pc;
    wire EXEreg_alusrc1_enable;
    reg [63:0]EXEreg_alusrc1;
    wire EXEreg_alusrc2_enable;
    reg [63:0]EXEreg_alusrc2;
    wire EXEreg_ALUctr_enable;
    reg [3:0]EXEreg_ALUctr;
    wire EXEreg_MULctr_enable;
    reg [3:0]EXEreg_MULctr;
    wire EXEreg_ALUext_enable;
    reg [2:0]EXEreg_ALUext;
    wire EXEreg_regWr_enable;
    reg EXEreg_regWr;
    wire EXEreg_Rd_enable;
    reg [4:0]EXEreg_Rd;
    wire EXEreg_memRd_enable;
    reg EXEreg_memRd;
    wire EXEreg_memop_enable;
    reg [2:0]EXEreg_memop;
    wire EXEreg_memtoreg_enable;
    reg EXEreg_memtoreg;
    wire EXEreg_jump_enable;
    reg EXEreg_jump;
    wire EXEreg_Datablock_enable;
    reg EXEreg_Datablock;
    wire EXEreg_CSRrd_enable;
    reg EXEreg_CSRrd;
    wire EXEreg_CSRrdata_enable;
    reg [63:0]EXEreg_CSRrdata;
    wire EXEreg_read_CLINT_enable;
    reg EXEreg_read_CLINT;
    reg [63:0]EXEreg_CLINT_value;
    reg EXEreg_handle_interrupt;

    //如果当前的ALU出现阻塞，则EXEreg不变，直到它计算完成
    assign EXEreg_inst_enable       =  ~Suspend_ALU & ~Suspend_LSU;  
    assign EXEreg_pc_enable         =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_alusrc1_enable    =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_alusrc2_enable    =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_ALUctr_enable     =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_MULctr_enable     =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_ALUext_enable     =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_regWr_enable      =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_Rd_enable         =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_memRd_enable      =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_memop_enable      =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_memtoreg_enable   =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_jump_enable       =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_Datablock_enable  =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_CSRrd_enable      =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_CSRrdata_enable   =  ~Suspend_ALU & ~Suspend_LSU;
    assign EXEreg_read_CLINT_enable =  ~Suspend_ALU & ~Suspend_LSU;
    
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen0 (clock, reset,( (IDreg_valid & (~Data_Conflict_block) & ~handle_timer_intr ) | Suspend_ALU | Suspend_LSU), EXEreg_valid, 1'b1);
    ysyx_22050854_Reg #(32,32'b0) EXEreg_geninst (clock, reset, IDreg_inst, EXEreg_inst, EXEreg_inst_enable);
    ysyx_22050854_Reg #(32,32'h0) EXEreg_genPC (clock, reset, IDreg_pc, EXEreg_pc, EXEreg_pc_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen1 (clock, reset, alu_src1, EXEreg_alusrc1, EXEreg_alusrc1_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen2 (clock, reset, alu_src2, EXEreg_alusrc2, EXEreg_alusrc2_enable);
    ysyx_22050854_Reg #(4,4'b1111) EXEreg_gen3 (clock, reset, ALUctr, EXEreg_ALUctr, EXEreg_ALUctr_enable);
    ysyx_22050854_Reg #(4,4'b0) EXEreg_gen4 (clock, reset, MULctr, EXEreg_MULctr, EXEreg_MULctr_enable);
    ysyx_22050854_Reg #(3,3'b0) EXEreg_gen5 (clock, reset, ALUext, EXEreg_ALUext, EXEreg_ALUext_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen6 (clock, reset, RegWr, EXEreg_regWr, EXEreg_regWr_enable);
    ysyx_22050854_Reg #(5,5'b0) EXEreg_gen7 (clock, reset, rd, EXEreg_Rd, EXEreg_Rd_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen9 (clock, reset, MemRd, EXEreg_memRd, EXEreg_memRd_enable);
    ysyx_22050854_Reg #(3,3'b0) EXEreg_gen10 (clock, reset, MemOP, EXEreg_memop, EXEreg_memop_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen11 (clock, reset, MemtoReg & ~Read_CLINT, EXEreg_memtoreg, EXEreg_memtoreg_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen13 (clock, reset, jump, EXEreg_jump, EXEreg_jump_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen14 (clock, reset, Data_Conflict_block, EXEreg_Datablock, EXEreg_Datablock_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen20 (clock, reset, CSR_read, EXEreg_CSRrd, EXEreg_CSRrd_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen21 (clock, reset, csr_rdata, EXEreg_CSRrdata, EXEreg_CSRrdata_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen22 (clock, reset, Read_CLINT, EXEreg_read_CLINT, EXEreg_read_CLINT_enable);
    ysyx_22050854_Reg #(64,64'b0) EXEreg_gen23 (clock, reset, CLINT_value, EXEreg_CLINT_value, EXEreg_read_CLINT_enable);
    ysyx_22050854_Reg #(1,1'b0) EXEreg_gen24 (clock, reset, handle_timer_intr, EXEreg_handle_interrupt, 1'b1);

    //------------ALU------------//
    wire Suspend_ALU;
    wire [63:0]alu_out;
    ysyx_22050854_alu alu1(
    .clock(clock),
    .reset(reset),
    .EXEreg_valid(EXEreg_valid),   
    .ALUctr(EXEreg_ALUctr),
    .MULctr(EXEreg_MULctr),
    .ALUext(EXEreg_ALUext),
    .src1(EXEreg_alusrc1),
    .src2(EXEreg_alusrc2),
    .alu_busy(Suspend_ALU),
    .alu_out(alu_out)
    );

    //--------------------------------------------- MEM_reg ---------------------------------------------//
    reg MEMreg_valid;
    reg [31:0]MEMreg_inst;
    reg [31:0]MEMreg_pc;
    reg [63:0]MEMreg_aluout;
    reg MEMreg_regwr;
    reg [4:0]MEMreg_rd;
    reg MEMreg_memrd;
    reg [2:0]MEMreg_memop;  //for get right data from 64bits data(from cache)
    reg MEMreg_memtoreg;
    reg MEMreg_CSRrd;
    reg [63:0]MEMreg_CSRrdata;
    reg MEMreg_read_CLINT;
    reg [63:0]MEMreg_CLINT_value;

    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen0 (clock, reset, ( EXEreg_valid & ~Suspend_ALU & ~Suspend_LSU ), MEMreg_valid, 1'b1); //如果ALU出现暂停信号，那么下周期MEMreg无效,如果LSU出现暂停，下周期MEMreg也无效
    ysyx_22050854_Reg #(32,32'b0) MEMreg_geninst (clock, reset, EXEreg_inst, MEMreg_inst, 1'b1);
    ysyx_22050854_Reg #(32,32'h0) MEMreg_genPC (clock, reset, EXEreg_pc, MEMreg_pc, 1'b1);  
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen1 (clock, reset, alu_out, MEMreg_aluout, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen2 (clock, reset, EXEreg_regWr, MEMreg_regwr, 1'b1);
    ysyx_22050854_Reg #(5,5'b0) MEMreg_gen3 (clock, reset, EXEreg_Rd, MEMreg_rd, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen5 (clock, reset, EXEreg_memRd, MEMreg_memrd, 1'b1);
    ysyx_22050854_Reg #(3,3'b0) MEMreg_gen6 (clock, reset, EXEreg_memop, MEMreg_memop, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen7 (clock, reset, EXEreg_memtoreg, MEMreg_memtoreg, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen8 (clock, reset, EXEreg_CSRrd, MEMreg_CSRrd, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen9 (clock, reset, EXEreg_CSRrdata, MEMreg_CSRrdata, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) MEMreg_gen10 (clock, reset, EXEreg_read_CLINT, MEMreg_read_CLINT, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) MEMreg_gen11 (clock, reset, EXEreg_CLINT_value, MEMreg_CLINT_value, 1'b1);
    
    wire [63:0] Dcache_ret_data;
    wire [6:0]Data_cache_index;
    wire [20:0]Data_cache_tag;
    wire [3:0]Data_cache_offset;
    assign Data_cache_offset = readmemaddr[3:0] ;
    assign Data_cache_index = readmemaddr[10:4];
    assign Data_cache_tag = readmemaddr[31:11];
    wire Data_cache_Data_ok;
    wire [7:0]Dcache_wr_wstb;
    assign Dcache_wr_wstb = MemOP == 3'b000 ? 8'b00000001 :
                            MemOP == 3'b001 ? 8'b00000011 :
                            MemOP == 3'b010 ? 8'b00001111 :
                            MemOP == 3'b011 ? 8'b11111111 :
                                              8'b00000000;

    wire [7:0]Device_wr_wstb;
    assign Device_wr_wstb = Dcache_wr_wstb << readmemaddr[2:0];

    wire [31:0]write_device_data_32;
    assign write_device_data_32 = MemOP == 3'b000 ? { New_src2[7:0], New_src2[7:0], New_src2[7:0], New_src2[7:0] } :
                                  MemOP == 3'b001 ? { New_src2[15:0], New_src2[15:0] } :
                                  MemOP == 3'b010 ? New_src2[31:0] :
                                  MemOP == 3'b011 ? New_src2[31:0] :
                                                    32'b0;

    wire [2:0]awsize;
    assign awsize = MemOP;  //just coincidence

    wire AXI_Dcache_rd_req;
    wire [31:0]AXI_Dcache_rd_addr;
    wire AXI_Dcache_rd_rdy;
    wire AXI_Dcache_ret_valid;
    wire AXI_Dcache_ret_last;
    wire [63:0]AXI_Dcache_ret_data;
    wire AXI_Dcache_wr_req;
    wire [31:0]AXI_Dcache_wr_addr;
    wire [7:0]AXI_Dcache_wr_wstb;
    wire [127:0]AXI_Dcache_wr_data;
    wire AXI_Dcache_wr_resp;
    wire AXI_Dcache_wr_rdy;
    assign AXI_Dcache_wr_rdy = last_writemem_finish;
    assign AXI_Dcache_rd_rdy = 1'b1;
    assign AXI_Dcache_ret_valid = ( io_master_rvalid == 1'b1 ) && ( io_master_rid == `Dcache_AXI4_ID ); //  && ( io_master_rresp  == 2'b10 );
    assign AXI_Dcache_ret_last = io_master_rlast;
    assign AXI_Dcache_ret_data = io_master_rdata;
    assign AXI_Dcache_wr_resp = ( io_master_bvalid == 1'b1 ); //  && ( io_master_bid == 4'b0010 ) && (io_master_bresp == 2'b10 );
    wire FenceI;
    assign FenceI = IDreg_valid && ( IDreg_inst[6:0] == 7'b0001111 )  && ( IDreg_inst[14:12] == 3'b001 );
    wire Suspend_MEM;
    ysyx_22050854_Dcache data_cache_inst (
        .clock(clock),
        .reset(reset),
        .valid(Data_cache_valid),
        .op(Data_cache_op),
        .index(Data_cache_index),
        .tag(Data_cache_tag),
        .offset(Data_cache_offset),
        .wstrb(Dcache_wr_wstb),
        .wdata(New_src2),
        .data_ok(Data_cache_Data_ok),
        .rdata(Dcache_ret_data),
        .unshoot(Suspend_MEM),
        .fencei(FenceI),

        //Dcache & AXI4 交互信号
        .rd_req(AXI_Dcache_rd_req),
        .rd_addr(AXI_Dcache_rd_addr),
        .rd_rdy(AXI_Dcache_rd_rdy),
        .ret_valid(AXI_Dcache_ret_valid),
        .ret_last(AXI_Dcache_ret_last),
        .ret_data(AXI_Dcache_ret_data),
        .wr_req(AXI_Dcache_wr_req),
        .wr_addr(AXI_Dcache_wr_addr),
        .wr_wstb(AXI_Dcache_wr_wstb),
        .wr_data(AXI_Dcache_wr_data),
        .wr_rdy(AXI_Dcache_wr_rdy),
        .wr_resp(AXI_Dcache_wr_resp),

        .sram4_addr(io_sram4_addr),
        .sram4_cen(io_sram4_cen),
        .sram4_wen(io_sram4_wen),
        .sram4_wmask(io_sram4_wmask),
        .sram4_wdata(io_sram4_wdata),
        .sram4_rdata(io_sram4_rdata),

        .sram5_addr(io_sram5_addr),
        .sram5_cen(io_sram5_cen),
        .sram5_wen(io_sram5_wen),
        .sram5_wmask(io_sram5_wmask),
        .sram5_wdata(io_sram5_wdata),
        .sram5_rdata(io_sram5_rdata),

        .sram6_addr(io_sram6_addr),
        .sram6_cen(io_sram6_cen),
        .sram6_wen(io_sram6_wen),
        .sram6_wmask(io_sram6_wmask),
        .sram6_wdata(io_sram6_wdata),
        .sram6_rdata(io_sram6_rdata),

        .sram7_addr(io_sram7_addr),
        .sram7_cen(io_sram7_cen),
        .sram7_wen(io_sram7_wen),
        .sram7_wmask(io_sram7_wmask),
        .sram7_wdata(io_sram7_wdata),
        .sram7_rdata(io_sram7_rdata)
    );


    // ----------------------------------   AXI4 signal generation ------------------------------------------------//
    // --------- write address channel ------------//
    reg Reg_awvalid;
    reg [31:0]Reg_awaddr;
    reg [3:0]Reg_awid;
    reg [7:0]Reg_awlen;
    reg [2:0]Reg_awsize;
    reg [1:0]Reg_awburst;
    reg Reg_is_device;
    always @(posedge clock)begin
        if(reset)begin
            Reg_awvalid <= 1'b0;
            Reg_awaddr <= 32'b0;
            Reg_awid <= 4'b0;
            Reg_awlen <= 8'b0;
            Reg_awsize <= 3'b0;
            Reg_awburst <= 2'b0;
            Reg_is_device <= 1'b0;
        end
        else if(AXI_Dcache_wr_req | AXI_device_wr_req)begin // if get write request from Dcache or IDreg(Device)
            Reg_awvalid <= 1'b1;
            Reg_awaddr <= AXI_Dcache_wr_req ? AXI_Dcache_wr_addr : ( AXI_device_wr_req ? readmemaddr : 32'b0 );
            Reg_awid <= AXI_Dcache_wr_req ? 4'b0001 : ( AXI_device_wr_req ? 4'b0000 : 4'b0 );
            Reg_awlen <= AXI_Dcache_wr_req ? 8'd1 : 8'd0;
            Reg_awsize <= AXI_Dcache_wr_req ? 3'b011 : ( AXI_device_wr_req ? awsize : 3'b000 );
            Reg_awburst <=  AXI_Dcache_wr_req ? 2'b01 : 2'b00;  //incrementing transfer
            Reg_is_device <= AXI_device_wr_req ? 1'b1 : 1'b0;
        end
        else if( Reg_awvalid && io_master_awready )begin
            Reg_awvalid <= 1'b0;
            Reg_awaddr <= 32'b0;
            Reg_awid <= 4'b0;
            Reg_awlen <= 8'b0;
            Reg_awsize <= 3'b0;
            Reg_awburst <= 2'b0;
            Reg_is_device <= 1'b0;
        end
    end
 
    assign io_master_awvalid = Reg_awvalid;
    assign io_master_awaddr = Reg_awaddr;
    assign io_master_awid = Reg_awid;  // 0001-->I-Cache   0010--->Dcache  0011-->device
    assign io_master_awlen = Reg_awlen;       
    assign io_master_awsize = Reg_awsize;  //2^6=64(8 bytes)  2^5=32(4 bytes) 
    assign io_master_awburst = Reg_awburst;  //incrementing transfer

    //for FenceI, because actual write mem may use many cycles
    reg last_writemem_finish;
    always @(posedge clock)begin
        if(reset)
            last_writemem_finish <= 1'b1;
        else if( io_master_wvalid && io_master_wready && io_master_wlast)
            last_writemem_finish <= 1'b1;
        else if( io_master_awvalid && ~io_master_awready )
            last_writemem_finish <= 1'b0;
    end 
    
    //---------------write data channel ------------ //
    //restore write AXI4 data temporarily
    reg [127:0]AXI_wr_data_temp;
    reg [7:0]AXI_wstb_temp;
    always @(posedge clock)begin
        if(reset) begin 
            AXI_wr_data_temp <= 128'b0;
            AXI_wstb_temp <= 8'h0;
        end
        else if( AXI_Dcache_wr_req ) begin
            AXI_wr_data_temp <= AXI_Dcache_wr_data;
            AXI_wstb_temp <= AXI_Dcache_wr_wstb;
        end
        else if( AXI_device_wr_req ) begin
            //AXI_wr_data_temp <= { 64'b0,write_device_data_32, write_device_data_32 }; //Soc
            AXI_wr_data_temp <= { 96'b0, New_src2[31:0] };       //npc
            AXI_wstb_temp <= Device_wr_wstb;
        end
    end

    reg AXI_Dcache_wlast;
    reg AXI_Dcache_wvalid;
    reg [63:0]AXI_Dcache_data_64;
    reg [7:0]AXI_wstb;
    reg AXI_Dcache_data_first_over;
    //由于采用突发传输传输128位，而总线位宽为64位，所以需要传递两次，需要重新组织待传输的数据
    //当检测到写地址信号时，第一个上升沿准备第一个写数据，并置写数据信号有效，第二个上升沿准备第二个写信号，同样置写数据信号有效
    always @(posedge clock)begin
        if(reset)begin
            AXI_Dcache_data_64 <= 64'b0;
            AXI_Dcache_data_first_over <= 1'b0;
            AXI_Dcache_wvalid <= 1'b0;
            AXI_Dcache_wlast <= 1'b0;
            AXI_wstb <= 8'b0;
        end
        else if( AXI_Dcache_data_first_over && io_master_wready )begin //cache's second data
            AXI_Dcache_data_64 <= AXI_wr_data_temp[127:64];
            AXI_Dcache_wvalid <= 1'b1;
            AXI_wstb <= AXI_wstb_temp;
            AXI_Dcache_data_first_over <= 1'b0;
            AXI_Dcache_wlast <= 1'b1;
        end
        else if( Reg_awvalid ) begin     //wdata is later one cycles than awaddress
            AXI_Dcache_wvalid <= 1'b1;
            AXI_Dcache_wlast <= Reg_is_device ? 1'b1 : 1'b0;
            AXI_Dcache_data_64 <= AXI_wr_data_temp[63:0];
            AXI_wstb <= AXI_wstb_temp;
            AXI_Dcache_data_first_over <= Reg_is_device ? 1'b0 : 1'b1;
        end
        else if(AXI_Dcache_wvalid && io_master_wready)  //if handshake success 
        begin
            AXI_Dcache_data_first_over <= 1'b0;
            AXI_Dcache_data_64 <= 64'b0;
            AXI_Dcache_wvalid <= 1'b0;
            AXI_Dcache_wlast <= 1'b0;
            AXI_wstb <= 8'b0;
        end
    end

    assign io_master_wvalid = AXI_Dcache_wvalid;
    assign io_master_wdata = AXI_Dcache_data_64;
    assign io_master_wstrb = AXI_wstb;
    assign io_master_wlast = AXI_Dcache_wlast;

    //write response channel
    assign io_master_bready = 1'b1;


    //-------------read address channel--------------------//
    ysyx_22050854_AXI_arbiter GEN_AXI_signal (
        .clock(clock),
        .reset(reset),

        .IFU_request(AXI_Icache_rd_req),
        .FLS_request(IFU_Flash_valid),
        .LSU_request(AXI_Dcache_rd_req),
        .DEV_request(AXI_device_rd_req),
        .arready(io_master_arready),
        .IFU_addr(AXI_Icache_rd_addr),
        .FLS_addr(Flash_PC),
        .LSU_addr(AXI_Dcache_rd_addr),
        .Device_addr(readmemaddr),
        .Device_arsize(awsize),
        .AXI_arbiter_arvalid(io_master_arvalid),
        .AXI_arbiter_arid(io_master_arid),
        .AXI_arbiter_addr(io_master_araddr),
        .AXI_arbiter_arlen(io_master_arlen),
        .AXI_arbiter_arsize(io_master_arsize),
        .AXI_arbiter_arburst(io_master_arburst)
    );
    //read data channel
    assign io_master_rready = 1'b1;

    wire AXI_Device_ret_valid;
    wire AXI_Device_wr_resp;
    assign AXI_Device_ret_valid = io_master_rvalid &&  io_master_rlast && ( io_master_rid == `Device_AXI4_ID );
    assign AXI_Device_wr_resp = io_master_bvalid;

    //因为访问设备肯定大于2周期，所以遇到访问设备的指令直接暂停，等到读回应/写回应之后再取消暂停
    reg Suspend_Device;
    always @(posedge clock)begin
        if(reset)
            Suspend_Device <= 1'b0;
        else if( AXI_device_rd_req | AXI_device_wr_req )
            Suspend_Device <= 1'b1;
        else if( ( AXI_Device_ret_valid || AXI_Device_wr_resp ) && Suspend_Device )
            Suspend_Device <= 1'b0;
    end
    wire Suspend_LSU;
    assign Suspend_LSU = Suspend_MEM | Suspend_Device;

    //LSU暂停期间从AXI4 得到的数据
    reg [63:0]Data_while_SuspendLSU;
    always @(posedge clock)begin
        if(reset)
            Data_while_SuspendLSU <= 64'b0;
        else if( Suspend_MEM & Data_cache_Data_ok)
            Data_while_SuspendLSU <= read_mem_data;
        else if( Suspend_Device && AXI_Device_ret_valid )
            Data_while_SuspendLSU <= read_mem_data;
    end

    wire [63:0] rdata;
    assign rdata = ( Data_cache_Data_ok ) ? Dcache_ret_data : io_master_rdata;
    reg [63:0]read_mem_data;
    //从mem读出的数据总是8字节的,所以要根据地址以及读操作数获得正确的数据
    //为什么暂停时取得的数还能用Mem的控制字，因为即使暂停，Mem也会从Exe跟新，只不过无效，但这里不管无效还是有效
    always@(*)begin
        case({MEMreg_aluout[2:0],MEMreg_memop})
            6'b000000: read_mem_data = {{56{rdata[7]}},rdata[7:0]};  //1 bytes signed extend  lb 000
            6'b000001: read_mem_data = {{48{rdata[15]}},rdata[15:0]}; //2 bytes signed extend  lh
            6'b000010: read_mem_data = {{32{rdata[31]}},rdata[31:0]}; //4 bytes signed extend  lw
            6'b000011: read_mem_data = rdata;                 //8 bytes ld
            6'b000100: read_mem_data = {56'b0,rdata[7:0]};    // 1 bytes unsigned extend lbu
            6'b000101: read_mem_data = {48'b0,rdata[15:0]};   // 2 bytes unsigned extend lhu
            6'b000110: read_mem_data = {32'b0,rdata[31:0]};   // 4 bytes unsigned extend lwu

            6'b001000: read_mem_data =  {{56{rdata[15]}},rdata[15:8]};  //1 bytes signed extend  lb 001
            6'b001001: read_mem_data =  {{48{rdata[23]}},rdata[23:8]}; //2 bytes signed extend  lh
            6'b001010: read_mem_data =  {{32{rdata[39]}},rdata[39:8]}; //4 bytes signed extend  lw
            6'b001100: read_mem_data =  {56'b0,rdata[15:8]};    // 1 bytes unsigned extend lbu
            6'b001101: read_mem_data =  {48'b0,rdata[23:8]};   // 2 bytes unsigned extend lhu
            6'b001110: read_mem_data =  {32'b0,rdata[39:8]};   // 4 bytes unsigned extend lwu

            6'b010000: read_mem_data = {{56{rdata[23]}},rdata[23:16]};  //1 bytes signed extend  lb 010
            6'b010001: read_mem_data = {{48{rdata[31]}},rdata[31:16]}; //2 bytes signed extend  lh
            6'b010010: read_mem_data = {{32{rdata[47]}},rdata[47:16]}; //4 bytes signed extend  lw
            6'b010100: read_mem_data = {56'b0,rdata[23:16]};   // 1 bytes unsigned extend lbu
            6'b010101: read_mem_data = {48'b0,rdata[31:16]};   // 2 bytes unsigned extend lhu
            6'b010110: read_mem_data = {32'b0,rdata[47:16]};   // 4 bytes unsigned extend lwu

            6'b011000: read_mem_data = {{56{rdata[31]}},rdata[31:24]};  //1 bytes signed extend  lb 011
            6'b011001: read_mem_data = {{48{rdata[39]}},rdata[39:24]}; //2 bytes signed extend  lh
            6'b011010: read_mem_data = {{32{rdata[55]}},rdata[55:24]}; //4 bytes signed extend  lw
            6'b011100: read_mem_data = {56'b0,rdata[31:24]};    // 1 bytes unsigned extend lbu
            6'b011101: read_mem_data = {48'b0,rdata[39:24]};   // 2 bytes unsigned extend lhu
            6'b011110: read_mem_data = {32'b0,rdata[55:24]};   // 4 bytes unsigned extend lwu

            6'b100000: read_mem_data = {{56{rdata[39]}},rdata[39:32]};  //1 bytes signed extend  lb 100
            6'b100001: read_mem_data = {{48{rdata[47]}},rdata[47:32]}; //2 bytes signed extend  lh
            6'b100010: read_mem_data = {{32{rdata[63]}},rdata[63:32]}; //4 bytes signed extend  lw
            6'b100100: read_mem_data = {56'b0,rdata[39:32]};   // 1 bytes unsigned extend lbu
            6'b100101: read_mem_data = {48'b0,rdata[47:32]};   // 2 bytes unsigned extend lhu
            6'b100110: read_mem_data = {32'b0,rdata[63:32]};   // 4 bytes unsigned extend lwu

            6'b101000: read_mem_data = {{56{rdata[47]}},rdata[47:40]};  //1 bytes signed extend  lb 101
            6'b101001: read_mem_data = {{48{rdata[55]}},rdata[55:40]}; //2 bytes signed extend  lh
            6'b101100: read_mem_data = {56'b0,rdata[47:40]};    // 1 bytes unsigned extend lbu
            6'b101101: read_mem_data = {48'b0,rdata[55:40]};   // 2 bytes unsigned extend lhu

            6'b110000: read_mem_data = {{56{rdata[55]}},rdata[55:48]};  //1 bytes signed extend  lb 110
            6'b110001: read_mem_data = {{48{rdata[63]}},rdata[63:48]};  //2 bytes signed extend  lh
            6'b110100: read_mem_data = {56'b0,rdata[55:48]};    // 1 bytes unsigned extend lbu
            6'b110101: read_mem_data = {48'b0,rdata[63:48]};   // 2 bytes unsigned extend lhu

            6'b111000: read_mem_data = {{56{rdata[63]}},rdata[63:56]};  //1 bytes signed extend  lb 111
            6'b111100: read_mem_data = {56'b0,rdata[63:56]};    // 1 bytes unsigned extend lbu
            default: read_mem_data = 64'b0;
        endcase
    end

    wire [63:0]Memdata_to_WBreg;
    assign Memdata_to_WBreg = Data_cache_Data_ok ? read_mem_data : Data_while_SuspendLSU;  //如果Dcache没有命中，那么需要暂停，此时读内存的数据就应该是之前记录的暂停期间读到的数

    //----------------------------------- WBreg -------------------------------------------------------------//
    reg WBreg_valid;
    reg [31:0]WBreg_inst;
    reg [31:0]WBreg_pc;
    reg [63:0]WBreg_readmemdata;
    reg WBreg_regwr;
    reg [4:0]WBreg_rd;
    reg [63:0]WBreg_aluout;
    reg WBreg_memRd;
    reg WBreg_memtoreg;
    reg WBreg_CSRrd;
    reg [63:0]WBreg_CSRrdata;
    reg WBreg_read_CLINT;
    reg [63:0]WBreg_CLINT_value;

    ysyx_22050854_Reg #(32,32'b0) WBreg_geninst (clock, reset, MEMreg_inst, WBreg_inst, 1'b1);
    ysyx_22050854_Reg #(32,32'h0) WBreg_genPC (clock, reset, MEMreg_pc, WBreg_pc, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen0 (clock, reset, MEMreg_valid, WBreg_valid, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen1 (clock, reset, Memdata_to_WBreg, WBreg_readmemdata, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen2 (clock, reset, MEMreg_regwr, WBreg_regwr, 1'b1);
    ysyx_22050854_Reg #(5,5'b0) WBreg_gen3 (clock, reset, MEMreg_rd, WBreg_rd, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen4 (clock, reset, MEMreg_aluout, WBreg_aluout, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen5 (clock, reset, MEMreg_memtoreg, WBreg_memtoreg, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen6 (clock, reset, MEMreg_memrd, WBreg_memRd, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen7 (clock, reset, MEMreg_CSRrd, WBreg_CSRrd, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen8 (clock, reset, MEMreg_CSRrdata, WBreg_CSRrdata, 1'b1);
    ysyx_22050854_Reg #(1,1'b0) WBreg_gen9 (clock, reset, MEMreg_read_CLINT, WBreg_read_CLINT, 1'b1);
    ysyx_22050854_Reg #(64,64'b0) WBreg_gen10 (clock, reset, MEMreg_CLINT_value, WBreg_CLINT_value, 1'b1);

    //写回寄存器的数据，总共有4 种可能 1.ALU计算值  2.LSU( memory/device )  3.从CSR读出的数据  4.mtime/mtimecmp
    wire [63:0]wr_reg_data;
    assign wr_reg_data =    WBreg_memtoreg ?    WBreg_readmemdata : 
                            WBreg_CSRrd ?       WBreg_CSRrdata :
                            WBreg_read_CLINT ?  WBreg_CLINT_value : 
                                                WBreg_aluout;

//以下代码为了调试使用
    //for difftest
    reg inst_finish;
    ysyx_22050854_Reg #(1,1'b0) inst_finish_gen (clock, reset, WBreg_valid, inst_finish, 1'b1);
    reg [31:0]inst_finish_pc;
    ysyx_22050854_Reg #(32,32'h0) inst_finishpc_gen (clock, reset, WBreg_pc, inst_finish_pc, 1'b1);
    reg [31:0]instruction_finsh;
    ysyx_22050854_Reg #(32,32'h0) instruction_finsh_gen (clock, reset, WBreg_inst, instruction_finsh, 1'b1);
    reg [31:0]access_mem_addr;
    ysyx_22050854_Reg #(32,32'h0) access_mem_addr_gen (clock, reset, WBreg_aluout[31:0], access_mem_addr, 1'b1);
    reg DIFFreg_memrd;
    ysyx_22050854_Reg #(1,1'b0) DIFFreg_memrd_gen (clock, reset, WBreg_memRd, DIFFreg_memrd, 1'b1);
    wire is_accessdevice;
    assign is_accessdevice = ( DIFFreg_memrd ) ? ( ( access_mem_addr > 32'h8fffffff ) ? 1'b1 : 1'b0 ) : 1'b0;

    //for debug
    wire [31:0]Data_Conflict_32;
    assign Data_Conflict_32 = {22'b0,ret_conflict_EXE,ret_conflict_MEM,ret_conflict_WB,store_conflict_EXE,store_conflict_MEM,store_conflict_WB,reg_Conflict_WB,reg_Conflict_MEM,reg_Conflict_EXE,Data_Conflict_block};

/*     
    import "DPI-C" function void get_next_pc_value(int next_pc);
    always@(*) get_next_pc_value(next_pc);

    wire [31:0]test_one;
    assign test_one = { 27'b0,  Last_LSU_IFU_Suspend , Last_ALUsuspend_IFUsuspend    ,Last_Jump_Suspend   ,Last_DataBlock_Suspend    ,Last_JumpAndBlock_Suspend };
    import "DPI-C" function void get_PC_JUMP_Suspend_value(int test_one);
    always@(*) get_PC_JUMP_Suspend_value(test_one);

    import "DPI-C" function void get_IDreginst_value(int IDreg_inst);
    always@(*) get_IDreginst_value(IDreg_inst);

    //Suspend_IFU
    wire [31:0]Suspend_IFU_32;
    assign Suspend_IFU_32 = { 31'b0 , Suspend_IFU };
    import "DPI-C" function void get_Suspend_IFU_value(int Suspend_IFU_32);
    always@(*) get_Suspend_IFU_value( Suspend_IFU_32 );

    import "DPI-C" function void get_IDregpc_value(int IDreg_pc);
    always@(*) get_IDregpc_value(IDreg_pc);

    import "DPI-C" function void get_Data_Conflict_value(int Data_Conflict_32);
    always@(*) get_Data_Conflict_value(Data_Conflict_32);

    wire [31:0]jump_32;
    assign jump_32 = {31'b0,jump};
    import "DPI-C" function void get_jump_value(int jump_32);
    always@(*) get_jump_value(jump_32);


    import "DPI-C" function void get_EXEreginst_value(int EXEreg_inst);
    always@(*) get_EXEreginst_value(EXEreg_inst);
    import "DPI-C" function void get_EXEreg_pc_value(int EXEreg_pc);
    always@(*) get_EXEreg_pc_value(EXEreg_pc);
    wire [31:0]EXEreg_valid_32;
    assign EXEreg_valid_32 = {31'b0,EXEreg_valid};
    import "DPI-C" function void get_EXEreg_valid_value(int EXEreg_valid_32);
    always@(*) get_EXEreg_valid_value(EXEreg_valid_32);



    wire [31:0]Suspend_alu_32;
    assign Suspend_alu_32 = {31'b0,Suspend_ALU};
    import "DPI-C" function void get_Suspend_alu_value(int Suspend_alu_32);
    always@(*) get_Suspend_alu_value(Suspend_alu_32);

    import "DPI-C" function void get_MEMreginst_value(int MEMreg_inst);
    always@(*) get_MEMreginst_value(MEMreg_inst);
    import "DPI-C" function void get_MEMreg_pc_value(int MEMreg_pc);
    always@(*) get_MEMreg_pc_value(MEMreg_pc);
    wire [31:0]memreg;
    assign memreg = MEMreg_aluout[31:0];
    import "DPI-C" function void get_MEMreg_aluout_value(int memreg);
    always@(*) get_MEMreg_aluout_value(memreg);

    wire [31:0]MEMreg_valid_32;
    assign MEMreg_valid_32 = {31'b0,MEMreg_valid};
    import "DPI-C" function void get_MEMreg_valid_value(int MEMreg_valid);
    always@(*) get_MEMreg_valid_value(MEMreg_valid_32);

    wire [31:0]wr_reg_data_32;
    assign wr_reg_data_32 = wr_reg_data[31:0];
    import "DPI-C" function void get_wr_reg_data_value(int wr_reg_data_32);
    always@(*) get_wr_reg_data_value(wr_reg_data_32);

    wire [31:0]rdata_32;
    assign rdata_32 = read_mem_data[31:0];
    import "DPI-C" function void get_rdata_value(int rdata_32);
    always@(*) get_rdata_value(rdata_32);

    wire [31:0]Suspend_LSU_32;
    assign Suspend_LSU_32 = { 31'b0 , Suspend_LSU };
    import "DPI-C" function void get_Suspend_LSU_value(int Suspend_LSU_32);
    always@(*) get_Suspend_LSU_value( Suspend_LSU_32 );

    wire [31:0]Data_cache_Data_ok_32;
    assign Data_cache_Data_ok_32 = { 31'b0 , Data_cache_Data_ok };
    import "DPI-C" function void get_Data_cache_Data_ok_value(int Data_cache_Data_ok_32);
    always@(*) get_Data_cache_Data_ok_value( Data_cache_Data_ok_32 );

    wire [31:0]Dcache_ret_data_32;
    assign Dcache_ret_data_32 = Dcache_ret_data[31:0];
    import "DPI-C" function void get_Dcache_ret_data_value(int Dcache_ret_data_32);
    always@(*) get_Dcache_ret_data_value(Dcache_ret_data_32);



    wire [31:0]New_src2_32;
    assign New_src2_32 = New_src2[31:0];
    import "DPI-C" function void get_New_src2_value(int New_src2_32);
    always@(*) get_New_src2_value(New_src2_32);

    wire [31:0]Dcache_addr;
    assign Dcache_addr = readmemaddr;
    import "DPI-C" function void get_Dcache_addr_value(int Dcache_addr);
    always@(*) get_Dcache_addr_value(Dcache_addr);

    import "DPI-C" function void get_AXI_Dcache_wr_addr_value(int AXI_Dcache_wr_addr);
    always@(*) get_AXI_Dcache_wr_addr_value(AXI_Dcache_wr_addr);

    wire [31:0]AXI_Dcache_data_32;
    assign AXI_Dcache_data_32 = AXI_Dcache_data_64[31:0];
    import "DPI-C" function void get_AXI_Dcache_data_64_value(int AXI_Dcache_data_32);
    always@(*) get_AXI_Dcache_data_64_value(AXI_Dcache_data_32);



    wire [31:0]wbreg;
    assign wbreg = WBreg_aluout[31:0];
    import "DPI-C" function void get_WBreg_aluout_value(int wbreg);
    always@(*) get_WBreg_aluout_value(wbreg);
    wire [31:0]wbrd_32;
    assign wbrd_32 = {27'b0,WBreg_rd};
    import "DPI-C" function void get_WBreg_rd_value(int wbrd_32);
    always@(*) get_WBreg_rd_value(wbrd_32);
    wire [31:0]WBreg_valid_32;
    assign WBreg_valid_32 = {31'b0,WBreg_valid};
    import "DPI-C" function void get_WBreg_valid_value(int WBreg_valid_32);
    always@(*) get_WBreg_valid_value(WBreg_valid_32);


    */

/*     import "DPI-C" function void get_inst_value(int inst);
    always@(*) get_inst_value(inst);

    wire [31:0]Data_cache_valid_32;
    assign Data_cache_valid_32 = { 31'b0 , LSU_access_valid };
    import "DPI-C" function void get_Data_cache_valid_value(int Data_cache_valid_32);
    always@(*) get_Data_cache_valid_value( Data_cache_valid_32 );

    wire [31:0]IDreg_valid_32;
    assign IDreg_valid_32 = {31'b0,IDreg_valid};
    import "DPI-C" function void get_IDreg_valid_value(int IDreg_valid_32);
    always@(*) get_IDreg_valid_value(IDreg_valid_32); */

/*     wire [31:0]IFU_valid_32;
    assign IFU_valid_32 = { 31'b0 , IFU_Icache_valid };
    import "DPI-C" function void get_IFU_valid_value(int IFU_valid_32);
    always@(*) get_IFU_valid_value( IFU_valid_32 );

    import "DPI-C" function void get_WBreg_pc_value(int WBreg_pc);
    always@(*) get_WBreg_pc_value(WBreg_pc);
    import "DPI-C" function void get_WBreginst_value(int WBreg_inst);
    always@(*) get_WBreginst_value(WBreg_inst);

    wire [31:0]is_device_32;
    assign is_device_32 = {31'b0,is_accessdevice};
    import "DPI-C" function void get_is_device_value(int is_device_32);
    always@(*) get_is_device_value(is_device_32);
    import "DPI-C" function void get_instruction_finsh_value(int instruction_finsh);
    always@(*) get_instruction_finsh_value(instruction_finsh);
*/

    import "DPI-C" function void get_pc_value(int pc_real);
    always@(*) get_pc_value(pc_real);

    wire [31:0]ebreak_32;
    assign ebreak_32 = { 31'b0,Insrtuction_ebreak };
    import "DPI-C" function void get_ebreak_value(int ebreak_32);
    always@(*) get_ebreak_value(ebreak_32);

    wire [31:0]inst_finish_32;
    assign inst_finish_32 = {31'b0,inst_finish};
    import "DPI-C" function void get_inst_finish_value(int inst_finish_32);
    always@(*) get_inst_finish_value(inst_finish_32);
    import "DPI-C" function void get_inst_finishpc_value(int inst_finish_pc);
    always@(*) get_inst_finishpc_value(inst_finish_pc);

//

endmodule 
