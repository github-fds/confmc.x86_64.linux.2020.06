`ifndef GPIF2MST_DEFINE_V
`define GPIF2MST_DEFINE_V
//------------------------------------------------------------------------------
// Copyright (c) 2018 by Future Design Systems.
// All right reserved.
//------------------------------------------------------------------------------
// gpif2mst_define.v
//------------------------------------------------------------------------------
// VERSION: 2018.05.29.
//------------------------------------------------------------------------------

// RTL VERSION
`define RTL_VERSION 32'h20180529

// thread address
`define ADD_CMD    2'b00 // USB-to-FPGA for command
`define ADD_U2F    2'b00 // USB-to-FPGA for data (the same as ADD_CMD)
`define ADD_F2U    2'b10 // FPGA-to-USB for data

// command of cmd-pkt
`define CMD_CU2F   4'b0010 // COMMAND
`define CMD_DU2F   4'b0100 // DATA (USB-to-FPGA)
`define CMD_DF2U   4'b0101 // DATA (FPGA-to-USB)
`define CMD_REQ    4'b1000 // Internal request

// operation mode
`define MODE_CMD   2'b00
`define MODE_SU2F  2'b01 // stream USB-to-FPGA
`define MODE_SF2U  2'b10 // stream FPGA-to-USB
`define MODE_SLOOP 2'b11 

//------------------------------------------------------------------------------
// for references
//
// SL_PCLK       GPIO[16]/PCLK
// SL_CS_N       GPIO[17]/CTL[0]
// SL_WR_N       GPIO[18]/CTL[1]
// SL_OE_N       GPIO[19]/CTL[2]
// SL_RD_N       GPIO[20]/CTL[3]
// SL_FLAGA      GPIO[21]/CTL[4]
// SL_FLAGB      GPIO[22]/CTL[5]
// SL_FLAGC      GPIO[23]/CTL[6]
// SL_PKTEND_N   GPIO[24]/CTL[7]
// SL_FLAGD      GPIO[25]/CTL[8]
// SL_RST_N      GPIO[26]/CTL[9]
// SL_MODE[0]    GPIO[17]/CTL[10]
// SL_AD[1:0]    GPIO[28:29]/CTL[11:12]
// SL_MODE[1]    GPIO[45]
// SL_DT[31:0]   GPIO[49:46]GPIO[44:33]GPIO[15:0]
// 
//------------------------------------------------------------------------------
// Revision History
//
// 2018.05.29: trx_ahb and trx_axi tested
// 2018.03.23: CMD_REQ added
// 2018.04.18: 2-thread version
// 2018.04.15: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
`endif
