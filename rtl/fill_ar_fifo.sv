`include "TYPEDEF.svh"

module FILL_AR_FIFO 
#(
	parameter ADDR_WIDTH	= `AXI_ADDR_WIDTH,
	parameter ID_WIDTH	= `AXI_ID_WIDTH,
	parameter ID		= `AXI_ID

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
wire					aempty;
wire					rdata;

reg					state,		state_n;

reg	[TID_WIDTH - 1 : 0]		tid,		tid_n;
reg	[ADDR_WIDTH - 1 : 0]		araddr,		araddr_n;
reg					arvalid,	arvalid_n;

reg					rden,		rden_n;		

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
		
		tid		<= 0;

		araddr		<= 0;		
		arvalid		<= 1'b0;

		rden		<= 1'b0;
	end
	else begin
		state		<= state_n;

		tid		<= tid_n;

		araddr		<= araddr_n;
		arvalid		<= arvalid_n;

		rden		<= rden_n;
	end
end

always_comb begin
	state_n		= state;
	
	tid_n		= tid;

	araddr_n	= araddr;
	arvalid_n	= arvalid;

	rden_n		= rden;

	case (state)
		S_IDLE: begin
			arvalid_n	= 1'b0;
			rden_n		= 1'b0;

			if(arready_i && !aempty) begin
				state_n	= S_RUN;
			end
		end
		S_RUN: begin
			arvalid_n	= 1'b1;
			rden_n		= 1'b1;

			tid_n		= rdata[TID_WIDTH + ADDR_WIDTH - 1 : ADDR_WIDTH];
			araddr_n	= rdata[ADDR_WIDTH - 1 : 0];

			state_n		= S_IDLE;
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
	.read_en_i	(arfifo_rden),
	.read_data_o	(rdata)
);

assign arid_o 		= ID;
assign araddr_o		= araddr;
assign arvalid_o	= arvalid;
assign arfifo_afull_o	= afull;

endmodule
