`define ADDR_W 	64
`define DATA_W	64*8
`define ID_W	16
`define ID	1

`define TAG_S	8*8
`define TAG_W 16
`define INDEX_W	10
`define OFFSET_W 38
`define BLANK_W 46	

`define TID_W	10

`timescale	1ps/1ps

module	TOB_TB;

reg	clk	= 1'b0;
reg	rst_n;

//////////////////////////////////////////////////////////////////
////////////////  Processor <-> DRAM $ Ctrl  /////////////////////
//////////////////////////////////////////////////////////////////

// AR channel (Processor <-> Index extractor)
reg	[`ID_W : 0]		arid_i;
reg	[`ADDR_W : 0]		araddr_i;
reg				arvalid_i;
wire				arready_o;

// AW channel (Processor <-> Index extractor)
reg	[`ID_W : 0]		awid_i;
reg	[`ADDR_W : 0]		awaddr_i;
reg				awvalid_i;
wire				awready_o;

// W channel (Processor <-> Wbuffer)
reg	[`DATA_W - 1 : 0]	wdata_i;
reg				wvalid_i;
wire				wready_o;	

// R channel (Processor -> ROB)
wire					rid_o;
wire	[`DATA_W - 1 : 0]		rdata_o;
wire					rvalid_o;
reg					rready_i;

//////////////////////////////////////////////////////////////////
////////////////  DRAM $ Ctrl <-> Memory Ctrl  ///////////////////
//////////////////////////////////////////////////////////////////
	
// AR channel (Index extractor -> Memory Ctrl)
wire 	[`ID_W - 1 : 0] 		m_arid_o;
wire 	[`ADDR_W - 1 : 0] 		m_araddr_o;
wire					m_arvalid_o;
reg					m_arready_i;

// R channel (Memory Ctrl -> Tag comparator)
reg					m_rid_i;
reg	[`TAG_S + `DATA_W - 1 : 0]	m_rdata_i;
reg					m_rvalid_i;
wire					m_rready_o;

// AW channel (Fill fifo <-> Memory Ctrl)
wire 	[`ID_W - 1 : 0] 		m_awid_o;
wire 	[`ADDR_W - 1 : 0] 		m_awaddr_o;
wire 					m_awvalid_o;
reg					m_awready_i;

// W channel (Fill fifo <-> Memory Ctrl)
wire	[`ID_W - 1 : 0]			m_wid_o;
wire	[`DATA_W - 1 : 0]		m_wdata_o;
wire					m_wvalid_o;
reg					m_wready_i;	

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

	// Processor <-> DRAM $ Ctrl //
	arid_i 		= 0;
	araddr_i 	= 0;
	arvalid_i	= 0;
	
	awid_i 		= 0;
	awaddr_i 	= 0;
	awvalid_i 	= 0;

	wdata_i		= 0;
	wvalid_i	= 0;

	rready_i	= 0;

	// DRAM $ Ctrl <-> Memory Ctrl //
	m_arready_i	= 0;
	
	m_rid_i 	= 0;
	m_rdata_i	= 0;
	m_rvalid_i	= 0;

	m_awready_i	= 0;
	
	m_wready_i	= 0;

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
	
	#(CLOCK_PERIOD);
	$display("addr = %x, arvalid = %d, ready = %d",m_araddr_o, m_arvalid_o, arready_o);
	araddr_i		= 64'habcd1234abcd1234;
	arvalid_i		= 1;

	#(CLOCK_PERIOD);
	$display("addr = %x, arvalid = %d, ready = %d",m_araddr_o, m_arvalid_o, arready_o);

	m_arready_i		= 1;	
	arvalid_i		= 0;
	
	m_rvalid_i		= 1;
	m_rdata_i[`TAG_W + `BLANK_W + `DATA_W - 1 : `BLANK_W + `DATA_W] = 16'habcd;
	m_rdata_i[`TAG_S + `DATA_W - 1] = 1;	//valid bit
	m_rdata_i[`DATA_W - 1 : 0]	= 512'haaaaaaaaaaaabbbbbbbbbbbbbb;

	#(CLOCK_PERIOD);
	$display("addr = %x, arvalid = %d, ready = %d",m_araddr_o, m_arvalid_o, arready_o);
	//m_arready_i		= 0;	
	
	#(CLOCK_PERIOD);
	$display("addr = %x, arvalid = %d, ready = %d",m_araddr_o, m_arvalid_o, arready_o);
	
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	$display("rdata_o = %x",rdata_o);
	#(CLOCK_PERIOD);
	$display("rdata_o = %x",rdata_o);
	#(CLOCK_PERIOD);
	$finish;
end

TOP_MODULE top_module
(
	.clk		(clk),
	.rst_n		(rst_n),

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
	.m_arid_o	(m_arid_o),
	.m_araddr_o	(m_araddr_o),
	.m_arvalid_o	(m_arvalid_o),
	.m_arready_i	(m_arready_i),

	.m_rid_i	(m_rid_i),
	.m_rdata_i	(m_rdata_i),
	.m_rvalid_i	(m_rvalid_i),
	.m_rready_o	(m_rready_o),

	.m_awid_o	(m_awid_o),
	.m_awaddr_o	(m_awaddr_o),
	.m_awvalid_o	(m_awvalid_o),
	.m_awready_i	(m_awready_i),

	.m_wid_o	(m_wid_o),
	.m_wdata_o	(m_wdata_o),
	.m_wvalid_o	(m_wvalid_o),
	.m_wready_i	(m_wready_i),

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

endmodule
