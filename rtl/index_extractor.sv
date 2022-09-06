module INDEX_EXTRACTOR # (
	parameter ADDR_WIDTH = 64,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 16,
	parameter INDEX_BIT_SIZE = 4
) (
	input	wire					clk,
	input	wire					rst_n,

	// AMBA AXI interface (AR channel)
	input	wire 	[ID_WIDTH-1 : 0] 		arid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 		araddr_i,
	input	wire					arvalid_i,
	output  	wire				arready_o,

	// AMBA AXI interface (AW channel)
	input 	wire 	[ID_WIDTH-1 : 0] 		awid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 		awaddr_i,
	input 	wire 					awvalid_i,
	output	wire					awready_o,

	// Index extractor -> Memory
	output 	wire 	[INDEX_BIT_SIZE-1 : 0]   	index_o,

	// Index extractor -> FIFO
	input 	wire					fifo_afull_i,
	output 	wire					fifo_write_en_o,
	output 	wire 	[127 : 0] 			fifo_data_o 	// 1 + 32 + 32 bit
);

localparam 			S_IDLE	= 2'd0,
				S_RREQ 	= 2'd1,
				S_WREQ	= 2'd2,
				S_FIFO	= 2'd3;

reg	[1:0]			state,		state_n;

reg 	[INDEX_BIT_SIZE-1 : 0] 	index,		index_n;
reg	[127 : 0]		fifo_data,	fifo_data_n;	// 1 + 32 + 32 bit
reg				fifo_write_en,	fifo_write_en_n;
reg				arbiter,	arbiter_n;

reg				arready,
				awready;

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;
		
		index		<= 4'd0;
		fifo_data	<= 128'd0;
		fifo_write_en	<= 0;
		arbiter		<= 0;
	end 
	else begin
		state		<= state_n;

		index		<= index_n;
		fifo_data	<= fifo_data_n;
		fifo_write_en	<= fifo_write_en_n;
		arbiter		<= arbiter_n;
	end

always_comb
begin
	state_n		= state;

	index_n		= index;
	fifo_data_n	= fifo_data;
	fifo_write_en_n	= fifo_write_en;
	arbiter_n	= arbiter;

	arready		= 1'b1;
	awready		= 1'b1;

	case (state)
		S_IDLE: begin
			if(arvalid_i & !arbiter) begin
				state_n					= S_RREQ;
				arbiter_n 				= 1'b1;
			end
			else if(awvalid_i & arbiter) begin
				state_n					= S_WREQ;
				arbiter_n 				= 1'b0;
			end
		end
		S_RREQ: begin
			arready						= 1'b0;

			index_n 					= araddr_i[INDEX_BIT_SIZE-1 : 0];
			fifo_data_n[0:0]				= 1'b0; 				//read
			if(fifo_afull_i == 0) begin
				state_n					= S_FIFO;
			end
		end
		S_WREQ: begin
			awready						= 1'b0;

			index_n 					= araddr_i[INDEX_BIT_SIZE-1 : 0];
			fifo_data_n[0:0]				= 1'b1; 				//write
			if(fifo_afull_i == 0) begin
				state_n					= S_FIFO;
			end
		end
		S_FIFO: begin
			arready						= 1'b0;
			awready						= 1'b0;

			fifo_data_n[ID_WIDTH:1]				= arid_i;
			fifo_data_n[ADDR_WIDTH+ID_WIDTH : ID_WIDTH+1]	= araddr_i[ADDR_WIDTH-1 : 0];
			fifo_write_en_n 				= 1'b1;

			state_n = S_IDLE;
		end
	endcase
end

assign index_o		= index;
assign fifo_data_o 	= fifo_data;
assign fifo_write_en_o  = fifo_write_en;
assign arready_o 	= arready;
assign awready_o 	= awready;

endmodule
