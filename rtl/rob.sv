`include "TYPEDEF.svh"

module ROB # (
	parameter DATA_WIDTH 	= `AXI_DATA_WIDTH,
	parameter FIFO_SIZE 	= `FIFO_SIZE,
	parameter ID_WIDTH  	= `AXI_ID_WIDTH,
	parameter TID_WIDTH	= `TID_WIDTH,
	parameter FIFO_WIDTH	= TID_WIDTH + DATA_WIDTH
)(
	input	wire					clk,
	input 	wire					rst_n,


	output	wire					valid_o,
	input	wire					ready_i,
	output	wire	[ID_WIDTH - 1 : 0]		rid_o,
	output	wire	[DATA_WIDTH - 1 : 0]		rdata_o,

	output	wire					full_hit_o,
	input	wire					write_en_hit_i,
	input	wire	[FIFO_WIDTH - 1 : 0]		wdata_hit_i,	

	output	wire					full_miss_o,
	input	wire					write_en_miss_i,
	input	wire	[FIFO_WIDTH - 1 : 0]		wdata_miss_i
);

localparam 		S_IDLE		= 1'd0,
			S_VAL		= 1'd1;

// tag compare - rob
wire					full_hit;
wire					write_en_hit;
wire	[FIFO_WIDTH - 1 : 0]		write_data_hit;

wire					empty_hit;
wire	[FIFO_WIDTH - 1 : 0]		read_data_hit;

// cxl controller - rob
wire					full_miss;
wire					write_en_miss;
wire	[FIFO_WIDTH - 1 : 0]		write_data_miss;

wire					empty_miss;
wire	[FIFO_WIDTH - 1 : 0]		read_data_miss;

// registers
reg	[2 : 0]				state, state_n;

reg	[TID_WIDTH - 1 : 0]		tID, tID_n;
reg	[TID_WIDTH - 1 : 0]		tID_hit, tID_hit_n;
reg	[TID_WIDTH - 1 : 0]		tID_miss, tID_miss_n;

reg	[FIFO_WIDTH - 1: 0]		rdata, rdata_n;

reg					en_hit, en_miss;

reg					valid;
reg	[ID_WIDTH - 1 : 0]		rid, rid_n;



always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
		tID		<= 1;
		rid		<= 0;
		rdata		<= 0;
		tID_hit		<= 0;
		tID_miss	<= 0;
	end
	else begin
		state		<= state_n;
		tID		<= tID_n;
		rid		<= rid_n;
		rdata		<= rdata_n;
		tID_hit		<= tID_hit_n;
		tID_miss	<= tID_miss_n;
	end
end

always_comb begin

	$display("%d %d %d", tID, tID_hit, tID_miss);
	state_n		= state;
	tID_n		= tID;
	rid_n		= rid;
	tID_hit_n	= read_data_hit[FIFO_WIDTH-1 : DATA_WIDTH];
	tID_miss_n	= read_data_miss[FIFO_WIDTH-1 : DATA_WIDTH];
	case (state)
		S_IDLE: begin
			en_hit			= 0;
			en_miss			= 0;
			if((!empty_hit & (tID == tID_hit)) | (!empty_miss & (tID == tID_miss))) begin
				tID_n	= tID + 1;

				if(tID == tID_hit) begin
					rdata_n		= read_data_hit;
					en_hit		= 1;
				end
				else begin
					rdata_n		= read_data_miss;
					en_miss		= 1;
				end
				state_n			= S_VAL;
				valid			= 1;
			end
		end
		S_VAL: begin
			if(ready_i) begin
				en_hit			= 1;
				en_miss			= 1;
				valid			= 0;
				state_n			= S_IDLE;
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
	.write_data_i	(wdata_hit_i),

	.empty_o	(empty_hit),
	.read_en_i	(en_hit),
	.read_data_o	(read_data_hit)
);


FIFO	miss_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.full_o		(full_miss),
	.write_en_i	(write_en_miss_i),
	.write_data_i	(wdata_miss_i),

	.empty_o	(empty_miss),
	.read_en_i	(en_miss),
	.read_data_o	(read_data_miss)
);

assign	valid_o			= valid;
assign	rid_o			= rid;
assign	rdata_o			= rdata;

assign	full_hit_o		= full_hit;
assign	full_miss_o		= full_miss;


endmodule
