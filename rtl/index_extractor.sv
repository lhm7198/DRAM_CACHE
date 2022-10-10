`include "TYPEDEF.svh"

module INDEX_EXTRACTOR
#(
	parameter ADDR_WIDTH	= `AXI_ADDR_WIDTH,	// 64
	parameter ID_WIDTH	= `AXI_ID_WIDTH, 	// 16
	
	parameter INDEX_WIDTH	= `INDEX_WIDTH, 	// 4
	parameter OFFSET_WIDTH	= `OFFSET_WIDTH, 	// 4
	parameter TID_WIDTH	= `TID_WIDTH  		// 10
)
(
	input	wire					clk,
	input	wire					rst_n,

	// AR channel (Processor -> DRAM $ Controller)
	input	wire 	[ID_WIDTH - 1 : 0] 		arid_i,
	input	wire 	[ADDR_WIDTH - 1 : 0] 		araddr_i,
	input	wire	[7 : 0]				arlen_i,
	input	wire					arvalid_i,
	output  wire					arready_o,

	// AW channel (Processor -> DRAM $ Controller)
	input 	wire 	[ID_WIDTH - 1 : 0] 		awid_i,
	input	wire 	[ADDR_WIDTH - 1 : 0] 		awaddr_i,
	input	wire	[7 : 0]				awlen_i,
	input 	wire 					awvalid_i,
	output	wire					awready_o,

	// AR channel (Index extractor <-> Memory Controller)
	output	wire 	[ID_WIDTH - 1 : 0] 		arid_o,
	output	wire 	[ADDR_WIDTH - 1 : 0] 		araddr_o,
	output	wire	[7 : 0]				arlen_o,
	output	wire					arvalid_o,
	input	wire					arready_i,	

	// Inner wire (Index extractor <-> Tag FIFO)
	input 	wire					tag_fifo_afull_i,
	output 	wire					tag_fifo_wren_o,
	output 	wire 	[ADDR_WIDTH + TID_WIDTH : 0] 	tag_fifo_data_o 	// 1 + 64 + 16 bit
);

localparam 			S_IDLE	= 3'd0,
				S_RRE 	= 3'd1,
				S_RREQ	= 3'd2,
				S_WRE	= 3'd3,
				S_WREQ	= 3'd4;

reg	[2:0]					state,		state_n;

reg 	[INDEX_WIDTH-1 : 0] 			index,		index_n;
reg	[9 : 0]		 			tid,		tid_n; 		 // 10 bit
reg	[ADDR_WIDTH + TID_WIDTH : 0]		tag_fifo_data,	tag_fifo_data_n; // 1 + 64 + 16 bit
reg						tag_fifo_wren,	tag_fifo_wren_n;
reg						arbiter,	arbiter_n;

reg						arready,	arready_n,
						awready,	awready_n,
						arvalid,	arvalid_n;

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;
		
		index		<= 0;
		tid		<= 1;
		tag_fifo_data	<= 0;
		tag_fifo_wren	<= 1'b0;
		arbiter		<= 1'b0;

		arready		<= 1'b1;
		awready		<= 1'b1;
		arvalid		<= 1'b0;
	end
	else begin
		state		<= state_n;
		
		index		<= index_n;
		tid		<= tid_n;
		tag_fifo_data	<= tag_fifo_data_n;
		tag_fifo_wren	<= tag_fifo_wren_n;
		arbiter		<= arbiter_n;
		
		arready		<= arready_n;
		awready		<= awready_n;
		arvalid		<= arvalid_n;
	end

always_comb begin
	state_n		= state;

	index_n		= index;
	tid_n		= tid;
	tag_fifo_data_n	= tag_fifo_data;
	tag_fifo_wren_n = tag_fifo_wren;
        arbiter_n	= arbiter;
	
	arready_n	= arready;
	awready_n	= awready;
	arvalid_n	= arvalid;

	case (state)
		S_IDLE: begin
			if(tag_fifo_afull_i) begin
				state_n					= state;
			end
			else if(arvalid_i && (!awvalid_i || !arbiter)) begin
				state_n					= S_RRE;
				arbiter_n 				= 1'b1;
				arready_n				= 1'b0;
				awready_n				= 1'b0;
				arvalid_n				= 1'b1;
			end
			else if(awvalid_i && (!arvalid_i || arbiter)) begin
				state_n					= S_WRE;
				arbiter_n 				= 1'b0;
				arready_n				= 1'b0;
				awready_n				= 1'b0;
				arvalid_n				= 1'b1;
			end
			else begin
				state_n					= state;
			end
		end
		S_RRE: begin
			index_n[OFFSET_WIDTH-1 : 0]					= 6'b0;
			index_n[OFFSET_WIDTH + INDEX_WIDTH -1 : OFFSET_WIDTH]		= araddr_i[15 : 6];
			index_n[ADDR_WIDTH : OFFSET_WIDTH + INDEX_WIDTH]		= 48'b0;

			tag_fifo_data_n[ADDR_WIDTH + TID_WIDTH : ADDR_WIDTH + TID_WIDTH]	= 1'b0; 	//read
			tag_fifo_data_n[ADDR_WIDTH + TID_WIDTH - 1 : ADDR_WIDTH]	= tid;
			tag_fifo_data_n[ADDR_WIDTH - 1 : 0]				= araddr_i;

			tid_n								= tid + 1;

			if(arready_i) begin
				tag_fifo_wren_n						= 1'b1;
				arvalid_n						= 1'b0;
				
				state_n 						= S_RREQ;
			end
		end
		S_RREQ: begin
			arready_n							= 1'b1;
			awready_n							= 1'b1;
			tag_fifo_wren_n							= 1'b0;

			state_n								= S_IDLE;
		end
		S_WRE: begin
			index_n[OFFSET_WIDTH-1 : 0]					= 6'b0;
			index_n[OFFSET_WIDTH + INDEX_WIDTH -1 : OFFSET_WIDTH]		= araddr_i[15 : 6];
			index_n[ADDR_WIDTH : OFFSET_WIDTH + INDEX_WIDTH]		= 48'b0;

			tag_fifo_data_n[ADDR_WIDTH + TID_WIDTH : ADDR_WIDTH + TID_WIDTH]	= 1'b1; 	//write
			tag_fifo_data_n[ADDR_WIDTH + TID_WIDTH - 1 : ADDR_WIDTH]	= 10'b0;
			tag_fifo_data_n[ADDR_WIDTH -1 : 0]				= awaddr_i;

			if(arready_i) begin
				tag_fifo_wren_n						= 1'b1;
				arvalid_n						= 1'b0;
		
				state_n 						= S_WREQ;
			end
		end
		S_WREQ: begin
			arready_n							= 1'b1;
			awready_n							= 1'b1;
			tag_fifo_wren_n							= 1'b0;
		
			state_n								= S_IDLE;
		end
	endcase
end

assign arready_o 	= arready; 
assign awready_o 	= awready;

assign arid_o		= arid_i;
assign araddr_o		= index;
assign arvalid_o	= arvalid;
assign axlen_o		= axlen_i;

assign tag_fifo_wren_o  = tag_fifo_wren;
assign tag_fifo_data_o 	= tag_fifo_data;

endmodule
