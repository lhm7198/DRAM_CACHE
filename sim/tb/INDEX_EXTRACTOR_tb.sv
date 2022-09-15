`timescale 1ps/1ps

module INDEX_EXTRACTOR_TB;

reg clk = 1'b0;
reg rst_n;

reg [15 : 0]	arid_i;
reg [63 : 0]	araddr_i;
reg		arvalid_i;
wire		arready_o;

reg [15 : 0]	awid_i;
reg [63 : 0]	awaddr_i;
reg		awvalid_i;
wire		awready_o;

wire [15 : 0]	arid_o;
wire [3 : 0] 	araddr_o;
wire		arvalid_o;
reg		arready_i;

reg 		fifo_afull_i;
wire 		fifo_write_en_o;
wire [80 : 0]	fifo_data_o;

localparam CLOCK_PERIOD = 1000;
always #(CLOCK_PERIOD/2) clk = ~clk;

int read_index;
int write_index;
int i;
int r_addr, w_addr;

initial
begin
	rst_n = 1'b1;

	arid_i = 0;
	araddr_i = 0;
	arvalid_i = 0;
	
	awid_i = 0;
	awaddr_i = 0;
	awvalid_i = 0;

	arready_i = 0;

	fifo_afull_i = 0;

	read_index = 0;
	write_index = 0;
	
	#(CLOCK_PERIOD);
	rst_n = 1'b0;
	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\nStart\n");

	for(i=0 ; i<10 ; i++) begin
		#(CLOCK_PERIOD);
	
		$display("%1d repetition\n",i);
		r_addr = $urandom % 156 + 100;
		w_addr = $urandom % 156 + 100;
		$display("r_addr = %x, w_addr = %x\n", r_addr, w_addr);

		arvalid_i = 0;
		arid_i = 0;
		araddr_i = 0;

		awvalid_i = 0;
		awid_i = 0;
		awaddr_i = 0;


		
		if(r_addr % 2 == 0) begin
			arid_i = read_index;
			arvalid_i = 1;
			araddr_i = r_addr;
			read_index++;
		end
		if(w_addr % 2 == 0) begin
			awid_i = write_index;
			awvalid_i = 1;
			awaddr_i = w_addr;
			write_index++;
		end

		#(CLOCK_PERIOD);

		$display("index = %x, fifo_data = %x\n", araddr_o, fifo_data_o);	
		$display("-----------------------------------------------------------------------\n");
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

	.arid_o(arid_o),
	.araddr_o(araddr_o),
	.arvalid_o(arvalid_o),
	.arready_i(arready_i),
	
	.fifo_afull_i(fifo_afull_i), 
	.fifo_write_en_o(fifo_write_en_o), 
	.fifo_data_o(fifo_data_o)
);

endmodule
