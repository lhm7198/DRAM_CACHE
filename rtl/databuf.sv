`include "TYPEDEF.svh"

module DATA_BUF # (
	parameter DATA_WIDTH	= `FIFO_DATA_WIDTH,
	parameter FIFO_SIZE	= `FIFO_SIZE,
)(
	input	wire			clk,
	input	wire			rst_n,

	input	wire			wvalid_i,
	output	wire			wready_o,
	input	wire	[:]		wdata_i,

	input	wire			read_en_i,
	output	wire	[:]		rdata_o,
	output	wire			empty_o
);
localparam			S_IDLE		= 2'd0,
				S_RED		= 2'd1,
				S_WR		= 2'd2;
	

wire	[:]			rdata;
wire				empty;
wire				full;
wire				write_en;
wire	[:]			wdata;

reg	[1:0]			state, state_n;
reg				ready, ready_n;

reg	[DATA_WIDTH-1 : 0] 	merge, merge_n;
reg	[2 : 0]			cnt, cnt_n;


always_ff @(posedge clk) begin
	if(!rst_n) begin
		state		<= S_IDLE;
		ready		<= 1;
		cnt		<= 0;
		merge		<= 0;
	end
	else begin
		state		<= state_n;
		ready		<= ready_n;
		cnt		<= cnt_n;
		merge		<= merge_n;
	end
end

always_comb begin
	state_n		= state;
	ready_n		= ready;
	cnt_n		= cnt;
	merge_n		= merge;

	case (state)
		S_IDLE: begin
			if(!full && wvalid_i) begin
				ready_n		= 0;
				state_n		= S_RED;
			end
		end
		S_RED: begin
			if(cnt == 7) begin
				merge[8*cnt + 7 : 8*cnt]
				cnt_n		= 0;
				state_n		= S_WR;//
			end
			else begin
				cnt_n				= cnt_n + 1;
				merge_n[8*cnt + 7 : 8*cnt]	= ;//
			end
		end
		S_WR: begin
			//wdata
			//write_en
			state_n		= S_IDLE;
		end
	endcase

end

FIFO	buffer
(
	.clk		(clk),
	.rst_n		(rst_n),

	.full_o		(full),
	.write_en_i	(write_en),
	.write_data_i	(wdata),

	.empty_o	(empty),
	.read_en_i	(read_en_i),
	.read_data_o	(rdata)
);

assign	wready_o	= full;
assign	empty_o		= empty;
assign	rdata_o		= rdata;
