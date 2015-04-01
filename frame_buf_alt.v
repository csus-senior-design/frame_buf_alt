`ifndef ASSERT
`define ASSERT 1'b0
`define DEASSERT 1'b1
`endif

`include "data_mem/data_mem.v"

module frame_buf #(parameter DATA_WIDTH = 24, ADDR_WIDTH = 3,
                    MEM_DEPTH = 1 << ADDR_WIDTH, NUM_BUFS = 1)
  (
    input wr_clk, rd_clk, reset, wr_en_in, rd_en_in,
    input [DATA_WIDTH - 1:0] data_in,
    output [DATA_WIDTH - 1:0] data_out
  );
  
  parameter IDLE = 1'h0, FILL = 1'h1, READ = 1'h1;
  
  reg wr_en, rd_en, mem_rdy;
  reg [ADDR_WIDTH - 1:0] wr_addr, rd_addr;
  reg curr_state, next_state, rd_curr_state, rd_next_state;
  
  data_mem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
           mem (.clk(wr_clk), .wr_en(wr_en), .rd_en(rd_en), .reset(reset),
            .wr_addr(wr_addr), .rd_addr(rd_addr), .wr_data(data_in),
            .rd_data(data_out));
            
  always @(posedge wr_clk) begin
    if (reset == `ASSERT)
      curr_state <= IDLE;
    else
      curr_state <= next_state;
  end
  
  always @(negedge wr_clk) begin
    next_state <= IDLE;
    case (curr_state)
      IDLE:   begin
                wr_addr <= {ADDR_WIDTH{1'b0}};
                if (rd_addr <= wr_addr || reset == `ASSERT)
                  mem_rdy <= 1'b0;
                if (wr_en_in == `ASSERT) begin
                  next_state <= FILL;
                  wr_en <= `ASSERT;
                end else begin
                  next_state <= IDLE;
                  wr_en <= `DEASSERT;
                  end
              end
            
      FILL:   begin
                if (wr_addr == {ADDR_WIDTH{1'b1}})
                  next_state <= IDLE;
                else if (wr_en_in == `ASSERT) begin
                  next_state <= FILL;
                  mem_rdy <= 1'b1;
                  wr_en <= `ASSERT;
                  wr_addr <= wr_addr + 1;
                end else begin
                  next_state <= FILL;
                  wr_en <= `DEASSERT;
                end
              end
    endcase
  end
  
  always @(posedge rd_clk) begin
    if (reset == `ASSERT)
      rd_curr_state <= IDLE;
    else
      rd_curr_state <= rd_next_state;
  end
  
  always @(negedge rd_clk) begin
    rd_next_state <= IDLE;
    case (rd_curr_state)
      IDLE:   begin
                rd_addr <= {ADDR_WIDTH{1'b0}};
                if (rd_en_in == `ASSERT && mem_rdy == 1'b1) begin
                  rd_next_state <= READ;
                  rd_en <= `ASSERT;
                end else begin
                  rd_next_state <= IDLE;
                  rd_en <= `DEASSERT;
                end
              end
            
      READ:   begin
                if (rd_addr == {ADDR_WIDTH{1'b1}})
                  rd_next_state <= IDLE;
                else if (rd_en_in == `ASSERT) begin
                  rd_next_state <= READ;
                  rd_en <= `ASSERT;
                  rd_addr <= rd_addr + 1;
                end else begin
                  rd_next_state <= READ;
                  rd_en <= `DEASSERT;
                end
              end
    endcase
  end

endmodule
