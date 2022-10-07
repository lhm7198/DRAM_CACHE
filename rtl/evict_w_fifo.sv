`include "TYPEDEF.svh"

module EVICT_W_FIFO 
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
	output	wire	[ID_WIDTH-1 : 0]			wid_o,
	output	wire	[ADDR_WIDTH-1 : 0]			wdata_o,
	//output	wire						wstrb_o,
	output	wire						wvalid_o,
	input	wire						wready_i,

	// Inner wire (Tag comparator <-> FILL AR FIFO)
	output	wire						wfifo_afull_o,
	input	wire						wfifo_wren_i,
	input	wire	[ADDR_WIDTH + TID_WIDTH - 1 : 0] 	wfifo_data_i
);

localparam 		S_IDLE		= 1'd0,
			S_RUN		= 1'd1,

wire					afull;
wire					aempty;
wire	[DATA_WIDTH - 1 : 0] 		rdata;

reg					state,		state_n;

reg	[DATA_WIDTH - 1 : 0]		wdata,		wdata_n;
reg					wvalid,		wvalid_n;

reg					rden,		rden_n;		

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;

		wdata		<= 0;		
		wvalid		<= 1'b0;

		rden		<= 1'b0;
	end
	else begin
		state		<= state_n;

		wdata		<= wdata_n;
		wvalid		<= wvalid_n;

		rden		<= rden_n;
	end
end

always_comb begin
	state_n		= state;
	
	wdata_n		= wdata;
	wvalid_n	= wvalid;

	rden_n		= rden;

	case (state)
		S_IDLE: begin
			wvalid_n	= 1'b0;
			rden_n		= 1'b0;

			if(wready_i && !aempty) begin
				state_n	= S_RUN;
			end
		end
		S_RUN: begin
			wvalid_n	= 1'b1;
			rden_n		= 1'b1;

			wdata_n		= rdata;

			state_n		= S_IDLE;
		end
	endcase
end


FIFO	evict_w_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(afull),
	.write_en_i	(wfifo_wren_i),
	.write_data_i	(wfifo_data_i),

	.A_empty_o	(aempty),
	.read_en_i	(rden),
	.read_data_o	(rdata)
);

assign wid_o 		= ID;
assign wdata_o		= wdata;
assign wvalid_o		= wvalid;
assign wfifo_afull_o	= afull;

endmodule
