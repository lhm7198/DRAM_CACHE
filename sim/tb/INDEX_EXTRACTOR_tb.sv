`timescale 1ps/1ps

module INDEX_EXTRACTOR_TB;

reg clk = 1'b0;
reg rst_n;

reg [31 : 0]	arid_i;
reg [31 : 0]	araddr_i;
reg		arvalid_i;
wire		arready_o;

reg [31 : 0]	awid_i;
reg [31 : 0]	awaddr_i;
reg		awvalid_i;
wire		awready_o;

wire [3 : 0]	index_o;

reg 		fifo_afull_i;
wire 		fifo_write_en_o;
wire [127 : 0]	fifo_data_o;

localparam CLOCK_PERIOD = 1000;
always #(CLOCK_PERIOD/2) clk = ~clk;

int i;
initial
begin
	rst_n = 1'b1;

	arid_i = 0;
	araddr_i = 0;
	arvalid_i = 0;
	
	awid_i = 0;
	awaddr_i = 0;
	awvalid_i = 0;

	fifo_afull_i = 0;
	
	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart");

	for(i=0 ; i<5 ; i++) begin
		#(CLOCK_PERIOD);
		//$display("ready_o = %d, slave_i = %d, fifo_write_enable = %d, fifo_i = %d\n", ready_o, slave_i, fifo_write_enable, fifo_i);	
	
		if($urandom % 2 == 0) begin
			arid_i = i;
			arvalid_i = 1;
			araddr_i = $urandom % 256;
			$display("araddr = %d ",araddr_i);
		end 
		else begin
			awid_i = i;
			awvalid_i = 1;
			awaddr_i = $urandom % 256;
			$display("awaddr = %d ",awaddr_i);
		end
		#(CLOCK_PERIOD);

		//$display("ready_o = %d, slave_i = %d, fifo_write_enable = %d, fifo_i = %d\n", ready_o, slave_i, fifo_write_enable, fifo_i);	
	end
	$finish;
end

INDEX_EXTRACTOR index_extractor
(
	.clk(clk), 
	.rst_n(rst_n),

	.arid_i(arid_i),
	.araddr_i(araddr_i),
	.arvalid_i(arvalid_i),
	.arready_o(arready_o),
       
	.awid_i(awid_i), 
	.awaddr_i(awaddr_i), 
	.awvalid_i(awvalid_i), 
	.awready_o(awready_o), 
	
	.index_o(index_o),

	.fifo_afull_i(fifo_afull_i), 
	.fifo_write_en_o(fifo_write_en_o), 
	.fifo_data_o(fifo_data_o)
);

endmodule
