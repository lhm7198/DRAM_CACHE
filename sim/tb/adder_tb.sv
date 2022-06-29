`timescale 1ps/1ps

module ADDER_TB;


reg clk = 1'b0;
reg rst_n = 1'b1;
reg [3:0]input_a, input_b;
reg [4:0] out_c, check_c;

localparam CLOCK_PERIOD = 1000;

always #(CLOCK_PERIOD/2) clk = ~clk;

int i;

initial
begin
	#(CLOCK_PERIOD-100);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;

	for (i=0; i<100; i=i+1) begin
		input_a = $urandom % 16;
		input_b = $urandom % 16;
		check_c = {1'b0, input_a} + {1'b0, input_b};

		#(CLOCK_PERIOD);
		if (check_c == out_c) begin
			$display("Pass!");
		end else begin
			$display("Fail!");
		end
	end
end

ADDER adder(.clk(clk), .rst_n(rst_n), .a(input_a), .b(input_b), .c(out_c));


endmodule
