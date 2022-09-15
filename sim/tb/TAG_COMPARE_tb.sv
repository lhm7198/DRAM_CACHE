`timescale 1ps/1ps

module TAG_COMPARE_TB;

reg clk = 1'b0;
reg rst_n;

wire 			rready;
wire	[80:0]		r_hit_data;
wire	[80:0]		r_miss_data;
wire	[80:0]		w_hit_data;
wire	[80:0]		w_miss_data;
reg	[80:0]		fifo_data;
reg	[7:0]		rtag;	//?
reg	[63:0]		rdata;	//?
reg			rvalid;

localparam CLOCK_PERIOD = 1000;

always #(CLOCK_PERIOD/2) clk = ~clk;

initial
begin
    // drive the default values
	fifo_data 	= 81'b0;
	rtag 		= 8'b0;
	rdata 		= 64'b0;
	rvalid 		= 1'b0;
	rst_n 		= 1'b1;

	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;

	#(CLOCK_PERIOD);

	$display("r hit -> r miss -> w hit -> w miss\n");
	#(CLOCK_PERIOD);

	fifo_data	[80 : 80] 		= 0;
	fifo_data	[15 : 0] 		= 10;
	rtag		[7 : 0]			= 10;
	rdata		[63 : 0]		= 100;

	$display("r hit data : %d, r miss data : %d, w hit data : %d, r miss data : %d", r_hit_data, r_miss_data, w_hit_data, w_miss_data);
	#(CLOCK_PERIOD);

	fifo_data	[80 : 80] 		= 0;
	fifo_data	[15 : 0] 		= 10;
	rtag		[7 : 0]			= 11;
	rdata		[63 : 0]		= 200;

	$display("r hit data : %d, r miss data : %d, w hit data : %d, r miss data : %d", r_hit_data, r_miss_data, w_hit_data, w_miss_data);
	#(CLOCK_PERIOD);


	fifo_data	[80 : 80] 		= 1;
	fifo_data	[15 : 0] 		= 10;
	rtag		[7 : 0]			= 10;
	rdata		[63 : 0]		= 100;
	
	$display("r hit data : %d, r miss data : %d, w hit data : %d, r miss data : %d", r_hit_data, r_miss_data, w_hit_data, w_miss_data);
	#(CLOCK_PERIOD);

	fifo_data	[80 : 80] 		= 1;
	fifo_data	[15 : 0] 		= 10;
	rtag		[7 : 0]			= 11;
	rdata		[63 : 0]		= 100;
	
	$display("r hit data : %d, r miss data : %d, w hit data : %d, r miss data : %d", r_hit_data, r_miss_data, w_hit_data, w_miss_data);
	#(CLOCK_PERIOD);
	
	$finish;
end

TAG_COMPARE tag_compare(
	.clk(clk),
       	.rst_n(rst_n), 

	.rtag_i(rtag),
       	.rdata_i(rdatal),
       	.rvalid_i(rvalid), 
	.rready_o(rready),

	.fifo_data_i(fifo_data),

	.r_hit_data_o(r_hit_data),
	.r_miss_data_o(r_miss_data),
	.w_hit_data_o(w_hit_data),
	.w_miss_data_o(w_miss_data));

endmodule

