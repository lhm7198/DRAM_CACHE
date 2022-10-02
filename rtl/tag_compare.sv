`include "AXI_TYPEDEF.svh"

module TAG_COMPARE
#(
	parameter ADDR_WIDTH 		= `AXI_ADDR_WIDTH,
	parameter ID_WIDTH 		= `AXI_ID_WIDTH,
	
	parameter INDEX_WIDTH 		= `INDEX_WIDTH,
	parameter OFFSET_WIDTH 		= `OFFSET_WIDTH,
	parameter TID_WIDTH		= `TID_WIDTH,
	
	parameter BURST_SIZE	 	= `BURST_SIZE,
	parameter BLANK_WIDTH		= `BLANK_WIDTH,

	parameter TOTAL_CYCLE		= `TOTAL_CYCLE
)
(
	input	wire					clk,
	input 	wire					rst_n,

	// R channel (Memory Ctrl -> DRAM $ Controller)
	input	wire	[ID_WIDTH - 1 : 0]			rid_i,
	input	wire	[BURST_SIZE - 1 : 0]			rdata_i,
	input	wire						rresp_i,
	input	wire						rlast_i,
	input	wire						rvalid_i,
	output 	wire						rready_o,

	// Inner wire (FIFO <-> Tag comparator)
	input	wire						tag_fifo_aempty_i,
	output	wire						tag_fifo_rden_o,
	input	wire	[ADDR_WIDTH + TID_WIDTH : 0]		tag_fifo_data_i, // R/W(1) + TID(10) + FULL ADDR(64)
	
	// Inner wire (Tag comparator <-> ROB)
	input 	wire						rob_afull_i,
	output	wire						rob_wren_o,
	output	wire	[BURST_SIZE * 8 + TID_WIDTH - 1 : 0]	rob_data_o,

	// Inner wire (Tag comparator <-> Fill AR FIFO)
	input	wire						arfifo_afull_i,
	output	wire						arfifo_wren_o,
	output	wire	[ADDR_WIDTH + TID_WIDTH - 1 : 0]	arfifo_data_o,

	// Inner wire (Tag comparator <-> Reordering Buffer)
	output 	wire	[BURST_SIZE - 1 : 0]			w_hit_data_o,
	output 	wire	[BURST_SIZE - 1 : 0]			w_miss_data_o
);

localparam			S_IDLE	= 3'd0,
				S_DEC	= 3'd1,
				S_RHIT	= 3'd2,
				S_RMISS	= 3'd3,
				S_WHIT	= 3'd4,
				S_WMISS = 3'd5;

reg	[2:0]						state,		state_n;

reg							tag_fifo_rden,	tag_fifo_rden_n;

reg							rob_wren,	rob_wren_n;
reg	[TID_WIDTH + BURST_SIZE*(TOTAL_CYCLE-1)-1 : 0]	rob_data,	rob_data_n;

reg							arfifo_wren,	arfifo_wren_n;
reg	[TID_WIDTH + ADDR_WIDTH - 1 : 0]		arfifo_data,	arfifo_data_n;

reg 							rready,		rready_n;
reg	[$clog2(TOTAL_CYCLE + 1) : 0]			cycle_cnt,	cycle_cnt_n;

wire	read  = !fifo_data_i[ADDR_WIDTH + ID_WIDTH : ADDR_WIDTH + ID_WIDTH];
wire	valid = read_data_i[BURST_SIZE - 1 : BURST_SIZE - 1];

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;

		tag_fifo_rden	<= 1'b0;

		rob_wren	<= 1'b0;
		rob_data	<= 0;

		arfifo_wren	<= 1'b0;
		arfifo_data	<= 0;

		rready		<= 1'b1;
		cycle_cnt	<= 0;
	end
	else begin
		state		<= state_n;

		tag_fifo_rden	<= tag_fifo_rden_n;
		
		rob_wren	<= rob_wren_n;
		rob_data	<= rob_data_n;

		arfifo_wren	<= arfifo_wren_n;
		arfifo_data	<= arfifo_data_n;

		rready		<= rready_n;
		cycle_cnt	<= cycle_cnt_n;

		if(cycle_cnt <= TOTAL_CYCLE && cycle_cnt >= 1) begin
			cycle_cnt <= cycle_cnt + 1;
		end
		else begin
			cycle_cnt <= 0;
		end
	end

always_comb begin
	state_n 	= state;
	
	tag_fifo_rden_n	= tag_fifo_rden;

	rob_wren_n	= rob_wren;
	rob_data_n	= rob_data;

	arfifo_wren_n	= arfifo_wren;
	arfifo_data_n	= arfifo_data;

	rready_n	= rready;
	cycle_cnt_n	= cycle_cnt;
	
	case (state)
		S_IDLE: begin
			cycle_cnt_n	= 0;
			rob_wren_n	= 1'b0;
			rob_data_n	= 0;

			arfifo_wren_n	= 1'b0;
			arfifo_data_n	= 0;

			if(rvalid_i && !tag_fifo_aempty_i) begin
				tag_fifo_rden_n		= 1'b1;

				state_n			= S_DEC;
			end
		end
		S_DEC: begin
			cycle_cnt_n	 	= 1;
			tag_fifo_rden_n 	= 1'b0;

			if(read) begin
				// read hit(valid && same tag) 
				if(valid && tag_fifo_data_i[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] == read_data_i[BURST_SIZE - 3 : BLANK_WIDTH]) begin
					rob_data_n[BURST_SIZE * 8 + 9 : BURST_SIZE * 8] = tag_fifo_data_i[ADDR_WIDTH + TID_WIDTH - 1 : ADDR_WIDTH];
					state_n		= S_RHIT;
				end
				// read miss
				else begin
					arfifo_data_n[TID_WIDTH + ADDR_WIDTH - 1 : 0] = tag_fifo_data_i[ADDR_WIDTH + TID_WIDTH - 1 : 0];
					state_n		= S_RMISS;
				end
			end
			else begin
				// write hit(valid && same tag)
				if(valid && tag_fifo_data_i[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] == read_data_i[BURST_SIZE - 3 : BLANK_WIDTH]) begin
					state_n		= S_WHIT;
				end
				// write miss
				else begin
					state_n		= S_WMISS;
				end
			end
		end
		S_RHIT: begin
			if(cycle_cnt < TOTAL_CYCLE) begin
				r_hit_data_n[BURST_SIZE * (TOTAL_CYCLE - cycle_cnt + 1) - 1 : BURST_SIZE * (TOTAL_CYCLE - cycle_cnt)] = rdata_i;
			end
			else if(cycle_cnt >= TOTAL_CYCLE) begin
				if(!rob_afull_i) begin
					rob_wren_n	= 1'b1;
					state_n		= S_IDLE;
				end
			end
		end
		S_RMISS: begin
			if(!arfifo_afull_i) begin
				arfifo_wren_n	= 1'b1;
				state_n		= S_IDLE;
			end
		end
		S_WHIT: begin
		end
		S_WMISS: begin
		end
	endcase
end

// memory ctrl
assign rready_o		= rready;

// tag fifo
assign tag_fifo_rden_o	= tag_fifo_rden;

// read hit
assign rob_wren_o	= rob_wren;
assign rob_data_o	= r_hit_data;

// read miss
assign arfifo_wren_o	= arfifo_wren;
assign arfifo_data_o	= arfifo_data;

endmodule
