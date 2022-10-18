`timescale	1ps/1ps

module	FILL_FIFO_TB;

reg	clk	= 1'b0;
reg	rst_n;

wire			afull_o;
reg			wren_i;
reg	[575:0]		data_i;

wire	[15:0]		wid_o;
wire			wvalid_o;
wire	[511:0]		wdata_o;
reg			wready_i;

wire	[15:0]		awid_o;
wire			awvalid_o;
wire	[63:0]		awaddr_o;
reg			awready_i;

localparam			CLOCK_PERIOD 	= 1000;
always #(CLOCK_PERIOD/2) 	clk 		= ~clk;

initial
begin

	rst_n			= 1'b1;

	wren_i			= 0;
	data_i			= 0;
	wready_i		= 0;
	awready_i		= 0;

	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart\n");
	$finish;
end

FILL_FIFO	fill_fifo
(
	.clk		(clk),
	.rst_n		(rst_n),

	.afull_o	(afull_o),
	.wren_i		(wren_i),
	.data_i		(data_i),

	.wid_o		(wid_o),
	.wvalid_o	(wvalid_o),
	.wdata_o	(wdata_o),
	.wready_i	(wready_i),

	.awid_o		(awid_o),
	.awvalid_o	(awvalid_o),
	.awaddr_o	(awaddr_o),
	.awready_i	(awready_i)

);
endmodule
