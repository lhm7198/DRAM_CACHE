`include "TYPEDEF.svh"

module ARBITER 
#(
	parameter ADDR_WIDTH		= `AXI_ADDR_WIDTH,
	parameter DATA_WIDTH 		= `AXI_DATA_WIDTH,
	parameter ID_WIDTH		= `AXI_ID_WIDTH,
	parameter ID			= `AXI_ID
)
(
	input	wire						clk,
	input 	wire						rst_n,

	// Inner wire (Tag Comparator <-> Arbiter)
	output	wire						fill_ready_o,
	input	wire						fill_valid_i,
	input	wire	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]	fill_data_i,

	// Inner wire (RMiss Handler <-> Arbiter)
	output	wire						rmiss_ready_o,
	input	wire						rmiss_valid_i,
	input	wire	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]	rmiss_data_i,

	// Inner wire (Arbiter <-> Fill FIFO)
	input	wire						fill_fifo_afull_i,
	output	wire						fill_fifo_wren_o,
	output	wire	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]	fill_fifo_data_o
);

localparam 		S_IDLE		= 2'd0,
			S_REQ		= 2'd1;

reg						state,		state_n;

reg						fill_ready;
reg						rmiss_ready;

reg						fill_fifo_wren;
reg	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]	fill_fifo_data, fill_fifo_data_n;

reg						arbiter,	arbiter_n;

always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
	
		fill_fifo_data	<= 0;

		arbiter		<= 1'b0;
	end
	else begin
		state		<= state_n;

		fill_fifo_data  <= fill_fifo_data_n;
		
		arbiter		<= arbiter_n;
	end
end

always_comb begin
	state_n			= state;

	fill_ready		= 1'b0;
	rmiss_ready		= 1'b1;

	fill_fifo_wren		= 1'b0;
	fill_fifo_data_n	= fill_fifo_data;

	arbiter_n		= arbiter;

	case (state)
		S_IDLE: begin
			fill_fifo_data_n	= 0;

			if(fill_fifo_afull_i) begin
				$display("no");	
				state_n			= state;
			end
			else if(fill_valid_i & (!rmiss_valid_i | !arbiter)) begin
				$display("no");	
				fill_ready		= 1'b1;
				arbiter_n		= 1'b1;

				fill_fifo_data_n	= fill_data_i;

				state_n			= S_REQ;
			end
			else if(rmiss_valid_i & (!fill_valid_i | arbiter)) begin
				rmiss_ready		= 1'b1;
				arbiter_n		= 1'b0;

				fill_fifo_data_n	= rmiss_data_i;

				state_n			= S_REQ;
			end
		end
		S_REQ: begin
			fill_ready = 1'b0;
			//rmiss_ready = 1'b0;
			
			if(!fill_fifo_afull_i) begin
				fill_fifo_wren	= 1'b1;
			
				state_n		= S_IDLE;
			end
		end
	endcase
end

assign fill_ready_o 	= fill_ready;
assign rmiss_ready_o	= rmiss_ready;

assign fill_fifo_wren_o	= fill_fifo_wren;
assign fill_fifo_data_o	= fill_fifo_data;

endmodule
