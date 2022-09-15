`timescale 1ps/1ps

module TAG_COMPARE_TB;

reg clk = 1'b0;
reg rst_n;

// AMBA AXI interface (R channel)
reg	[71 : 0]	rdata_i;
reg	[55 : 0]	rtag_i;
reg			rvalid_i;
wire			rready_o;

// FIFO -> Tag Comparator
reg	[80 : 0]	fifo_data_i;

// Tag Comparator -> Reordering Buffer
wire	[71 : 0]	r_hit_data_o;
wire	[71 : 0]	r_miss_data_o;
wire	[71 : 0]	w_hit_data_o;
wire	[71 : 0]	w_miss_data_o;

localparam CLOCK_PERIOD = 1000;

always #(CLOCK_PERIOD/2) clk = ~clk;

initial
begin
    	// drive the default values
	rst_n		= 1'b1;

	rdata_i		= 0;
	rtag_i		= 0;
	rvalid_i	= 0;

	fifo_data_i	= 0;

	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;

	#(CLOCK_PERIOD);

	$display("START\n");

	// read hit
	fifo_data_i	[80 : 80] 		= 1'd0;
	fifo_data_i	[63 : 8] 		= 56'd10;
	rtag_i		[55 : 0]		= 56'd10;
	rdata_i		[71 : 0]		= 72'd100;

	#(CLOCK_PERIOD);
	$display("r hit data : %d, r miss data : %d, w hit data : %d, w miss data : %d\n", r_hit_data_o, r_miss_data_o, w_hit_data_o, w_miss_data_o);
	
	// read miss
	fifo_data_i	[80 : 80] 		= 1'd0;
	fifo_data_i	[63 : 8] 		= 56'd10;
	rtag_i		[55 : 0]		= 56'd11;
	rdata_i		[71 : 0]		= 72'd200;

	#(CLOCK_PERIOD);
	$display("r hit data : %d, r miss data : %d, w hit data : %d, w miss data : %d\n", r_hit_data_o, r_miss_data_o, w_hit_data_o, w_miss_data_o);

	// write hit
	fifo_data_i	[80 : 80] 		= 1'd1;
	fifo_data_i	[63 : 8] 		= 56'd10;
	rtag_i		[55 : 0]		= 56'd10;
	rdata_i		[71 : 0]		= 72'd300;

	#(CLOCK_PERIOD);
	$display("r hit data : %d, r miss data : %d, w hit data : %d, w miss data : %d\n", r_hit_data_o, r_miss_data_o, w_hit_data_o, w_miss_data_o);

	// write miss
	fifo_data_i	[80 : 80] 		= 1'd1;
	fifo_data_i	[63 : 8] 		= 56'd10;
	rtag_i		[55 : 0]		= 56'd11;
	rdata_i		[71 : 0]		= 72'd400;
	
	#(CLOCK_PERIOD);
	$display("r hit data : %d, r miss data : %d, w hit data : %d, w miss data : %d\n", r_hit_data_o, r_miss_data_o, w_hit_data_o, w_miss_data_o);
	
	#(CLOCK_PERIOD);
	$display("r hit data : %d, r miss data : %d, w hit data : %d, w miss data : %d\n", r_hit_data_o, r_miss_data_o, w_hit_data_o, w_miss_data_o);
	
	#(CLOCK_PERIOD);
	$display("r hit data : %d, r miss data : %d, w hit data : %d, w miss data : %d\n", r_hit_data_o, r_miss_data_o, w_hit_data_o, w_miss_data_o);
	#(CLOCK_PERIOD);
	$display("r hit data : %d, r miss data : %d, w hit data : %d, w miss data : %d\n", r_hit_data_o, r_miss_data_o, w_hit_data_o, w_miss_data_o);
	#(CLOCK_PERIOD);
	$display("r hit data : %d, r miss data : %d, w hit data : %d, w miss data : %d\n", r_hit_data_o, r_miss_data_o, w_hit_data_o, w_miss_data_o);
	$finish;
end

TAG_COMPARE tag_compare(
	.clk(clk),
       	.rst_n(rst_n), 

       	.rdata_i(rdata_i),
	.rtag_i(rtag_i),
       	.rvalid_i(rvalid_i), 
	.rready_o(rready_o),

	.fifo_data_i(fifo_data_i),

	.r_hit_data_o(r_hit_data_o),
	.r_miss_data_o(r_miss_data_o),
	.w_hit_data_o(w_hit_data_o),
	.w_miss_data_o(w_miss_data_o));

endmodule

