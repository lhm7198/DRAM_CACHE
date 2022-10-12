`include "TYPEDEF.svh"

module FIFO # (
	parameter DATA_WIDTH = `FIFO_DATA_WIDTH, // 8
	parameter FIFO_SIZE = `FIFO_SIZE, // 8
	parameter A_FULL_THR = `FIFO_AFULL_THR, // 6
	parameter A_EMPTY_THR = `FIFO_AEMPTY_THR // 2
)(
	input	wire				clk,
	input 	wire				rst_n,

	output 	wire				full_o,
	output 	wire				A_full_o,
	input 	wire				write_en_i,
	input 	wire	[DATA_WIDTH - 1 : 0] 	write_data_i,

	output 	wire				empty_o,
	output 	wire				A_empty_o,
	input 	wire				read_en_i,
	output 	wire	[DATA_WIDTH - 1 : 0] 	read_data_o,

	output	wire	[3:0]			remain_o
);

localparam PTR_WIDTH = $clog2(FIFO_SIZE + 1);

reg                     	full,
                        	A_full,
                        	empty,
                        	A_empty;
// internals 
reg     [DATA_WIDTH-1:0] 	mem[FIFO_SIZE-1:0];
reg     [PTR_WIDTH-1:0] 	tail,   tail_n;
reg     [PTR_WIDTH-1:0] 	head,   head_n;
reg 	[PTR_WIDTH:0]   	cnt,    cnt_n;

wire                    	write   = !full & write_en_i;
wire                    	read    = !empty & read_en_i;

// write ptr next 
always @(*) begin
    head_n    = head;
    tail_n    = tail;
    cnt_n     = cnt;

    if (read) begin
	    if (head == (FIFO_SIZE-1)) begin 
		    head_n = 0;
	    end else begin 
		    head_n = head + 1;        
	    end
    end

    if (write) begin
	    if (tail == (FIFO_SIZE-1)) begin 
		    tail_n = 0;
	    end 
	    else begin 
		    tail_n = tail + 1;        
	    end
    end

    if (write & !read) begin
        cnt_n = cnt + 1;
    end
    else if (!write & read) begin
        cnt_n = cnt - 1;
    end
end

int i;
always @(posedge clk) begin
	if (!rst_n) begin 
		head 	<= 0;
		tail 	<= 0;
		cnt 	<= 0;

		for (i=0; i < FIFO_SIZE; i++)
			mem[i]	<= 0;

        	full 	<= 1'b0;
       		A_full 	<= 1'b0;
        	empty 	<= 1'b1;
        	A_empty <= 1'b1;
	end 
	else begin 
        	head    <= head_n;
        	tail    <= tail_n;
        	cnt     <= cnt_n;

		if (write) begin
			mem[tail] <= write_data_i;        
		end

        	full 	<= (cnt_n==FIFO_SIZE);
        	A_full 	<= (cnt_n>=A_FULL_THR);
        	empty 	<= (cnt_n==0);
        	A_empty <= (cnt_n<=A_EMPTY_THR);
	end
end

assign read_data_o 	= mem[head];

assign full_o 		= full;
assign A_full_o 	= A_full;
assign empty_o		= empty;
assign A_empty_o	= A_empty;

assign remain_o 	= cnt;

endmodule

