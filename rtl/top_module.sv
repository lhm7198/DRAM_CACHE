`include "AXI_TYPEDEF.svh"

module DRAM_CACHE_TOP
#(
	parameter ADDR_WIDTH	= `AXI_ADDR_WIDTH, // 64
	parameter DATA_WIDTH	= `AXI_DATA_WIDTH, // 32
	parameter ID_WIDTH	= `AXI_ID_WIDTH, // 16
	parameter INDEX_WIDTH	= `INDEX_WIDTH // 4
)
(
	input	wire		clk,
	input	wire		rst_n,

	// AR channel (Processor <-> DRAM $ Controller)
	input	wire 	[ID_WIDTH-1 : 0] 	arid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 	araddr_i,
	input	wire				arvalid_i,
	output  wire				arready_o,

	// AW channel (Processor <-> DRAM $ Controller)
	input 	wire 	[ID_WIDTH-1 : 0] 	awid_i,
	input	wire 	[ADDR_WIDTH-1 : 0] 	awaddr_i,
	input 	wire 				awvalid_i,
	output	wire				awready_o,

	// AR channel (DRAM $ Controller -> Memory Controller)
	output	wire 	[ID_WIDTH-1 : 0] 	arid_o,
	output	wire 	[INDEX_WIDTH-1 : 0] 	araddr_o,
	output	wire				arvalid_o,
	input	wire				arready_i,

	// R channel (Memory Controller -> Dram $ Controller)
	input	wire	[71 : 0]		rdata_i,
	input	wire	[55 : 0]		rtag_i,
	input	wire				rvalid_i,
	output	wire				rready_o
);

	// Index extractor <-> FIFO
	wire					fifo_afull;
	wire					fifo_write_en;
	wire 	[ADDR_WIDTH + ID_WIDTH : 0] 	fifo_wdata; 	// 1 + 64 + 16 bit

	// FIFO -> Tag compare
	wire	[ADDR_WIDTH + ID_WIDTH : 0]	fifo_rdata;	
	
	// Tag compare -> FIFO
	wire	[71 : 0]			r_hit_data;
	wire	[71 : 0]			r_miss_data;
	wire	[71 : 0]			w_hit_data;
	wire	[71 : 0]			w_miss_data;
	
	
	
	INDEX_EXTRACTOR u_index_extractor(
		.clk(clk),
		.rst_n(rst_n),

		.arid_i(arid_i),
		.araddr_i(araddr_i),
		.arvalid_i(arvalid_i),
		.arready_o(arready_o),

		.awid_i(awid_i),
		.awaddr_i(awaddr_i),
		.awvalid_i(awvalid_i),
		.awready_o(awready_o),

		.arid_o(arid_o),
		.araddr_o(araddr_o),
		.arvalid_o(arvalid_o),
		.arready_i(arready_i),

		.fifo_afull_i(fifo_afull),
		.fifo_write_en_o(fifo_write_en),
		.fifo_data_o(fifo_data)
	);

	FIFO u_fifo(
		.clk(clk),
		.rst_n(rst_n),

		.full_o(),
		.A_full_o(fifo_afull),
		.write_en_i(fifo_write_en),
		.write_data_i(fifo_wdata),

		.empty_o(),
		.A_empty_o(),
		.read_en_i(),
		.read_data_o(fifo_rdata),

		.remain_o()
	);	

	TAG_COMPARE u_tag_compare(
		.clk(clk),
		.rst_n(rst_n),

	);
