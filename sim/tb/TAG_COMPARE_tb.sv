`define ADDR_W	 64
`define DATA_W	 64*8
`define ID_W	 16

`define TAG_S 	 8*8
`define BLANK_W	 46

`define TAG_W	 16
`define INDEX_W	 10
`define OFFSET_W 38

`define TID_W	 10

`timescale 1ps/1ps

module TAG_COMPARE_TB;

reg clk = 1'b0;
reg rst_n;

// R channel
reg [`ID_W - 1 : 0	]		rid_i;
reg [`TAG_S + `DATA_W - 1 : 0] 		rdata_i;
reg					rvalid_i;
wire					rready_o;

// Tag FIFO
reg 					tag_fifo_aempty_i;
wire					tag_fifo_rden_o;
reg [`TID_W + `ADDR_W : 0]	   	tag_fifo_data_i;

// WBuffer
reg 					wbuffer_aempty_i;
wire					wbuffer_rden_o;
reg [`DATA_W - 1 : 0]	   		wbuffer_data_i;

// ROB
reg 					rob_afull_i;
wire					rob_wren_o;
wire [`TID_W + `DATA_W - 1 : 0]  	rob_data_o;

// AR FIFO
reg 					ar_fifo_afull_i;
wire					ar_fifo_wren_o;
wire [`TID_W + `ADDR_W - 1 : 0]  	ar_fifo_data_o;

// AW FIFO
reg 					aw_fifo_afull_i;
wire					aw_fifo_wren_o;
wire [`ADDR_W - 1 : 0] 	 		aw_fifo_data_o;

// AR FIFO
reg 					w_fifo_afull_i;
wire					w_fifo_wren_o;
wire [`DATA_W - 1 : 0]			w_fifo_data_o;

// Arbiter
reg					fill_ready_i;
wire					fill_valid_o;
wire [`ADDR_W + `DATA_W - 1 : 0]	fill_data_o;

// etc
reg [`TAG_S - 1 : 0] 			tmp_tag;
reg [`ADDR_W - 1 : 0]			tmp_addr;

localparam CLOCK_PERIOD = 1000;
always #(CLOCK_PERIOD/2) clk = ~clk;

initial
begin
	rst_n = 1'b0;

	rid_i = 0;
	rdata_i = 0;
	rvalid_i = 1'b0;

	tag_fifo_aempty_i = 1'b1;
  	tag_fifo_data_i = 0;

	wbuffer_aempty_i = 1'b1;
	wbuffer_data_i = 0;

	rob_afull_i = 1'b0;
	ar_fifo_afull_i = 1'b0;
	aw_fifo_afull_i = 1'b0;
	w_fifo_afull_i = 1'b0;

	fill_ready_i = 1'b1;

	tmp_addr = 0;
	tmp_tag = 0;

	#(CLOCK_PERIOD);
	rst_n = 1'b1;
	
	#(CLOCK_PERIOD);

	$display("\n$$$$$$$$$$$$$$  Start  $$$$$$$$$$$$$$\n");
	
	//////////////////////////////////////////////
	////////////////  read hit  //////////////////
	/////////////////////////////////////////////
	$display("-------- READ HIT START ---------\n");
	
	// tag_fifo_data_i
	tmp_addr[`TAG_W + `INDEX_W +`OFFSET_W - 1 : `INDEX_W + `OFFSET_W] = 3; // tag data
	tmp_addr[`INDEX_W + `OFFSET_W - 1 : `OFFSET_W] = 1; // index
	tmp_addr[`OFFSET_W - 1 : 0] = 0; // offset

	tag_fifo_data_i[`TID_W + `ADDR_W : `TID_W + `ADDR_W] = 1'b0; // R/W flag
	tag_fifo_data_i[`TID_W + `ADDR_W - 1 : `ADDR_W] = 1; // tid
	tag_fifo_data_i[`ADDR_W - 1 : 0] = tmp_addr; // addr
	
	// rdata_i
	tmp_tag[`TAG_S - 1 : `TAG_S - 1] = 1'b1; // valid
	tmp_tag[`TAG_S - 2 : `TAG_S - 2] = 1'b1; // dirty
	tmp_tag[`TAG_S - 3 : `BLANK_W] = 3; // tag data
	tmp_tag[`BLANK_W - 1 : 0] = 46'b0; // blank

	rdata_i[`DATA_W - 1 : 0] = 15; // data
	rdata_i[`TAG_S + `DATA_W - 1 : `DATA_W] = tmp_tag; // tag

	// S_IDLE -> S_RHIT
	rvalid_i = 1'b1;
	tag_fifo_aempty_i = 1'b0;
	#(CLOCK_PERIOD);

	// S_RHIT -> S_IDLE
	rob_afull_i = 1'b0;
	#(CLOCK_PERIOD);
	$display("rob_wren_o : %x\nrob_tid : %x\nrob_data : %x\n", 
		rob_wren_o, rob_data_o[`TID_W + `DATA_W - 1 : `DATA_W], rob_data_o[`DATA_W - 1 : 0]);

	$display("---------------------------------\n");
	
	//////////////////////////////////////////////////
	/////////////////  read miss  ////////////////////
	//////////////////////////////////////////////////

	$display("-------- READ MISS START --------\n");
	// tag_fifo_data_i
	tmp_addr[`TAG_W + `INDEX_W +`OFFSET_W - 1 : `INDEX_W + `OFFSET_W] = 3; // tag data
	tmp_addr[`INDEX_W + `OFFSET_W - 1 : `OFFSET_W] = 1; // index
	tmp_addr[`OFFSET_W - 1 : 0] = 0; // offset

	tag_fifo_data_i[`TID_W + `ADDR_W : `TID_W + `ADDR_W] = 1'b0; // R/W flag
	tag_fifo_data_i[`TID_W + `ADDR_W - 1 : `ADDR_W] = 2; // tid
	tag_fifo_data_i[`ADDR_W - 1 : 0] = tmp_addr; // addr
	
	// rdata_i
	tmp_tag[`TAG_S - 1 : `TAG_S - 1] = 1'b1; // valid
	tmp_tag[`TAG_S - 2 : `TAG_S - 2] = 1'b1; // dirty
	tmp_tag[`TAG_S - 3 : `BLANK_W] = 7; // tag data
	tmp_tag[`BLANK_W - 1 : 0] = 46'b0; // blank

	rdata_i[`DATA_W - 1 : 0] = 16; // data
	rdata_i[`TAG_S + `DATA_W - 1 : `DATA_W] = tmp_tag; // tag

	// S_IDLE -> S_RMISS
	rvalid_i = 1'b1;
	tag_fifo_aempty_i = 1'b0;
	#(CLOCK_PERIOD);

	// S_RMISS -> S_IDLE
	ar_fifo_afull_i = 1'b0;
	aw_fifo_afull_i = 1'b0;
	w_fifo_afull_i = 1'b0;
	#(CLOCK_PERIOD);
	$display("ar_wren_o : %x, aw_wren_o : %x, w_wren_o : %x\nar_addr : %x\naw_addr : %x\nw_data : %x\n", 
		  ar_fifo_wren_o, aw_fifo_wren_o, w_fifo_wren_o, 
		  ar_fifo_data_o[`ADDR_W - 1 : 0],
		  aw_fifo_data_o[`ADDR_W - 1 : 0],
		  w_fifo_data_o[`DATA_W - 1 : 0]);
	
	$display("-----------------------------------\n");

	//////////////////////////////////////////////////
	/////////////////  write hit  ////////////////////
	//////////////////////////////////////////////////
	$display("-------- WRITE HIT START --------\n");

	// tag_fifo_data_i
	tmp_addr[`TAG_W + `INDEX_W +`OFFSET_W - 1 : `INDEX_W + `OFFSET_W] = 3; // tag data
	tmp_addr[`INDEX_W + `OFFSET_W - 1 : `OFFSET_W] = 1; // index
	tmp_addr[`OFFSET_W - 1 : 0] = 0; // offset

	tag_fifo_data_i[`TID_W + `ADDR_W : `TID_W + `ADDR_W] = 1'b1; // R/W flag
	tag_fifo_data_i[`TID_W + `ADDR_W - 1 : `ADDR_W] = 2; // tid
	tag_fifo_data_i[`ADDR_W - 1 : 0] = tmp_addr; // addr
	
	// rdata_i
	tmp_tag[`TAG_S - 1 : `TAG_S - 1] = 1'b1; // valid
	tmp_tag[`TAG_S - 2 : `TAG_S - 2] = 1'b1; // dirty
	tmp_tag[`TAG_S - 3 : `BLANK_W] = 3; // tag data
	tmp_tag[`BLANK_W - 1 : 0] = 46'b0; // blank

	rdata_i[`DATA_W - 1 : 0] = 10; // data
	rdata_i[`TAG_S + `DATA_W - 1 : `DATA_W] = tmp_tag; // tag

	// wbuffer
	wbuffer_data_i = 14;

	// S_IDLE -> S_WHIT
	rvalid_i = 1'b1;
	tag_fifo_aempty_i = 1'b0;
	#(CLOCK_PERIOD);

	$display("fill_valid_o : %x\nfill_addr : %x\nfill_data : %x\n", 
		  fill_valid_o, 
		  fill_data_o[`ADDR_W + `DATA_W - 1 : `DATA_W],
		  fill_data_o[`DATA_W - 1 : 0]);
	

	// S_WHIT -> S_IDLE
	fill_ready_i = 1'b1;
	#(CLOCK_PERIOD);
	/*$display("fill_valid_o : %x\nfill_addr : %x\nfill_data : %x\n", 
		  fill_valid_o, 
		  fill_data_o[`ADDR_W + `DATA_W - 1 : `DATA_W],
		  fill_data_o[`DATA_W - 1 : 0]);*/
	
	$display("-----------------------------------\n");

	//////////////////////////////////////////////////
	/////////////////  write miss  ///////////////////
	//////////////////////////////////////////////////
	$display("-------- WRITE MISS START --------\n");

	// tag_fifo_data_i
	tmp_addr[`TAG_W + `INDEX_W +`OFFSET_W - 1 : `INDEX_W + `OFFSET_W] = 3; // tag data
	tmp_addr[`INDEX_W + `OFFSET_W - 1 : `OFFSET_W] = 1; // index
	tmp_addr[`OFFSET_W - 1 : 0] = 0; // offset

	tag_fifo_data_i[`TID_W + `ADDR_W : `TID_W + `ADDR_W] = 1'b1; // R/W flag
	tag_fifo_data_i[`TID_W + `ADDR_W - 1 : `ADDR_W] = 2; // tid
	tag_fifo_data_i[`ADDR_W - 1 : 0] = tmp_addr; // addr
	
	// rdata_i
	tmp_tag[`TAG_S - 1 : `TAG_S - 1] = 1'b1; // valid
	tmp_tag[`TAG_S - 2 : `TAG_S - 2] = 1'b1; // dirty
	tmp_tag[`TAG_S - 3 : `BLANK_W] = 7; // tag data
	tmp_tag[`BLANK_W - 1 : 0] = 46'b0; // blank

	rdata_i[`DATA_W - 1 : 0] = 5; // data
	rdata_i[`TAG_S + `DATA_W - 1 : `DATA_W] = tmp_tag; // tag

	// wbuffer
	wbuffer_data_i = 9;

	// S_IDLE -> S_WMISS
	rvalid_i = 1'b1;
	tag_fifo_aempty_i = 1'b0;
	#(CLOCK_PERIOD);
	
	// S_WMISS -> S_IDLE
	aw_fifo_afull_i = 1'b0;
	w_fifo_afull_i = 1'b0;
	fill_ready_i = 1'b1;
	#(CLOCK_PERIOD);
	$display("aw_fifo_data : %x\nw_fifo_data : %x\nfill_addr : %x\nfill_data : %x\n", 
		  aw_fifo_data_o,
		  w_fifo_data_o, 
		  fill_data_o[`ADDR_W + `DATA_W - 1 : `DATA_W],
		  fill_data_o[`DATA_W - 1 : 0]);
	
	$display("-----------------------------------\n");

	$display("\n$$$$$$$$$$$$$$$  End  $$$$$$$$$$$$$$$\n");

	$finish;
end

TAG_COMPARE tag_comparator
(
	.clk(clk), 
	.rst_n(rst_n),

	.rid_i(rid_i),
	.rdata_i(rdata_i),
	.rvalid_i(rvalid_i),
	.rready_o(rready_o),

	.tag_fifo_aempty_i(tag_fifo_aempty_i),
	.tag_fifo_rden_o(tag_fifo_rden_o),
	.tag_fifo_data_i(tag_fifo_data_i),

	.wbuffer_aempty_i(wbuffer_aempty_i),
	.wbuffer_rden_o(wbuffer_rden_o),
	.wbuffer_data_i(wbuffer_data_i),

	.rob_afull_i(rob_afull_i),
	.rob_wren_o(rob_wren_o),
	.rob_data_o(rob_data_o),

	.ar_fifo_afull_i(ar_fifo_afull_i),
	.ar_fifo_wren_o(ar_fifo_wren_o),
	.ar_fifo_data_o(ar_fifo_data_o),

	.aw_fifo_afull_i(aw_fifo_afull_i),
	.aw_fifo_wren_o(aw_fifo_wren_o),
	.aw_fifo_data_o(aw_fifo_data_o),


	.w_fifo_afull_i(w_fifo_afull_i),
	.w_fifo_wren_o(w_fifo_wren_o),
	.w_fifo_data_o(w_fifo_data_o),

	.fill_ready_i(fill_ready_i),
	.fill_valid_o(fill_valid_o),
	.fill_data_o(fill_data_o)
);

endmodule
