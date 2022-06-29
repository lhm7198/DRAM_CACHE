`timescale 1ps/1ps

module FIFO_TB;

reg clk = 1'b0;
reg reset = 1'b0;

wire full, A_full;
reg write_en;
reg [7:0] write_data;

wire empty, A_empty;
reg read_en;
reg [7:0] read_data;

localparam CLOCK_PERIOD = 1000;

always #(CLOCK_PERIOD/2) clk = ~clk;

initial
begin
	#(CLOCK_PERIOD-100);
	reset = 1'b1;
	#(CLOCK_PERIOD);
	reset = 1'b0;

	$display("Here!");
	write_en = 1'b1;
	write_data = 8'b1;
	$display("I am!");

	$finish;
end

FIFO fifo(.clk(clk), .reset(reset), .full(full), .A_full(A_full), .write_en(write_en), .write_data(write_data),
	.empty(empty), .A_empty(A_empty), .read_en(read_en), .read_data(read_data));

endmodule
