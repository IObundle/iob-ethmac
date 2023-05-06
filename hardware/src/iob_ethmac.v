`include "timescale.v"
`include "ethmac_defines.v"

module iob_ethmac #
  (
   //IOb-bus Parameters
   parameter ADDR_W      = 12,
   parameter MEM_ADDR_W  = 32,
   parameter DATA_W      = 32,
   parameter TARGET      = "XILINX"
   )
  (
   input                   clk_i,
   input                   arst_i,

   //IOb slave control bus signals
   input                   c_valid_i,
   input [ADDR_W-1:0]      c_addr_i,
   input [DATA_W-1:0]      c_wdata_i,
   input [DATA_W/8-1:0]    c_wstrb_i,
   output [DATA_W-1:0]     c_rdata_o,
   output                  c_ready_o,
   //aux signals
   input [DATA_W/8-1:0]    c_sel_i,
   output                  c_err_o,

   //IOb master data bus signals
   output                  d_valid_o,
   output [MEM_ADDR_W-1:0] d_addr_o,
   output [DATA_W-1:0]     d_wdata_o,
   output [DATA_W/8-1:0]   d_wstrb_o,
   input [DATA_W-1:0]      d_rdata_i,
   input                   d_ready_i,
   //aux signals
   output [DATA_W/8-1:0]   d_sel_o,
   input                   d_err_i,


   // Ethernet MII signals
   input                   mii_rx_clk_i,
   input [3:0]             mii_rxd_i,
   input                   mii_rx_dv_i,
   input                   mii_rx_er_i,
   input                   mii_tx_clk_i,
   output [3:0]            mii_txd_o,
   output                  mii_tx_en_o,
   output                  mii_tx_er_o,
   input                   mii_md_i,
   output                  mii_mdc_o,
   output                  mii_md_o,
   output                  mii_mdoe_o,
   input                   mii_coll_i,
   input                   mii_crs_i,

   // Ethernet interrupt
   output                  eth_int_o
   );


  wire [ADDR_W-1:0]        wb_adr;
  wire [DATA_W-1:0]        wb_wdata;
  wire [DATA_W/8-1:0]      wb_sel;
  wire [DATA_W-1:0]        wb_rdata;
  wire                     wb_stb;
  wire                     wb_we;
  wire                     wb_cyc;
  wire                     wb_ack;
  wire                     wb_err;

  // IOB to Wishbone bridge (control)
  iob_iob2wishbone #
    (
     .ADDR_W(ADDR_W), 
     .DATA_W(DATA_W)
     ) 
  iob2wishbone 
    (
     .clk_i(clk_i),
     .arst_i(arst_i),

     .valid_i(c_valid_i),
     .addr_i(c_addr_i),
     .wdata_i(c_wdata_i),
     .wstrb_i(c_wstrb_i),
     .rdata_o(c_rdata_o),
     .ready_o(c_ready_o),
     .sel_i(c_sel_i),
     .err_o(c_err_o),

     .wb_adr_o(wb_adr),
     .wb_we_o(wb_we),
     .wb_stb_o(wb_stb),
     .wb_cyc_o(wb_cyc),
     .wb_sel_o(wb_sel),
     .wb_dat_o(wb_wdata),
     .wb_ack_i(wb_ack),
     .wb_dat_i(wb_rdata),
     .wb_err_i(wb_err)
  );

  wire [DATA_W-1:0]        d_wb_rdata;
  wire                     d_wb_ack;
  wire                     d_wb_err;
  wire                     d_wb_stb;
  wire                     d_wb_cyc;
  wire                     d_wb_we;
  wire [DATA_W-1:0]        d_wb_wdata;
  wire [DATA_W/8-1:0]      d_wb_sel;
  wire [MEM_ADDR_W-1:0]    d_wb_adr;


  // Connecting Ethernet top module
  ethmac eth_top 
    (
     // WISHBONE common
     .wb_clk_i(clk_i),
     .wb_rst_i(arst_i), 
     
     // WISHBONE control slave bus
     .wb_adr_i(wb_adr[ADDR_W-1:2]),
     .wb_sel_i(wb_sel),
     .wb_we_i(wb_we), 
     .wb_cyc_i(wb_cyc),
     .wb_stb_i(wb_stb),
     .wb_ack_o(wb_ack), 
     .wb_err_o(wb_err),
     .wb_dat_i(wb_wdata),
     .wb_dat_o(wb_rdata), 
    
     // WISHBONE data master bus
     .m_wb_adr_o(d_wb_adr),
     .m_wb_sel_o(d_wb_sel),
     .m_wb_we_o(d_wb_we),
     .m_wb_cyc_o(d_wb_cyc),
     .m_wb_stb_o(d_wb_stb),
     .m_wb_dat_o(d_wb_wdata),
     .m_wb_ack_i(d_wb_ack),
     .m_wb_err_i(d_wb_err), 
     .m_wb_dat_i(d_wb_rdata),

`ifdef ETH_WISHBONE_B3
     .m_wb_cti_o(m_wb_cti_o),
     .m_wb_bte_o(m_wb_bte_o),
`endif

     //TX
     .mtx_clk_pad_i(mii_tx_clk_i),
     .mtxd_pad_o(mii_txd_o),
     .mtxen_pad_o(mii_tx_en_o),
     .mtxerr_pad_o(mii_tx_er_o),
     
     //RX
     .mrx_clk_pad_i(mii_rx_clk_i),
     .mrxd_pad_i(mii_rxd_i),
     .mrxdv_pad_i(mii_rx_dv_i),
     .mrxerr_pad_i(mii_rx_er_i), 
     
     // Common Tx and Rx
     .mcoll_pad_i(mii_coll_i),
     .mcrs_pad_i(mii_crs_i), 
     
    // MIIM
     .mdc_pad_o(mii_mdc_o),
     .md_pad_i(mii_md_i),
     .md_pad_o(mii_md_o),
     .md_padoe_o(mii_mdoe_o),
     
     // Bist
`ifdef ETH_BIST
     .mbist_si_i       (1'b0),
     .mbist_so_o       (),
     .mbist_ctrl_i     (3'b001), // {enable, clock, reset}
`endif
     
     .int_o(eth_int_o)

     );

  iob_wishbone2iob #
    (
     .ADDR_W(MEM_ADDR_W), 
     .DATA_W(DATA_W)
     )
  wishbone2iob 
    (
     .clk_i(clk_i),
     .arst_i(arst_i),
     .wb_adr_i(d_wb_adr),
     .wb_sel_i(d_wb_sel),
     .wb_we_i(d_wb_we),
     .wb_cyc_i(d_wb_cyc),
     .wb_stb_i(d_wb_stb),
     .wb_dat_i(d_wb_wdata),
     .wb_ack_o(d_wb_ack),
     .wb_err_o(d_wb_err),
     .wb_dat_o(d_wb_rdata),

     .valid_o(d_valid_o),
     .addr_o(d_addr_o),
     .wdata_o(d_wdata_o),
     .wstrb_o(d_wstrb_o),
     .rdata_i(d_rdata_i),
     .ready_i(d_ready_i),
     .sel_o(d_sel_o),
     .err_i(d_err_i)
  );

endmodule
