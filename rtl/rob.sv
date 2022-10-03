`include "TYPEDEF.svh"

module ROB # (
	parameter DATA_WIDTH 	= `FIFO_DATA_WIDTH, // 8
	parameter FIFO_SIZE 	= `FIFO_SIZE, // 8
	parameter ID_WIDTH  	= `AXI_ID_WIDTH,
	parameter MAX_TID	= 'MAX_TID
)(
	input	wire					clk,
	input 	wire					rst_n,


	output	wire					valid_o,
	input	wire					ready_i,
	output	wire	[ID_WIDTH - 1 : 0]		rid_o,
	output	wire	[DATA_WIDTH - 1 : 0]		rdata_o,

	output	wire					full_hit_o,
	input	wire					write_en_hit_i,
	input	wire	[DATA_WIDTH - 1 : 0]		rdata_hit_i,	

	output	wire					full_miss_o,
	input	wire					write_en_miss_i,
	input	wire	[DATA_WIDTH - 1 : 0]		rdata_miss_i,	

);

localparam 		S_IDLE		= 3'd0,
			S_VALID		= 3'd1,
			S_HIT		= 3'd2,
			S_MISS		= 3'd3;

wire					full_hit;
wire					write_en_hit;
wire	[DATA_WIDTH - 1 : 0]		write_data_hit;

wire					empty_hit;
wire					read_en_hit;
wire	[DATA_WIDTH - 1 : 0]		read_data_hit;


wire					full_miss;
wire					write_en_miss;
wire	[DATA_WIDTH - 1 : 0]		write_data_miss;

wire					empty_miss;
wire					read_en_miss;
wire	[DATA_WIDTH - 1 : 0]		read_data_miss;

reg	[2 : 0]				state, state_n;

reg	[ID_WIDTH - 1 : 0]		tID;
reg	[ID_WIDTH - 1 : 0]		tID_hit, tID_miss;
reg	[:]				rdata, rdata_n;

reg					valid, valid_n;
reg	[ID_WIDTH - 1 : 0]		rid, rdi_n;

reg					flag;


always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
		tID		<= 0;
		tID_hit		<= 0;
		tID_miss	<= 0;
		valid		<= 0;
		rid		<= 0;
		flag		<= 0;
		rdata		<= 0;
	end
	else begin
		state		<= state_n;
		tID		<= tID_n;
		tID_hit		<= read_data_hit[:];
		tID_miss	<= read_data_miss[:];
		valid		<= valid_n;
		rid		<= rid_n;
		flag		<= flag_n;
		rdata		<= rdata_n;
	end
end

always_comb begin
	state_n		= state;
	tID_n		= tID;
	valid_n		= valid;
	rid_n		= rid;
	flag_n		= flag;

	case (state)
		S_IDLE: begin
			if((!empty_hit && tID == tID_hit) || (!empty_miss && tID == tID_miss)) begin
				if(tID == MAX_TID - 1)
					tID_n		= 0;
				else
					tID_n		= tID + 1;

				if(tID == tID_hit) begin
					flag_n		= 0;
					rdata_n		= read_data_hit;
				end
				else begin
					flag_n		= 1;
					rdata_n		= read_data_miss;
				end
				state_n			= S_VALID;
				valid_n			= 1;
		end
		S_VAL: begin
			if(ready_i)    //??
				valid_n			= 0;
				state_n			= S_IDLE;
				if(flag == 0) begin
					read_en_hit		= 1;
				end
				else begin
					read_en_miss		= 1;
				end
		end
	endcase
end


FIFO	hit_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.full_o		(full_hit),
	.write_en_i	(write_en_hit_i),
	.write_data_i	(write_data_hit_i),

	.empty_o	(empty_hit),
	.read_en_i	(read_en_hit),
	.read_data_o	(read_data_hit)
);


FIFO	miss_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.full_o		(full_miss),
	.write_en_i	(write_en_miss_i),
	.write_data_i	(write_data_miss_i),

	.empty_o	(empty_miss),
	.read_en_i	(read_en_miss),
	.read_data_o	(read_data_miss)
);

assign	valid_o			= valid;
assign	rid_o			= rid;
assign	rdata_o			= rdata;

assign	full_hit_o		= full_hit;
assign	full_miss_o		= full_miss;


endmodule
