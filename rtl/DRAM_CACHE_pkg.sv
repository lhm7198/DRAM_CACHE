parameter   TID_WIDTH   8
parameter   DATA_WIDTH  32

package DRAM_CACHE_pkg;
typedef struct packed {
    logic   [TID_WIDTH-1:0]     	tid;
    logic   [DATA_WIDTH-1:0] 	  	data; 
    logic                		last; // end-of-transaction
} rob_queue_entry_t;
endpackage

import DRAM_CACHE_pkg::*;

wire    rob_queue_entry_t       read_entry, write_entry;

read_entry = rob_queue_entyr_t'(read_data);
if (read_entry.tid) begin
end

FIFO #(.DATA_WIDTH ($bits(rob_queue_entry_t)))
u_hit_fifo
(
    .clk                       		(clk),
    .rst_n                     		(rst_n),
    .hit_write_en              		(),
    .hit_write_data            		(write_entry),
    .hit_read_data             		(read_entry)
)
