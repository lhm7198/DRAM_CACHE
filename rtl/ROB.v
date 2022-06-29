module ROB # ( 
	parameter DATA_BIT_SIZE = 8,
	parameter ROB_SIZE = 8
)(
	input clk,
	input reset,
	
//hit queue
	output full_hit,
	input write_en_hit,
	input [7:0] write_tID_hit,
	input [DATA_BIT_SIZE-1:0] write_data_hit,
	output empty_hit,
	
//miss queue
	output full_miss,
	input write_en_miss,
	input [7:0] write_tID_miss,
	input [DATA_BIT_SIZE-1:0] write_data_miss,
	output empty_miss,

	output [DATA_BIT_SIZE-1:0] read_data

);

reg	[7:0] tID;
reg	[7:0] tID_nxt;

reg     [DATA_BIT_SIZE-1:0] mem_hit[ROB_SIZE-1:0];
reg	[7:0] tID_hit[ROB_SIZE-1:0];
reg     [7:0] head_hit;
reg     [7:0] head_hit_nxt;
reg     head_phase_hit; 
reg     head_phase_hit_nxt; 

reg     [7:0] tail_hit;
reg     [7:0] tail_hit_nxt;
reg     tail_phase_hit; 
reg     tail_phase_hit_nxt; 


reg     [DATA_BIT_SIZE-1:0] mem_miss[ROB_SIZE-1:0];
reg	[7:0] tID_miss[ROB_SIZE-1:0];
reg     [7:0] head_miss;
reg     [7:0] head_miss_nxt;
reg     head_phase_miss; 
reg     head_phase_miss_nxt; 

reg     [7:0] tail_miss;
reg     [7:0] tail_miss_nxt;
reg     tail_phase_miss; 
reg     tail_phase_miss_nxt; 

reg	[DATA_BIT_SIZE-1:0] read_data_nxt;


always @(*) begin
	if (tID == (ROBO_SIZE-1)) begin 
		tID_nxt = 0;
	end else begin 
		tID_nxt = tID + 1;        
	end
end


//for hit fifo
always @(*) begin
	if (head_hit == (ROBO_SIZE-1)) begin 
		head_hit_nxt = 0;
		head_phase_hit_nxt = ~head_phase_hit;
	end else begin 
		head_hit_nxt = head_hit + 1;        
		haed_phase_hit_nxt = head_phase_hit;
	end
end

always @(*) begin
	if (tail_hit == (ROB_SIZE-1)) begin 
		tail_hit_nxt = 0;
		tail_phase_hit_nxt = ~tail_phase_hit;
	end else begin 
		tail_hit_nxt = tail_hit + 1;        
		tail_phase_hit_nxt = tail_phase_hit;
	end
end

int i;
always @(posedge clk) begin
	if (reset) begin 
		head_hit <= 0;
		head_phase_hit <= 0;
		tail_hit <= 0;
		tail_phase_hit <= 0;
		for (i=0; i < ROB_SIZE; i++) begin
			mem_hit[i] <= 0;
			tID_hit[i] <= 0;
		end
	end else begin 
		if (!full_hit && write_en_hit) begin
			mem_hit[head_hit] <= write_data_hit;
		 	tID_hit[head_hit] <= write_tID_hit;	
			head_hit <= head_hit_nxt;
			head_phase_hit <= head_phase_hit_nxt;
		end
	end
end


//for miss fifo
always @(*) begin
	if (head_miss == (ROBO_SIZE-1)) begin 
		head_miss_nxt = 0;
		head_phase_miss_nxt = ~head_phase_miss;
	end else begin 
		head_miss_nxt = head_miss + 1;        
		haed_phase_miss_nxt = head_phase_miss;
	end
end

always @(*) begin
	if (tail_miss == (ROB_SIZE-1)) begin 
		tail_miss_nxt = 0;
		tail_phase_miss_nxt = ~tail_phase_miss;
	end else begin 
		tail_miss_nxt = tail_miss + 1;        
		tail_phase_miss_nxt = tail_phase_miss;
	end
end

int j;
always @(posedge clk) begin
	if (reset) begin 
		head_miss <= 0;
		head_phase_miss <= 0;
		tail_miss <= 0;
		tail_phase_miss <= 0;
		for (j=0; j < ROB_SIZE; j++) begin
			mem_miss[j] <= 0;
			tID_miss[j] <= 0;
		end
	end else begin 
		if (!full_miss && write_en_miss) begin
			mem_miss[head_miss] <= write_data_miss;
		 	tID_miss[head_miss] <= write_tID_miss;	
			head_miss <= head_miss_nxt;
			head_phase_miss <= head_phase_miss_nxt;
		end
	end
end


always @(posedge clk) begin
	if( tID == tID_hit[tail_hit] && !empty_hit) begin
		read_data_nxt <= mem_hit[tail_hit];
		tail_hit <= tail_hit_nxt;
		tail_phase_hit <= tail_phase_hit_nxt;
		tID <= tID_nxt;
	end
	else if( tID == tID_miss[tail_miss] && !empty_miss) begin
		read_data_nxt <= mem_miss[tail_miss];
		tail_miss <= tail_miss_nxt;
		tail_phase_miss <= tail_phase_miss_nxt;
		tID <= tID_nxt;
	end
	else begin
		read_data <= read_data;
		tail_miss <= tail_miss;
		tail_phase_miss <= tail_phase_miss;
		tID <= tID;
	end
end

assign full_hit = (head_phase_hit != tail_phase_hit) && (head_hit == tail_hit);
assign full_miss = (head_phase_miss != tail_phase_miss) && (head_miss == tail_miss);

assign empty_hit = (head_phase_hit == tail_phase_hit) && (head_hit == tail_hit);
assign empty_miss = (head_phase_miss == tail_phase_miss) && (head_miss == tail_miss);

assign read_data = read_data_nxt; 


