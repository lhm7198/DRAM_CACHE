`include "AXI_TYPEDEF.svh"

module TAG_COMPARE
#(
	parameter ADDR_WIDTH 		= `AXI_ADDR_WIDTH,
	parameter ID_WIDTH 		= `AXI_ID_WIDTH,
	
	parameter INDEX_WIDTH 		= `INDEX_WIDTH,
	parameter OFFSET_WIDTH 		= `OFFSET_WIDTH,
	
	parameter BURST_SIZE	 	= `BURST_SIZE,
	parameter BLANK_WIDTH		= 'BLANK_WIDTH,

	parameter TOTAL_CYCLE		= `TOTAL_CYCLE
)
(
	input	wire					clk,
	input 	wire					rst_n,

	// AMBA AXI interface (R channel)
	input	wire	[ID_WIDTH - 1 : 0]		rid_i,
	input	wire	[BURST_SIZE - 1 : 0]		rdata_i,
	input	wire					rresp_i,
	input	wire					rlast_i,
	input	wire					rvalid_i,
	output 	wire					rready_o,

	// FIFO <-> Tag comparator
	input	wire					tag_fifo_aempty_i,
	output	wire					tag_fifo_rden_o,
	input	wire	[ADDR_WIDTH + ID_WIDTH : 0]	tag_fifo_data_i,
	
	// Tag comparator <-> Reordering Buffer
	output 	wire	[BURST_SIZE - 1 : 0]		r_hit_data_o,
	output 	wire	[BURST_SIZE - 1 : 0]		r_miss_data_o,
	output 	wire	[BURST_SIZE - 1 : 0]		w_hit_data_o,
	output 	wire	[BURST_SIZE - 1 : 0]		w_miss_data_o
);

localparam			S_IDLE	= 3'd0,
				S_DEC	= 3'd1,
				S_RHIT	= 3'd2,
				S_RMISS	= 3'd3,
				S_WHIT	= 3'd4,
				S_WMISS = 3'd5;

reg	[2:0]			state,		state_n;

reg	[BURST_SIZE - 1 : 0]	r_hit_data,	r_hit_data_n,
				r_miss_data,	r_miss_data_n,
				w_hit_data,	w_hit_data_n,
				w_miss_data,	w_miss_data_n;

reg				tag_fifo_rden;
reg 				rready;

wire				read  = !fifo_data_i[ADDR_WIDTH + ID_WIDTH : ADDR_WIDTH + ID_WIDTH];
wire				valid = read_data_i[BURST_SIZE - 1 : BURST_SIZE - 1];

int				cycle_cnt;
always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;

		r_hit_data	<= 0;
		r_miss_data	<= 0;
		w_hit_data	<= 0;
		w_miss_data	<= 0;

		cycle_cnt	<= 0;
	end
	else begin
		state		<= state_n;

		r_hit_data	<= r_hit_data_n;
		r_miss_data	<= r_miss_data_n;
		w_hit_data	<= w_hit_data_n;
		w_miss_data	<= w_miss_data_n;

		if(cycle_cnt < TOTAL_CYCLE && cycle_cnt >= 1) begin
			cycle_cnt <= cycle_cnt + 1;
		end
		else begin
			cycle_cnt <= 0;
		end
	end

always_comb begin
	state_n 	= state;
	
	r_hit_data_n	= r_hit_data;
	r_miss_data_n	= r_miss_data;
	w_hit_data_n	= w_hit_data;
	w_miss_data_n	= w_miss_data;

	tag_fifo_rden	= 1'b0;
	rready		= 1'b1;
	
	case (state)
		S_IDLE: begin
			if(rvalid_i && tag_fifo_aempty_i) begin
				tag_fifo_rden		= 1'b1;

				state_n			= S_DEC;
			end
		end
		S_DEC: begin
			cycle_cnt	= 1;

			if(read) begin
				// read hit(valid && same tag) 
				if(valid && fifo_data_i[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] == read_data_i[BURST_SIZE - 3 : BLANK_WIDTH]) begin
					state_n		= S_RHIT;
				end
				// read miss
				else begin
					state_n		= S_RMISS;
				end
			end
			else begin
				// write hit(valid && same tag)
				if(valid && fifo_data_i[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] == read_data_i[BURST_SIZE - 3 : BLANK_WIDTH]) begin
					state_n		= S_WHIT;
				end
				// write miss
				else begin
					state_n		= S_WMISS;
				end
			end
		end
		S_RHIT: begin
			rready			= 1'b0;

			if(cycle_cnt == 1) begin
				state_n		= S_RHIT;
			end
			else if(cycle_cnt >= 2 && cycle_cnt <= 9) begin
				r_hit_data_n	= rdata_i;
				state_n		= S_RHIT;
			end
			else begin
				state_n		= S_IDLE;
			end
		end
		S_RMISS: begin
			rready			= 1'b0;
			
			if(cycle_cnt >= 2 && !rlast_i) begin
				//r_miss_data_n	= 
				state_n		= S_IDLE;
			end
		end
		S_WHIT: begin
			rready			= 1'b0;

			if(cycle_cnt == 1) begin
				state_n		= S_WHIT;
			end
			else if(cycle_cnt >= 2 && cycle_cnt <= 9) begin
				w_hit_data_n	= rdata_i;
				state_n		= S_WHIT;
			end
			else begin
				state_n		= S_IDLE;
			end
		end
		S_WMISS: begin
			rready			= 1'b0;
			if(cycle_cnt == 1) begin
				state_n		= S_WMISS;
			end
			else if(cycle_cnt >= 2 && cycle_cnt <= 9) begin
				w_miss_data_n	= rdata_i;
				state_n		= S_WMISS;
			end
			else begin
				state_n		= S_IDLE;
			end

		end
	endcase
end

assign rready_o		= rready;

assign r_hit_data_o	= r_hit_data;
assign r_miss_data_o	= r_miss_data;
assign w_hit_data_o	= w_hit_data;
assign w_miss_data_o	= w_miss_data;

endmodule
