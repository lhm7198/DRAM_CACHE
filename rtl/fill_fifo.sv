`include "TYPEDEF.svh"

module FILL_FIFO # (
	parameter ADDR_WIDTH	= `AXI_ADDR_WIDTH,
	parameter INDEX_WIDTH	= `INDEX_WIDTH,
	parameter OFFSET_WIDTH	= `OFFSET_WIDTH,
	parameter DATA_WIDTH 	= `AXI_DATA_WIDTH,
	parameter ID_WIDTH	= `AXI_ID_WIDTH,
	parameter ID		= `AXI_ID
)(
	input	wire					clk,
	input	wire					rst_n,
	
	output	wire					afull_o,
	input	wire					wren_i,
	input	wire	[ADDR_WIDTH+DATA_WIDTH-1 : 0]	data_i,

	///////////w channel//////////////
	
	output	wire	[ID_WIDTH-1 : 0]		wid_o,
	output	wire					wvalid_o,
	output	wire	[DATA_WIDTH-1 : 0]		wdata_o,
	input	wire					wready_i,
	
	///////////aw channel/////////////
	
	output	wire	[ID_WIDTH-1 : 0]		awid_o,
	output	wire					awvalid_o,
	output	wire	[ADDR_WIDTH-1 : 0]		awaddr_o,
	input	wire					awready_i
);

localparam		S_IDLE		= 1'd0,
			S_READY		= 1'd1;

reg					state, state_n;
reg	[DATA_WIDTH-1 : 0]		wdata, wdata_n;
reg	[ADDR_WIDTH-1 : 0]		awaddr, awaddr_n;
reg					empty;
reg	[ADDR_WIDTH+DATA_WIDTH-1 : 0]	rdata;
reg					wvalid, awvalid;
reg					read_en;

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
	awaddr_n	= awaddr;
	wvalid		= 0;
	awvalid		= 0;
	read_en		= 0;

	case(state)
		S_IDLE: begin
			if(!empty) begin
				$display("fill fifo data : %x", rdata);
				wdata_n		= rdata[DATA_WIDTH-1 : 0];

				awaddr_n[OFFSET_WIDTH - 1 : 0]					= 0;
				awaddr_n[ADDR_WIDTH + DATA_WIDTH - 1 : OFFSET_WIDTH]		= rdata[ADDR_WIDTH + DATA_WIDTH - 1 : OFFSET_WIDTH + DATA_WIDTH];

				//wvalid		= 1;
				//awvalid		= 1;
				state_n		= S_READY;
			end
		end
		S_READY: begin
				wvalid		= 1;
				awvalid		= 1;
				if(wready_i & awready_i) begin
					$display("aaaaaaaaaaaaaaaaaa");
					read_en	= 1;
					state_n	= S_IDLE;
				end
		end
	endcase
end

FIFO
#(
	.DATA_WIDTH	(DATA_WIDTH+ADDR_WIDTH)
) fill_fifo
(
	.clk			(clk),
	.rst_n			(rst_n),

	.A_full_o		(afull),
	.write_en_i		(wren_i),
	.write_data_i		(data_i),

	.empty_o		(empty),
	.read_en_i		(read_en),
	.read_data_o		(rdata)
);

assign 	afull_o		= afull;

assign	wid_o		= ID;
assign	wvalid_o	= wvalid;
assign	wdata_o		= wdata;

assign	awid_o		= ID;
assign	awvalid_o	= awvalid;
assign	awaddr_o	= awaddr;

endmodule
