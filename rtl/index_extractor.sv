`include "AXI_TYPEDEF.svh"

module INDEX_EXTRACTOR
#(
	parameter ADDR_WIDTH	= `AXI_ADDR_WIDTH, // 64
	parameter DATA_WIDTH	= `AXI_DATA_WIDTH, // 32
	parameter ID_WIDTH	= `AXI_ID_WIDTH, // 16
	parameter INDEX_WIDTH	= `INDEX_WIDTH // 4
)
(
	input	wire					clk,
	input	wire					rst_n,

	// AR channel (Processor -> DRAM $ Controller)
	input	wire 	[ID_WIDTH-1 : 0] 		arid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 		araddr_i,
	input	wire					arvalid_i,
	output  wire					arready_o,

	// (Processor -> DRAM $ Controller)
	input 	wire 	[ID_WIDTH-1 : 0] 		awid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 		awaddr_i,
	input 	wire 					awvalid_i,
	output	wire					awready_o,

	// AR channel (DRAM $ Controller -> Memory Controller)
	output	wire 	[ID_WIDTH-1 : 0] 		arid_o,
	output	wire 	[INDEX_WIDTH-1 : 0] 		araddr_o,
	output	wire					arvalid_o,
	input	wire					arready_i,	

	// Inner wire (Index extractor -> FIFO)
	input 	wire					fifo_afull_i,
	output 	wire					fifo_write_en_o,
	output 	wire 	[ADDR_WIDTH + ID_WIDTH : 0] 	fifo_data_o 	// 1 + 64 + 16 bit
);

localparam 			S_IDLE	= 2'd0,
				S_RREQ 	= 2'd1,
				S_WREQ	= 2'd2;

reg	[1:0]					state,		state_n;

reg 	[INDEX_WIDTH-1 : 0] 			index,		index_n;
reg	[ID_WIDTH-1 : 0] 			tid,		tid_n;
reg	[ADDR_WIDTH + ID_WIDTH : 0]		fifo_data,	fifo_data_n;	// 1 + 64 + 16 bit
reg						fifo_write_en,	fifo_write_en_n;
reg						arbiter,	arbiter_n;

reg						arready,
						awready,
						arvalid;

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;
		
		index		<= 4'd0;
		tid		<= 0;
		fifo_data	<= 0;
		fifo_write_en	<= 1'b0;
		arbiter		<= 1'b0;
	end
	else begin
		state		<= state_n;
		
		index		<= index_n;
		tid		<= tid_n;
		fifo_data	<= fifo_data_n;
		fifo_write_en	<= fifo_write_en_n;
		arbiter		<= arbiter_n;
	end

always_comb begin
	state_n		= state;

	index_n		= index;
	tid_n		= tid;
	fifo_data_n	= fifo_data;
	fifo_write_en_n = fifo_write_en;
        arbiter_n	= arbiter;

	arready		= 1'b1;
	awready		= 1'b1;
	arvalid		= 1'b0;

	case (state)
		S_IDLE: begin
			fifo_write_en_n					= 1'b0;

			if(fifo_afull_i) begin
				state_n					= state;
				arbiter_n				= arbiter;
			end
			else if(arvalid_i && (!awvalid_i || !arbiter)) begin
				state_n					= S_RREQ;
				arbiter_n 				= 1'b1;
			end
			else if(awvalid_i && (!arvalid_i || arbiter)) begin
				state_n					= S_WREQ;
				arbiter_n 				= 1'b0;
			end
		end
		S_RREQ: begin
			arready								= 1'b0;
			arvalid								= 1'b1;

			index_n 							= araddr_i[INDEX_WIDTH-1 : 0];
			tid_n								= arid_i;

			fifo_write_en_n							= 1'b1;

			fifo_data_n[ADDR_WIDTH + ID_WIDTH : ADDR_WIDTH + ID_WIDTH]	= 1'b0; 	//read
			fifo_data_n[ADDR_WIDTH + ID_WIDTH - 1 : ADDR_WIDTH]		= arid_i;
			fifo_data_n[ADDR_WIDTH - 1 : 0]					= araddr_i;

			state_n								= S_IDLE;
		end
		S_WREQ: begin
			awready								= 1'b0;
			arvalid								= 1'b1;

			index_n 							= awaddr_i[INDEX_WIDTH-1 : 0];
			tid_n								= awid_i;

			fifo_write_en_n							= 1'b1;
		
			fifo_data_n[ADDR_WIDTH + ID_WIDTH : ADDR_WIDTH + ID_WIDTH]	= 1'b1; 	//write
			fifo_data_n[ADDR_WIDTH + ID_WIDTH - 1 : ADDR_WIDTH]		= awid_i;
			fifo_data_n[ADDR_WIDTH -1 : 0]					= awaddr_i;

			state_n								= S_IDLE;
		end
	endcase
end

assign arready_o 	= arready;

assign awready_o 	= awready;

assign arid_o		= tid;
assign araddr_o		= index;
assign arvalid_o	= arvalid;

assign fifo_write_en_o  = fifo_write_en;
assign fifo_data_o 	= fifo_data;

endmodule
