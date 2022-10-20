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

	// B channel
	output	wire	[ID_WIDTH - 1 : 0]		bid_o,
	output	wire					bvalid_o,
	input	wire					bready_i,

	//////////////////////////////////////////////////////////////////
	////////////////  Processor <-> DRAM $ Ctrl  /////////////////////
	//////////////////////////////////////////////////////////////////

	// AR channel (Processor <-> Index extractor)
	input	wire 	[ID_WIDTH - 1 : 0] 		arid_i,
	input	wire 	[ADDR_WIDTH - 1 : 0] 		araddr_i,
	input	wire					arvalid_i,
	output  wire					arready_o,

	// AW channel (Processor <-> Index extractor)
	input 	wire 	[ID_WIDTH - 1 : 0] 		awid_i,
	input	wire 	[ADDR_WIDTH - 1 : 0] 		awaddr_i,
	input 	wire 					awvalid_i,
	output	wire					awready_o,

	// W channel (Processor <-> Wbuffer)
	input	wire	[DATA_WIDTH - 1 : 0]		wdata_i,
	input	wire					wvalid_i,
	output	wire					wready_o,	

	// R channel (Processor -> ROB)
	output	wire					rid_o,
	output	wire	[DATA_WIDTH - 1 : 0]		rdata_o,
	output	wire					rvalid_o,
	input	wire					rready_i,

	//////////////////////////////////////////////////////////////////
	////////////////  DRAM $ Ctrl <-> Memory Ctrl  ///////////////////
	//////////////////////////////////////////////////////////////////

	// AR channel (Index extractor -> Memory Ctrl)
	output	wire 	[ID_WIDTH - 1 : 0] 		m_arid_o,
	output	wire 	[ADDR_WIDTH - 1 : 0] 		m_araddr_o,
	output	wire					m_arvalid_o,
	input	wire					m_arready_i,

	// R channel (Memory Ctrl -> Tag comparator)
	input	wire					m_rid_i,
	input	wire	[TAG_SIZE + DATA_WIDTH - 1 : 0]	m_rdata_i,
	input	wire					m_rvalid_i,
	output	wire					m_rready_o,

	// AW channel (Fill fifo <-> Memory Ctrl)
	output 	wire 	[ID_WIDTH - 1 : 0] 		m_awid_o,
	output	wire 	[ADDR_WIDTH - 1 : 0] 		m_awaddr_o,
	output 	wire 					m_awvalid_o,
	input	wire					m_awready_i,

	// W channel (Fill fifo <-> Memory Ctrl)
	output	wire	[ID_WIDTH - 1 : 0]		m_wid_o,
	output	wire	[DATA_WIDTH - 1 : 0]		m_wdata_o,
	output	wire					m_wvalid_o,
	input	wire					m_wready_i,	

	//////////////////////////////////////////////////////////////////
	////////////////   DRAM $ Ctrl <-> CXL Ctrl   ////////////////////
	//////////////////////////////////////////////////////////////////

	// AR channel (Fill AR <-> CXL Ctrl)
	output	wire 	[ID_WIDTH - 1 : 0] 		c_arid_o,
	output	wire 	[ADDR_WIDTH - 1 : 0] 		c_araddr_o,
	output	wire					c_arvalid_o,
	input	wire					c_arready_i,

	// AW channel (Evict AW W <-> CXL Ctrl)
	output 	wire 	[ID_WIDTH - 1 : 0] 		c_awid_o,
	output	wire 	[ADDR_WIDTH - 1 : 0] 		c_awaddr_o,
	output 	wire 					c_awvalid_o,
	input	wire					c_awready_i,

	// W channel (Evict AW W <-> CXL Ctrl)
	output	wire	[ID_WIDTH - 1 : 0]		c_wid_o,
	output	wire	[DATA_WIDTH - 1 : 0]		c_wdata_o,
	output	wire					c_wvalid_o,
	input	wire					c_wready_i,	

	// R channel (RMiss Handler -> CXL Ctrl)
	input	wire	[ID_WIDTH - 1 : 0]		c_rid_i,
	input	wire	[DATA_WIDTH - 1 : 0]		c_rdata_i,
	input	wire					c_rvalid_i,
	output	wire					c_rready_o,

	// B channel (Evict AW W <-> CXL Ctrl)
	input	wire	[ID_WIDTH - 1 : 0]		c_bid_i,
	input	wire					c_bvalid_i,
	output	wire					c_bready_o
);

////////////////////////////////////////////////////////////////////
//////////////////////  Index extractor ////////////////////////////
////////////////////////////////////////////////////////////////////

// Tag fifo
wire						tag_fifo_afull;
wire						tag_fifo_wren;
wire 	[TID_WIDTH + ADDR_WIDTH : 0] 		tag_fifo_wdata;


////////////////////////////////////////////////////////////////////
//////////////////////  Tag comparator  ////////////////////////////
////////////////////////////////////////////////////////////////////

// Tag fifo
wire						tag_fifo_aempty;
wire						tag_fifo_rden;
wire	[TID_WIDTH + ADDR_WIDTH : 0]		tag_fifo_rdata;

// Wbuffer
wire						wbuffer_aempty;
wire						wbuffer_rden;
wire	[DATA_WIDTH - 1 : 0]			wbuffer_rdata;

// ROB
wire						rob_full_hit;
wire						rob_wren_hit;
wire 	[TID_WIDTH + DATA_WIDTH - 1 : 0] 	rob_wdata_hit;

// AR fifo
wire						arfifo_afull;
wire						arfifo_wren;
wire 	[TID_WIDTH + ADDR_WIDTH - 1 : 0] 	arfifo_wdata;

// AW fifo
wire						awfifo_afull;
wire						awfifo_wren;
wire 	[ADDR_WIDTH - 1 : 0] 			awfifo_wdata;

// W fifo
wire						wfifo_afull;
wire						wfifo_wren;
wire 	[DATA_WIDTH - 1 : 0] 			wfifo_wdata;

// Arbiter
wire						fill_ready;
wire						fill_valid;
wire	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]	fill_wdata;


////////////////////////////////////////////////////////////////////
/////////////////////////  Fill AR   ///////////////////////////////
////////////////////////////////////////////////////////////////////

// AR fifo
wire						arfifo_aempty;
wire						arfifo_rden;
wire	[TID_WIDTH + ADDR_WIDTH - 1 : 0]	arfifo_rdata;

// RM fifo
wire						rmfifo_afull;
wire						rmfifo_wren;
wire	[TID_WIDTH + ADDR_WIDTH - 1 : 0]	rmfifo_wdata;


////////////////////////////////////////////////////////////////////
///////////////////////   Evict AW W   /////////////////////////////
////////////////////////////////////////////////////////////////////

// AW fifo
wire						awfifo_aempty;
wire						awfifo_rden;
wire	[ADDR_WIDTH - 1 : 0]			awfifo_rdata;

// W fifo
wire						wfifo_aempty;
wire						wfifo_rden;
wire	[DATA_WIDTH - 1 : 0]			wfifo_rdata;

////////////////////////////////////////////////////////////////////
//////////////////////   RMiss Handler   ///////////////////////////
////////////////////////////////////////////////////////////////////

// ROB
wire						rob_full_miss;
wire						rob_wren_miss;
wire 	[TID_WIDTH + DATA_WIDTH - 1 : 0] 	rob_wdata_miss;

// RMiss fifo
wire						rmfifo_aempty;
wire						rmfifo_rden;
wire	[TID_WIDTH + ADDR_WIDTH - 1 : 0]	rmfifo_rdata;

// Rmiss handler
wire						rmiss_ready;
wire						rmiss_valid;
wire	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]	rmiss_data;

////////////////////////////////////////////////////////////////////
/////////////////////////  Arbiter   ///////////////////////////////
////////////////////////////////////////////////////////////////////

// Fill fifo
wire						fill_fifo_afull;
wire						fill_fifo_wren;
wire	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]	fill_fifo_data;


INDEX_EXTRACTOR	index_extractor
(
	.clk			(clk),
	.rst_n			(rst_n),

	.arid_i			(arid_i),
	.araddr_i		(araddr_i),
	.arvalid_i		(arvalid_i),
	.arready_o		(arready_o),

	.awid_i			(awid_i),
	.awaddr_i		(awaddr_i),
	.awvalid_i		(awvalid_i),
	.awready_o		(awready_o),

	.arid_o			(m_arid_o),
	.araddr_o		(m_araddr_o),
	.arvalid_o		(m_arvalid_o),
	.arready_i		(m_arready_i),

	.tag_fifo_afull_i	(tag_fifo_afull),
	.tag_fifo_wren_o	(tag_fifo_wren),
	.tag_fifo_data_o	(tag_fifo_wdata)
);

TAG_COMPARE tag_compare
(
	.clk		(clk),
	.rst_n		(rst_n),

	.rid_i		(m_rid_i),
	.rdata_i	(m_rdata_i),
	.rvalid_i	(m_rvalid_i),
	.rready_o	(m_rready_o),

	.tag_fifo_aempty_i 	(tag_fifo_aempty),
	.tag_fifo_rden_o	(tag_fifo_rden),
	.tag_fifo_data_i	(tag_fifo_rdata),

	.wbuffer_aempty_i	(wbuffer_aempty),
	.wbuffer_rden_o		(wbuffer_rden),
	.wbuffer_data_i		(wbuffer_rdata),

	.rob_afull_i		(rob_full_hit),
	.rob_wren_o		(rob_wren_hit),
	.rob_data_o		(rob_wdata_hit),

	.ar_fifo_afull_i	(arfifo_afull),
	.ar_fifo_wren_o		(arfifo_wren),
	.ar_fifo_data_o		(arfifo_wdata),

	.aw_fifo_afull_i	(awfifo_afull),
	.aw_fifo_wren_o		(awfifo_wren),
	.aw_fifo_data_o		(awfifo_wdata),

	.w_fifo_afull_i		(wfifo_afull),
	.w_fifo_wren_o		(wfifo_wren),
	.w_fifo_data_o		(wfifo_wdata),

	.fill_ready_i		(fill_ready),
	.fill_valid_o		(fill_valid),
	.fill_data_o		(fill_wdata)
);

FILL_AR	 fill_ar
(
	.clk		(clk),
	.rst_n		(rst_n),

	.arid_o			(c_arid_o),
	.araddr_o		(c_araddr_o),
	.arvalid_o		(c_arvalid_o),
	.arready_i		(c_arready_i),

	.arfifo_aempty_i	(arfifo_aempty),
	.arfifo_rden_o		(arfifo_rden),
	.arfifo_data_i		(arfifo_rdata),

	.rmfifo_afull_i		(rmfifo_afull),
	.rmfifo_wren_o		(rmfifo_wren),
	.rmfifo_data_o		(rmfifo_wdata)
);

EVICT_AW_W evict_aw_w
(
	.clk		(clk),
	.rst_n		(rst_n),

	.awid_o			(c_awid_o),
	.awaddr_o		(c_awaddr_o),
	.awvalid_o		(c_awvalid_o),
	.awready_i		(c_awready_i),

	.wid_o			(c_wid_o),
	.wdata_o		(c_wdata_o),
	.wvalid_o		(c_wvalid_o),
	.wready_i		(c_wready_i),

	.bid_i			(c_bid_i),
	.bvalid_i		(c_bvalid_i),
	.bready_o		(c_bready_o),

	.awfifo_aempty_i	(awfifo_aempty),
	.awfifo_rden_o		(awfifo_rden),
	.awfifo_data_i		(awfifo_rdata),

	.wfifo_aempty_i		(wfifo_aempty),
	.wfifo_rden_o		(wfifo_rden),
	.wfifo_data_i		(wfifo_rdata)
);

READ_MISS_HANDLER rmiss_handler
(
	.clk		(clk),
	.rst_n		(rst_n),

	.valid_i	(c_rvalid_i),
	.ready_o	(c_rready_o),
	.data_i		(c_rdata_i),
	.rid_i		(c_rid_i),

	.read_en_o	(rmfifo_rden),
	.empty_i	(rmfifo_empty),
	.ar_i		(rmfifo_rdata),

	.write_en_o	(rob_wren_miss),
	.full_i		(rob_full_miss),
	.wdata_ROB_o	(rob_wdata_miss),

	.valid_o	(rmiss_valid),
	.ready_i	(rmiss_ready),
	.wdata_Arbiter_o (rmiss_data)
);

ARBITER arbiter
(
	.clk		(clk),
	.rst_n		(rst_n),

	.fill_ready_o		(fill_ready),
	.fill_valid_i		(fill_valid),
	.fill_data_i		(fill_wdata),

	.rmiss_ready_o		(rmiss_ready),
	.rmiss_valid_i		(rmiss_valid),
	.rmiss_data_i		(rmiss_data),

	.fill_fifo_afull_i	(fill_fifo_afull),
	.fill_fifo_wren_o	(fill_fifo_wren),
	.fill_fifo_data_o	(fill_fifo_data)
);

ROB rob
(
	.clk		(clk),
	.rst_n		(rst_n),

	.valid_o	(rvalid_o),
	.ready_i	(rready_i),
	.rid_o		(rid_o),
	.rdata_o	(rdata_o),

	.full_hit_o	(rob_full_hit),
	.write_en_hit_i (rob_wren_hit),
	.wdata_hit_i	(rob_wdata_hit),

	.full_miss_o	(rob_full_miss),
	.write_en_miss_i (rob_wren_miss),
	.wdata_miss_i   (rob_wdata_miss)
);

WBUFFER	wbuffer
(
	.clk		(clk),
	.rst_n		(rst_n),

	.valid_i	(wvalid_i),
	.wdata_i	(wdata_i),
	.ready_o	(wready_o),

	.Aempty_o	(wbuffer_aempty),
	.rden_i		(wbuffer_rden),
	.rdata_o	(wbuffer_rdata)	
);

FILL_FIFO fill_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.afull_o	(fill_fifo_afull),
	.wren_i		(fill_fifo_wren),
	.data_i		(fill_fifo_data),

	.wid_o		(m_wid_o),
	.wvalid_o	(m_wvalid_o),
	.wdata_o	(m_wdata_o),
	.wready_i	(m_wready_i),

	.awid_o		(m_awid_o),
	.awvalid_o	(m_awvalid_o),
	.awaddr_o	(m_awaddr_o),
	.awready_i	(m_awready_i)
);

FIFO
#(
	.DATA_WIDTH 	(TID_WIDTH + ADDR_WIDTH + 1),
     	.FIFO_SIZE 	(64),
     	.A_FULL_THR 	(62),
        .A_EMPTY_THR 	(0)
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

FIFO
#(
	.DATA_WIDTH 	(TID_WIDTH + ADDR_WIDTH),
	.FIFO_SIZE 	(64),
	.A_FULL_THR 	(62),
	.A_EMPTY_THR 	(0)
) ar_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(arfifo_afull),
	.write_en_i	(arfifo_wren),
	.write_data_i	(arfifo_wdata),

	.A_empty_o	(arfifo_aempty),
	.read_en_i	(arfifo_rden),
	.read_data_o	(arfifo_rdata)	
);

FIFO
#(
	.DATA_WIDTH 	(ADDR_WIDTH),
	.FIFO_SIZE 	(64),
	.A_FULL_THR 	(62),
	.A_EMPTY_THR 	(0)
) aw_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(awfifo_afull),
	.write_en_i	(awfifo_wren),
	.write_data_i	(awfifo_wdata),

	.A_empty_o	(awfifo_aempty),
	.read_en_i	(awfifo_rden),
	.read_data_o	(awfifo_rdata)	
);

FIFO
#(
	.DATA_WIDTH 	(DATA_WIDTH),
	.FIFO_SIZE 	(64),
	.A_FULL_THR 	(62),
	.A_EMPTY_THR 	(0)
) w_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(wfifo_afull),
	.write_en_i	(wfifo_wren),
	.write_data_i	(wfifo_wdata),

	.A_empty_o	(wfifo_aempty),
	.read_en_i	(wfifo_rden),
	.read_data_o	(wfifo_rdata)	
);

FIFO
#(
	.DATA_WIDTH 	(TID_WIDTH + ADDR_WIDTH),
	.FIFO_SIZE 	(64),
	.A_FULL_THR 	(62),
	.A_EMPTY_THR 	(0)
) rmiss_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(rmfifo_afull),
	.write_en_i	(rmfifo_wren),
	.write_data_i	(rmfifo_wdata),

	.empty_o	(rmfifo_empty),
	.read_en_i	(rmfifo_rden),
	.read_data_o	(rmfifo_rdata)	
);
endmodule
