module TAG_COMPARE
#(
	parameter TAG_BIT_SIZE = 4
)
(
	input wire				clk,
	input wire				rst_n,

	input wire	[80 : 0]		fifo_data_i,
	input wire	[63-TAG_BIT_SIZE : 0]	tag_i,
	input wire	[? : ?]			data_i,

	output wire				r_hit_o,
	output wire				r_miss_o,
	output wire				w_hit_o,
	output wire				w_miss_o
);

// if(fifo_data_i[80:80] == 0)
	// read
	// if(fifo_data_i[63 : TAG_BIT_SIZE] == tag_i[63-TAG_BIT_SIZE : 0]
		// r_hit
	// else
		// r_miss
// else
	// write
	// if(fifo_data_i[63 : TAG_BIT_SIZE] == tag_i[63-TAG_BIT_SIZE : 0]
		// w_hit
	// else
		// w_miss
