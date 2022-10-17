`include "TYPEDEF.svh"

module EVICT_AW_W
#(
	parameter ADDR_WIDTH		= `AXI_ADDR_WIDTH,
	parameter DATA_WIDTH 		= `AXI_DATA_WIDTH,
	parameter ID_WIDTH		= `AXI_ID_WIDTH,
	parameter ID			= `AXI_ID
)
(
	input	wire						clk,
	input 	wire						rst_n,

	// AW channel (Evict AW W FIFO <-> CXL Ctrl)
	output	wire	[ID_WIDTH - 1 : 0]			awid_o,
	output	wire	[ADDR_WIDTH - 1 : 0]			awaddr_o,
	output	wire						awvalid_o,
	input	wire						awready_i,

	// W channel (Evict AW W FIFO <-> CXL Ctrl)
	output	wire	[ID_WIDTH - 1 : 0]			wid_o,
	output	wire	[DATA_WIDTH - 1 : 0]			wdata_o,
	output	wire						wvalid_o,
	input	wire						wready_i,

	// B channel (EVICT AW W FIFO <-> CXL Ctrl)
	output	wire	[ID_WIDTH - 1 : 0]			bid_o,
	output	wire						bvalid_o,
	input	wire						bready_i,

	// Inner wire (AW FIFO <-> Evict AW W)
	input	wire						awfifo_aempty_i,
	output	wire						awfifo_rden_o,
	input	wire	[ADDR_WIDTH - 1 : 0] 			awfifo_data_i,

	// Inner wire (W FIFO <-> Evict AW W)
	input	wire						wfifo_aempty_i,
	output	wire						wfifo_rden_o,
	input	wire	[DATA_WIDTH - 1 : 0]		 	wfifo_data_i
);

localparam 		S_IDLE		= 1'd0,
			S_RUN		= 1'd1;

reg						state,		state_n;

reg	[DATA_WIDTH - 1 : 0]			wdata,		wdata_n;

reg						awfifo_rden;		
reg						wfifo_rden;

reg	[ADDR_WIDTH - 1 : 0]			awaddr,		awaddr_n;
reg						awvalid;
reg						wvalid;
reg						bvalid;

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
		
		wdata		<= 0;

		awaddr		<= 0;
	end
	else begin
		state		<= state_n;

		wdata		<= wdata_n;

		awaddr		<= awaddr_n;
	end
end

always_comb begin
	state_n		= state;

	wdata_n		= wdata;

	awfifo_rden	= 1'b0;
	wfifo_rden	= 1'b0;

	awaddr_n	= awaddr;
	awvalid		= 1'b0;
	wvalid		= 1'b0;
	bvalid		= 1'b0;

	case (state)
		S_IDLE: begin
			$display("S_IDLE\n");
			if(!awfifo_aempty_i & !wfifo_aempty_i) begin
				awfifo_rden	= 1'b1;
				wfifo_rden	= 1'b1;

				awaddr_n	= awfifo_data_i[ADDR_WIDTH - 1 : 0];
				wdata_n		= wfifo_data_i;		

				state_n	= S_RUN;
			end
		end
		S_RUN: begin
			$display("S_RUN\n");
			awfifo_rden	= 1'b0;
			wfifo_rden	= 1'b0;
			
			awvalid		= 1'b1;
			wvalid		= 1'b1;

			if(awready_i & wready_i) begin
				state_n		= S_IDLE;
			end
		end
	endcase
end

assign awid_o 		= ID;
assign awaddr_o		= awaddr;
assign awvalid_o	= awvalid;

assign wid_o		= ID;
assign wdata_o		= wdata;
assign wvalid_o		= wvalid;

assign bid_o		= ID;
assign bvalid_o		= bvalid;

assign awfifo_rden_o	= awfifo_rden;
assign wfifo_rden_o	= wfifo_rden;

endmodule
