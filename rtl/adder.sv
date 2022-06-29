module ADDER(
	input clk,
	input rst_n,

	input [3:0] a,
	input [3:0] b,

	output [4:0] c
);

reg [4:0] reg_c;

always @(posedge clk or negedge rst_n)
begin
	if (~rst_n) begin
		reg_c <= 5'b0;
	end else begin
		reg_c <= {1'b0, a} + {1'b0, b};
	end
end

assign c = reg_c;

endmodule
