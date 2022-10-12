`timescale	1ps/1ps

module	TOB_TB;

reg	clk	= 1'b0;
reg	rst_n;

reg	[15 : 0]		arid_i;
reg	[63 : 0]		araddr_i;
reg	[7 : 0]			arlen_i;
reg				arval_i;
wire				arready_o;

reg	[15 : 0]		awid_i;
reg	[63 : 0]		awaddr_i;
reg	[7 : 0]			awlen_i;
reg				awval_i;
wire				awready_o;

wire	[15 : 0]		arid_o;
wire	[63 : 0]		araddr_o;
wire	[7 : 0]			arlen_o;
wire				arval_o;
reg				arready_i;

wire				aempty_o;
reg				rden_i;
wire	[80 : 0]		data_o;

localparam			CLOCK_PERIOD 	= 1000;
always #(CLOCK_PERIOD/2) 	clk 		= ~clk;

int	i;

initial
begin
	rst_n		= 1'b1;

	arid_i 		= 0;
	araddr_i 	= 0;
	arlen_i		= 0;
	arval_i		= 0;
	
	awid_i 		= 0;
	awaddr_i 	= 0;
	awlen_i		= 0;
	awval_i 	= 0;

	arready_i 	= 0;

	rden_i		= 0;
	
	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart\n");
	
	arid_i		= 7;
	araddr_i	= 64'heeeeeeeeeeeeeeee;
	arlen_i		= 10;
	arval_i		= 1;

	arready_i	= 1;

	#(CLOCK_PERIOD);
	
	$display("arid = %x, araddr = %x, arlen = %x, arval = %x", arid_o, araddr_o, arlen_o, arval_o);
	$display("aempty = %x, data = %x\n", aempty_o, data_o);
	
	arid_i		= 5;
	araddr_i	= 64'h0;
	arlen_i		= 10;
	arval_i		= 1;

	arready_i	= 1;


	#(CLOCK_PERIOD);
	
	$display("arid = %x, araddr = %x, arlen = %x, arval = %x", arid_o, araddr_o, arlen_o, arval_o);
	$display("aempty = %x, data = %x\n", aempty_o, data_o);
	
	arid_i		= 3;
	araddr_i	= 64'hccccccccccc;
	arlen_i		= 10;
	arval_i		= 1;

	arready_i	= 1;


	#(CLOCK_PERIOD);
	
	$display("arid = %x, araddr = %x, arlen = %x, arval = %x", arid_o, araddr_o, arlen_o, arval_o);
	$display("aempty = %x, data = %x\n", aempty_o, data_o);
		
	arid_i		= 2;
	araddr_i	= 64'hddddddddddd;
	arlen_i		= 10;
	arval_i		= 1;

	arready_i	= 1;


	#(CLOCK_PERIOD);
		
	arid_i		= 1;
	araddr_i	= 64'heeeeeeeeeeee;
	arlen_i		= 10;
	arval_i		= 1;

	arready_i	= 1;


	$display("arid = %x, araddr = %x, arlen = %x, arval = %x", arid_o, araddr_o, arlen_o, arval_o);
	$display("aempty = %x, data = %x\n", aempty_o, data_o);



	$finish;
end

TOP_MODULE	top
(
	.clk		(clk),
	.rst_n		(rst_n),

	.arid_i		(arid_i),
	.araddr_i	(araddr_i),
	.arlen_i	(arlen_i),
	.arvalid_i	(arval_i),
	.arready_o	(arready_o),

	.awid_i		(awid_i),
	.awaddr_i	(awaddr_i),
	.awlen_i	(awlen_i),
	.awvalid_i	(awval_i),
	.awready_o	(awready_o),

	.arid_o		(arid_o),
	.araddr_o	(araddr_o),
	.arlen_o	(arlen_o),
	.arvalid_o	(arval_o),
	.arready_i	(arready_i),

	.aempty_o	(aempty_o),
	.rden_i		(rden_i),
	.data_o		(data_o)
);

endmodule