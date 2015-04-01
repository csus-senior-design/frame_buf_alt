`include "frame_buf_alt.v"

module frame_buf_alt_tb;

  reg wr_clk, rd_clk, reset, wr_en_in, rd_en_in;
  reg [23:0] data_in;
  wire [23:0] data_out;

  frame_buf_alt uut(.wr_clk(wr_clk), .rd_clk(rd_clk), .reset(reset),
                .wr_en_in(wr_en_in), .rd_en_in(rd_en_in),
                .data_in(data_in), .data_out(data_out));

  always #10 wr_clk = ~wr_clk;

  always #10 rd_clk = ~rd_clk;

  initial begin
    wr_clk = 1'b0;
    rd_clk = 1'b0;
    reset = 1'b0;
    wr_en_in = 1'b1;
    rd_en_in = 1'b1;
    data_in = 24'h1;

    $monitor("data_out: %h", data_out);

    #20 reset = 1'b1;
    wr_en_in = 1'b0;

    #20 data_in = 24'h2;

    #20 data_in = 24'h3;

    #20 data_in = 24'h4;
    rd_en_in = 1'b0;

    #20 data_in = 24'h5;

    #20 data_in = 24'h6;

    #20 data_in = 24'h7;

    #20 data_in = 24'h8;

    #20 data_in = 24'h9;

    #20 data_in = 24'hA;

    #20 $finish;
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
