module gpif2mst
(
     input  wire         SYS_CLK_STABLE /* synthesis xc_pulldown = 1 */
   , input  wire         SYS_CLK
   , output wire         SYS_RST_N /* synthesis xc_pullup = 1 */
   , input  wire         SL_RST_N
   , output wire         SL_CS_N
   , output wire         SL_PCLK
   , output wire [ 1:0]  SL_AD
   , input  wire         SL_FLAGA /* synthesis xc_pullup = 1 */
   , input  wire         SL_FLAGB /* synthesis xc_pullup = 1 */
   , input  wire         SL_FLAGC /* synthesis xc_pullup = 1 */
   , input  wire         SL_FLAGD /* synthesis xc_pullup = 1 */
   , output wire         SL_RD_N  /* synthesis xc_pullup = 1 */
   , output wire         SL_WR_N  /* synthesis xc_pullup = 1 */
   , output wire         SL_OE_N  /* synthesis xc_pullup = 1 */
   , output wire         SL_PKTEND_N /* synthesis xc_pullup = 1 */
   , input  wire [31:0]  SL_DT_I
   , output wire [31:0]  SL_DT_O
   , output wire         SL_DT_T // when low, SL_DT_O drives
   , input  wire [ 1:0]  SL_MODE /* synthesis xc_pulldown = 1 */
   //---------------------------------------------------------------------------
   , output wire [ 3:0]  transactor_sel // transactor selection (0 for SU2F or SF2U)
   //---------------------------------------------------------------------------
   , input  wire         cmd_rd_clk
   , input  wire         cmd_rd_ready
   , output wire         cmd_rd_valid
   , output wire [31:0]  cmd_rd_data
   , output wire         cmd_rd_empty
   , output wire [15:0]  cmd_rd_items
   , input  wire         u2f_rd_clk
   , input  wire         u2f_rd_ready
   , output wire         u2f_rd_valid
   , output wire [31:0]  u2f_rd_data
   , output wire         u2f_rd_empty
   , output wire [15:0]  u2f_rd_items
   , input  wire         f2u_wr_clk
   , output wire         f2u_wr_ready // data will be written when it is high, even though f2u_wr_full is high
   , input  wire         f2u_wr_valid
   , input  wire [33:0]  f2u_wr_data  // [33:32] 2'b00=normal, 2'b10=short, 2'b11=zlp
                                      // [32] = wr_n (active-low)
                                      // [33] = pktend (active-high)
                                      // [31:0] is not valid when [33:32]=2'b11 (zlp)
   , output wire         f2u_wr_full
   , output wire [15:0]  f2u_wr_rooms
);
   parameter DEPTH_FIFO_CU2F=512 // command-fifo 4-word unit (USB-to-FPGA)
           , DEPTH_FIFO_DU2F=512 // data stream-in-fifo 4-word unit (USB-to-FPGA)
           , DEPTH_FIFO_DF2U=512 // data stream-out-fifo 4-word unit (FPGA-to-USB)
           , PCLK_INV       =1'b1        // SL_PCLK=~SYS_CLK when 1
           , PCLK_FREQ      =80_000_000  // SL_PCLK frequency
           , FPGA_FAMILY    ="VIRTEX4";  // SPARTAN6, VIRTEX4
// synthesis attribute box_type gpif2mst "black_box"
endmodule
