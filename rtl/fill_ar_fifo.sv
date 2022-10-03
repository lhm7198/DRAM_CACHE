`include "TYPEDEF.svh"

module FILL_AR_FIFO 
#(
	parameter ADDR_WIDTH	= `AXI_ADDR_WIDTH,
	parameter ID_WIDTH	= `AXI_ID_WIDTH,

	parameter TID_WIDTH	= `TID_WIDTH,

	parameter DATA_WIDTH 	= `FIFO_DATA_WIDTH,
	parameter FIFO_SIZE 	= `FIFO_SIZE	
)
(
	input	wire						clk,
	input 	wire						rst_n,

	// AR channel (FILL AR FIFO <-> CXL Ctrl)
	output	wire	[ID_WIDTH-1 : 0]			arid_o,
	output	wire	[ADDR_WIDTH-1 : 0]			araddr_o,
	output	wire	[7 : 0]					arlen_o,
	output	wire						arvalid_o,
	input	wire						arready_i,

	// Inner wire (Tag comparator <-> FILL AR FIFO)
	output	wire						arfifo_afull_o,
	input	wire						arfifo_wren_i,
	input	wire	[ADDR_WIDTH + TID_WIDTH - 1 : 0] 	arfifo_data_i
);

localparam 		S_IDLE		= 1'd0,
			S_RUN		= 1'd1,

wire					afull;
wire					wren;
wire	[DATA_WIDTH - 1 : 0]		wdata;

wire					aempty;
wire					rden;
wire	[DATA_WIDTH - 1 : 0]		rdata;

reg					state,		state_n;
reg	[TID_WIDTH - 1 : 0]		tid,		tid_n;
reg	[ADDR_WIDTH - 1 : 0]		araddr,		araddr_n;
reg					arvalid,	arvalid_n;

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
		
	end
	else begin
		state		<= state_n;
	end
end

always_comb begin
	state_n		= state;

	case (state)
		S_IDLE: begin
		end
		S_RUN: begin
		end
	endcase
end


FIFO	fill_ar_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(afull),
	.write_en_i	(arfifo_wren_i),
	.write_data_i	(arfifo_data_i),

	.A_empty_o	(aempty),
	.read_en_i	(read_en_hit),
	.read_data_o	(read_data_hit)
);



assign arfifo_afull_o	= afull;

endmodule
