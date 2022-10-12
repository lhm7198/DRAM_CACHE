`include "TYPEDEF.svh"

module TOP_MODULE
#(
	parameter	ADDR_WIDTH	= `AXI_ADDR_WIDTH,
	parameter	DATA_WIDTH	= `AXI_DATA_WIDTH,
	parameter	ID_WIDTH	= `AXI_ID_WIDTH,
	parameter	TID_WIDTH	= `TID_WIDTH,
	parameter	INDEX_WIDTH	= `INDEX_WIDTH
)
(
	input	wire	clk,
	input	wire	rst_n,

	// AR channel (Processor <-> DRAM $ Controller)
	input	wire 	[ID_WIDTH-1 : 0] 	arid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 	araddr_i,
	input	wire	[7 : 0]			arlen_i,
	input	wire				arvalid_i,
	output  wire				arready_o,

	// AW channel (Processor <-> DRAM $ Controller)
	input 	wire 	[ID_WIDTH-1 : 0] 	awid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 	awaddr_i,
	input	wire	[7 : 0]			awlen_i,
	input 	wire 				awvalid_i,
	output	wire				awready_o,

	// AR channel (DRAM $ Controller -> Memory Controller)
	output	wire 	[ID_WIDTH-1 : 0] 	arid_o,
	output	wire 	[ADDR_WIDTH-1 : 0] 	araddr_o,
	input	wire	[7 : 0]			arlen_o,
	output	wire				arvalid_o,
	input	wire				arready_i,
/*
	// R channel (Memory Controller -> Dram $ Controller)
	input	wire	[71 : 0]		rdata_i,
	input	wire	[55 : 0]		rtag_i,
	input	wire				rvalid_i,
	output	wire				rready_o
*/
	// Tag fifo -> Tag compare
	output	wire					aempty_o,
	input	wire					rden_i,
	output 	wire 	[ADDR_WIDTH + TID_WIDTH : 0] 	data_o 	// 1 + 64 + 16 bit
);

// INDEX_EXTRACTOR <-> Tag fifo
wire					afull_IE_TF;
wire					wren_IE_TF;
wire 	[ADDR_WIDTH + TID_WIDTH : 0] 	data_IE_TF; 	// 1 + 64 + 16 bit
	



INDEX_EXTRACTOR	index_extractor
(
	.clk			(clk),
	.rst_n			(rst_n),

	.arid_i			(arid_i),
	.araddr_i		(araddr_i),
	.arlen_i		(arlen_i),
	.arvalid_i		(arvalid_i),
	.arready_o		(arready_o),

	.awid_i			(awid_i),
	.awaddr_i		(awaddr_i),
	.awlen_i		(awlen_i),
	.awvalid_i		(awvalid_i),
	.awready_o		(awready_o),

	.arid_o			(arid_o),
	.araddr_o		(araddr_o),
	.arlen_o		(arlen_o),
	.arvalid_o		(arvalid_o),
	.arready_i		(arready_i),

	.tag_fifo_afull_i	(afull_IE_TF),
	.tag_fifo_wren_o	(wren_IE_TF),
	.tag_fifo_data_o	(data_IE_TF)
);

FIFO		tag_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(afull_IE_TF),
	.write_en_i	(wren_IE_TF),
	.write_data_i	(data_IE_TF),

	.A_empty_o	(aempty_o),
	.read_en_i	(rden_i),
	.read_data_o	(data_o)	
);

endmodule


