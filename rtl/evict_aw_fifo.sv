`include "TYPEDEF.svh"

module EVICT_AW_FIFO 
#(
	parameter ADDR_WIDTH	= `AXI_ADDR_WIDTH,
	parameter ID_WIDTH	= `AXI_ID_WIDTH,
	parameter ID		= `AXI_ID,

	parameter AXI_LEN	= `AXI_LEN,
	parameter AXI_SIZE	= `AXI_SIZE,

	parameter TID_WIDTH	= `TID_WIDTH,

	parameter DATA_WIDTH 	= `FIFO_DATA_WIDTH,
	parameter FIFO_SIZE 	= `FIFO_SIZE	
)
(
	input	wire						clk,
	input 	wire						rst_n,

	// AR channel (FILL AR FIFO <-> CXL Ctrl)
	output	wire	[ID_WIDTH-1 : 0]			awid_o,
	output	wire	[ADDR_WIDTH-1 : 0]			awaddr_o,
	output	wire	[7 : 0]					awlen_o,
	output	wire	[2 : 0] 				awsize_o,
	output	wire						awvalid_o,
	input	wire						awready_i,

	// Inner wire (Tag comparator <-> FILL AR FIFO)
	output	wire						awfifo_afull_o,
	input	wire						awfifo_wren_i,
	input	wire	[ADDR_WIDTH - 1 : 0] 			awfifo_data_i
);

localparam 		S_IDLE		= 1'd0,
			S_RUN		= 1'd1,

wire					afull;
wire					aempty;
wire	[DATA_WIDTH - 1 : 0] 		rdata;

reg					state,		state_n;

reg	[ADDR_WIDTH - 1 : 0]		awddr,		awaddr_n;
reg					awvalid,	awvalid_n;

reg					rden,		rden_n;		

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
		
		awaddr		<= 0;		
		awvalid		<= 1'b0;

		rden		<= 1'b0;
	end
	else begin
		state		<= state_n;

		awaddr		<= awaddr_n;
		awvalid		<= awvalid_n;

		rden		<= rden_n;
	end
end

always_comb begin
	state_n		= state;
	
	awaddr_n	= awaddr;
	awvalid_n	= awvalid;

	rden_n		= rden;

	case (state)
		S_IDLE: begin
			awvalid_n	= 1'b0;
			rden_n		= 1'b0;

			if(awready_i && !aempty) begin
				state_n	= S_RUN;
			end
		end
		S_RUN: begin
			awvalid_n	= 1'b1;
			rden_n		= 1'b1;

			awaddr_n	= rdata;

			state_n		= S_IDLE;
		end
	endcase
end


FIFO	evict_aw_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(afull),
	.write_en_i	(awfifo_wren_i),
	.write_data_i	(awfifo_data_i),

	.A_empty_o	(aempty),
	.read_en_i	(rden),
	.read_data_o	(rdata)
);

assign awid_o 		= ID;
assign awaddr_o		= awaddr;
assign awlen_o		= AXI_LEN;
assign awsize_o		= AXI_SIZE;
assign awvalid_o	= awvalid;
assign awfifo_afull_o	= afull;

endmodule
