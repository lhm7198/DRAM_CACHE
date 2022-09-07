`include "./AXI_TYPEDEF.svh"

module INDEX_EXTRACTOR
#(
	parameter ADDR_WIDTH	= 'AXI_ADDR_WIDTH,
	parameter DATA_WIDTH	= 'AXI_DATA_WIDTH,
	parameter ID_WIDTH	= 'AXI_ID_WIDTH,
	parameter INDEX_WIDTH	= 'INDEX_WIDTH
)
(
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
	output 	wire 	[INDEX_WIDTH-1 : 0]   		index_o,

	// Index extractor -> FIFO
	input 	wire					fifo_afull_i,
	output 	wire					fifo_write_en_o,
	output 	wire 	[80 : 0] 			fifo_data_o 	// 1 + 64 + 16 bit
);

localparam 			S_IDLE	= 2'd0,
				S_RREQ 	= 2'd1,
				S_WREQ	= 2'd2;

reg	[1:0]			state,		state_n;

reg 	[INDEX_WIDTH-1 : 0] 	index,		index_n;
reg	[127 : 0]		fifo_data,	fifo_data_n;	// 1 + 64 + 16 bit
reg				fifo_write_en,	fifo_write_en_n;
reg				arbiter,	arbiter_n;

reg				arready,
				awready;

always @(posedge clk) begin
	if (!rst_n) begin
		state		<= S_IDLE;
		
		index		<= 4'd0;
		fifo_data	<= 128'd0;
		fifo_write_en	<= 0;
		arbiter		<= 0;

		state_n		<= S_IDLE;
		
		index_n		<= 4'd0;
		fifo_data_n	<= 128'd0;
		fifo_write_en_n	<= 0;
		arbiter_n	<= 0;

	end 
	else begin
		case (state)
			S_IDLE: begin
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
				arready						= 1'b0;
				index_n 					= araddr_i[INDEX_WIDTH-1 : 0];
				fifo_data_n[80:80]				= 1'b0; 				//read
				fifo_data_n[79:64]				= arid_i;
				fifo_data_n[63:0]				= araddr_i;
				state_n						= S_IDLE;
			end
			S_WREQ: begin
				awready						= 1'b0;
				index_n 					= awaddr_i[INDEX_WIDTH-1 : 0];
				fifo_data_n[80:80]				= 1'b1; 				//write
				fifo_data_n[79:64]				= awid_i;
				fifo_data_n[63:0]				= awaddr_i;
				state_n						= S_IDLE;
			end
		endcase

		state		<= state_n;

		index		<= index_n;
		fifo_data	<= fifo_data_n;
		fifo_write_en	<= fifo_write_en_n;
		arbiter		<= arbiter_n;
		
		arready		= !fifo_afull_i;
		awready		= !fifo_afull_i;
	end
end

assign index_o		= index;
assign fifo_data_o 	= fifo_data;
assign fifo_write_en_o  = fifo_write_en;
assign arready_o 	= arready;
assign awready_o 	= awready;

endmodule
