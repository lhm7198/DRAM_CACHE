`timescale 1ps/1ps

module FIFO_TB;

reg clk = 1'b0;
reg rst_n;

wire full, A_full;
reg write_en;
reg [7:0] write_data;

wire empty, A_empty;
reg read_en;
reg [7:0] read_data;

wire [3:0] remain;

localparam CLOCK_PERIOD = 1000;

always #(CLOCK_PERIOD/2) clk = ~clk;

int i;
initial
begin
    // drive the default values
	write_en = 1'b0;
	read_en = 1'b0;
	rst_n = 1'b1;

	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;

	#(CLOCK_PERIOD);

	$display("\nWrite");
	#(CLOCK_PERIOD);
	write_en = 1'b1;
	for(i=0; i<16; i++) begin
		write_data = $urandom % 256;

		$display("%dst write_data : %d, full : %d, empty : %d, remain : %d, A_EMPTY : %d, A_FULL : %d",
		       	i, write_data, full, empty, remain, A_empty, A_full);
	
		#(CLOCK_PERIOD);
	end
	write_en = 1'b0;
	
	#(CLOCK_PERIOD);
	$display("Read");
	#(CLOCK_PERIOD);
	read_en = 1'b1;
	for(i=0; i<16; i++) begin
		$display("%dst read_data : %d, full : %d, empty : %d, remain : %d, A_EMPTY : %d, A_FULL : %d",
		       	i, read_data, full, empty, remain, A_empty, A_full);

		#(CLOCK_PERIOD);	
	end
	read_en = 1'b0;
	$finish;
end

FIFO fifo(
	.clk(clk),
       	.rst_n(rst_n), 

	.full_o(full),
       	.A_full_o(A_full),
       	.write_en_i(write_en), 
	.write_data_i(write_data),

	.empty_o(empty), 
	.A_empty_o(A_empty),
       	.read_en_i(read_en),
       	.read_data_o(read_data),
       	.remain_o(remain));

endmodule

