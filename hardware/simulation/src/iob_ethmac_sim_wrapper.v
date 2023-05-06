`include "timescale.v"

module iob_ethmac_sim_wrapper 
  #(
    parameter MEM_ADDR_W = 32,
    parameter ADDR_W  = 12,
    parameter DATA_W  = 32
    ) 
  (
   // WISHBONE common
   input                               wb_clk_i, // WISHBONE clock
   input                               wb_rst_i, // WISHBONE reset

   // WISHBONE slave
   input [31:0]                        wb_dat_i, // WISHBONE data input
   output [31:0]                       wb_dat_o, // WISHBONE data output
   output                              wb_err_o, // WISHBONE error output
   input [ADDR_W-1:2]                  wb_adr_i, // WISHBONE address input
   input [3:0]                         wb_sel_i, // WISHBONE byte select input
   input                               wb_we_i, // WISHBONE write enable input
   input                               wb_cyc_i, // WISHBONE cycle input
   input                               wb_stb_i, // WISHBONE strobe input
   output                              wb_ack_o, // WISHBONE acknowledge output

   // WISHBONE master
   output [31:0]                       m_wb_adr_o,
   output [3:0]                        m_wb_sel_o,
   output                              m_wb_we_o,
   input [31:0]                        m_wb_dat_i,
   output [31:0]                       m_wb_dat_o,
   output                              m_wb_cyc_o,
   output                              m_wb_stb_o,
   input                               m_wb_ack_i,
   input                               m_wb_err_i,
   output [2:0]                        m_wb_cti_o, // Cycle Type Identifier
   output [1:0]                        m_wb_bte_o, // Burst Type Extension

   // Tx
   input                               mtx_clk_pad_i, // Transmit clock (from PHY)
   output [3:0]                        mtxd_pad_o, // Transmit nibble (to PHY)
   output                              mtxen_pad_o, // Transmit enable (to PHY)
   output                              mtxerr_pad_o, // Transmit error (to PHY)

   // Rx
   input                               mrx_clk_pad_i, // Receive clock (from PHY)
   input [3:0]                         mrxd_pad_i, // Receive nibble (from PHY)
   input                               mrxdv_pad_i, // Receive data valid (from PHY)
   input                               mrxerr_pad_i, // Receive data error (from PHY)

   // Common Tx and Rx
   input                               mcoll_pad_i, // Collision (from PHY)
   input                               mcrs_pad_i, // Carrier sense (from PHY)

   // MII Management interface
   input                               md_pad_i, // MII data input (from I/O cell)
   output                              mdc_pad_o, // MII Management data clock (to PHY)
   output                              md_pad_o, // MII data output (to I/O cell)
   output                              md_padoe_o, // MII data output enable (to I/O cell)
  
   // Bist
`ifdef ETH_BIST
   input                               mbist_si_i, // bist scan serial in
   output                              mbist_so_o, // bist scan serial out
   input [`ETH_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i, // bist chain shift control
`endif

   output                              int_o // Interrupt output
   );

  // IOb control interface
  wire                                 c_valid;
  wire [ADDR_W-1:0]                    c_addr;
  wire [DATA_W-1:0]                    c_wdata;
  wire [DATA_W/8-1:0]                  c_wstrb;
  wire [DATA_W-1:0]                    c_rdata;
  wire                                 c_ready;
  wire                                 c_err;
  wire [DATA_W/8-1:0]                  c_sel;

  // IOb control interface
  iob_wishbone2iob #
    (
     ADDR_W, DATA_W
     ) 
  wishbone2iob
    (
     .clk_i(wb_clk_i), 
     .arst_i(wb_rst_i),
    
     .wb_adr_i({wb_adr_i, 2'b00}),
     .wb_sel_i(wb_sel_i),
     .wb_we_i(wb_we_i),
     .wb_cyc_i(wb_cyc_i),
     .wb_stb_i(wb_stb_i),
     .wb_dat_i(wb_dat_i),
     .wb_ack_o(wb_ack_o),
     .wb_err_o(wb_err_o),
     .wb_dat_o(wb_dat_o),

     .valid_o(c_valid),
     .addr_o(c_addr),
     .wdata_o(c_wdata),
     .wstrb_o(c_wstrb),
     .rdata_i(c_rdata),
     .ready_i(c_ready),
     .err_i(c_err),
     .sel_o(c_sel)
     );

  // IOb data interface
  wire                                 d_valid;
  wire [MEM_ADDR_W-1:0]                d_addr;
  wire [DATA_W-1:0]                    d_wdata;
  wire [DATA_W/8-1:0]                  d_wstrb;
  wire [DATA_W/8-1:0]                  d_sel;
  wire [DATA_W-1:0]                    d_rdata;
  wire                                 d_ready;
  wire                                 d_err;

  // IOb Ethernet MAC wrapper
  iob_ethmac 
    #(
      //IOb-bus Parameters
      .ADDR_W(ADDR_W),
      .MEM_ADDR_W(MEM_ADDR_W),
      .DATA_W(DATA_W),
      .TARGET("SIM")
      ) 
  eth_0 
    (
     .clk_i(wb_clk_i),
     .arst_i(wb_rst_i),
    
     .c_valid_i(c_valid),
     .c_addr_i(c_addr),
     .c_wdata_i(c_wdata),
     .c_wstrb_i(c_wstrb),
     .c_rdata_o(c_rdata),
     .c_ready_o(c_ready),
     .c_sel_i(c_sel),
     .c_err_o(c_err),
    
     .d_valid_o(d_valid),
     .d_addr_o(d_addr),
     .d_wdata_o(d_wdata),
     .d_wstrb_o(d_wstrb),
     .d_rdata_i(d_rdata),
     .d_ready_i(d_ready),
     .d_sel_o(d_sel),
     .d_err_i(d_err),
    
     .mii_rx_clk_i(mrx_clk_pad_i),
     .mii_rxd_i(mrxd_pad_i),
     .mii_rx_dv_i(mrxdv_pad_i),
     .mii_rx_er_i(mrxerr_pad_i),
     .mii_tx_clk_i(mtx_clk_pad_i),
     .mii_txd_o(mtxd_pad_o),
     .mii_tx_en_o(mtxen_pad_o),
     .mii_tx_er_o(mtxerr_pad_o),
     .mii_md_i(md_pad_i),
     .mii_mdc_o(mdc_pad_o),
     .mii_md_o(md_pad_o),
     .mii_mdoe_o(md_padoe_o),
     .mii_coll_i(mcoll_pad_i),
     .mii_crs_i(mcrs_pad_i),
    
     .eth_int_o(int_o)
     );


  iob_iob2wishbone 
    #(
      .ADDR_W(MEM_ADDR_W), 
      .DATA_W(DATA_W)
      ) 
  iob2wishbone 
    (
     .clk_i(wb_clk_i), 
     .arst_i(wb_rst_i),
    
     .valid_i(d_valid),
     .addr_i(d_addr),
     .wdata_i(d_wdata),
     .wstrb_i(d_wstrb),
     .rdata_o(d_rdata),
     .ready_o(d_ready),
     .sel_i(d_sel),
     .err_o(d_err),
    
     .wb_adr_o(m_wb_adr_o),
     .wb_sel_o(m_wb_sel_o),
     .wb_we_o(m_wb_we_o),
     .wb_dat_i(m_wb_dat_i),
     .wb_dat_o(m_wb_dat_o),
     .wb_cyc_o(m_wb_cyc_o),
     .wb_stb_o(m_wb_stb_o),
     .wb_ack_i(m_wb_ack_i),
     .wb_err_i(m_wb_err_i)
     );

endmodule
