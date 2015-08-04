`include "frame_buf_alt.v"
`include "data_mem_alt/data_mem_alt.v"

module frame_buf_alt_tb #(
  parameter DATA_WIDTH = 32,
            ADDR_WIDTH = 3,
            BUF_SIZE = 5
);

  reg wr_clk, rd_clk, mem_clk, reset, wr_en_in, rd_en_in;
  reg [31:0] data_in;
  wire wr_rdy, rd_rdy, rd_en, wr_en, full;
  wire [ADDR_WIDTH - 1:0] rd_addr, wr_addr;
  wire [31:0] data_out;

  frame_buf_alt #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .BUF_SIZE(BUF_SIZE)
  ) uut (
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .reset(reset),
    .wr_en_in(wr_en_in),
    .rd_en_in(rd_en_in),
    .wr_rdy(wr_rdy),
    .rd_rdy(rd_rdy),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .full(full),
    .wr_addr(wr_addr),
    .rd_addr(rd_addr)
  );
                
  data_mem_alt #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mem (
    .clk(mem_clk),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .reset(reset),
    .wr_addr(wr_addr),
    .rd_addr(rd_addr),
    .wr_data(data_in),
    .rd_data_valid(rd_data_valid),
    .wr_rdy(wr_rdy),
    .rd_rdy(rd_rdy),
    .rd_data(data_out)
  );

  always #10 wr_clk = ~wr_clk;

  always #10 rd_clk = ~rd_clk;
  
  always #10 mem_clk = ~mem_clk;

  initial begin
    wr_clk = 1'b0;
    rd_clk = 1'b0;
    mem_clk = 1'b0;
    reset = 1'b0;
    wr_en_in = 1'b1;
    rd_en_in = 1'b1;
    data_in = 32'h1;

    $monitor("data_out: %h", data_out);

    #20 reset = 1'b1;
        wr_en_in = 1'b0;

    #60 data_in = 32'h2;

    #20 data_in = 32'h3;

    #20 data_in = 32'h4;

    #20 data_in = 32'h5;

    #20 data_in = 32'h6;
        wr_en_in = 1'b1;
        rd_en_in = 1'b0;
    
    #300 $finish;
  end


/*
  Conditional Environment Settings for the following:
    - Icarus Verilog
    - VCS
    - Altera Modelsim
    - Xilinx ISIM
*/
// Icarus Verilog
`ifdef IVERILOG
    initial $dumpfile("vcdbasic.vcd");
    initial $dumpvars();
`endif

// VCS
`ifdef VCS
    initial $vcdpluson;
`endif

// Altera Modelsim
`ifdef MODEL_TECH
`endif

// Xilinx ISIM
`ifdef XILINX_ISIM
`endif

endmodule
