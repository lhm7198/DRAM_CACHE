`timescale 1ps/1ps

module INDEX_EXTRACTOR_TB;

reg clk = 1'b0;
reg rst_n;

reg [31 : 0]	arid_i;
reg [31 : 0]	araddr_i;
reg		arvalid_i;

reg [31 : 0]	awid_i;
reg [31 : 0]	awaddr_i;
reg		awvalid_i;

wire		ready_o;

wire [3 : 0]	slave_i;

reg 		fifo_Afull;
wire 		fifo_write_enable;
wire [127 : 0]	fifo_i;

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

	fifo_Afull = 0;
	
	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart");

	for(i=0 ; i<5 ; i++) begin
		#(CLOCK_PERIOD);
		$display("ready_o = %d, slave_i = %d, fifo_write_enable = %d, fifo_i = %d\n", ready_o, slave_i, fifo_write_enable, fifo_i);	
	
		if($urandom % 2 == 0) begin
			arid_i = i;
			arvalid_i = 1;
			araddr_i = $urandom % 256;
			$display("araddr = %d ",araddr_i);
		end else
			awid_i = i;
			awvalid_i = 1;
			awaddr_i = $urandom % 256;
			$display("awaddr = %d ",awaddr_i);
		end
		#(CLOCK_PERIOD);

		$display("ready_o = %d, slave_i = %d, fifo_write_enable = %d, fifo_i = %d\n", ready_o, slave_i, fifo_write_enable, fifo_i);	
	end
	$finish;
end

INDEX_EXTRACTOR index_extractor(.clk(clk), .rst_n(rst_n), .arid_i(arid_i), .araddr_i(araddr_i), .arvalid_i(arvalid_i), .awid_i(awid_i), .awaddr_i(awaddr_i), .awvalid_i(awvalid_i), .ready_o(ready_o), .slave_i(slave_i), .fifo_Afull(fifo_Afull), .fifo_write_enable(fifo_write_enable), .fifo_i(fifo_i));

endmodule
