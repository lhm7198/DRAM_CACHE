`define ADDR_W	 64
`define DATA_W	 64*8
`define ID_W	 16

`define TID_W	 10

`timescale 1ps/1ps

module EVICT_AW_W_TB;

reg clk = 1'b0;
reg rst_n;

// AW channel
wire [`ID_W - 1 : 0]			awid_o;
wire [`ADDR_W - 1 : 0] 			awaddr_o;
wire					awvalid_o;
reg					awready_i;

// AW channel
wire [`ID_W - 1 : 0]			wid_o;
wire [`DATA_W - 1 : 0] 			wdata_o;
wire					wvalid_o;
reg					wready_i;

// B channel
wire [`ID_W - 1 : 0]			bid_o;
wire					bvalid_o;
reg					bready_i;

// AW FIFO
reg 					awfifo_aempty_i;
wire					awfifo_rden_o;
reg [`ADDR_W - 1 : 0]		  	awfifo_data_i;

// AW FIFO
reg 					wfifo_aempty_i;
wire					wfifo_rden_o;
reg [`DATA_W - 1 : 0]		  	wfifo_data_i;


localparam CLOCK_PERIOD = 1000;
always #(CLOCK_PERIOD/2) clk = ~clk;

initial
begin
	rst_n = 1'b0;

	awready_i = 1'b1;
	wready_i = 1'b1;
	bready_i = 1'b1;
		
	awfifo_aempty_i = 1'b1;
	awfifo_data_i = 0;
	
	wfifo_aempty_i = 1'b1;
	wfifo_data_i = 0;

	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\n$$$$$$$$$$$$$$  Start  $$$$$$$$$$$$$$\n");
	
	//////////////////////////////////////////////
	/////////////  read write miss  //////////////
	//////////////////////////////////////////////
	$display("-------- READ MISS START ---------\n");
	
	awfifo_aempty_i = 1'b0;

	awfifo_data_i[`TID_W + `ADDR_W - 1 : `ADDR_W] = 1; // tid
	awfifo_data_i[`ADDR_W - 1 : 0] = 1; // addr

	wfifo_aempty_i = 1'b0;

	wfifo_data_i = 12; // data
	
	// S_IDLE -> S_RUN
	awready_i = 1'b1;
	wready_i = 1'b1;

	#(CLOCK_PERIOD);

	// S_RUN -> S_IDLE
	#(CLOCK_PERIOD);

	#(CLOCK_PERIOD);
	$display("awaddr : %x\nwdata : %x\n", 
		awaddr_o, wdata_o);

	$display("---------------------------------\n");

	$display("\n$$$$$$$$$$$$$$$  End  $$$$$$$$$$$$$$$\n");

	$finish;
end

EVICT_AW_W evict_aw_w
(
	.clk(clk), 
	.rst_n(rst_n),

	.awid_o(awid_o),
	.awaddr_o(awaddr_o),
	.awvalid_o(awvalid_o),
	.awready_i(awready_i),

	.wid_o(wid_o),
	.wdata_o(wdata_o),
	.wvalid_o(wvalid_o),
	.wready_i(wready_i),

	.bid_o(bid_o),
	.bvalid_o(bvalid_o),
	.bready_i(bready_i),

	.awfifo_aempty_i(awfifo_aempty_i),
	.awfifo_rden_o(awfifo_rden_o),
	.awfifo_data_i(awfifo_data_i),

	.wfifo_aempty_i(wfifo_aempty_i),
	.wfifo_rden_o(wfifo_rden_o),
	.wfifo_data_i(wfifo_data_i)
);

endmodule
