`define ADDR_W	 64
`define DATA_W	 64*8
`define ID_W	 16

`timescale 1ps/1ps

module TAG_COMPARE_TB;

reg clk = 1'b0;
reg rst_n;

// Tag comparator
wire 					fill_ready_o;
reg					fill_valid_i;
reg [`ADDR_W + `DATA_W - 1 : 0]		fill_data_i;

// RMiss Handler
wire 					rmiss_ready_o;
reg					rmiss_valid_i;
reg [`ADDR_W + `DATA_W - 1 : 0]		rmiss_data_i;

// FILL FIFO
reg 					fill_fifo_afull_i;
wire					fill_fifo_wren_o;
wire [`ADDR_W + `DATA_W - 1 : 0]	fill_fifo_data_o;

localparam CLOCK_PERIOD = 1000;
always #(CLOCK_PERIOD/2) clk = ~clk;

initial
begin
	rst_n = 1'b0;

	fill_valid_i = 1'b0;
	fill_data_i = 0;

	rmiss_valid_i = 1'b0;
	rmiss_data_i = 0;

	fill_fifo_afull_i = 1'b0;
	
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\n$$$$$$$$$$$$$$  Start  $$$$$$$$$$$$$$\n");
	
	/////////////////////////////////////////////
	/////////////  w hit & miss  ////////////////
	/////////////////////////////////////////////
	$display("-------- W HIT & MISS START ---------\n");
	
	// fill_data_i
	fill_data_i[`ADDR_W + `DATA_W - 1 : `DATA_W] = 15; // addr
	fill_data_i[`DATA_W - 1 : 0] = 17; // data

	// S_IDLE -> S_WREQ
	fill_valid_i = 1'b1;
	rmiss_valid_i = 1'b0;
	#(CLOCK_PERIOD);

	// S_WREQ -> S_IDLE
	#(CLOCK_PERIOD);

	$display("fifo_addr : %x\nfifo_data : %x\n", 
		fill_fifo_data_o[`ADDR_W + `DATA_W - 1 : `DATA_W], 
		fill_fifo_data_o[`DATA_W - 1 : 0]);

	$display("---------------------------------\n");

	/////////////////////////////////////////////
	///////////////  read miss  /////////////////
	/////////////////////////////////////////////
	$display("-------- READ MISS START --------\n");
	
	// rmiss_data_i
	rmiss_data_i[`ADDR_W + `DATA_W - 1 : `DATA_W] = 17; // addr
	rmiss_data_i[`DATA_W - 1 : 0] = 5; // data

	// S_IDLE -> S_RREQ
	fill_valid_i = 1'b0;
	rmiss_valid_i = 1'b1;
	#(CLOCK_PERIOD);

	// S_WREQ -> S_IDLE
	#(CLOCK_PERIOD);

	$display("fifo_addr : %x\nfifo_data : %x\n", 
		fill_fifo_data_o[`ADDR_W + `DATA_W - 1 : `DATA_W], 
		fill_fifo_data_o[`DATA_W - 1 : 0]);

	$display("---------------------------------\n");

	/////////////////////////////////////////////
	///////////////  concurrent  ////////////////
	/////////////////////////////////////////////
	$display("------ READ & WRITE START -------\n");
	
	// fill_data_i
	fill_data_i[`ADDR_W + `DATA_W - 1 : `DATA_W] = 3; // addr
	fill_data_i[`DATA_W - 1 : 0] = 14; // data
	
	// rmiss_data_i
	rmiss_data_i[`ADDR_W + `DATA_W - 1 : `DATA_W] = 17; // addr
	rmiss_data_i[`DATA_W - 1 : 0] = 5; // data

	// S_IDLE -> S_RREQ
	fill_valid_i = 1'b1;
	rmiss_valid_i = 1'b1;
	#(CLOCK_PERIOD);

	// S_WREQ -> S_IDLE
	#(CLOCK_PERIOD);

	$display("fifo_addr : %x\nfifo_data : %x\n", 
		fill_fifo_data_o[`ADDR_W + `DATA_W - 1 : `DATA_W], 
		fill_fifo_data_o[`DATA_W - 1 : 0]);

	$display("---------------------------------\n");

	// fill_data_i
	fill_data_i[`ADDR_W + `DATA_W - 1 : `DATA_W] = 4; // addr
	fill_data_i[`DATA_W - 1 : 0] = 15; // data
	
	// rmiss_data_i
	rmiss_data_i[`ADDR_W + `DATA_W - 1 : `DATA_W] = 17; // addr
	rmiss_data_i[`DATA_W - 1 : 0] = 5; // data

	// S_IDLE -> S_RREQ
	fill_valid_i = 1'b1;
	rmiss_valid_i = 1'b1;
	#(CLOCK_PERIOD);

	// S_WREQ -> S_IDLE
	#(CLOCK_PERIOD);

	$display("fifo_addr : %x\nfifo_data : %x\n", 
		fill_fifo_data_o[`ADDR_W + `DATA_W - 1 : `DATA_W], 
		fill_fifo_data_o[`DATA_W - 1 : 0]);

	$display("---------------------------------\n");


	$display("\n$$$$$$$$$$$$$$$  End  $$$$$$$$$$$$$$$\n");

	$finish;
end

ARBITER arbiter
(
	.clk(clk), 
	.rst_n(rst_n),

	.fill_ready_o(fill_ready_o),
	.fill_valid_i(fill_valid_i),
	.fill_data_i(fill_data_i),

	.rmiss_ready_o(rmiss_ready_o),
	.rmiss_valid_i(rmiss_valid_i),
	.rmiss_data_i(rmiss_data_i),

	.fill_fifo_afull_i(fill_fifo_afull_i),
	.fill_fifo_wren_o(fill_fifo_wren_o),
	.fill_fifo_data_o(fill_fifo_data_o)
);

endmodule
