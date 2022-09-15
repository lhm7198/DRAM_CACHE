`timescale 1ps/1ps

module TAG_COMPARE_TB;

reg clk = 1'b0;
reg rst_n;

// AMBA AXI interface (R channel)
reg	[71 : 0]	rdata_i;
reg			rvalid_i;
wire			rready_o;

// FIFO -> Tag Comparator
reg	[80 : 0]	fifo_data_i;

// Tag Comparator -> Reordering Buffer
wire	[80 : 0]	r_hit_data_o;
wire	[80 : 0]	r_miss_data_o;
wire	[80 : 0]	w_hit_data_o;
wire	[80 : 0]	w_miss_data_o;

localparam CLOCK_PERIOD = 1000;

always #(CLOCK_PERIOD/2) clk = ~clk;

initial
begin
    	// drive the default values
	rst_n		= 1'b1;

	rdata_i		= 0;
	rvalid_i	= 0;

	fifo_data_i	= 0;

	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;

	#(CLOCK_PERIOD);

	$display("r hit -> r miss -> w hit -> w miss\n");
	#(CLOCK_PERIOD);

	// read hit
	fifo_data	[80 : 80] 		= 0;
	fifo_data	[15 : 0] 		= 10;
	rtag		[7 : 0]			= 10;
	rdata		[63 : 0]		= 100;

	$display("r hit data : %d, r miss data : %d, w hit data : %d, r miss data : %d\n", r_hit_data, r_miss_data, w_hit_data, w_miss_data);
	#(CLOCK_PERIOD);

	// read miss
	fifo_data	[80 : 80] 		= 0;
	fifo_data	[15 : 0] 		= 10;
	rtag		[7 : 0]			= 11;
	rdata		[63 : 0]		= 200;

	$display("r hit data : %d, r miss data : %d, w hit data : %d, r miss data : %d\n", r_hit_data, r_miss_data, w_hit_data, w_miss_data);
	#(CLOCK_PERIOD);

	// write hit
	fifo_data	[80 : 80] 		= 1;
	fifo_data	[15 : 0] 		= 10;
	rtag		[7 : 0]			= 10;
	rdata		[63 : 0]		= 100;
	
	$display("r hit data : %d, r miss data : %d, w hit data : %d, r miss data : %d\n", r_hit_data, r_miss_data, w_hit_data, w_miss_data);
	#(CLOCK_PERIOD);

	// write miss
	fifo_data	[80 : 80] 		= 1;
	fifo_data	[15 : 0] 		= 10;
	rtag		[7 : 0]			= 11;
	rdata		[63 : 0]		= 100;
	
	$display("r hit data : %d, r miss data : %d, w hit data : %d, r miss data : %d\n", r_hit_data, r_miss_data, w_hit_data, w_miss_data);
	#(CLOCK_PERIOD);
	
	$finish;
end

TAG_COMPARE tag_compare(
	.clk(clk),
       	.rst_n(rst_n), 

       	.rdata_i(rdata_i),
       	.rvalid_i(rvalid_i), 
	.rready_o(rready_o),

	.fifo_data_i(fifo_data),

	.r_hit_data_o(r_hit_data),
	.r_miss_data_o(r_miss_data),
	.w_hit_data_o(w_hit_data),
	.w_miss_data_o(w_miss_data));

endmodule

