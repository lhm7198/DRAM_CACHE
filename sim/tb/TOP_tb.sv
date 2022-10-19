`define ADDR_W 	64
`define DATA_W	64*8
`define ID_W	16
`define ID	1

`define TAG_S	8*8
`define TAG_W	 32
`define INDEX_W	 26
`define OFFSET_W 6
`define BLANK_W  30

`define TID_W	10

`timescale	1ps/1ps

module	TOB_TB;

reg	clk	= 1'b0;
reg	rst_n;


wire	[`ID_W - 1 : 0]			bid_o;
wire					bvalid_o;
reg					bready_i;

//////////////////////////////////////////////////////////////////
////////////////  Processor <-> DRAM $ Ctrl  /////////////////////
//////////////////////////////////////////////////////////////////

// AR channel (Processor <-> Index extractor)
reg	[`ID_W - 1 : 0]			arid_i;
reg	[`ADDR_W : 0]			araddr_i;
reg					arvalid_i;
wire					arready_o;

// AW channel (Processor <-> Index extractor)
reg	[`ID_W - 1 : 0]			awid_i;
reg	[`ADDR_W : 0]			awaddr_i;
reg					awvalid_i;
wire					awready_o;

// W channel (Processor <-> Wbuffer)
reg	[`DATA_W - 1 : 0]		wdata_i;
reg					wvalid_i;
wire					wready_o;	

// R channel (Processor -> ROB)
wire					rid_o;
wire	[`DATA_W - 1 : 0]		rdata_o;
wire					rvalid_o;
reg					rready_i;

//////////////////////////////////////////////////////////////////
////////////////  DRAM $ Ctrl <-> Memory Ctrl  ///////////////////
//////////////////////////////////////////////////////////////////
	
// AR channel (Index extractor -> Memory Ctrl)
wire 	[`ID_W - 1 : 0] 		m_arid;
wire 	[`ADDR_W - 1 : 0] 		m_araddr;
wire					m_arvalid;
wire					m_arready;

// R channel (Memory Ctrl -> Tag comparator)
wire					m_rid;
wire	[`TAG_S + `DATA_W - 1 : 0]	m_rdata;
wire					m_rvalid;
wire					m_rready;

// AW channel (Fill fifo <-> Memory Ctrl)
wire 	[`ID_W - 1 : 0] 		m_awid;
wire 	[`ADDR_W - 1 : 0] 		m_awaddr;
wire 					m_awvalid;
wire					m_awready;

// W channel (Fill fifo <-> Memory Ctrl)
wire	[`ID_W - 1 : 0]			m_wid;
wire	[`DATA_W - 1 : 0]		m_wdata;
wire					m_wvalid;
wire					m_wready;	

//////////////////////////////////////////////////////////////////
////////////////   DRAM $ Ctrl <-> CXL Ctrl   ////////////////////
//////////////////////////////////////////////////////////////////

// AR channel (Fill AR <-> CXL Ctrl)
wire 	[`ID_W - 1 : 0] 		c_arid_o;
wire 	[`ADDR_W - 1 : 0] 		c_araddr_o;
wire					c_arvalid_o;
reg					c_arready_i;

// AW channel (Evict AW W <-> CXL Ctrl)
wire 	[`ID_W - 1 : 0] 		c_awid_o;
wire 	[`ADDR_W - 1 : 0] 		c_awaddr_o;
wire 					c_awvalid_o;
reg					c_awready_i;

// W channel (Evict AW W <-> CXL Ctrl)
wire	[`ID_W - 1 : 0]			c_wid_o;
wire	[`DATA_W - 1 : 0]		c_wdata_o;
wire					c_wvalid_o;
reg					c_wready_i;	

// R channel (RMiss Handler -> CXL Ctrl)
reg	[`ID_W - 1 : 0]			c_rid_i;
reg	[`DATA_W - 1 : 0]		c_rdata_i;
reg					c_rvalid_i;
wire					c_rready_o;

// B channel (Evict AW W <-> CXL Ctrl)
wire	[`ID_W - 1 : 0]			c_bid_o;
wire					c_bvalid_o;
reg					c_bready_i;

localparam			CLOCK_PERIOD 	= 1000;
always #(CLOCK_PERIOD/2) 	clk 		= ~clk;

initial
begin
	rst_n		= 1'b1;

	bready_i	= 1'b1;
	// Processor <-> DRAM $ Ctrl //
	arid_i 		= 0;
	araddr_i 	= 0;
	arvalid_i	= 0;
	
	awid_i 		= 0;
	awaddr_i 	= 0;
	awvalid_i 	= 0;

	wdata_i		= 0;
	wvalid_i	= 0;

	rready_i	= 1'b1;

	// DRAM $ Ctrl <-> Memory Ctrl //

	// DRAM $ Ctrl <-> CXL Ctrl //
	c_arready_i 	= 0;

	c_awready_i	= 0;

	c_wready_i	= 0;

	c_rid_i		= 0;
	c_rdata_i	= 0;
	c_rvalid_i	= 0;

	c_bready_i	= 0;
	
	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart\n");

	/////////////////////////////////////////////////
	/////////////////// write miss  /////////////////
	/////////////////////////////////////////////////
	awaddr_i		= 64'h0000000f00000040; // tag(f), index(1), offset(0)
	awvalid_i		= 1'b1;
	wdata_i			= 64'hddddddddddddddddd;
	wvalid_i		= 1'b1;
	#(CLOCK_PERIOD);

	awvalid_i		= 1'b0;
	wvalid_i		= 1'b0;
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	$display("m_awaddr = %x",m_awaddr);
	$display("m_data = %x",m_wdata);

	/////////////////////////////////////////////////
	/////////////////// read hit  ///////////////////
	/////////////////////////////////////////////////

	//memory_ctrl.write_8byte(1, 64'hc0000003c0000000); // valid(1), dirty(1), tag(f), blank(0)
	//memory_ctrl.write_64byte(1, 64'hfffffffffffffffff);

	// index extractor get data
	araddr_i		= 64'h0000000f00000040; // tag(f) + index(1) + offset(0)
	arvalid_i		= 1'b1;
	#(CLOCK_PERIOD);

	// tag comparator get data
	arvalid_i		= 1'b0;
	
	#(CLOCK_PERIOD); 
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	$display("rdata_o : %x\n", rdata_o);

	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);





	$finish;
end

TOP_MODULE top_module
(
	.clk		(clk),
	.rst_n		(rst_n),

	.bid_o		(bid_o),
	.bvalid_o	(bvalid_o),
	.bready_i	(bready_i),

	// 1
	.arid_i		(arid_i),
	.araddr_i	(araddr_i),
	.arvalid_i	(arvalid_i),
	.arready_o	(arready_o),

	.awid_i		(awid_i),
	.awaddr_i	(awaddr_i),
	.awvalid_i	(awvalid_i),
	.awready_o	(awready_o),

	.wdata_i	(wdata_i),
	.wvalid_i	(wvalid_i),
	.wready_o	(wready_o),

	.rid_o		(rid_o),
	.rdata_o	(rdata_o),
	.rvalid_o	(rvalid_o),
	.rready_i	(rready_i),

	// 2
	.m_arid_o	(m_arid),
	.m_araddr_o	(m_araddr),
	.m_arvalid_o	(m_arvalid),
	.m_arready_i	(m_arready),

	.m_rid_i	(m_rid),
	.m_rdata_i	(m_rdata),
	.m_rvalid_i	(m_rvalid),
	.m_rready_o	(m_rready),

	.m_awid_o	(m_awid),
	.m_awaddr_o	(m_awaddr),
	.m_awvalid_o	(m_awvalid),
	.m_awready_i	(m_awready),

	.m_wid_o	(m_wid),
	.m_wdata_o	(m_wdata),
	.m_wvalid_o	(m_wvalid),
	.m_wready_i	(m_wready),

	// 3
	.c_arid_o	(c_arid_o),
	.c_araddr_o	(c_araddr_o),
	.c_arvalid_o	(c_arvalid_o),
	.c_arready_i	(c_arready_i),

	.c_awid_o	(c_awid_o),
	.c_awaddr_o	(c_awaddr_o),
	.c_awvalid_o	(c_awvalid_o),
	.c_awready_i	(c_awready_i),

	.c_wid_o	(c_wid_o),
	.c_wdata_o	(c_wdata_o),
	.c_wvalid_o	(c_wvalid_o),
	.c_wready_i	(c_wready_i),

	.c_rid_i	(c_rid_i),
	.c_rdata_i	(c_rdata_i),
	.c_rvalid_i	(c_rvalid_i),
	.c_rready_o	(c_rready_o),

	.c_bid_o	(c_bid_o),
	.c_bvalid_o	(c_bvalid_o),
	.c_bready_i	(c_bready_i)
);

AXI_SLAVE memory_ctrl
(
	.clk		(clk),
	.rst_n		(rst_n),

	.arid_i		(m_arid),
	.araddr_i	(m_araddr),
	.arvalid_i	(m_arvalid),
	.arready_o	(m_arready),

	.rid_o		(m_rid),
	.rdata_o	(m_rdata),
	.rvalid_o	(m_rvalid),
	.rready_i	(m_rready),

	.awid_i		(m_awid),
	.awaddr_i	(m_awaddr),
	.awvalid_i	(m_awvalid),
	.awready_o	(m_awready),

	.wid_i		(m_wid),
	.wdata_i	(m_wdata),
	.wvalid_i	(m_wvalid),
	.wready_o	(m_wready),

	.bid_o		(bid_o),
	.bvalid_o	(bvalid_o),
	.bready_i	(bready_i)
);

endmodule
