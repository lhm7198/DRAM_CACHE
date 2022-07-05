module FIFO # (
	parameter DATA_BIT_SIZE = 8,
	parameter FIFO_SIZE = 8,
	parameter A_FULL_THR = 6,
	parameter A_EMPTY_THR = 2
)(
	input clk,
	input rst_n,

	output full,
	output A_full,
	input write_en,
	input [DATA_BIT_SIZE-1:0] write_data,

	output empty,
	output A_empty,
	input read_en,
	output [DATA_BIT_SIZE-1:0] read_data,

	output [3:0] test
);

localparam PTR_WIDTH = $clog2(FIFO_SIZE);

reg                     full,
                        A_full,
                        empty,
                        A_empty;
// internals 
reg     [DATA_BIT_SIZE-1:0] mem[FIFO_SIZE-1:0];
reg     [PTR_WIDTH-1:0] tail,   tail_nxt;
reg     [PTR_WIDTH-1:0] head,   head_nxt;
reg 	[PTR_WIDTH:0]   cnt,    cnt_nxt;

wire                    write   = !full & write_en;
wire                    read    = !empty & read_en;

// write ptr next 
always @(*) begin
    head_nxt    = head;
    tail_nxt    = tail;
    cnt_nxt     = cnt;
    if (read) begin
	    if (head == (FIFO_SIZE-1)) begin 
		    head_nxt = 0;
	    end else begin 
		    head_nxt = head + 1;        
	    end
    end

    if (write) begin
	    if (tail == (FIFO_SIZE-1)) begin 
		    tail_nxt = 0;
	    end else begin 
		    tail_nxt = tail + 1;        
	    end
    end

    if (write & !read) begin
        cnt_nxt = cnt + 1;
    end
    else if (!write & read) begin
        cnt_nxt = cnt - 1;
    end
end

int i;
always @(posedge clk) begin
	if (!rst_n) begin 
		head <= 0;
		tail <= 0;
		cnt <= 0;
		for (i=0; i < FIFO_SIZE; i++)
			mem[i] <= 0;
        full <= 1'b0;
        A_full <= 1'b0;
        empty <= 1'b1;
        A_empty <= 1'b1;
	end else begin 
        head    <= head_nxt;
        tail    <= tail_nxt;
        cnt     <= cnt_nxt;
		if (write) begin
			mem[tail] <= write_data;        
		end
        full <= (cnt_nxt==FIFO_SIZE);
        A_full <= (cnt_nxt>=A_FULL_THR);
        empty <= (cnt_nxt==0);
        A_empty <= (cnt_nxt<=A_EMPTY_THR);
	end
end

assign read_data = mem[head]; 

assign test = cnt;

endmodule

