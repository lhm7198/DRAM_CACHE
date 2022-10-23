`include "TYPEDEF.svh"

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
	
	parameter TID_WIDTH		= `TID_WIDTH
)
(
	input	wire							clk,
	input 	wire							rst_n,

	// R channel (Memory Ctrl -> DRAM $ Ctrl)
	input	wire	[ID_WIDTH - 1 : 0]				rid_i,
	input	wire	[TAG_SIZE + DATA_WIDTH - 1 : 0]			rdata_i,
	input	wire							rvalid_i,
	output 	wire							rready_o,

	// Inner wire (Tag FIFO <-> Tag comparator)
	input	wire							tag_fifo_aempty_i,
	output	wire							tag_fifo_rden_o,
	input	wire	[TID_WIDTH + ADDR_WIDTH : 0]			tag_fifo_data_i,

	// Inner wire (Tag comparator <-> wbuffer)
	input	wire							wbuffer_aempty_i,
	output	wire							wbuffer_rden_o,
	input	wire	[DATA_WIDTH - 1 : 0]				wbuffer_data_i,

	// Inner wire (Tag comparator <-> ROB), Read Hit
	input 	wire							rob_afull_i,
	output	wire							rob_wren_o,
	output	wire	[TID_WIDTH + DATA_WIDTH - 1 : 0]		rob_data_o,

	// Inner wire (Tag comparator <-> AR FIFO), Read Miss
	input	wire							ar_fifo_afull_i,
	output	wire							ar_fifo_wren_o,
	output	wire	[TID_WIDTH + ADDR_WIDTH - 1 : 0]		ar_fifo_data_o,

	// Inner wire (Tag comparator <-> AW FIFO), Read Miss & Write Miss
	input	wire							aw_fifo_afull_i,
	output	wire							aw_fifo_wren_o,
	output	wire	[ADDR_WIDTH - 1 : 0]				aw_fifo_data_o,

	// Inner wire (Tag comparator <-> W FIFO), Read Miss & Write Miss
	input	wire							w_fifo_afull_i,
	output	wire							w_fifo_wren_o,
	output	wire	[DATA_WIDTH - 1 : 0]				w_fifo_data_o,

	// Inner wire (Tag comparator <-> Fill Arbiter), Write Hit & Write Miss
	input	wire							fill_ready_i,
	output	wire							fill_valid_o,
	output	wire	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]		fill_data_o

);

localparam			S_IDLE	= 3'd0,
				S_RHIT	= 3'd1,
				S_RMISS	= 3'd2,
				S_WHIT	= 3'd3,
				S_WMISS = 3'd4;

reg	[2:0]						state,		state_n;

reg							tag_fifo_rden;
reg							wbuffer_rden;

reg							rob_wren;
reg	[TID_WIDTH + DATA_WIDTH - 1 : 0]		rob_data,	rob_data_n;

reg							ar_fifo_wren;
reg	[TID_WIDTH + ADDR_WIDTH - 1 : 0]		ar_fifo_data,	ar_fifo_data_n;

reg							aw_fifo_wren;
reg	[ADDR_WIDTH - 1 : 0]				aw_fifo_data,	aw_fifo_data_n;

reg							w_fifo_wren;
reg	[DATA_WIDTH - 1 : 0]				w_fifo_data,	w_fifo_data_n;

reg							fill_valid;
reg	[ADDR_WIDTH + DATA_WIDTH - 1 : 0]		fill_data, 	fill_data_n;

reg 							rready;
reg							dirty, 		dirty_n;

wire	read  = !tag_fifo_data_i[TID_WIDTH + ADDR_WIDTH : TID_WIDTH + ADDR_WIDTH]; // read = 0, write = 1
wire	valid = rdata_i[TAG_SIZE + DATA_WIDTH - 1 : TAG_SIZE + DATA_WIDTH - 1]; // tag = VALID + DIRTY + TAG DATA + BLANK

always_ff @(posedge clk)
	if (!rst_n) begin
		state		<= S_IDLE;

		rob_data	<= 0;
		ar_fifo_data	<= 0;
		aw_fifo_data	<= 0;
		w_fifo_data	<= 0;

		fill_data	<= 0;
		dirty		<= 0;
	end
	else begin
		state		<= state_n;

		rob_data	<= rob_data_n;
		ar_fifo_data	<= ar_fifo_data_n;
		aw_fifo_data	<= aw_fifo_data_n;
		w_fifo_data	<= w_fifo_data_n;
		
		fill_data	<= fill_data_n;
		dirty		<= dirty_n;
	end

always_comb begin
	state_n 		= state;

	tag_fifo_rden		= 1'b0;
	wbuffer_rden		= 1'b0;

	rob_wren		= 1'b0;
	rob_data_n		= rob_data;

	ar_fifo_wren		= 1'b0;
	ar_fifo_data_n		= ar_fifo_data;

	aw_fifo_wren		= 1'b0;
	aw_fifo_data_n		= aw_fifo_data;

	w_fifo_wren		= 1'b0;
	w_fifo_data_n		= w_fifo_data;

	fill_valid		= 1'b0;
	fill_data_n		= fill_data;

	dirty_n			= dirty;

	rready			= 1'b0;
	
	case (state)
		S_IDLE: begin
			rob_data_n		= 0;
			ar_fifo_data_n		= 0;
			aw_fifo_data_n		= 0;
			w_fifo_data_n		= 0;

			fill_data_n		= 0;

			if(rvalid_i & !tag_fifo_aempty_i) begin
				tag_fifo_rden		= 1'b1;
				rready			= 1'b1;
				dirty_n			= rdata_i[TAG_SIZE + DATA_WIDTH - 2 : TAG_SIZE + DATA_WIDTH - 2];
				if(read) begin
					// read hit(valid && same tag) 
					if(valid & (tag_fifo_data_i[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] == rdata_i[TAG_WIDTH + BLANK_WIDTH + DATA_WIDTH - 1 : BLANK_WIDTH + DATA_WIDTH])) begin
						rob_data_n[TID_WIDTH + DATA_WIDTH - 1 : DATA_WIDTH] = tag_fifo_data_i[TID_WIDTH + ADDR_WIDTH - 1 : ADDR_WIDTH]; // tid
						rob_data_n[DATA_WIDTH - 1 : 0] = rdata_i[DATA_WIDTH - 1 : 0];
						state_n		= S_RHIT;
						//$display("S_RHIT");
					end
					// read miss
					else begin
						ar_fifo_data_n[TID_WIDTH + ADDR_WIDTH - 1 : 0] = tag_fifo_data_i[TID_WIDTH + ADDR_WIDTH - 1 : 0]; // tid + addr
					
						aw_fifo_data_n[ADDR_WIDTH - 1 : 0] = tag_fifo_data_i[ADDR_WIDTH - 1 : 0]; // addr
						aw_fifo_data_n[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] = rdata_i[TAG_WIDTH + BLANK_WIDTH + DATA_WIDTH - 1 : BLANK_WIDTH + DATA_WIDTH]; // tag in addr
					
						w_fifo_data_n = rdata_i[DATA_WIDTH - 1 : 0];
	
						state_n		= S_RMISS;
						//$display("S_RMISS");
					end
				end
				else begin
					wbuffer_rden	= 1'b1;
					// write hit(valid && same tag)
					if(valid & (tag_fifo_data_i[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] == rdata_i[TAG_WIDTH + BLANK_WIDTH + DATA_WIDTH - 1 : BLANK_WIDTH + DATA_WIDTH])) begin
						fill_data_n[ADDR_WIDTH + DATA_WIDTH - 1 : DATA_WIDTH] = tag_fifo_data_i[ADDR_WIDTH - 1 : 0]; // addr
						fill_data_n[DATA_WIDTH - 1 : 0] = wbuffer_data_i[DATA_WIDTH - 1 : 0]; // data
						fill_data_n[ADDR_WIDTH + DATA_WIDTH - 1 : ADDR_WIDTH + DATA_WIDTH - 1] = 1'b1; // write flag
						//$display("S_WHIT");
						state_n		= S_WHIT;
					end
					// write miss
					else begin
						aw_fifo_data_n[ADDR_WIDTH - 1 : 0] = tag_fifo_data_i[ADDR_WIDTH - 1 : 0]; // addr
						aw_fifo_data_n[ADDR_WIDTH - 1 : INDEX_WIDTH + OFFSET_WIDTH] = rdata_i[TAG_WIDTH + BLANK_WIDTH + DATA_WIDTH - 1 : BLANK_WIDTH + DATA_WIDTH]; // tag in addr
						
						w_fifo_data_n = rdata_i[DATA_WIDTH - 1 : 0];
						
						fill_data_n[ADDR_WIDTH + DATA_WIDTH - 1 : DATA_WIDTH] = tag_fifo_data_i[ADDR_WIDTH - 1 : 0]; // addr
						fill_data_n[DATA_WIDTH - 1 : 0] = wbuffer_data_i[DATA_WIDTH - 1 : 0]; // data
						fill_data_n[ADDR_WIDTH + DATA_WIDTH - 1 : ADDR_WIDTH + DATA_WIDTH - 1] = 1'b1; // write flag
						//$display("S_WMISS");

						state_n		= S_WMISS;
					end
				end
			end
		end
		S_RHIT: begin			
			tag_fifo_rden	= 1'b0;
			rready 		= 1'b0;

			if(!rob_afull_i) begin
				rob_wren	= 1'b1;

				state_n		= S_IDLE;
			end
		end
		S_RMISS: begin
			tag_fifo_rden	= 1'b0;
			rready		= 1'b0;
			if(!dirty & !ar_fifo_afull_i) begin
				ar_fifo_wren	= 1'b1;
				state_n		= S_IDLE;
			end
			else if(!ar_fifo_afull_i & !aw_fifo_afull_i & !w_fifo_afull_i) begin
				ar_fifo_wren	= 1'b1;
				aw_fifo_wren	= 1'b1;
				w_fifo_wren	= 1'b1;

				state_n		= S_IDLE;
			end
		end
		S_WHIT: begin
			tag_fifo_rden	= 1'b0;
			wbuffer_rden	= 1'b0;

			fill_valid	= 1'b1;
			rready 		= 1'b0;

			if(fill_ready_i) begin
				state_n		= S_IDLE;
			end
		end
		S_WMISS: begin
			tag_fifo_rden	= 1'b0;
			wbuffer_rden	= 1'b0;

			fill_valid 	= 1'b1;
			rready 		= 1'b0;
			if(!dirty & fill_ready_i) begin
				state_n		= S_IDLE;
			end
			else if(!aw_fifo_afull_i & !w_fifo_afull_i & fill_ready_i) begin
				aw_fifo_wren	= 1'b1;
				w_fifo_wren	= 1'b1;
				state_n		= S_IDLE;
			end			
		end
	endcase
end

// memory ctrl
assign rready_o		= rready;

// tag fifo
assign tag_fifo_rden_o	= tag_fifo_rden;

// rob
assign rob_wren_o	= rob_wren;
assign rob_data_o	= rob_data;

// ar fifo
assign ar_fifo_wren_o	= ar_fifo_wren;
assign ar_fifo_data_o	= ar_fifo_data;

// aw fifo 
assign aw_fifo_wren_o	= aw_fifo_wren;
assign aw_fifo_data_o	= aw_fifo_data;

// w fifo
assign w_fifo_wren_o	= w_fifo_wren;
assign w_fifo_data_o	= w_fifo_data;

// fill arbiter
assign fill_valid_o	= fill_valid;
assign fill_data_o	= fill_data;

// wbuffer
assign  wbuffer_rden_o	= wbuffer_rden;

endmodule
