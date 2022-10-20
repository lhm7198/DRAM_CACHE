`include "TYPEDEF.svh"

module READ_MISS_HANDLER # (
	parameter	ADDR_WIDTH	= `AXI_ADDR_WIDTH,
	parameter	DATA_WIDTH	= `AXI_DATA_WIDTH,
	parameter	WDATA_WIDTH	= ADDR_WIDTH + DATA_WIDTH,
	parameter	TID_WIDTH	= `TID_WIDTH,
	parameter	ID_WIDTH	= `AXI_ID_WIDTH
)(
	input	wire		clk,
	input	wire		rst_n,

	//CXL ctr
	input	wire					valid_i,
	output	wire					ready_o,
	input	wire	[DATA_WIDTH-1 : 0]		data_i,
	input	wire	[ID_WIDTH-1 : 0]		rid_i,

	//R_MISS_FIFO
	output	wire					read_en_o,
	input	wire					empty_i,
	input	wire	[ADDR_WIDTH+TID_WIDTH-1 : 0]	ar_i,

	//ROB
	output	wire					write_en_o,
	input	wire					full_i,
	output	wire	[DATA_WIDTH+TID_WIDTH-1 : 0]	wdata_ROB_o,

	//Arbiter
	output	wire					valid_o,
	input	wire					ready_i,
	output	wire	[WDATA_WIDTH-1 : 0]		wdata_Arbiter_o
);

localparam		S_IDLE	= 1'b0,
			S_RUN	= 1'b1;

reg					state, state_n;
reg					rready;
reg	[DATA_WIDTH+TID_WIDTH-1 : 0]	wdata_ROB, wdata_ROB_n;
reg	[WDATA_WIDTH-1 : 0]		wdata_Arbiter, wdata_Arbiter_n;
reg					rmvalid;
reg					write_en;
reg					read_en;

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;

		wdata_Arbiter	<= 0;
		wdata_ROB	<= 0;
	end
	else begin
		state		<= state_n;

		wdata_Arbiter	<= wdata_Arbiter_n;
		wdata_ROB	<= wdata_ROB_n;
	end
end

always_comb begin
	state_n		= state;

	wdata_Arbiter_n	= wdata_Arbiter;
	wdata_ROB_n	= wdata_ROB;
	write_en	= 1'b0;
	read_en		= 1'b0;
	rmvalid		= 1'b0;
	rready		= 1'b1;

	case(state)
		S_IDLE: begin
			if(valid_i & !empty_i) begin
				wdata_Arbiter_n[DATA_WIDTH-1 : 0] 			= data_i;
				wdata_Arbiter_n[WDATA_WIDTH-1 : DATA_WIDTH]		= ar_i[ADDR_WIDTH-1 : 0];
				wdata_ROB_n[DATA_WIDTH-1 : 0]				= data_i;
				wdata_ROB_n[DATA_WIDTH+TID_WIDTH-1 : DATA_WIDTH]	= ar_i[ADDR_WIDTH+TID_WIDTH-1 : ADDR_WIDTH];
				
				read_en 						= 1'b1;

				state_n 						= S_RUN;
			end
		end
		S_RUN: begin
			rready	= 1'b0;
			rmvalid	= 1'b1;
			if(ready_i & !full_i) begin
				write_en	= 1'b1;
				rmvalid		= 1'b0;
				state_n		= S_IDLE;
			end
		end
	endcase
end

assign	ready_o		= rready;
assign	valid_o		= rmvalid;
assign	read_en_o	= read_en;
assign	write_en_o	= write_en;
assign	wdata_ROB_o	= wdata_ROB;
assign	wdata_Arbiter_o	= wdata_Arbiter;

endmodule
