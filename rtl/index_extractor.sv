module INDEX_EXTRACTOR # (
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 32,
	parameter INDEX_BIT_SIZE = 4
) (
	input	wire				clk,
	input	wire				rst_n,

	// AMBA AXI interface (AR channel)
	input	wire 	[ID_WIDTH-1 : 0] 		arid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 	araddr_i,
	input	wire				arvalid_i,

	// AMBA AXI interface (AW channel)
	input 	wire 	[ID_WIDTH-1 : 0] 		awid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 	awaddr_i,
	input 	wire 				awvalid_i,

	output 	wire 				ready_o,

	// Index extractor -> Memory
	output 	wire 	[INDEX_BIT_SIZE-1 : 0]   	slave_i,

	// Index extractor -> FIFO
	input 	wire				fifo_Afull,
	output 	wire				fifo_write_enable,
	output 	wire 	[127 : 0] 			fifo_i 		// 1 + 32 + 32 bit
);

reg				ready;
reg 	[INDEX_BIT_SIZE-1 : 0] 	index;
reg	[ADDR_WIDTH-1 : 0] 	tag;
reg	[127 : 0]		fifo_in; 				// 1 + 32 + 32 bit
reg				write_en;

always @(posedge clk) begin
	if (!rst_n) begin
		ready <= 0;
		write_en <= 0;
	end 
	else begin
		if(arvalid_i && !ready && !fifo_Afull) begin
			ready <= 1;
			index <= araddr_i[INDEX_BIT_SIZE-1 : 0];
			fifo_in[0:0] <= 0; //read
			fifo_in[ID_WIDTH:1] <= arid_i;
			fifo_in[ADDR_WIDTH+ID_WIDTH : ID_WIDTH+1] <= araddr_i[ADDR_WIDTH-1 : 0];
			write_en <= 1;
		end
		else if(awvalid_i && !ready && !fifo_Afull) begin
			ready <= 1;
			index <= awaddr_i[INDEX_BIT_SIZE-1 : 0];
			fifo_in[0:0] <= 1; //write
			fifo_in[ID_WIDTH:1] <= awid_i;
			fifo_in[ADDR_WIDTH+ID_WIDTH : ID_WIDTH+1] <= awaddr_i[ADDR_WIDTH-1 : 0];
			write_en <= 1;
		end
		else begin
			ready <= 0;
			index <= 0;
			fifo_in[127:0] <= 0;
			write_en <= 0;
		end
	end
end

assign slave_i = index;
assign fifo_i = fifo_in;
assign fifo_write_enable = write_en;
assign ready_o = ready;

endmodule
	
