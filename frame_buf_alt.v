/*
--------------------------------------------------
Stereoscopic Vision System
Senior Design Project - Team Honeybadger (Team 11)
California State University, Sacramento
Spring 2015 / Fall 2015
--------------------------------------------------

Frame Buffer for the Altera External Memory Interface
Authors:	Padraic Hagerty (guitarisrockin@hotmail.com)

Description:
	This is the frame buffer designed for the Altera Cyclone 5 GX Starter Kit.
	It autonomously handles all addressing to the memory based upon the rd_en
	and wr_en signals.
	
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
				BUF_SIZE = 307200				// 640 * 480 pixels
)(
	input							clk,
									reset,
									wr_en,
									rd_en,
									ram_rdy,
									avl_ready,
	output	reg						avl_write_req,
									avl_read_req,
									full = DEASSERT_H,
									rd_done = DEASSERT_H,
	output	reg	[ADDR_WIDTH - 1:0]	wr_addr,
									rd_addr,
	output		[ADDR_WIDTH - 1:0]	avl_addr
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
	
	//reg						mem_rdy = 1'b0;
	reg						mem_rdy = 1'b1;
	(* syn_encoding = "safe" *)
	reg						curr_state = IDLE,
							rd_curr_state = IDLE;
	reg						rd_data_valid_reg,
							wr_c = 1'b0,
							rd_c = 1'b0;
	reg	[ADDR_WIDTH - 1:0]	wr_addr_stop,
							rd_addr_stop;
		
	assign avl_addr = (avl_read_req) ? rd_addr : wr_addr;
	
	always @(*) begin
		if (~reset) begin
			avl_write_req = DEASSERT_H;
			avl_read_req = DEASSERT_H;
		end else begin
			if (wr_en == ASSERT_L && avl_ready &&
					wr_addr < BASE_ADDR + BUF_SIZE && rd_en != ASSERT_L)
				avl_write_req = ASSERT_H;
			else
				avl_write_req = DEASSERT_H;
			
			if (rd_en == ASSERT_L && avl_ready &&
					rd_addr < BASE_ADDR + BUF_SIZE && wr_en != ASSERT_L)
				avl_read_req = ASSERT_H;
			else
				avl_read_req = DEASSERT_H;
		end
	end
	
	always @(posedge clk) begin
		if (~reset) begin
		
			curr_state <= IDLE;
			wr_addr <= BASE_ADDR;
			//mem_rdy <= DEASSERT_H;
			mem_rdy <= ASSERT_H;
			wr_c <= 1'b0;
			full <= DEASSERT_H;
			//avl_write_req <= DEASSERT_H;
			
		end else if (ram_rdy) begin
			full <= DEASSERT_H;
				
			if (wr_addr == BASE_ADDR + BUF_SIZE) begin
			
				wr_addr <= BASE_ADDR;
				wr_c <= ~wr_c;
				//wr_en <= DEASSERT_L;
				//avl_write_req <= DEASSERT_H;
				full <= ASSERT_H;
				
			end else if (wr_en == ASSERT_L && avl_ready/* &&
							((wr_addr >= rd_addr && rd_c == wr_c) ||
							(wr_addr < rd_addr && rd_c != wr_c))*/) begin
										
				//mem_rdy <= 1'b1;
				//wr_en <= ASSERT_L;
				//avl_write_req <= ASSERT_H;
				wr_addr <= wr_addr + 1;
						
			end
			
		end
		
	end
	
	always @(posedge clk) begin
		if (~reset) begin
		
			rd_addr <= BASE_ADDR;
			rd_c <= 1'b0;
			rd_done <= DEASSERT_H;
			//avl_read_req <= DEASSERT_H;
			
		end else if (ram_rdy) begin
			rd_done <= DEASSERT_H;
			
			if (rd_addr == BASE_ADDR + BUF_SIZE) begin
			
				rd_addr <= BASE_ADDR;
				rd_c <= ~rd_c;
				//rd_en <= DEASSERT_L;
				//avl_read_req <= DEASSERT_H;
				rd_done <= ASSERT_H;
				
			end else if (rd_en == ASSERT_L && wr_en == DEASSERT_L &&
							avl_ready/* &&
							((rd_addr < wr_addr && rd_c == wr_c) ||
							(rd_addr >= wr_addr && rd_c != wr_c))*/)
																begin
				
				//rd_en <= ASSERT_L;
				//avl_read_req <= ASSERT_H;
				rd_addr <= rd_addr + 1;
			
			end
			
		end
		
	end

endmodule
