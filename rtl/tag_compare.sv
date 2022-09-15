module TAG_COMPARE
#(
	parameter TAG_BIT_SIZE = 4
)
(
	input	wire				clk,
	input 	wire				rst_n,

	// AMBA AXI interface (R channel)
	input	wire	[ID_WIDTH-1 : 0]	rid_i,
	input	wire	[? : ?]			rdata_i,
	input	wire				rvalid_i,
	output 	wire				rready_o,

	// FIFO -> Tag comparator
	input	wire	[80 : 0]		fifo_data_i,
	
	// ? input 	wire	[63-TAG_BIT_SIZE : 0]	tag_i,
	// ? input 	wire	[? : ?]			data_i,

	// Tag comparator -> Reordering Buffer
	output 	wire	[80 : 0]		r_hit_data_o,
	output 	wire	[80 : 0]		r_miss_data_o,
	output 	wire	[80 : 0]		w_hit_data_o,
	output 	wire	[80 : 0]		w_miss_data_o,
);

localparam		S_IDLE	= 3'd0,
			S_RHIT	= 3'd1,
			S_RMISS	= 3'd2,
			S_WHIT	= 3'd3,
			S_WMISS = 3'd4;

reg	[2:0]		state,		state_n;

reg 			rready;

reg	[80:0]		r_hit_data,
			r_miss_data,
			w_hit_data,
			w_miss_data;

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;

		r_hit_data	<= 80'd0;
		r_miss_data	<= 80'd0;
		w_hit_data	<= 80'd0;
		w_miss_data	<= 80'd0;
	end
	else begin
		state		<= state_n;
	end

always_comb begin
	state_n 	= state;
	
	r_hit_data	= 80'd0;
	r_miss_data	= 80'd0;
	w_hit_data	= 80'd0;
	w_miss_data	= 80'd0;
	
	rready		= 1'b1;
	
	case (state)
		S_IDLE: begin
			if(fifo_data_i[80:80] == 0) begin
				if(fifo_data_i[63 : TAG_BIT_SIZE] == tag_i[63-TAG_BIT_SIZE : 0]) begin
					state_n		= S_RHIT;
				end
				else begin
					state_n		= S_RMISS;
				end
			end
			else begin
				if(fifo_data_i[63 : TAG_BIT_SIZE] == tag_i[63-TAG_BIT_SIZE : 0]) begin
					state_n		= S_WHIT;
				end
				else begin
					state_n		= S_WMISS;
				end
			end
		end
		S_RHIT: begin
			r_hit_data		= fifo_data_i;
		end
		S_RMISS: begin
			r_miss_data		= fifo_data_i;
		end
		S_WHIT: begin
			w_hit_data		= fifo_data_i;
		end
		S_WMISS: begin
			w_miss_data		= fifo_data_i;
		end
	endcase
end

assign rready_o		= rready;
assign r_hit_data_o	= r_hit_data;
assign r_hit_data_o	= r_miss_data;
assign w_hit_data_o	= r_hit_data;
assign w_hit_data_o	= r_miss_data;

endmodule
