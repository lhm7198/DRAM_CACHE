`include "TYPEDEF.svh"

module TOP_MODULE
#(
	parameter	ADDR_WIDTH	= `AXI_ADDR_WIDTH,
	parameter	DATA_WIDTH	= `AXI_DATA_WIDTH,
	parameter	ID_WIDTH	= `AXI_ID_WIDTH,
	parameter	ID		= `AXI_ID,

	parameter 	TAG_SIZE	= `TAG_SIZE,

	parameter	INDEX_WIDTH	= `INDEX_WIDTH,
	parameter 	OFFSET_WIDTH	= `OFFSET_WIDTH,

	parameter	AFULL_THR	= `FIFO_AFULL_THR,
	parameter	AEMPTY_THR	= `FIFO_AEMPTY_THR,

	parameter	TID_WIDTH	= `TID_WIDTH
)
(
	input	wire	clk,
	input	wire	rst_n,

	//////////////////////////////////////////////////////////////////
	////////////////  Processor <-> DRAM $ Ctrl  /////////////////////
	//////////////////////////////////////////////////////////////////

	// AR channel (Processor <-> Index extractor)
	input	wire 	[ID_WIDTH - 1 : 0] 		arid_i,
	input	wire 	[ADDR_WIDTH - 1 : 0] 		araddr_i,
	input	wire	[7 : 0]				arlen_i,
	input	wire					arvalid_i,
	output  wire					arready_o,

	// AW channel (Processor <-> Index extractor)
	input 	wire 	[ID_WIDTH - 1 : 0] 		awid_i,
	input	wire 	[ADDR_WIDTH - 1 : 0] 		awaddr_i,
	input	wire	[7 : 0]				awlen_i,
	input 	wire 					awvalid_i,
	output	wire					awready_o,
/*
	// W channel (Processor <-> Wbuffer)
	input	wire	[DATA_WIDTH - 1 : 0]		wdata_i,
	input	wire					wvalid_i,
	output	wire					wready_o,	
*/
	//////////////////////////////////////////////////////////////////
	////////////////  DRAM $ Ctrl <-> Memory Ctrl  ///////////////////
	//////////////////////////////////////////////////////////////////

	// AR channel (Index extractor -> Memory Controller)
	output	wire 	[ID_WIDTH - 1 : 0] 		arid_o,
	output	wire 	[ADDR_WIDTH - 1 : 0] 		araddr_o,
	input	wire	[7 : 0]				arlen_o,
	output	wire					arvalid_o,
	input	wire					arready_i,
/*
	// R channel (Memory Controller -> Tag comparator)
	input	wire					rid_i,
	input	wire	[TAG_SIZE + DATA_WIDTH - 1 : 0]	rdata_i,
	input	wire					rvalid_i,
	output	wire					rready_o
*/
	output	wire					tag_fifo_aempty,
	input	wire					tag_fifo_rden,
	output	wire	[TID_WIDTH + ADDR_WIDTH : 0] 	tag_fifo_rdata
);

// Index extractor <-> Tag fifo
wire					tag_fifo_afull;
wire					tag_fifo_wren;
wire 	[TID_WIDTH + ADDR_WIDTH : 0] 	tag_fifo_wdata;

/*
// Tag fifo <-> Tag comparator
wire					tag_fifo_aempty;
wire					tag_fifo_rden;
wire	[TID_WIDTH + ADDR_WIDTH : 0]	tag_fifo_rdata;

// Wbuffer <-> Tag comparator
wire					wbuffer_aempty;
wire					wbuffer_rden;
wire	[DATA_WIDTH - 1 : 0]		wbuffer_rdata;
*/

INDEX_EXTRACTOR	index_extractor
(
	.clk			(clk),
	.rst_n			(rst_n),

	.arid_i			(arid_i),
	.araddr_i		(araddr_i),
	.arlen_i		(),
	.arvalid_i		(arvalid_i),
	.arready_o		(arready_o),

	.awid_i			(awid_i),
	.awaddr_i		(awaddr_i),
	.awlen_i		(),
	.awvalid_i		(awvalid_i),
	.awready_o		(awready_o),

	.arid_o			(arid_o),
	.araddr_o		(araddr_o),
	.arlen_o		(),
	.arvalid_o		(arvalid_o),
	.arready_i		(arready_i),

	.tag_fifo_afull_i	(tag_fifo_afull),
	.tag_fifo_wren_o	(tag_fifo_wren),
	.tag_fifo_data_o	(tag_fifo_wdata)
);

FIFO
#(
	.DATA_WIDTH 	(TID_WIDTH + ADDR_WIDTH + 1),
     	.FIFO_SIZE 	(64),
     	.A_FULL_THR 	(62),
        .A_EMPTY_THR 	(2)
) tag_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(tag_fifo_afull),
	.write_en_i	(tag_fifo_wren),
	.write_data_i	(tag_fifo_wdata),

	.A_empty_o	(tag_fifo_aempty),
	.read_en_i	(tag_fifo_rden),
	.read_data_o	(tag_fifo_rdata)	
);
/*
TAG_COMPARE tag_compare
(
	.clk		(clk),
	.rst_n		(rst_n),

	.rid_i		(ID),
	.rdata_i	(rdata_i),
	.rvalid_i	(rvalid_i),
	.rready_o	(rready_o),

	.tag_fifo_aempty_i 	(tag_fifo_aempty),
	.tag_fifo_rden_o	(tag_fifo_rden),
	.tag_fifo_data_i	(tag_fifo_rdata),

	.wbuffer_aempty_i	(),
	.wbuffer_rden_o		(),
	.wbuffer_data_i		(),

	.rob_afull_i		(),
	.rob_wren_o		(),
	.rob_data_o		(),

	.ar_fifo_afull_i	(),
	.ar_fifo_wren_o		(),
	.ar_fifo_data_o		(),

	.aw_fifo_afull_i	(),
	.aw_fifo_wren_o		(),
	.aw_fifo_data_o		(),

	.w_fifo_afull_i		(),
	.w_fifo_wren_o		(),
	.w_fifo_data_o		(),

	.fill_ready_i		(),
	.fill_valid_o		(),
	.fill_data_o		(),
)

FIFO
#(
	.DATA_WIDTH 	(DATA_WIDTH),
	.FIFO_SIZE 	(64),
	.A_FULL_THR 	(62),
	.A_EMPTY_THR 	(2)
) wbuffer
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(!rready_o),
	.write_en_i	(rvalid_i),
	.write_data_i	(rdata_i),

	.A_empty_o	(wbuffer_aempty),
	.read_en_i	(wbuffer_rden),
	.read_data_o	(wbuffer_rdata)	
);
*/
endmodule


