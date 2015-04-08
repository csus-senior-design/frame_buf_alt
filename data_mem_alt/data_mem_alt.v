`ifndef ASSERT_L
`define ASSERT_L 1'b0
`define DEASSERT_L 1'b1
`endif
`ifndef ASSERT_H
`define ASSERT_H 1'b1
`define DEASSERT_H 1'b0
`endif

module data_mem_alt #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 29, MEM_DEPTH = 1 << ADDR_WIDTH)
  (
    input [ADDR_WIDTH - 1:0] wr_addr, rd_addr,
    input [DATA_WIDTH - 1:0] wr_data,
    input clk, wr_en, rd_en, reset,
    output reg rd_data_valid, wr_rdy,
    output reg [DATA_WIDTH - 1:0] rd_data
  );
  
   /* Define the required states. */
  parameter IDLE = 2'h0, WRITE = 2'h1, READ = 2'h2;
  
  reg [DATA_WIDTH - 1:0] mem [MEM_DEPTH - 1:0];
  reg [ADDR_WIDTH - 1:0] prev_rd_addr, prev_wr_addr;
  reg [1:0] curr_state;
  integer i;

  /* Begin interface logic */
  always @(posedge clk) begin
    if (reset == `ASSERT_L) begin
      for (i = 0; i < MEM_DEPTH; i = i + 1)
        mem[i] <= {DATA_WIDTH{1'b0}};
      prev_rd_addr <= {ADDR_WIDTH{1'h0}};
      prev_wr_addr <= {ADDR_WIDTH{1'h0}};
      rd_data <= {DATA_WIDTH{1'bZ}};
      rd_data_valid <= `DEASSERT_H;
      curr_state <= IDLE;
      wr_rdy <= `DEASSERT_H;
    end else
      rd_data_valid <= `DEASSERT_H;
      case (curr_state)
        IDLE:   begin
                  wr_rdy <= `DEASSERT_H;
                  if (wr_en == `ASSERT_L && rd_en == `DEASSERT_L
                        && prev_wr_addr != wr_addr) begin
                    curr_state <= WRITE;
                    wr_rdy <= `ASSERT_H;
                  end else if (rd_en == `ASSERT_L && wr_en == `DEASSERT_L
                            && prev_rd_addr != rd_addr)
                    curr_state <= READ;
                  else
                    curr_state <= IDLE;
                end
        
        WRITE:  begin
                  wr_rdy <= `ASSERT_H;
                  if (wr_en == `ASSERT_L && prev_wr_addr != wr_addr) begin
                    mem[wr_addr] <= wr_data;
                    prev_wr_addr <= wr_addr;
                  end
                  
                  if (rd_en == `ASSERT_L || (rd_en == `ASSERT_L &&
                        wr_en == `ASSERT_L))
                    curr_state <= READ;
                  else if (wr_en == `ASSERT_L)
                    curr_state <= WRITE;
                  else
                    curr_state <= IDLE;
                end
        
        READ:   begin
                  rd_data_valid <= `DEASSERT_H;
                  if (rd_en == `ASSERT_L && prev_rd_addr != rd_addr) begin
                    rd_data <= mem[rd_addr];
                    prev_rd_addr <= rd_addr;
                    rd_data_valid <= `ASSERT_H;
                  end
                  
                  if (wr_en == `ASSERT_L || (rd_en == `ASSERT_L &&
                        wr_en == `ASSERT_L))
                    curr_state <= WRITE;
                  else if (rd_en == `ASSERT_L)
                    curr_state <= READ;
                  else
                    curr_state <= IDLE;
                end
      endcase
  end
    
endmodule