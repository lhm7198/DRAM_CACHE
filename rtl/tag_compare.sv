module TAG_COMPARE
#(
	parameter INDEX_BIT_SIZE = 8,
	parameter TAG_BIT_SIZE	= 56
)
(
	input	wire				clk,
	input 	wire				rst_n,

	// AMBA AXI interface (R channel)
	input	wire	[71 : 0]		rdata_i,
	input 	wire	[TAG_BIT_SIZE-1 : 0]	rtag_i,
	input	wire				rvalid_i,
	output 	wire				rready_o,

	// FIFO -> Tag comparator
	input	wire				fifo_aempty_i,
	//input	wire				fifo_read_en_i,
	input	wire	[80 : 0]		fifo_data_i,
	
	// Tag comparator -> Reordering Buffer
	output 	wire	[71 : 0]		r_hit_data_o,
	output 	wire	[71 : 0]		r_miss_data_o,
	output 	wire	[71 : 0]		w_hit_data_o,
	output 	wire	[71 : 0]		w_miss_data_o
);

localparam		S_IDLE	= 3'd0,
			S_RHIT	= 3'd1,
			S_RMISS	= 3'd2,
			S_WHIT	= 3'd3,
			S_WMISS = 3'd4;

reg	[2:0]		state,		state_n;

reg	[71:0]		r_hit_data,	r_hit_data_n,
			r_miss_data,	r_miss_data_n,
			w_hit_data,	w_hit_data_n,
			w_miss_data,	w_miss_data_n;


reg 			rready;

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;

		r_hit_data	<= 0;
		r_miss_data	<= 0;
		w_hit_data	<= 0;
		w_miss_data	<= 0;
	end
	else begin
		state		<= state_n;

		r_hit_data	<= r_hit_data_n;
		r_miss_data	<= r_miss_data_n;
		w_hit_data	<= w_hit_data_n;
		w_miss_data	<= w_miss_data_n;
	end

always_comb begin
	state_n 	= state;
	
	r_hit_data_n	= r_hit_data;
	r_miss_data_n	= r_miss_data;
	w_hit_data_n	= w_hit_data;
	w_miss_data_n	= w_miss_data;
	
	rready		= 1'b1;
	
	case (state)
		S_IDLE: begin
			if(!rvalid_i) begin
				state_n			= state;
			end
			else if(fifo_data_i[80:80] == 0) begin
				if(fifo_data_i[63 : INDEX_BIT_SIZE] == rtag_i) begin
					state_n		= S_RHIT;
				end
				else begin
					state_n		= S_RMISS;
				end
			end
			else if(fifo_data_i[80:80] == 1) begin
				if(fifo_data_i[63 : INDEX_BIT_SIZE] == rtag_i) begin
					state_n		= S_WHIT;
				end
				else begin
					state_n		= S_WMISS;
				end
			end
		end
		S_RHIT: begin
			rready			= 1'b0;
			r_hit_data_n		= rdata_i;
			r_miss_data_n		= 0;
			w_hit_data_n		= 0;
			w_miss_data_n		= 0;
			state_n			= S_IDLE;
		end
		S_RMISS: begin
			rready			= 1'b0;
			r_hit_data_n		= 0;
			r_miss_data_n		= rdata_i;
			w_hit_data_n		= 0;
			w_miss_data_n		= 0;
			state_n			= S_IDLE;
		end
		S_WHIT: begin
			rready			= 1'b0;
			r_hit_data_n		= 0;
			r_miss_data_n		= 0;
			w_hit_data_n		= rdata_i;
			w_miss_data_n		= 0;
			state_n			= S_IDLE;
	
		end
		S_WMISS: begin
			rready			= 1'b0;
			r_hit_data_n		= 0;
			r_miss_data_n		= 0;
			w_hit_data_n		= 0;
			w_miss_data_n		= rdata_i;
			state_n			= S_IDLE;

		end
	endcase
end

assign rready_o		= rready;

assign r_hit_data_o	= r_hit_data;
assign r_miss_data_o	= r_miss_data;
assign w_hit_data_o	= w_hit_data;
assign w_miss_data_o	= w_miss_data;

endmodule
