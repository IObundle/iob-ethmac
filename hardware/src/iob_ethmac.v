`timescale 1ns/1ps
`include "ethmac_defines.v"

module iob_ethmac #(
    //IOb-bus Parameters
    parameter ADDR_W      = 12,
    parameter DATA_W      = 32,
    parameter TARGET      = "XILINX"
  )(
    input wire clk,
    input wire rst,
    
    input  wire                s_valid,
    input  wire [ADDR_W-1:0]   s_address,
    input  wire [DATA_W-1:0]   s_wdata,
    input  wire [DATA_W/8-1:0] s_wstrb,
    output  reg [DATA_W-1:0]   s_rdata,
    output wire                s_ready,

    output wire                m_valid,
    output wire [31:0]         m_addr,
    output wire [DATA_W-1:0]   m_wdata,
    output wire [DATA_W/8-1:0] m_wstrb,
    input  wire [DATA_W-1:0]   m_rdata,
    input  wire                m_ready,

    input  wire       mii_rx_clk_i,
    input  wire [3:0] mii_rxd_i,
    input  wire       mii_rx_dv_i,
    input  wire       mii_rx_er_i,
    input  wire       mii_rx_ctrl_i,
    input  wire       mii_tx_clk_i,
    output wire [3:0] mii_txd_o,
    output wire       mii_tx_en_o,
    output wire       mii_tx_er_o,
    output wire       mii_mdc_o,
    inout  wire       mii_mdio_io,
    input  wire       mii_coll_i,
    input  wire       mii_crs_i,

    output wire eth_int_o
  );

  // ETHERNET wires
  wire mii_mdi_I;
  wire mii_mdo_O;
  wire mii_mdo_OE;
  // // Wichbone master
  wire [32-1:0] m_ETH_wb_adr;
  wire [DATA_W/8-1:0] m_ETH_wb_sel;
  wire m_ETH_wb_we;
  wire [DATA_W-1:0] m_ETH_wb_dat_in;
  wire [DATA_W-1:0] m_ETH_wb_dat_out;
  wire m_ETH_wb_cyc;
  wire m_ETH_wb_stb;
  wire m_ETH_wb_ack;
  wire m_ETH_wb_err;

  // IOb2Wishbone wires
  wire [ADDR_W-1:0] s_wb_addr;
  wire [DATA_W-1:0] s_wb_data_in;
  wire [DATA_W-1:0] s_wb_data_out;
  wire s_wb_we;
  wire s_wb_cyc; // Cycle Input, Indicates that a s_valid bus cycle is in progress.
  wire s_wb_stb; // Strobe Input, Indicates the beginning of a s_valid transfer cycle.
  wire [DATA_W/8-1:0] s_wb_select;
  wire s_wb_ack;
  wire s_wb_error;

  // ETHERNET logic
  // // Connecting Ethernet PHY Module
  assign mii_mdio_io = mii_mdo_OE ? mii_mdo_O : 1'bz ;
  assign mii_mdi_I   = mii_mdio_io;
  // assign mii_coll    = 1'b0; // No collision detection
  // assign mii_crs     = 1'b0; // The media is always in an idle state
  /* In full-duplex mode, the Carrier Sense and the Collision Detect signals are ignored. */

  iob_iob2wishbone #(
    ADDR_W, DATA_W
  ) iob2wishbone (
    clk, rst,
    s_valid, s_address, s_wdata, s_wstrb, s_rdata, s_ready,
    s_wb_addr, s_wb_select, s_wb_we, s_wb_cyc, s_wb_stb, s_wb_data_in, s_wb_ack, s_wb_error, s_wb_data_out
  );

  iob_wishbone2iob #(
    ADDR_W, DATA_W
  ) wishbone2iob (
    clk, rst,
    m_ETH_wb_adr, m_ETH_wb_sel, m_ETH_wb_we, m_ETH_wb_cyc, m_ETH_wb_stb, m_ETH_wb_dat_out, m_ETH_wb_ack, m_ETH_wb_err, m_ETH_wb_dat_in,
    m_valid, m_addr, m_wdata, m_wstrb, m_rdata, m_ready
  );

  // Connecting Ethernet top module
  ethmac eth_top (
    // WISHBONE common
    .wb_clk_i(clk),
    .wb_rst_i(rst), 

    // WISHBONE slave
    .wb_adr_i(s_wb_addr[ADDR_W-1:2]),
    .wb_sel_i(s_wb_select),
    .wb_we_i(s_wb_we), 
    .wb_cyc_i(s_wb_cyc),
    .wb_stb_i(s_wb_stb),
    .wb_ack_o(s_wb_ack), 
    .wb_err_o(s_wb_error),
    .wb_dat_i(s_wb_data_in),
    .wb_dat_o(s_wb_data_out), 
    
    // WISHBONE master
    .m_wb_adr_o(m_ETH_wb_adr),
    .m_wb_sel_o(m_ETH_wb_sel),
    .m_wb_we_o(m_ETH_wb_we),
    .m_wb_cyc_o(m_ETH_wb_cyc),
    .m_wb_stb_o(m_ETH_wb_stb),
    .m_wb_dat_o(m_ETH_wb_dat_out),
    .m_wb_ack_i(m_ETH_wb_ack),
    .m_wb_err_i(m_ETH_wb_err), 
    .m_wb_dat_i(m_ETH_wb_dat_in),

  `ifdef ETH_WISHBONE_B3
    .m_wb_cti_o(eth_ma_wb_cti_o),
    .m_wb_bte_o(eth_ma_wb_bte_o),
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
    .mcoll_pad_i(mii_coll_i),
    .mcrs_pad_i(mii_crs_i), 
    
    // MIIM
    .mdc_pad_o(mii_mdc_o),
    .md_pad_i(mii_mdi_I),
    .md_pad_o(mii_mdo_O),
    .md_padoe_o(mii_mdo_OE),
    
    .int_o(eth_int_o)

    // Bist
  `ifdef ETH_BIST
    ,
    .mbist_si_i       (1'b0),
    .mbist_so_o       (),
    .mbist_ctrl_i     (3'b001) // {enable, clock, reset}
  `endif
  );

endmodule
