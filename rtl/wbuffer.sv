`include "TYPEDEF.svh"

module WBUFFER # (
	parameter DATA_WIDTH 	= `AXI_DATA_WIDTH,
	parameter FIFO_SIZE 	= `FIFO_SIZE
)(
	input	wire				clk,
	input	wire				rst_n,

	input	wire				valid_i,
	input	wire	[DATA_WIDTH-1 : 0]	wdata_i,
	output	wire				ready_o,

	output	wire				Aempty_o,
	input	wire				rden_i,
	output	wire	[DATA_WIDTH-1 : 0]	rdata_o
);

localparam			S_IDLE		= 1'd0,
				S_VAL		= 1'd1;

reg				afull;
reg				write_en;

wire				aempty;
wire	[DATA_WIDTH-1 : 0]	read_data;

reg				state, state_n;
reg				ready;

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
	end
	else begin
		state		<= state_n;
	end
end

always_comb begin
	
	state_n		= state;
	ready		= 0;
	write_en	= 0;
	case(state)
		S_IDLE: begin
			if(valid_i & !afull) begin
				ready		= 1;
				write_en	= 1;
				state_n		= S_VAL;
			end
		end
		S_VAL: begin
			$display("Valid");
			ready			= 0;
			write_en		= 0;
			state_n			= S_IDLE;
		end

	endcase
end

FIFO
#(
	.DATA_WIDTH	(DATA_WIDTH)
) wbuffer
(
	.clk		(clk),
	.rst_n		(rst_n),

	.A_full_o	(afull),
	.write_en_i	(write_en),
	.write_data_i	(wdata_i),

	.A_empty_o	(aempty),
	.read_en_i	(rden_i),
	.read_data_o	(read_data)
);

assign	ready_o		= ready;
assign	Aempty_o	= aempty;
assign	rdata_o		= read_data;

endmodule
