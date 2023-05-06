`include "timescale.v"

module iob_wishbone2iob #
  (
   parameter ADDR_W = 32,
   parameter DATA_W = 32
   ) 
  (
   input                 clk_i,
   input                 arst_i,

    // Wishbone salve interface
   input [ADDR_W-1:0]    wb_adr_i,
   input [DATA_W/8-1:0]  wb_sel_i,
   input                 wb_we_i,
   input                 wb_cyc_i,
   input                 wb_stb_i,
   input [DATA_W-1:0]    wb_dat_i,
   output                wb_ack_o,
   output                wb_err_o,
   output [DATA_W-1:0]   wb_dat_o,

   // IOb master interface
   output                valid_o,
   output [ADDR_W-1:0]   addr_o,
   output [DATA_W-1:0]   wdata_o,
   output [DATA_W/8-1:0] wstrb_o,
   input [DATA_W-1:0]    rdata_i,
   input                 ready_i,
   //aux signals
   output [DATA_W/8-1:0] sel_o,
   input                 err_i
   );

  assign valid_o = wb_cyc_i & wb_stb_i & ~ready_i;
  assign addr_o  = wb_adr_i;
  assign wdata_o = wb_dat_i;
  assign wstrb_o = wb_we_i? wb_sel_i: {DATA_W/8{1'b0}};
  assign sel_o   = wb_sel_i;

  assign wb_dat_o = rdata_i;
  assign wb_ack_o = ready_i;
  assign wb_err_o = 1'b0;
  
endmodule
