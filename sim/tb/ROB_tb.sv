`timescale	1ps/1ps

module	ROB_TB;

reg	clk	= 1'b0;
reg	rst_n;

wire			valid_o;
reg			ready_i;
wire	[15 : 0]	rid_o;
wire	[511 : 0]	rdata_o;

wire			full_hit_o;
reg			write_en_hit_i;
reg	[521 : 0]	wdata_hit_i;

wire			full_miss_o;
reg			write_en_miss_i;
reg	[521 : 0]	wdata_miss_i;

localparam			CLOCK_PERIOD 	= 1000;
always #(CLOCK_PERIOD/2) 	clk 		= ~clk;

initial
begin
	rst_n			= 1'b1;

	ready_i 		= 0;
	
	write_en_hit_i 		= 0;
	wdata_hit_i		= 0;
	
	write_en_miss_i 	= 0;
	wdata_miss_i		= 0;
	
	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart\n");
	
	ready_i				= 1;

	wdata_hit_i[521 : 512]		= 10'd2;
	wdata_hit_i[511 : 0]		= 512'hbb;
	write_en_hit_i			= 1;

	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
	
	wdata_hit_i[521 : 512]		= 10'd3;
	wdata_hit_i[511 : 0]		= 512'hcc;
	write_en_hit_i			= 1;

	#(CLOCK_PERIOD);
	#(CLOCK_PERIOD);
		
	wdata_hit_i[521 : 512]		= 10'd4;
	wdata_hit_i[511 : 0]		= 512'hdd;
	write_en_hit_i			= 1;


	wdata_miss_i[521 : 512]		= 10'd1;
	wdata_miss_i[511 : 0]		= 512'haa;
	write_en_miss_i			= 1;

	$display("a in");

	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);
	
	#(CLOCK_PERIOD);
	$display("valid = %d, rdata = %x",valid_o,rdata_o);

	$finish;
end

ROB	rob
(
	.clk			(clk),
	.rst_n			(rst_n),

	.valid_o		(valid_o),
	.ready_i		(ready_i),
	.rid_o			(rid_o),
	.rdata_o		(rdata_o),

	.full_hit_o		(full_hit_o),
	.write_en_hit_i		(write_en_hit_i),
	.wdata_hit_i		(wdata_hit_i),
	
	.full_miss_o		(full_miss_o),
	.write_en_miss_i	(write_en_miss_i),
	.wdata_miss_i		(wdata_miss_i)

);

endmodule
