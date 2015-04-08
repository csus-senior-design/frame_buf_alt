`ifndef ASSERT_L
`define ASSERT_L 1'b0
`define DEASSERT_L 1'b1
`endif

`ifndef ASSERT_H
`define ASSERT_H 1'b1
`define DEASSERT_H 1'b0
`endif

`include "data_mem_alt/data_mem_alt.v"

module frame_buf_alt #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 3,
                    MEM_DEPTH = 1 << ADDR_WIDTH, NUM_BUFS = 1)
  (
    input wr_clk, rd_clk, reset, wr_en_in, rd_en_in,
    input [DATA_WIDTH - 1:0] data_in,
    output [DATA_WIDTH - 1:0] data_out
  );
  
  parameter IDLE = 1'h0, FILL = 1'h1, READ = 1'h1;
  
  reg wr_en, rd_en, mem_rdy;
  reg [ADDR_WIDTH - 1:0] wr_addr, rd_addr;
  reg curr_state, rd_curr_state, rd_data_valid_reg, wr_c, rd_c;
  
  data_mem_alt #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
           mem (.clk(wr_clk), .wr_en(wr_en), .rd_en(rd_en), .reset(reset),
            .wr_addr(wr_addr), .rd_addr(rd_addr), .wr_data(data_in),
            .rd_data_valid(rd_data_valid), .rd_data(data_out));
            
  always @(posedge wr_clk) begin
    if (reset == `ASSERT_L) begin
      curr_state <= IDLE;
      wr_addr <= {ADDR_WIDTH{1'b0}} + 2;
      wr_en <= `DEASSERT_L;
      mem_rdy <= `DEASSERT_H;
      wr_c <= 1'b0;
    end else
      case (curr_state)
        IDLE:   begin
                  if (wr_en_in == `ASSERT_L) begin
                    curr_state <= FILL;
                    wr_en <= `ASSERT_L;
                  end else begin
                    curr_state <= IDLE;
                    wr_en <= `DEASSERT_L;
                  end
                end
              
        FILL:   begin
                  if (wr_addr == {ADDR_WIDTH{1'b1}})
                    curr_state <= IDLE;
                  else if (wr_en_in == `ASSERT_L) begin
                    curr_state <= FILL;
                    mem_rdy <= 1'b1;
                    wr_en <= `ASSERT_L;
                    {wr_c, wr_addr} <= wr_addr + 1;
                  end else begin
                    curr_state <= FILL;
                    wr_en <= `DEASSERT_L;
                  end
                end
      endcase
  end
  
  always @(posedge rd_clk) begin
    if (reset == `ASSERT_L) begin
      rd_curr_state <= IDLE;
      rd_en <= `DEASSERT_L;
      rd_addr <= {ADDR_WIDTH{1'b0}} + 2;
      rd_c <= 1'b0;
    end else
      case (rd_curr_state)
        IDLE:   begin
                  if (rd_en_in == `ASSERT_L && mem_rdy == 1'b1) begin
                    rd_curr_state <= READ;
                    rd_en <= `ASSERT_L;
                  end else begin
                    rd_curr_state <= IDLE;
                    rd_en <= `DEASSERT_L;
                  end
                end
              
        READ:   begin
                  if (rd_addr == {ADDR_WIDTH{1'b1}})
                    rd_curr_state <= IDLE;
                    {rd_c, rd_addr} <= rd_addr + 1;
                  else if (rd_en_in == `ASSERT_L && ((rd_addr < wr_addr &&
                            rd_c == wr_c) || (rd_addr >= wr_addr &&
                            rd_c != wr_c))) begin
                    rd_curr_state <= READ;
                    rd_en <= `ASSERT_L;
                    {rd_c, rd_addr} <= rd_addr + 1;
                  end else begin
                    rd_curr_state <= READ;
                    rd_en <= `DEASSERT_L;
                  end
                end
      endcase
  end

endmodule
