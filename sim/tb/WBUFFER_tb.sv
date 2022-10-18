`timescale	1ps/1ps

module	WBUFFER_TB;

reg	clk	= 1'b0;
reg	rst_n;

reg			valid_i;
reg	[511 : 0]	wdata_i;
wire			ready_o;

wire			Aempty_o;
reg			rden_i;
wire	[511 : 0]	rdata_o;

localparam			CLOCK_PERIOD 	= 1000;
always #(CLOCK_PERIOD/2) 	clk 		= ~clk;

initial
begin
	rst_n			= 1'b1;
	
	valid_i			= 0;
	wdata_i			= 0;

	rden_i			= 0;
	
	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart\n");

	wdata_i		= 512'haa;
	valid_i		= 1;
	
	#(CLOCK_PERIOD);

	valid_i		= 0;

	#(CLOCK_PERIOD);

	wdata_i		= 512'hbb;
	valid_i		= 1;
	
	#(CLOCK_PERIOD);

	valid_i		= 0;

	#(CLOCK_PERIOD);

	rden_i		= 1;
	$display("%x",rdata_o);

	#(CLOCK_PERIOD);
	$display("%x",rdata_o);
	
	#(CLOCK_PERIOD);
	$display("%x",rdata_o);
	
	#(CLOCK_PERIOD);
	$display("%x",rdata_o);
	#(CLOCK_PERIOD);
	$display("%x",rdata_o);
	#(CLOCK_PERIOD);
	$display("%x",rdata_o);
	$finish;
end

WBUFFER		wbuffer
(
	.clk		(clk),
	.rst_n		(rst_n),

	.valid_i	(valid_i),
	.wdata_i	(wdata_i),
	.ready_o	(ready_o),

	.Aempty_o	(Aempty_o),
	.rden_i		(rden_i),
	.rdata_o	(rdata_o)
);

endmodule
