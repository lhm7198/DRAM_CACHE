`timescale	1ps/1ps

module	RMH_TB;

reg	clk	= 1'b0;
reg	rst_n;

reg			valid_i;
wire			ready_o;
reg	[511 : 0]	data_i;

wire			read_en_o;
reg			empty_i;
reg	[73 : 0]	ar_i;

wire			write_en_o;
reg			full_i;
wire	[521 : 0]	wdata_ROB_o;

wire			valid_o;
reg			ready_i;
wire	[575 : 0]	wdata_Arbiter_o;



localparam			CLOCK_PERIOD 	= 1000;
always #(CLOCK_PERIOD/2) 	clk 		= ~clk;

initial
begin
	rst_n			= 1'b1;

	valid_i		= 0;
	data_i		= 0;
	empty_i		= 0;	
	ar_i		= 0;
	full_i		= 0;
	ready_i		= 0;

	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart\n");

	ar_i		= 64'hab;
	valid_i		= 1;
	data_i		= 512'hcc;

	$display("\nr_en = %d, ready = %d", read_en_o, ready_o);
	$display("wdata_ROB 	= %x, w_en = %d", wdata_ROB_o, write_en_o);
	$display("wdata_Arbiter 	= %x, valid = %d", wdata_Arbiter_o, valid_o);

	#(CLOCK_PERIOD);
	
	ar_i		= 64'h11;
	valid_i		= 1;
	data_i		= 512'h33;


	ready_i		= 1;

	$display("\nr_en = %d, ready = %d", read_en_o, ready_o);
	$display("wdata_ROB 	= %x, w_en = %d", wdata_ROB_o, write_en_o);
	$display("wdata_Arbiter 	= %x, valid = %d", wdata_Arbiter_o, valid_o);

	#(CLOCK_PERIOD);

	$display("\nr_en = %d, ready = %d", read_en_o, ready_o);
	$display("wdata_ROB 	= %x, w_en = %d", wdata_ROB_o, write_en_o);
	$display("wdata_Arbiter 	= %x, valid = %d", wdata_Arbiter_o, valid_o);

	#(CLOCK_PERIOD);

	$display("\nr_en = %d, ready = %d", read_en_o, ready_o);
	$display("wdata_ROB 	= %x, w_en = %d", wdata_ROB_o, write_en_o);
	$display("wdata_Arbiter 	= %x, valid = %d", wdata_Arbiter_o, valid_o);

	#(CLOCK_PERIOD);
	$display("\nr_en = %d, ready = %d", read_en_o, ready_o);
	$display("wdata_ROB 	= %x, w_en = %d", wdata_ROB_o, write_en_o);
	$display("wdata_Arbiter 	= %x, valid = %d", wdata_Arbiter_o, valid_o);

	#(CLOCK_PERIOD);
	$display("\nr_en = %d, ready = %d", read_en_o, ready_o);
	$display("wdata_ROB 	= %x, w_en = %d", wdata_ROB_o, write_en_o);
	$display("wdata_Arbiter 	= %x, valid = %d", wdata_Arbiter_o, valid_o);

	#(CLOCK_PERIOD);

	$finish;
end

READ_MISS_HANDLER	rmh
(
	.clk			(clk),
	.rst_n			(rst_n),

	.valid_i		(valid_i),
	.ready_o		(ready_o),
	.data_i			(data_i),

	.read_en_o		(read_en_o),
	.empty_i		(empty_i),
	.ar_i			(ar_i),
	
	.write_en_o		(write_en_o),
	.full_i			(full_i),
	.wdata_ROB_o		(wdata_ROB_o),

	.valid_o		(valid_o),
	.ready_i		(ready_i),
	.wdata_Arbiter_o	(wdata_Arbiter_o)
);

endmodule
