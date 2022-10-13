`define ADDR_W	 64
`define DATA_W	 64*8
`define ID_W	 16

`define TID_W	 10

`timescale 1ps/1ps

module FILL_AR_TB;

reg clk = 1'b0;
reg rst_n;

// AR channel
wire [`ID_W - 1 : 0]			arid_o;
wire [`ADDR_W - 1 : 0] 			araddr_o;
wire					arvalid_o;
reg					arready_i;

// AR FIFO
reg 					arfifo_aempty_i;
wire					arfifo_rden_o;
reg [`TID_W + `ADDR_W - 1 : 0]  	arfifo_data_i;

// RMISS FIFO
reg 					rmfifo_afull_i;
wire					rmfifo_wren_o;
wire [`TID_W + `ADDR_W - 1 : 0]		rmfifo_data_o;

localparam CLOCK_PERIOD = 1000;
always #(CLOCK_PERIOD/2) clk = ~clk;

initial
begin
	rst_n = 1'b0;

	arready_i = 1'b1;
	
	arfifo_aempty_i = 1'b1;
	arfifo_data_i = 0;

	rmfifo_afull_i = 1'b0;

	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\n$$$$$$$$$$$$$$  Start  $$$$$$$$$$$$$$\n");
	
	//////////////////////////////////////////////
	////////////////  read miss  /////////////////
	/////////////////////////////////////////////
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
