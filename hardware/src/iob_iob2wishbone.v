`include "timescale.v"

module iob_iob2wishbone #
(
 parameter ADDR_W = 32,
 parameter DATA_W = 32,
 parameter READ_BYTES = 4
 ) 
  (
   input                 clk_i,
   input                 arst_i,

    // IOb slave interface
   input                 valid_i,
   input [ADDR_W-1:0]    addr_i,
   input [DATA_W-1:0]    wdata_i,
   input [DATA_W/8-1:0]  wstrb_i,
   output [DATA_W-1:0]   rdata_o,
   output                ready_o,
   // aux signals
   input [DATA_W/8-1:0]  sel_i,
   output                err_o,

    // Wishbone master interface
   output [ADDR_W-1:0]   wb_adr_o,
   output [DATA_W/8-1:0] wb_sel_o,
   output                wb_we_o,
   output                wb_cyc_o,
   output                wb_stb_o,
   output [DATA_W-1:0]   wb_dat_o,
   input                 wb_ack_i,
   input [DATA_W-1:0]    wb_dat_i,
   input                 wb_err_i
   );
    
   assign wb_stb_o = wb_cyc_o;  

   iob_reg #(1,0) iob_reg_valid
     (
      .clk(clk_i), 
      .arst(arst_i),
      .rst(1'b0), 
      .en(1'b1),
      .data_in(valid_i),
      .data_out(wb_cyc_o)
      );

   iob_reg #(ADDR_W,0) iob_reg_addr
     (
      .clk(clk_i), 
      .arst(arst_i),
      .rst(1'b0), 
      .en(1'b1),
      .data_in(addr_i),
      .data_out(wb_adr_o)
      );

   iob_reg #(DATA_W,0) iob_reg_wdata
     (
      .clk(clk_i), 
      .arst(arst_i),
      .rst(1'b0), 
      .en(1'b1),
      .data_in(wdata_i),
      .data_out(wb_dat_o)
      );

   iob_reg #(DATA_W/8,0) iob_reg_sel
     (
      .clk(clk_i), 
      .arst(arst_i),
      .rst(1'b0), 
      .en(1'b1),
      .data_in(sel_i),
      .data_out(wb_sel_o)
      );

   iob_reg #(1,0) iob_reg_we
       (
         .clk(clk_i), 
         .arst(arst_i),
         .rst(1'b0), 
         .en(1'b1),
         .data_in(|wstrb_i),
         .data_out(wb_we_o)
         );
   
   assign ready_o = wb_ack_i;
   assign rdata_o = wb_dat_i;
   assign err_o = wb_err_i;

endmodule
