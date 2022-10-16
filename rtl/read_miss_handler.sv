`include "TYPEDEF.svh"

module READ_MISS_HANDLER # (
	parameter	ADDR_WIDTH	= `AXI_ADDR_WIDTH,
	parameter	DATA_WIDTH	= `AXI_DATA_WIDTH,
	parameter	WDATA_WIDTH	= ADDR_WIDTH + DATA_WIDTH
)(
	input	wire		clk,
	input	wire		rst_n,

	//CXL ctr
	input	wire					valid_i,
	output	wire					ready_o,
	input	wire	[DATA_WIDTH-1 : 0]		data_i,

	//R_MISS_FIFO
	output	wire					read_en_o,
	input	wire					empty_i,
	input	wire	[ADDR_WIDTH-1 : 0]		ar_i,

	//ROB
	output	wire					write_en_o,
	input	wire					full_i,
	output	wire	[WDATA_WIDTH-1 : 0]		wdata_ROB_o,

	//Arbiter
	output	wire					valid_o,
	input	wire					ready_i,
	output	wire	[WDATA_WIDTH-1 : 0]		wdata_Arbiter_o
);

localparam		S_IDLE	= 2'd0,
			S_READY	= 2'd1,
			S_RUN	= 2'd2;

reg	[1 : 0]				state, state_n;
reg					ready, ready_n;
reg	[WDATA_WIDTH-1 : 0]		wdata, wdata_n;
reg					valid, valid_n;
reg					write_en, write_en_n;
reg					read_en, read_en_n;

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;

		wdata		<= 0;
	end
	else begin
		state		<= state_n;

		wdata		<= wdata_n;
	end
end

always_comb begin
	state_n		= state;

	wdata_n		= wdata;
	write_en	= 0;
	read_en		= 0;

	case(state)
		S_IDLE: begin
			if(valid_i) begin
				wdata_n[DATA_WIDTH-1 : 0] 		= data_i;
				wdata_n[WDATA_WIDTH-1 : DATA_WIDTH]	= ar_i;
				valid	 				= 1;
				ready					= 0;
				read_en 				= 1;
				state_n 				= S_READY;
			end
			else begin
				valid					= 0;
				ready					= 1;
			end
		end
		S_READY: begin
			ready			= 0;
			if(ready_i) begin
				write_en	= 1;
				state_n		= S_RUN;
				valid		= 0;
			end
			else
				valid		= 1;
		end
		S_RUN: begin
			valid 			= 0;
			if(!full_i) begin
				ready		= 1;
				state_n		= S_IDLE;
			end
			else
				ready		= 0;
		end
	endcase
end

assign	ready_o		= ready;
assign	valid_o		= valid;
assign	read_en_o	= read_en;
assign	write_en_o	= write_en;
assign	wdata_ROB_o	= wdata;
assign	wdata_Arbiter_o	= wdata;

endmodule
