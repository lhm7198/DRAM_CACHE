module FIFO # (
	parameter DATA_BIT_SIZE = 8,
	parameter FIFO_SIZE = 8,
	parameter A_FULL_THR = 6,
	parameter A_EMPTY_THR = 2
)(
	input clk,
	input reset,

	output full,
	output A_full,
	input write_en,
	input [DATA_BIT_SIZE-1:0] write_data,

	output empty,
	output A_empty,
	input read_en,
	output [DATA_BIT_SIZE-1:0] read_data           
);


// internals 
reg     [DATA_BIT_SIZE-1:0] mem[FIFO_SIZE-1:0];
reg     [7:0] head;
reg     [7:0] head_nxt;

reg     [7:0] tail;
reg     [7:0] tail_nxt;

// write ptr next 
always @(*) begin
	if (head == (FIFO_SIZE-1)) begin 
		head_nxt = 0;
	end else begin 
		head_nxt = head + 1;        
	end
end

int i;
always @(posedge clk) begin
	if (reset) begin 
		head <= 0;
		remain <= 0;
		for (i=0; i < FIFO_SIZE; i++)
			mem[i] <= 0;
	end else begin 
		if (!full && write_en) begin
			mem[head] <= write_data;        
			head <= head_nxt;
			remain <= remain + 1;
		end
	end
end

// read ptr next 
always @(*) begin
	if (tail == (FIFO_SIZE-1)) begin 
		tail_nxt = 0;
	end else begin 
		tail_nxt = tail + 1;        
	end
end

// read ptr 
always @(posedge clk) begin
	if (reset) begin 
		tail <= 0;
	end else begin 
		if (!empty && read_en) begin
			tail <= tail_nxt;
			remain <= remain - 1;
		end
	end
end

assign full = (remain == FIFO_SIZE);
assign A_full = (remain >= A_FULL_THR);

assign empty = (remain == 0);
assign A_empty = (remain <= A_EMPTY_THR);

assign read_data = mem[tail]; 

endmodule
