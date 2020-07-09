//------------------------------------------------------------------------------
// Copyright (c) 2018 by Future Design Systems.
// All right reserved.
//------------------------------------------------------------------------------
// gpif2slv.v
//------------------------------------------------------------------------------
// VERSION: 2018.02.01.
//------------------------------------------------------------------------------
// Cypress EZ-USB GPIF-II slave interface slave model.
// - EZ-USB model
// - SL_EMPTY_N/SL_PRE_EMPTY_N may not behavior like the actual hardware.
//------------------------------------------------------------------------------
//   +-----------+                        +-----------+
//   | FX3       |                        | gpif2mst  |
//   |           +----> SL_RST_N -------->|-----------+---> SYS_RST_N
//   | gpif2slv  +<---- SL_PCLK ----------+-T-1-+-----|<--- SYS_CLK
//   |           +----- SL_FLAGA -------->|     |     |
//   |           +----- SL_FLAGB -------->|     |     |
//   |           +----- SL_FLAGC -------->|     |     |
//   |           +----- SL_FLAGD -------->|     |     |
//   |           |<---- SL_RD_N ----------|    \_/    |
//   |           |<---- SL_WR_N ----------|           |
//   |           |<---- SL_OE_N ----------|           |
//   |           |<---- SL_PKTEND_N ------|           |
//   |           |<---- SL_AD[1:0] -------|           |
//   |           |<---- SL_DT[31:0] ----->|           |
//   |           +----- SL_MODE[1:0] -----|           |
//   +-----------+                        +-----------+
//------------------------------------------------------------------------------
//   Firmware-controlled           FPGA
//   FIFO in FX3                   gpif2mst
//   <thread0>                     +---------------+
//   --------+     |\              |               +-->transactor_sel[3:0]
//     | | | |====>| \             |    --------+  |
//   --------+     |  \            |      | | | |=====>FIFO_CU2F
//                 |  |<--A[1:0]---|    --------+  |
//                 |  |            |    --------+  |
//                 |  |<==========>|      | | | |=====>FIFO_DU2F
//                 |  |            |    --------+  |
//   <thread2>     |  |  GPIF-II   |      +------- |
//     +-------    |  /            |      | | | |<=====FIFO_DF2U
//     | | | |<====| /             |      +------- |      
//     +-------    |/              +---------------+
//------------------------------------------------------------------------------
// Packet over GPIF-II
//              31      27      23      19      15      11       7       3     0
//              +-------------------------------+-------------------------------+
//              | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
//              +-------------------------------+-------+-------+-------+-------+
//
//              +-------------------------------+-------+-------+-------+-------+
// cmd-pkt      |         LENG (num of words)   |0 0 1 0|       |TRSNO  |       |
// (come from   +-------------------------------+-------+-------+-------+-------+
//  thread0     | <data 1> (if LENG is 0, there is no data)                     |
//  push        +---------------------------------------------------------------+
//  FIFO_CU2F)  | <data 2>                                                      |
//              +---------------------------------------------------------------+
//              |  .....                                                        |
//              +---------------------------------------------------------------+
//              | <data LENG>                                                   |
//              +---------------------------------------------------------------+
//
//              +-------------------------------+-------+-------+-------+-------+
// u2f-pkt      |         LENG (num of words)   |0 1 0 0|       |TRSNO  |       |
// (come from   +-------------------------------+-------+-------+-------+-------+
//  thread0     | <data 1> (if LENG is 0, there is no data)                     |
//  push        +---------------------------------------------------------------+
//  FIFO_DU2F)  | <data 2>                                                      |
//              +---------------------------------------------------------------+
//              |  .....                                                        |
//              +---------------------------------------------------------------+
//              | <data LENG>                                                   |
//              +---------------------------------------------------------------+
//
//              +-------------------------------+-------+-------+-------+-------+
// f2u-pkt      |         LENG (num of words)   |0 1 0 1|       |TRSNO  |       |
// (come from   +-------------------------------+-------+-------+-------+-------+
//  thread2)
// (pop         +-------------------------------+-------+-------+-------+-------+
//  FIFO_DU2F   | <data 1> (if LENG is 0, there is no data)                     |
//  goes to     +---------------------------------------------------------------+
//  thread2)    | <data 2>                                                      |
//              +---------------------------------------------------------------+
//              |  .....                                                        |
//              +---------------------------------------------------------------+
//              | <data LENG>                                                   |
//              +---------------------------------------------------------------+
//
// 'TRSNO' is not used for this implementation.
//
//------------------------------------------------------------------------------
// gpif2slv model
//  +--------------------------------+
//  |                 thread 0       |
//  |                 cmd fifo       |
//  |                 -+-+-+    |\   |
//  |gpif2_u2f_cmd()==>| | |===>| \  |
//  |gpif2_u2f_dat()  -+-+-+    | |  |
//  |                           | |  | SL_AD[1:0]
//  |                           | |<-+---+
//  |                           | |  |   |
//  |                           | |  |   |
//  |                           | |  |   |
//  |                           | |  |   |
//  |                           | |  |   |
//  |                 thread 2  | |<=+=GPIF-II==>
//  |                 f2u fifo  | |  |
//  |                 +-+-+-    | |  |
//  |gpif2_f2u_dat()<=| | |<====| /  |
//  |                 +-+-+-    |/   |
//  |                                |
//  +--------------------------------+
//------------------------------------------------------------------------------
`include "gpif2mst_define.v"
`include "gpif2slv_fifo_sync.v"
`ifdef SIM
`include "sim_define.v"
`endif
`timescale 1ns/1ns

module gpif2slv
     #(parameter WIDTH_DT=32
               , DEPTH_FIFO_U2F=1024 // command-fifo 4-word unit (USB-to-FPGA)
               , DEPTH_FIFO_F2U=1024 // data stream-out-fifo 4-word unit (FPGA-to-USB)
               , NUM_WATERMARK  =4
               , FPGA_FAMILY    ="ARTIX7") // SPARTAN6, ARTIX7, VIRTEX4
(
     output reg                 SL_RST_N=1'b1
   , input  wire                SL_PCLK
   , input  wire                SL_CS_N
   , input  wire [ 1:0]         SL_AD
   , output wire                SL_FLAGA // thread 0/1, active-low empty (U2F) SL_EMPTY_N
   , output wire                SL_FLAGB // thread 0/1, active-low almmost empty SL_PRE_EMPTY_N
   , output wire                SL_FLAGC // thread 2, active-low full (F2U) SL_FULL_N
   , output wire                SL_FLAGD // thread 2, active-low almost empty SL_PRE_FULL_N
   , input  wire                SL_RD_N
   , input  wire                SL_WR_N
   , input  wire                SL_OE_N
   , input  wire                SL_PKTEND_N
   , inout  wire [WIDTH_DT-1:0] SL_DT
   , output reg  [ 1:0]         SL_MODE=2'b00
   , input  wire                READY // to keep track of system ready,
                                      // which uses DCM and takes time to be stable.
);
   //---------------------------------------------------------------------------
   localparam WIDTH_FIFO_U2F=clogb2(DEPTH_FIFO_U2F)
            , WIDTH_FIFO_F2U=clogb2(DEPTH_FIFO_F2U);
   //---------------------------------------------------------------------------
   // thread address
   localparam ADD_U2F=`ADD_U2F // USB-to-FPGA for command/data
            , ADD_F2U=`ADD_F2U;// FPGA-to-USB for data
   // command of cmd-pkt
   localparam CMD_CU2F=`CMD_CU2F // COMMAND
            , CMD_DU2F=`CMD_DU2F // DATA (USB-to-FPGA)
            , CMD_DF2U=`CMD_DF2U // DATA (FPGA-to-USB)
            , CMD_REQ =`CMD_REQ ;// Internal request
   // operation mode
   localparam MODE_CMD  =`MODE_CMD  
            , MODE_SU2F =`MODE_SU2F  // stream USB-to-FPGA
            , MODE_SF2U =`MODE_SF2U  // stream FPGA-to-USB
            , MODE_SLOOP=`MODE_SLOOP;
   //---------------------------------------------------------------------------
   reg SL0_EMPTY_N    =1'b0;// thread 0, active-low empty (U2F)
   reg SL0_PRE_EMPTY_N=1'b0;// thread 0, active-low almmost empty
   reg SL2_FULL_N     =1'b0;// thread 2, active-low full (F2U)
   reg SL2_PRE_FULL_N =1'b0;// thread 2, active-low almost empty
   //---------------------------------------------------------------------------
   assign SL_FLAGA = SL0_EMPTY_N    ;// thread 0, active-low empty (U2F)
   assign SL_FLAGB = SL0_PRE_EMPTY_N;// thread 0, active-low almmost empty
   assign SL_FLAGC = SL2_FULL_N     ;// thread 2, active-low full (F2U)
   assign SL_FLAGD = SL2_PRE_FULL_N ;// thread 2, active-low almost empty
   //---------------------------------------------------------------------------
   wire                     u2f_wr_ready;
   reg                      u2f_wr_valid=1'b0;
   reg  [WIDTH_DT-1:0]      u2f_wr_data = 'h0;
   reg                      u2f_rd_ready=1'b0;
   wire                     u2f_rd_valid;
   wire [WIDTH_DT-1:0]      u2f_rd_data ;
   wire                     u2f_full    ;
   wire                     u2f_empty   ;
   wire                     u2f_fullN   ;
   wire                     u2f_emptyN  ;
   wire [WIDTH_FIFO_U2F:0]  u2f_items   ;
   wire [WIDTH_FIFO_U2F:0]  u2f_rooms   ;
   //---------------------------------------------------------------------------
   wire                     f2u_wr_ready;
   reg                      f2u_wr_valid=1'b0;
   reg  [WIDTH_DT-1:0]      f2u_wr_data ;
   reg                      f2u_rd_ready=1'b0;
   wire                     f2u_rd_valid;
   wire [WIDTH_DT-1:0]      f2u_rd_data ;
   wire                     f2u_full    ;
   wire                     f2u_empty   ;
   wire                     f2u_fullN   ;
   wire                     f2u_emptyN  ;
   wire [WIDTH_FIFO_F2U:0]  f2u_items   ;
   wire [WIDTH_FIFO_F2U:0]  f2u_rooms   ;
   //---------------------------------------------------------------------------
   `include "gpif2slv_tasks.v"
   //---------------------------------------------------------------------------
   reg done=1'b0;
   integer ida, idb;
   integer error;
   reg [31:0] valueC=32'h0403_0201;
   reg [31:0] valueD=32'h0102_0304;
   integer seed=7;
   //---------------------------------------------------------------------------
localparam TEST_CMD0  =`TEST_CMD0    // GPIF2MST info reading
         , TEST_CMD1  =`TEST_CMD1    // CMD-FIFO to DF2U-FIFO without delay
         , TEST_CMD2  =`TEST_CMD2    // CMD-FIFO to DF2U-FIFO with delay
         , TEST_CMD3  =`TEST_CMD3    // CDM-FIFO, DU2F-FIFO to DF2U-FIFO without delay
         , TEST_CMD4  =`TEST_CMD4    // CDM-FIFO, DU2F-FIFO to DF2U-FIFO with delay
         , TEST_2048  =`TEST_2048    // large dara with 1024 break with (PRE_EMPTY_N)
         , TEST_SLOOP0=`TEST_SLOOP0  // Stream loop without delay
         , TEST_SLOOP1=`TEST_SLOOP1  // Stream loop with delay
         , TEST_SU2F0 =`TEST_SU2F0   // Stream-out without delay
         , TEST_SU2F1 =`TEST_SU2F1   // Stream-out with delay
         , TEST_SF2U0 =`TEST_F2U0    // Stream-in without delay
         , TEST_SF2U1 =`TEST_F2U1;   // Stream-in with delay
   //---------------------------------------------------------------------------
   initial begin
       done      = 1'b0;
       SL_RST_N  = 1'b1;
       SL_MODE   = 2'b0;
       #7;
       SL_RST_N  = 1'b0;
       #55;
       SL_RST_N  = 1'b1;
       wait (READY==1'b1);

       //-----------------------------------------------------------------------
if (TEST_CMD0) begin
       gpif2_mode(MODE_CMD);
       gpif2_get_info();
       $display("%m GPIF2MST VERSION 0x%08X", f2u_data[2]);
       $display("%m CU2F-FIFO=%d DU2F-FIFO=%d, DF2U-FIFO=%d",
                 f2u_data[1]&32'hFFFF, f2u_data[0]&32'hFFFF, (f2u_data[0]>>16)&32'hFFFF);
       $display("%m GPIF2MST CLK FREQ %d-Mhz %s", (f2u_data[1]>>16)&16'hFF
                                                , (f2u_data[1]&32'h0100_0000)
                                                  ? "INVERTED" : "NOT-INVERTED");
end

       //-----------------------------------------------------------------------
       // variable-length cases
       // note that 'LENGTH' 0 means no data paylod.
if (TEST_CMD1) begin
       // It pushes data to CMD-FIFO and receives from DF2U-FIFO without delay.
       gpif2_mode(MODE_CMD);
       for (ida=0; ida<=10; ida=ida+1) begin
            valueC = 32'h0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueC = valueC + 1;
                 u2f_data[idb] = valueC;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_cmd(4'h0, ida);
            repeat (50) @ (posedge SL_PCLK);
            gpif2_f2u_dat(4'h0, ida);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t C-to-D loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t C-to-D loopback OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY F2U-FIFO");
       $fflush(0);
`define u7u7
`ifdef  u7u7
       //-----------------------------------------------------------------------
       // It pushes data to CMD-FIFO and receives from DF2U-FIFO without delay.
       gpif2_mode(MODE_CMD);
       for (ida=1024; ida<=1024; ida=ida*2) begin
            valueC = 'h0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueC        = valueC + 1;
                 u2f_data[idb] = valueC;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_cmd(4'h0, ida);
            gpif2_f2u_dat(4'h0, ida);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t C-to-D loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t C-to-D loopback OK %d\n", $time, ida);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY F2U-FIFO");
       $fflush(0);
`endif
end
       //-----------------------------------------------------------------------
if (TEST_CMD2) begin
       // It pushes data to CMD-FIFO and receives from DF2U-FIFO with delay.
       gpif2_mode(MODE_CMD);
       for (ida=1; ida<=10; ida=ida+1) begin
            valueC = 32'h0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueC = valueC + 1;
                 u2f_data[idb] = valueC;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_cmd_dly(4'h0, ida);
            repeat (10) @ (posedge SL_PCLK);
            gpif2_f2u_dat_dly(4'h0, ida);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t C-to-D loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t C-to-D loopback OK %d\n", $time, ida);
            $fflush(0);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY F2U-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
if (TEST_CMD3) begin
       // It pushes command to CMD-FIFO,
       // then data to DU2F-FIFO and receives from DF2U-FIFO without delay.
       gpif2_mode(MODE_CMD);
       for (ida=0; ida<10; ida=ida+1) begin
            valueD = 32'h0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
               //valueD[ 7: 0] = valueD[ 7: 0] + 4;
               //valueD[15: 8] = valueD[15: 8] + 4;
               //valueD[23:16] = valueD[23:16] + 4;
               //valueD[31:24] = valueD[31:24] + 4;
            end
            gpif2_u2f_dat(4'h1, ida);
            repeat (10) @ (posedge SL_PCLK);
            gpif2_f2u_dat(4'h1, ida);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t D-to-D loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t D-to-D loopback OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY F2U-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
if (TEST_CMD4) begin
       // It pushes command to CMD-FIFO,
       // then data to DU2F-FIFO and receives from DF2U-FIFO with delay.
       gpif2_mode(MODE_CMD);
       for (ida=0; ida<=10; ida=ida+1) begin
            valueD = 32'h0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
               //valueD[ 7: 0] = valueD[ 7: 0] + 4;
               //valueD[15: 8] = valueD[15: 8] + 4;
               //valueD[23:16] = valueD[23:16] + 4;
               //valueD[31:24] = valueD[31:24] + 4;
            end
            gpif2_u2f_dat_dly(4'h1, ida);
            repeat (10) @ (posedge SL_PCLK);
            gpif2_f2u_dat_dly(4'h1, ida);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t D-to-D loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t D-to-D loopback OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY F2U-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
if (TEST_2048) begin
       // It pushes command to CMD-FIFO,
       // then data to DU2F-FIFO and receives from DF2U-FIFO with delay.
       gpif2_mode(MODE_CMD);
       for (ida=1024; ida<=4096; ida=ida*2) begin
            valueD = 32'h0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD        = valueD+ 1;
                 u2f_data[idb] = valueD;
               //valueD[ 7: 0] = valueD[ 7: 0] + 4;
               //valueD[15: 8] = valueD[15: 8] + 4;
               //valueD[23:16] = valueD[23:16] + 4;
               //valueD[31:24] = valueD[31:24] + 4;
            end
            gpif2_u2f_dat(4'h1, ida);
            repeat (50) @ (posedge SL_PCLK);
            gpif2_f2u_dat(4'h1, ida);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t D-to-D loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t D-to-D loopback OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m C-to-D loopback error: NON-EMPTY F2U-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
if (TEST_SLOOP0) begin
       // It don't not use command fifo
       gpif2_mode(MODE_SLOOP);
       for (ida=1; ida<=10; ida=ida+1) begin
            valueD = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_stream_core(ida, 1'b0);
            repeat (10) @ (posedge SL_PCLK);
            gpif2_f2u_stream_core(ida, 1'b0);
            @ (posedge SL_PCLK); while (u2f_empty==1'b0) @ (posedge SL_PCLK);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t stream loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t stream loopback OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m error: NON-EMPTY F2U-FIFO");
       $fflush(0);
       //-----------------------------------------------------------------------
`define aabbcc
`ifdef  aabbcc
       gpif2_mode(MODE_SLOOP);
       for (ida=1024; ida<=4096; ida=ida*2) begin
            valueD = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_stream_core(ida, 1'b0);
            repeat (10) @ (posedge SL_PCLK);
            gpif2_f2u_stream_core(ida, 1'b0);
            @ (posedge SL_PCLK); while (u2f_empty==1'b0) @ (posedge SL_PCLK);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t stream loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t stream loopback OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m error: NON-EMPTY F2U-FIFO");
       $fflush(0);
`endif
end
       //-----------------------------------------------------------------------
if (TEST_SLOOP1) begin
       // It don't not use command fifo with delay
       gpif2_mode(MODE_SLOOP);
       for (ida=0; ida<=10; ida=ida+1) begin
            valueD = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_stream_core(ida, 1'b1);
            gpif2_f2u_stream_core(ida, 1'b1);
            @ (posedge SL_PCLK); while (u2f_empty==1'b0) @ (posedge SL_PCLK);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t stream loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t stream loopback OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m error: NON-EMPTY F2U-FIFO");
       $fflush(0);
       //-----------------------------------------------------------------------
       gpif2_mode(MODE_SLOOP);
       for (ida=1024; ida<=4096; ida=ida*2) begin
            valueD = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_stream_core(ida, 1'b1);
            gpif2_f2u_stream_core(ida, 1'b1);
            @ (posedge SL_PCLK); while (u2f_empty==1'b0) @ (posedge SL_PCLK);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t stream loopback error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t stream loopback OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m error: NON-EMPTY F2U-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
if (TEST_SU2F0) begin
       // It don't not use command fifo
       gpif2_mode(MODE_SU2F);
       for (ida=0; ida<=100; ida=ida+1) begin
            valueD = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_stream_core(ida, 1'b0);
            @ (posedge SL_PCLK); while (u2f_empty==1'b0) @ (posedge SL_PCLK);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m error: NON-EMPTY F2U-FIFO");
       $fflush(0);
       repeat (50) @ (posedge SL_PCLK);
       //-----------------------------------------------------------------------
       gpif2_mode(MODE_SU2F);
       for (ida=1024; ida<=4096; ida=ida*2) begin
            valueD = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_stream_core(ida, 1'b0);
            @ (posedge SL_PCLK); while (u2f_empty==1'b0) @ (posedge SL_PCLK);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m error: NON-EMPTY F2U-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
if (TEST_SU2F1) begin
       // It don't not use command fifo
       gpif2_mode(MODE_SU2F);
       for (ida=0; ida<=100; ida=ida+1) begin
            valueD = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_stream_core(ida, 1'b1);
            @ (posedge SL_PCLK); while (u2f_empty==1'b0) @ (posedge SL_PCLK);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m error: NON-EMPTY F2U-FIFO");
       $fflush(0);
       repeat (50) @ (posedge SL_PCLK);
       //-----------------------------------------------------------------------
       gpif2_mode(MODE_SU2F);
       for (ida=1024; ida<=4096; ida=ida*2) begin
            valueD = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
                 f2u_data[idb] = 32'h0;
            end
            gpif2_u2f_stream_core(ida, 1'b1);
            @ (posedge SL_PCLK); while (u2f_empty==1'b0) @ (posedge SL_PCLK);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       if (f2u_empty!=1'b1) $display("%m error: NON-EMPTY F2U-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
if (TEST_SF2U0) begin
       // It don't not use command fifo
       gpif2_mode(MODE_SF2U);
       valueD = 0;
       for (ida=0; ida<=100; ida=ida+1) begin
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
            end
            gpif2_f2u_stream_core(ida, 1'b0);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t stream out error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t stream out OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
if (TEST_SF2U1) begin
       // It don't not use command fifo
       gpif2_mode(MODE_SF2U);
       valueD = 0;
       for (ida=16; ida<=17; ida=ida+1) begin
            for (idb=0; idb<ida; idb=idb+1) begin
                 valueD = valueD + 1;
                 u2f_data[idb] = valueD;
            end
            gpif2_f2u_stream_core(ida, 1'b1);
            error = 0;
            for (idb=0; idb<ida; idb=idb+1) begin
                 if (u2f_data[idb]!=f2u_data[idb]) begin
                     error = error + 1;
                 end
            end
            if (error>0) $display("%m %t stream out error %d/%d ===============\n", $time, error, ida);
            else         $display("%m %t stream out OK %d\n", $time, ida);
            repeat (50) @ (posedge SL_PCLK);
       end
       @ (negedge SL_PCLK);
       if (u2f_empty!=1'b1) $display("%m error: NON-EMPTY U2F-FIFO");
       $fflush(0);
end
       //-----------------------------------------------------------------------
       repeat (20) @ (posedge SL_PCLK);
       done = 1'b1;
       //-----------------------------------------------------------------------
   end // initial
   //---------------------------------------------------------------------------
   reg SL_RD_N0=1'b1;
 //reg u2f_empty_dly0=1'b0, u2f_empty_dly1=1'b0;
   always @ (posedge SL_PCLK or negedge SL_RST_N) begin
   if (SL_RST_N==1'b0) begin
       SL_RD_N0       <= 1'b1;
     //u2f_empty_dly0 <= 1'b0;
     //u2f_empty_dly1 <= 1'b0;
   end else begin
       SL_RD_N0       <= SL_RD_N;
     //u2f_empty_dly0 <= u2f_empty;
     //u2f_empty_dly1 <= u2f_empty_dly0;
   end
   end // always
   //---------------------------------------------------------------------------
   reg [WIDTH_DT-1:0] SL_DT_O;
   reg [WIDTH_DT-1:0] SL_DT_O_reg={WIDTH_DT{1'b0}};
   assign SL_DT = (SL_OE_N==1'b0) ? SL_DT_O : {WIDTH_DT{1'bZ}};
   //---------------------------------------------------------------------------
   always @ ( * ) begin
       SL0_EMPTY_N     = 1'b0;
       SL0_PRE_EMPTY_N = 1'b0;
       SL2_FULL_N      = 1'b1;
       SL2_PRE_FULL_N  = 1'b1;
       f2u_wr_valid    = 1'b0;
       u2f_rd_ready    = 1'b0;
       u2f_rd_ready    = 1'b0;
   if (SL_RST_N==1'b1) begin
       SL0_EMPTY_N     = ~u2f_empty ;
       SL0_PRE_EMPTY_N = ~u2f_emptyN;
       SL2_FULL_N      = ~f2u_full  ;
       SL2_PRE_FULL_N  = ~f2u_fullN ;
       f2u_wr_valid    = 1'b0;
       u2f_rd_ready    = 1'b0;
       u2f_rd_ready    = 1'b0;
       if (SL_AD==ADD_U2F) begin
           u2f_rd_ready  =~SL_RD_N0;
           SL_DT_O       = (SL_OE_N==1'b0) ? SL_DT_O_reg : 32'hZ;
           if ((SL_RD_N==1'b0)&&(SL_OE_N==1'b1)) $display("%m %t ERROR SL_OE_N should be 0 for F2U", $time);
           if ((SL_RD_N==1'b0)&&(SL_WR_N==1'b0)) $display("%m %t ERROR SL_RD_N & SL_WR_N both low", $time);
       end else if (SL_AD==ADD_F2U) begin
           f2u_wr_valid  =~SL_WR_N;
           f2u_wr_data   = SL_DT;
           if ((SL_WR_N==1'b0)&&(SL_OE_N==1'b0)) $display("%m %t ERROR SL_OE_N should be 1 for F2U", $time);
           if ((SL_RD_N==1'b0)&&(SL_WR_N==1'b0)) $display("%m %t ERROR SL_RD_N & SL_WR_N both low", $time);
       end else begin
           if ($time>10) $display("%m %t un-supprted SL_AD: %2b", SL_AD, $time, SL_AD);
       end
   end else begin
       SL0_EMPTY_N     = 1'b0;
       SL0_PRE_EMPTY_N = 1'b0;
       SL2_FULL_N      = 1'b1;
       SL2_PRE_FULL_N  = 1'b1;
       u2f_rd_ready    = 1'b0;
       u2f_rd_ready    = 1'b0;
       f2u_wr_valid    = 1'b0;
       f2u_wr_data     = 32'hZ;
   end
   end // always
   //---------------------------------------------------------------------------
   // It holds SL_DT data.
   always @ (posedge SL_PCLK or negedge SL_RST_N) begin
   if (SL_RST_N==1'b0) begin
       SL_DT_O_reg={WIDTH_DT{1'b0}};
   end else begin
       if (SL_AD==ADD_U2F) begin
           if ((u2f_rd_ready==1'b1)&&(u2f_rd_valid==1'b1)) SL_DT_O_reg <= u2f_rd_data;
       end else begin
           if ((u2f_rd_ready==1'b1)&&(u2f_rd_valid==1'b1)) SL_DT_O_reg <= u2f_rd_data;
       end
   end // if
   end // always
   //---------------------------------------------------------------------------
   gpif2slv_fifo_sync #(.FDW (WIDTH_DT) // fifof data width
                       ,.FAW (WIDTH_FIFO_U2F) // num of entries in 2 to the power FAW
                       ,.FULN(NUM_WATERMARK*32/WIDTH_DT-3)// lookahead-full
                       ,.EMPTN(NUM_WATERMARK*32/WIDTH_DT-1))// lookahead-empty
   u_u2f (
          .rst     (~SL_RST_N     )
        , .clr     ( 1'b0         )
        , .clk     ( SL_PCLK      )
        , .wr_rdy  ( u2f_wr_ready )
        , .wr_vld  ( u2f_wr_valid )
        , .wr_din  ( u2f_wr_data  )
        , .rd_rdy  ( u2f_rd_ready )
        , .rd_vld  ( u2f_rd_valid )
        , .rd_dout ( u2f_rd_data  )
        , .full    ( u2f_full     )
        , .empty   ( u2f_empty    )
        , .fullN   ( u2f_fullN    )
        , .emptyN  ( u2f_emptyN   )
        , .rd_cnt  ( u2f_items    )
        , .wr_cnt  ( u2f_rooms    )
   );
   //---------------------------------------------------------------------------
   //
// Following full behaviour should be reflected.
//               __    __   *__    __    __    __   *__    __    __    
// CLK          |  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
//              ______|     |     |     |     |     |     |     |     |
// SL_PRE_FULL_N      \_____|_____|_____|_____|_____|_____|_____|_____|
//              ______|_____ _____|_____|_____|     |     |     |     |
// SL_FULL_N          |     |     |     |     \_____|_____|_____|_____|
//                    |     |_____|_____|_____|_____|_____|     |     |
// SL_WR_N      ______|_____/     |     |     |     |     |     |     |
//                    |_____|_____|_____|_____|_____|_____|     |     |
//                    |0    |1    |2    |3    |4    |5    |

//               __    __   *__    __    __    __   *__    __    __    
// CLK          |  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
//              ______|     |     |     |     |     |     |     |     |
// SL_PRE_EMPTY_N     \_____|_____|_____|_____|_____|_____|_____|_____|
//              ______|_____ _____|_____|_____|     |     |     |     |
// SL_EMPTY_N         |     |     |     |     \_____|_____|_____|_____|
//                    |     |     |_____|_____|_____|_____|     |     |
// SL_RD_N      ______|_____|_____/     |     |     |     |     |     |
//              ______|_____|_____|_____|_____|     |     |
// SL_DT_I      ______X_____X_____X_____X_____XXXXXXXXXXXXX
//                    |_____|_____|_____|_____|_____|_____|     |     |
//                    |0    |1    |2    |3    |4    |5    |

   gpif2slv_fifo_sync #(.FDW (WIDTH_DT) // fifof data width
                       ,.FAW (WIDTH_FIFO_F2U) // num of entries in 2 to the power FAW
                       ,.FULN(NUM_WATERMARK*32/WIDTH_DT-3)// lookahead-full
                       ,.EMPTN(NUM_WATERMARK*32/WIDTH_DT-1))// lookahead-empty
   u_f2u (
          .rst     (~SL_RST_N     )
        , .clr     ( 1'b0         )
        , .clk     ( SL_PCLK      )
        , .wr_rdy  ( f2u_wr_ready )
        , .wr_vld  ( f2u_wr_valid )
        , .wr_din  ( f2u_wr_data  )
        , .rd_rdy  ( f2u_rd_ready )
        , .rd_vld  ( f2u_rd_valid )
        , .rd_dout ( f2u_rd_data  )
        , .full    ( f2u_full     )
        , .empty   ( f2u_empty    )
        , .fullN   ( f2u_fullN    )
        , .emptyN  ( f2u_emptyN   )
        , .rd_cnt  ( f2u_items    )
        , .wr_cnt  ( f2u_rooms    )
   );
   //---------------------------------------------------------------------------
   function integer clogb2;
   input [31:0] value;
   reg   [31:0] tmp;
   begin
      tmp = value - 1;
      for (clogb2 = 0; tmp > 0; clogb2 = clogb2 + 1) tmp = tmp >> 1;
   end
   endfunction
   //---------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2018.03.07: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
