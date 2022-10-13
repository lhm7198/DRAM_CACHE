`define ADDR_W	 64
`define DATA_W	 64*8
`define ID_W	 16

`define TID_W	 10

`timescale 1ps/1ps

module FILL_AR_TB;

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

	arready_i = 1'b1;
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
	
	arfifo_aempty_i = 1'b0;

	arfifo_data_i[`TID_W + `ADDR_W - 1 : `ADDR_W] = 1; // tid
	arfifo_data_i[`ADDR_W - 1 : 0] = 1; // addr
	
	// S_IDLE -> S_RUN
	arfifo_aempty_i = 1'b0;
	arready_i = 1'b1;
	#(CLOCK_PERIOD);

	// S_RUN -> S_IDLE
	#(CLOCK_PERIOD);

	$display("rmfifo_data : %x\naraddr : %x\n", 
		rmfifo_data_o, araddr_o);

	$display("---------------------------------\n");

	$display("\n$$$$$$$$$$$$$$$  End  $$$$$$$$$$$$$$$\n");

	$finish;
end

FILL_AR fill_ar
(
	.clk(clk), 
	.rst_n(rst_n),

	.arid_o(arid_o),
	.araddr_o(araddr_o),
	.arvalid_o(arvalid_o),
	.arready_i(arready_i),

	.arfifo_aempty_i(arfifo_aempty_i),
	.arfifo_rden_o(arfifo_rden_o),
	.arfifo_data_i(arfifo_data_i),

	.rmfifo_afull_i(rmfifo_afull_i),
	.rmfifo_wren_o(rmfifo_wren_o),
	.rmfifo_data_o(rmfifo_data_o)
);

endmodule
