/*
--------------------------------------------------
Stereoscopic Vision System
Senior Design Project - Team Honeybadger (Team 11)
California State University, Sacramento
Spring 2015 / Fall 2015
--------------------------------------------------

Frame Buffer for the Altera External Memory Interface
Authors: Padraic Hagerty (guitarisrockin@hotmail.com)

Description:
	This is the frame buffer designed for the Altera Cyclone 5 GX Starter Kit.
	It autonomously handles all addressing to the memory based upon the rd_en_in
	and wr_en_in signals.
	
Instructions:
	Look at frame_buf_alt_tb.v for an example of how this module should be
	connected with the memory interface. The memory in the testbench is a
	model of the memory interface written for the Altera Cyclone 5 GX Starter
	Kit.
*/

module frame_buf_alt #(
	parameter	DATA_WIDTH = 32,
				ADDR_WIDTH = 29,
				MEM_DEPTH = 1 << ADDR_WIDTH,
				BASE_ADDR = 2,
				BUF_SIZE = 307200
)(
	input							wr_clk,
									rd_clk,
									reset,
									wr_en_in,
									rd_en_in,
									wr_rdy,
									rd_rdy,
	output	reg						wr_en,
									rd_en,
									full,
	output	reg	[ADDR_WIDTH - 1:0]	wr_addr,
									rd_addr
);

	localparam
		ASSERT_L = 1'b0,
		DEASSERT_L = 1'b1,
		ASSERT_H = 1'b1,
		DEASSERT_H = 1'b0;
	
	localparam
		IDLE = 1'h0,
		FILL = 1'h1,
		READ = 1'h1;
	
	reg	mem_rdy = 1'b0;
	(* syn_encoding = "safe" *)
	reg	curr_state = IDLE,
			rd_curr_state = IDLE;
	reg	rd_data_valid_reg,
			wr_c = 1'b0,
			rd_c = 1'b0,
			rd_done = DEASSERT_H;
	
	always @(posedge wr_clk) begin
		if (~reset) begin
		
			curr_state <= IDLE;
			wr_addr <= BASE_ADDR;
			wr_en <= DEASSERT_L;
			mem_rdy <= DEASSERT_H;
			wr_c <= 1'b0;
			full <= DEASSERT_H;
			
		end else
		
			case (curr_state)
				IDLE: begin
					if (wr_en_in == ASSERT_L && ((wr_addr >= rd_addr &&
							rd_c == wr_c) || (wr_addr < rd_addr &&
							rd_c != wr_c))) begin
							
						curr_state <= FILL;
						wr_en <= ASSERT_L;
						full <= DEASSERT_H;
						
					end else begin
					
						curr_state <= IDLE;
						wr_en <= DEASSERT_L;
						
						if (rd_done)
							full <= DEASSERT_H;
							
					end
				end
							
				FILL: begin
					if (wr_addr == BASE_ADDR + BUF_SIZE - 1) begin
					
						curr_state <= IDLE;
						wr_addr <= BASE_ADDR;
						wr_c <= ~wr_c;
						wr_en <= DEASSERT_L;
						full <= ASSERT_H;
						
					end else if (wr_en_in == ASSERT_L && ((wr_addr >= rd_addr &&
										rd_c == wr_c) || (wr_addr < rd_addr &&
										rd_c != wr_c))) begin
												
						curr_state <= FILL;
						mem_rdy <= 1'b1;
						wr_en <= ASSERT_L;
						
						if (wr_rdy)
							if (wr_addr == BASE_ADDR + BUF_SIZE - 1) begin
								curr_state <= IDLE;
								wr_addr <= BASE_ADDR;
								wr_c <= ~wr_c;
								wr_en <= DEASSERT_L;
								full <= ASSERT_H;
							end else
								wr_addr <= wr_addr + 1;
								
					end else begin
					
						curr_state <= FILL;
						wr_en <= DEASSERT_L;
						
					end
					
				end
				
			endcase
	end
	
	always @(posedge rd_clk) begin
		if (~reset) begin
		
			rd_curr_state <= IDLE;
			rd_en <= DEASSERT_L;
			rd_addr <= BASE_ADDR;
			rd_c <= 1'b0;
			rd_done <= DEASSERT_H;
			
		end else
		
			case (rd_curr_state)
				IDLE: begin
					if (rd_en_in == ASSERT_L && mem_rdy == 1'b1 &&
							((rd_addr < wr_addr && rd_c == wr_c) ||
							(rd_addr >= wr_addr && rd_c != wr_c))) begin
							
						rd_curr_state <= READ;
						rd_en <= ASSERT_L;
						rd_done <= DEASSERT_H;
						
					end else begin
					
						rd_curr_state <= IDLE;
						rd_en <= DEASSERT_L;
						
					end
				end
							
				READ: begin
					if (rd_addr == BASE_ADDR + BUF_SIZE - 1) begin
					
						rd_curr_state <= IDLE;
						rd_addr <= BASE_ADDR;
						rd_c <= ~rd_c;
						rd_en <= DEASSERT_L;
						rd_done <= ASSERT_H;
						
					end else if (rd_en_in == ASSERT_L && ((rd_addr < wr_addr &&
										rd_c == wr_c) || (rd_addr >= wr_addr &&
										rd_c != wr_c))) begin
						
						rd_curr_state <= READ;
						rd_en <= ASSERT_L;
						
						if (rd_rdy)
							if (rd_addr == BASE_ADDR + BUF_SIZE - 1) begin
								rd_curr_state <= IDLE;
								rd_addr <= BASE_ADDR;
								rd_c <= ~rd_c;
								rd_en <= DEASSERT_L;
								rd_done <= ASSERT_H;
							end else
								rd_addr <= rd_addr + 1;
					
					end else begin
						rd_curr_state <= READ;
						rd_en <= DEASSERT_L;
					end
					
				end
				
			endcase
			
	end

endmodule
