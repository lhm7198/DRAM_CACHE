`include "AXI_TYPEDEF.svh"

module TAG_COMPARE
#(
	parameter ADDR_WIDTH 		= `AXI_ADDR_WIDTH,
	parameter DATA_WIDTH		= `AXI_DATA_WIDTH,
	parameter ID_WIDTH 		= `AXI_ID_WIDTH,
	
	parameter TAG_SIZE		= `TAG_SIZE,
	parameter TAG_WIDTH		= `TAG_WIDTH,
	parameter BLANK_WIDTH		= `BLANK_WIDTH,

	parameter INDEX_WIDTH 		= `INDEX_WIDTH,
	parameter OFFSET_WIDTH 		= `OFFSET_WIDTH,
	parameter TID_WIDTH		= `TID_WIDTH,
	
	parameter TOTAL_CYCLE		= `TOTAL_CYCLE
)
(
	input	wire							clk,
	input 	wire							rst_n,

	// R channel (Memory Ctrl -> DRAM $ Ctrl)
	input	wire	[ID_WIDTH - 1 : 0]				rid_i,
	input	wire	[TAG_SIZE + DATA_WIDTH - 1 : 0]			rdata_i,
	input	wire							rvalid_i,
	output 	wire							rready_o,

	// Inner wire (FIFO <-> Tag comparator)
	input	wire							tag_fifo_aempty_i,
	output	wire							tag_fifo_rden_o,
	input	wire	[TID_WIDTH + ADDR_WIDTH : 0]			tag_fifo_data_i,
	
	// Inner wire (Tag comparator <-> ROB), Read Hit
	input 	wire							rob_afull_i,
	output	wire							rob_wren_o,
	output	wire	[TID_WIDTH + DATA_WIDTH - 1 : 0]		rob_data_o,

	// Inner wire (Tag comparator <-> Fill AR FIFO), Read Miss
	input	wire							ar_fifo_afull_i,
	output	wire							ar_fifo_wren_o,
	output	wire	[TID_WIDTH + ADDR_WIDTH - 1 : 0]		ar_fifo_data_o,


	// Inner wire (Tag comparator <-> Fix FIFO), Write Hit
	input	wire							fix_fifo_afull_i,
	output	wire							fix_fifo_wren_o,
	output	wire	[ADDR_WIDTH - 1 : 0]				fix_fifo_data_o,

	// Inner wire (Tag comparator <-> Evict AW FIFO), Write Miss
	input	wire							aw_fifo_afull_i,
	output	wire							aw_fifo_wren_o,
	output	wire	[ADDR_WIDTH - 1 : 0]				aw_fifo_data_o,

	// Inner wire (Tag comparator <-> Evict W FIFO), Write Miss
	input	wire							w_fifo_afull_i,
	output	wire							w_fifo_wren_o,
	output	wire	[DATA_WIDTH - 1 : 0]				w_fifo_data_o,
);

localparam			S_IDLE	= 3'd0,
				S_DEC	= 3'd1,
				S_RHIT	= 3'd2,
				S_RMISS	= 3'd3,
				S_WHIT	= 3'd4,
				S_WMISS = 3'd5;

reg	[2:0]						state,		state_n;

reg							tag_fifo_rden,	tag_fifo_rden_n;

reg							rob_wren,	rob_wren_n;
reg	[TID_WIDTH + DATA_WIDTH - 1 : 0]		rob_data,	rob_data_n;

reg							ar_fifo_wren,	ar_fifo_wren_n;
reg	[TID_WIDTH + ADDR_WIDTH - 1 : 0]		ar_fifo_data,	ar_fifo_data_n;

reg							fix_fifo_wren,	fix_fifo_wren_n;
reg	[ADDR_WIDTH - 1 : 0]				fix_fifo_data, 	fix_fifo_data_n;

reg							aw_fifo_wren,	aw_fifo_wren_n;
reg	[ADDR_WIDTH - 1 : 0]				aw_fifo_data,	aw_fifo_data_n;

reg							w_fifo_wren,	w_fifo_wren_n;
reg	[DATA_WIDTH - 1 : 0]				w_fifo_data,	w_fifo_data_n;

reg 							rready,		rready_n;

wire	read  = !tag_fifo_data_i[ADDR_WIDTH + ID_WIDTH : ADDR_WIDTH + ID_WIDTH]; // read = 0, write = 1
wire	valid = rdata_i[TAG_SIZE + DATA_WIDTH - 1 : TAG_SIZE + DATA_WIDTH - 1]; // tag = VALID + DIRTY + TAG DATA + BLANK

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;

		tag_fifo_rden	<= 1'b0;

		rob_wren	<= 1'b0;
		rob_data	<= 0;

		ar_fifo_wren	<= 1'b0;
		ar_fifo_data	<= 0;

		fix_fifo_wren	<= 1'b0;
		fix_fifo_data	<= 0;

		aw_fifo_wren	<= 1'b0;
		aw_fifo_data	<= 0;

		w_fifo_wren	<= 1'b0;
		w_fifo_data	<= 0;

		rready		<= 1'b1;
	end
	else begin
		state		<= state_n;

		tag_fifo_rden	<= tag_fifo_rden_n;
		
		rob_wren	<= rob_wren_n;
		rob_data	<= rob_data_n;

		ar_fifo_wren	<= ar_fifo_wren_n;
		ar_fifo_data	<= ar_fifo_data_n;

		fix_fifo_wren	<= fix_fifo_wren_n;
		fix_fifo_data	<= fix_fifo_data_n;

		aw_fifo_wren	<= aw_fifo_wren_n;
		aw_fifo_data	<= aw_fifo_data_n;

		w_fifo_wren	<= w_fifo_wren_n;
		w_fifo_data	<= w_fifo_data_n;

		rready		<= rready_n;
	end

always_comb begin
	state_n 	= state;
	
	tag_fifo_rden_n	= tag_fifo_rden;

	rob_wren_n	= rob_wren;
	rob_data_n	= rob_data;

	ar_fifo_wren_n	= ar_fifo_wren;
	ar_fifo_data_n	= ar_fifo_data;

	fix_fifo_wren_n	= fix_fifo_wren;
	fix_fifo_data_n	= fix_fifo_data;

	aw_fifo_wren_n	= aw_fifo_wren;
	aw_fifo_data_n	= aw_fifo_data;

	w_fifo_wren_n	= w_fifo_wren;
	w_fifo_data_n	= w_fifo_data;

	rready_n	= rready;
	
	case (state)
		S_IDLE: begin
			rob_wren_n	= 1'b0;
			rob_data_n	= 0;

			ar_fifo_wren_n	= 1'b0;
			ar_fifo_data_n	= 0;

			fix_fifo_wren_n	= 1'b0;
			fix_fifo_data_n	= 0;

			aw_fifo_wren_n	= 1'b0;
			aw_fifo_data_n	= 0;

			w_fifo_wren_n	= 1'b0;
			w_fifo_data_n	= 0;

			rready_n	= 1'b1;

			if(rvalid_i && !tag_fifo_aempty_i) begin
				tag_fifo_rden_n		= 1'b1;
				state_n			= S_DEC;
			end
		end
		S_DEC: begin
			tag_fifo_rden_n 	= 1'b0;
			rready_n		= 1'b0;

			if(read) begin
				// read hit(valid && same tag) 
				if(valid && tag_fifo_data_i[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] == read_data_i[TAG_WIDTH + BLANK_WIDTH + DATA_WIDTH - 1 : BLANK_WIDTH + DATA_WIDTH]) begin
					rob_data_n[TID_WIDTH + DATA_WIDTH - 1 : DATA_WIDTH] = tag_fifo_data_i[TID_WIDTH + ADDR_WIDTH - 1 : ADDR_WIDTH]; // tid
					state_n		= S_RHIT;
				end
				// read miss
				else begin
					ar_fifo_data_n[TID_WIDTH + ADDR_WIDTH - 1 : 0] = tag_fifo_data_i[TID_WIDTH + ADDR_WIDTH - 1 : 0]; // tid + addr
					state_n		= S_RMISS;
				end
			end
			else begin
				// write hit(valid && same tag)
				if(valid && tag_fifo_data_i[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] == read_data_i[TAG_WIDTH + BLANK_WIDTH + DATA_WIDTH - 1 : BLANK_WIDTH + DATA_WIDTH]) begin
					fix_fifo_data_n[ADDR_WIDTH - 1 : 0] = tag_fifo_data_i[ADDR_WIDTH - 1 : 0]; // addr
					state_n		= S_WHIT;
				end
				// write miss
				else begin
					ar_fifo_data_n[TID_WIDTH + ADDR_WIDTH - 1 : 0] = tag_fifo_data_i[TID_WIDTH + ADDR_WIDTH - 1 : 0]; // tid + addr
					aw_fifo_data_n[ADDR_WIDTH - 1 : 0] = tag_fifo_data_i[ADDR_WIDTH - 1 : 0]; // addr
					state_n		= S_WMISS;
				end
			end
		end
		S_RHIT: begin
			rob_data_n[DATA_WIDTH - 1 : 0] = rdata_i[DATA_WIDTH - 1 : 0];
			
			if(!rob_afull_i) begin
				rob_wren_n	= 1'b1;
				state_n		= S_IDLE;
			end
		end
		S_RMISS: begin
			if(!ar_fifo_afull_i) begin
				ar_fifo_wren_n	= 1'b1;
				state_n		= S_IDLE;
			end
		end
		S_WHIT: begin
			if(!fix_fifo_afull_i) begin
				fix_fifo_wren_n	= 1'b1;
				state_n		= S_IDLE;
			end
		end
		S_WMISS: begin
			w_fifo_data_n = rdata_i[DATA_WIDTH - 1 : 0];

			if(!(ar_fifo_afull_i || aw_fifo_afull_i || w_fifo_afull_i)) begin
				ar_fifo_wren_n	= 1'b1;
				aw_fifo_wren_n	= 1'b1;
				w_fifo_wren_n	= 1'b1;
				state_n		= S_IDLE;
			end			
		end
	endcase
end

// memory ctrl
assign rready_o		= rready;

// tag fifo
assign tag_fifo_rden_o	= tag_fifo_rden;

// read hit
assign rob_wren_o	= rob_wren;
assign rob_data_o	= r_hit_data;

// read miss && write miss
assign ar_fifo_wren_o	= ar_fifo_wren;
assign ar_fifo_data_o	= ar_fifo_data;

// write hit
assign fix_fifo_wren_o	= fix_fifo_wren;
assign fix_fifo_data_o	= fix_fifo_data;

// write miss
assign aw_fifo_wren_o	= aw_fifo_wren;
assign aw_fifo_data_o	= aw_fifo_data;
assign w_fifo_wren_o	= w_fifo_wren;
assign w_fifo_data_o	= w_fifo_data;

endmodule
