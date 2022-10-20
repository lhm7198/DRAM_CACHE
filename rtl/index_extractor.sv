`include "TYPEDEF.svh"

module INDEX_EXTRACTOR
#(
	parameter ADDR_WIDTH	= `AXI_ADDR_WIDTH,	// 64
	parameter ID_WIDTH	= `AXI_ID_WIDTH, 	
	parameter ID		= `AXI_ID,
	
	parameter INDEX_WIDTH	= `INDEX_WIDTH, 	
	parameter OFFSET_WIDTH	= `OFFSET_WIDTH, 	
	parameter TID_WIDTH	= `TID_WIDTH  		
)
(
	input	wire					clk,
	input	wire					rst_n,

	// AR channel (Processor -> DRAM $ Controller)
	input	wire 	[ID_WIDTH - 1 : 0] 		arid_i,
	input	wire 	[ADDR_WIDTH - 1 : 0] 		araddr_i,
	input	wire					arvalid_i,
	output  wire					arready_o,

	// AW channel (Processor -> DRAM $ Controller)
	input 	wire 	[ID_WIDTH - 1 : 0] 		awid_i,
	input	wire 	[ADDR_WIDTH - 1 : 0] 		awaddr_i,
	input 	wire 					awvalid_i,
	output	wire					awready_o,

	// AR channel (Index extractor <-> Memory Controller)
	output	wire 	[ID_WIDTH - 1 : 0] 		arid_o,
	output	wire 	[ADDR_WIDTH - 1 : 0] 		araddr_o,
	output	wire					arvalid_o,
	input	wire					arready_i,	

	// Inner wire (Index extractor <-> Tag FIFO)
	input 	wire					tag_fifo_afull_i,
	output 	wire					tag_fifo_wren_o,
	output 	wire 	[ADDR_WIDTH + TID_WIDTH : 0] 	tag_fifo_data_o 	// 1 + 64 + 16 bit
);

localparam 			S_IDLE	= 1'd0,
				S_REQ 	= 1'd1;

reg						state,		state_n;

reg 	[ADDR_WIDTH - 1 : 0] 			index,		index_n;
reg	[TID_WIDTH - 1 : 0]		 	tid,		tid_n; 		 // 10 bit
reg	[ADDR_WIDTH + TID_WIDTH : 0]		tag_fifo_data,	tag_fifo_data_n; // 1 + 64 + 16 bit
reg						tag_fifo_wren,	tag_fifo_wren_n;
reg						arbiter,	arbiter_n;

reg						arready,	awready,
						arvalid,	arvalid_n;

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;
		
		index		<= 0;
		tid		<= 1;
		tag_fifo_data	<= 0;
		tag_fifo_wren	<= 1'b0;
		arbiter		<= 1'b0;

		arvalid		<= 1'b0;
	end
	else begin
		state		<= state_n;
		
		index		<= index_n;
		tid		<= tid_n;
		tag_fifo_data	<= tag_fifo_data_n;
		tag_fifo_wren	<= tag_fifo_wren_n;
		arbiter		<= arbiter_n;
		
		arvalid		<= arvalid_n;
	end

always_comb begin
	state_n		= state;

	index_n		= index;
	tid_n		= tid;
	tag_fifo_data_n	= tag_fifo_data;
	tag_fifo_wren_n = tag_fifo_wren;
        arbiter_n	= arbiter;

	arready 	= 1'b0;
	awready		= 1'b0;	
	arvalid_n	= arvalid;

	case (state)
		S_IDLE: begin
			if(tag_fifo_afull_i) begin
				state_n					= state;
			end
			else if(arvalid_i & (!awvalid_i | !arbiter)) begin
				index_n[OFFSET_WIDTH - 1 : 0]						= 0;
				index_n[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH]			= araddr_i[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
				index_n[ADDR_WIDTH - 1 : OFFSET_WIDTH + INDEX_WIDTH]			= 0;

				tag_fifo_data_n[ADDR_WIDTH - 1 : 0]					= araddr_i;
				tag_fifo_data_n[ADDR_WIDTH + TID_WIDTH - 1 : ADDR_WIDTH]		= tid;
				tag_fifo_data_n[ADDR_WIDTH + TID_WIDTH : ADDR_WIDTH + TID_WIDTH]	= 1'b0; 	

				tid_n					= tid + 1;

				arready					= 1'b1;
				awready					= 1'b0;
				arvalid_n				= 1'b1;

				arbiter_n 				= 1'b1;
				tag_fifo_wren_n				= 1'b1;
				
				state_n					= S_REQ;
			end
			else if(awvalid_i & (!arvalid_i | arbiter)) begin
				index_n[OFFSET_WIDTH - 1 : 0]						= 0;
				index_n[OFFSET_WIDTH + INDEX_WIDTH - 1 : OFFSET_WIDTH]			= awaddr_i[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
				index_n[ADDR_WIDTH - 1 : OFFSET_WIDTH + INDEX_WIDTH]			= 0;
				
				tag_fifo_data_n[ADDR_WIDTH - 1 : 0]					= awaddr_i;				
				tag_fifo_data_n[ADDR_WIDTH + TID_WIDTH - 1 : ADDR_WIDTH]		= 0;
				tag_fifo_data_n[ADDR_WIDTH + TID_WIDTH : ADDR_WIDTH + TID_WIDTH]	= 1'b1;

				arready					= 1'b0;
				awready					= 1'b1;
				arvalid_n				= 1'b1;
				
				arbiter_n 				= 1'b0;
				tag_fifo_wren_n				= 1'b1;

				state_n					= S_REQ;
			end
			else begin
				state_n					= state;
			end
		end
		S_REQ: begin
			tag_fifo_wren_n				= 1'b0;
		
			arready 				= 1'b0;
			awready					= 1'b0;	
			if(arready_i) begin
				arvalid_n			= 1'b0;

				state_n 			= S_IDLE;
			end
		end
	endcase
end

assign arready_o 	= arready; 
assign awready_o 	= awready;

assign arid_o		= ID;
assign araddr_o		= index;
assign arvalid_o	= arvalid;

assign tag_fifo_wren_o  = tag_fifo_wren;
assign tag_fifo_data_o 	= tag_fifo_data;

endmodule
