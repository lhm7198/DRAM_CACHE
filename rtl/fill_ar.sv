`include "TYPEDEF.svh"

module FILL_AR 
#(
	parameter ADDR_WIDTH		= `AXI_ADDR_WIDTH,
	parameter DATA_WIDTH 		= `AXI_DATA_WIDTH,
	parameter ID_WIDTH		= `AXI_ID_WIDTH,
	parameter ID			= `AXI_ID,

	parameter TID_WIDTH		= `TID_WIDTH
)
(
	input	wire						clk,
	input 	wire						rst_n,

	// AR channel (Fill AR <-> CXL Ctrl)
	output	wire	[ID_WIDTH - 1 : 0]			arid_o,
	output	wire	[ADDR_WIDTH - 1 : 0]			araddr_o,
	output	wire						arvalid_o,
	input	wire						arready_i,

	// Inner wire (AR FIFO <-> Fill AR)
	input	wire						arfifo_aempty_i,
	output	wire						arfifo_rden_o,
	input	wire	[TID_WIDTH + ADDR_WIDTH - 1 : 0] 	arfifo_data_i,

	// Inner wire (Fill AR <-> RMiss FIFO)
	input	wire						rmfifo_afull_i,
	output	wire						rmfifo_wren_o,
	output	wire	[TID_WIDTH + ADDR_WIDTH - 1 : 0]	rmfifo_data_o
);

localparam 		S_IDLE		= 1'd0,
			S_RUN		= 1'd1;

reg						state,		state_n;

reg	[TID_WIDTH + ADDR_WIDTH - 1 : 0]	rmfifo_data,	rmfifo_data_n;

reg						arfifo_rden;		
reg						rmfifo_wren;

reg	[ADDR_WIDTH - 1 : 0]			araddr,		araddr_n;
reg						arvalid;

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
		
		rmfifo_data	<= 0;
		
		araddr		<= 0;
	end
	else begin
		state		<= state_n;

		rmfifo_data	<= rmfifo_data_n;

		araddr		<= araddr_n;
	end
end

always_comb begin
	state_n		= state;

	rmfifo_data_n	= rmfifo_data;

	arfifo_rden	= 1'b0;
	rmfifo_wren	= 1'b0;

	araddr_n	= araddr;
	arvalid		= 1'b0;

	case (state)
		S_IDLE: begin
			if(!arfifo_aempty_i) begin
				arfifo_rden	= 1'b1;

				rmfifo_data_n   = arfifo_data_i;
				araddr_n	= arfifo_data_i[ADDR_WIDTH - 1 : 0];
				
				state_n		= S_RUN;
			end
		end
		S_RUN: begin
			arfifo_rden	= 1'b0;

			arvalid		= 1'b1;

			if(arready_i & !rmfifo_afull_i) begin
				rmfifo_wren 	= 1'b1;

				state_n		= S_IDLE;
			end
		end
	endcase
end

assign arid_o 		= ID;
assign araddr_o		= araddr;
assign arvalid_o	= arvalid;

assign arfifo_rden_o	= arfifo_rden;
assign rmfifo_wren_o 	= rmfifo_wren;
assign rmfifo_data_o	= rmfifo_data;

endmodule
