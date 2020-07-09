`ifdef VIVADO
`define DBG_TRX_AXI (* mark_debug="true" *)
`else
`define DBG_TRX_AXI
`endif
(* black_box *) module trx_axi // only for 32-bit address, 32-bit data, 4-bit id
(
                    input  wire                     ARESETn
     ,              input  wire                     ACLK
     , `DBG_TRX_AXI input  wire [ 3:0]              MID // master id
     //-------------------------------------------------------------------------
     , `DBG_TRX_AXI output wire [ 3:0]              AWID
     , `DBG_TRX_AXI output wire [31:0]              AWADDR
     , `DBG_TRX_AXI output wire [ 7:0]              AWLEN
     , `DBG_TRX_AXI output wire                     AWLOCK
     , `DBG_TRX_AXI output wire [ 2:0]              AWSIZE
     , `DBG_TRX_AXI output wire [ 1:0]              AWBURST
   //`ifdef AMBA_AXI_CACHE
   //,              output wire [ 3:0]              AWCACHE
   //`endif
   //`ifdef AMBA_AXI_PROT
   //,              output wire [ 2:0]              AWPROT
   //`endif
     , `DBG_TRX_AXI output wire                     AWVALID
     , `DBG_TRX_AXI input  wire                     AWREADY
     ,              output wire [ 3:0]              AWQOS
     ,              output wire [ 3:0]              AWREGION
     //-------------------------------------------------------------------------
     , `DBG_TRX_AXI output wire [ 3:0]              WID
     , `DBG_TRX_AXI output wire [31:0]              WDATA
     , `DBG_TRX_AXI output wire [ 3:0]              WSTRB
     , `DBG_TRX_AXI output wire                     WLAST
     , `DBG_TRX_AXI output wire                     WVALID
     , `DBG_TRX_AXI input  wire                     WREADY
     //-------------------------------------------------------------------------
     , `DBG_TRX_AXI input  wire [ 3:0]  BID
     , `DBG_TRX_AXI input  wire [ 1:0]              BRESP
     , `DBG_TRX_AXI input  wire                     BVALID
     , `DBG_TRX_AXI output wire                     BREADY
     //-------------------------------------------------------------------------
     , `DBG_TRX_AXI output wire [ 3:0]              ARID
     , `DBG_TRX_AXI output wire [31:0]              ARADDR
     , `DBG_TRX_AXI output wire [ 7:0]              ARLEN
     , `DBG_TRX_AXI output wire                     ARLOCK
     , `DBG_TRX_AXI output wire [ 2:0]              ARSIZE
     , `DBG_TRX_AXI output wire [ 1:0]              ARBURST
   //`ifdef AMBA_AXI_CACHE
   //,              output wire [ 3:0]              ARCACHE
   //`endif
   //`ifdef AMBA_AXI_PROT
   //,              output wire [ 2:0]              ARPROT
   //`endif
     , `DBG_TRX_AXI output wire                     ARVALID
     , `DBG_TRX_AXI input  wire                     ARREADY
     ,              output wire [ 3:0]              ARQOS
     ,              output wire [ 3:0]              ARREGION
     //-------------------------------------------------------------------------
     , `DBG_TRX_AXI input  wire [ 3:0]              RID
     , `DBG_TRX_AXI input  wire [31:0]              RDATA
     , `DBG_TRX_AXI input  wire [ 1:0]              RRESP
     , `DBG_TRX_AXI input  wire                     RLAST
     , `DBG_TRX_AXI input  wire                     RVALID
     , `DBG_TRX_AXI output wire                     RREADY
     //-------------------------------------------------------------------------
     , `DBG_TRX_AXI input  wire                     IRQ
     , `DBG_TRX_AXI input  wire                     FIQ
     , `DBG_TRX_AXI output wire [ 15:0]             GPOUT
     , `DBG_TRX_AXI input  wire [ 15:0]             GPIN
     //-------------------------------------------------------------------------
     , `DBG_TRX_AXI input   wire  [ 3:0]  transactor_sel
     , `DBG_TRX_AXI output  wire          cmd_ready
     , `DBG_TRX_AXI input   wire          cmd_valid
     , `DBG_TRX_AXI input   wire  [31:0]  cmd_data 
     , `DBG_TRX_AXI input   wire  [15:0]  cmd_items
     , `DBG_TRX_AXI output  wire          u2f_ready
     , `DBG_TRX_AXI input   wire          u2f_valid
     , `DBG_TRX_AXI input   wire  [31:0]  u2f_data   // justified data
     , `DBG_TRX_AXI input   wire  [15:0]  u2f_items
     , `DBG_TRX_AXI input   wire          f2u_ready 
     , `DBG_TRX_AXI output  wire          f2u_valid
     , `DBG_TRX_AXI output  wire  [33:0]  f2u_data // justified data
     , `DBG_TRX_AXI input   wire  [15:0]  f2u_rooms 
);
// synthesis attribute box_type trx_axi "black_box"
endmodule
