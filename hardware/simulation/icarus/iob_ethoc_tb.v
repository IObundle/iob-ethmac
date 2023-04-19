`timescale 1ns / 1ps
`include "ethmac_defines.v"

`define FREQ 100000000
`define ECLK_FREQ 25000000

module iob_ethoc_tb;

  localparam clk_per = 1000000000/`FREQ;
  localparam eck_per = 1000000000/`ECLK_FREQ;

  //clock & ethernet clock
  reg                clk_i = 1;
  reg                eth_clk_i = 1;
  always #(clk_per/2) clk_i = ~clk_i;
  always #(eck_per/2) eth_clk_i = ~eth_clk_i;

  //reset
  reg                arst_i = 0;

  // DUT inputs
  reg                 valid;
  reg [`ADDR_W-1:0]   address;
  reg [`DATA_W-1:0]   wdata;
  reg [`DATA_W/8-1:0] wstrb;

  // DUT outputs
  wire               ready;
  wire [`DATA_W-1:0] rdata;
  wire               interrupt;

  // Testbench variables
  integer    i = 0;
  reg [31:0] read_reg;

  initial begin
    //assert reset
    #100 arst_i = 1;
    valid = 0;
    address = 0;
    wdata = 0;
    wstrb = 0;
    read_reg = 0;
    // deassert rst
    repeat (100) @(posedge clk_i) #1;
    arst_i = 0;
    //wait an arbitray (10) number of cycles
    repeat (10) @(posedge clk_i) #1;

    $display("Testbench Started!");
    // Start of testbench

    $display("Enable loop back, TX is looped back to the RX.");
    set_inputs(`ETH_MODER_ADR, 32'h0000A080, 4'hf);
    wait_responce(read_reg);
    $display("Enable full-duplex mode.");
    set_inputs(`ETH_MODER_ADR, 32'h0000A480, 8'hf);
    wait_responce(read_reg);
    $display("Reading Mode Register.");
    set_inputs(`ETH_MODER_ADR, 32'h0, 4'h0);
    wait_responce(read_reg);
    $display("Value: %x.", read_reg);

    // Store transmission buffer to memory
    // // memory is being initialised with data
    // Prepare frame reception, ch.4.2.4
    $display("Prepare frame reception.");
    set_inputs(32'h604, 32'h80, 8'hf);
    wait_responce(read_reg);
    set_inputs(32'h600, 32'h0010C000, 8'hf);
    wait_responce(read_reg);
    set_inputs(`ETH_MODER_ADR, 32'h0000A481, 8'hf);
    wait_responce(read_reg);
    // Prepare frame transmission, ch.4.2.3
    $display("Prepare frame transmission.");
    set_inputs(32'h404, 32'h0, 8'hf);
    wait_responce(read_reg);
    set_inputs(32'h400, 32'h0010D000, 8'hf);
    wait_responce(read_reg);
    set_inputs(`ETH_MODER_ADR, 32'h0000A483, 8'hf);
    wait_responce(read_reg);
    // Wait for interrupt generated when frame is received
    // set_inputs(`ETH_INT_MASK_ADR, 32'h07f, 8'hf);
    // wait_responce(read_reg);
    //while(~interrupt) begin
    //  set_inputs(32'h600, 32'h0, 8'h0);
    //  wait_responce(read_reg);
    //end
    $display("Value read from buffer descriptor: %x", read_reg);
    // Load received buffer from memory

    // End of testbench
    @(posedge clk_i) #1 $display("Testbench finished!");

    repeat (200) @(posedge clk_i) #1;
    $finish;
  end

  iob_ethoc_sim_wrapper #(
    `ADDR_W, `DATA_W
  ) eth_uut (
    .clk_i     (clk_i),
    .arst_i     (arst_i),
    .eth_clk_i (eth_clk_i),

    .valid   (valid),
    .address (address),
    .wdata   (wdata),
    .wstrb   (wstrb),
    .rdata   (rdata),
    .ready   (ready),

    .ethernet_interrupt(interrupt)
    );

  task wait_responce;
    output [31:0] data_read;
    begin
    data_read = rdata;
    while(ready != 1) begin
      @ (posedge clk_i) data_read = rdata;
      end
    end
  endtask

  task set_inputs;
    input [31:0]  set_address;
    input [31:0]  set_data;
    input [3:0]   set_strb;
    begin
    valid = 1;
    address = set_address;
    wdata = set_data;
    wstrb = set_strb;
    @ (posedge clk_i) #1 valid = 0; // weird bug caused by delay
    wstrb = 0;
    end
  endtask

endmodule
