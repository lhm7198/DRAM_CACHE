`define ADDR_W	64
`define DATA_W	64*8
`define ID_W 	16
`define ID 	1

`define TAG_S 	8*8

`define INDEX_W 26
`define OFFSET_W 6

`define BLANK_W 30

module AXI_SLAVE_CXL
(
    	input   wire                clk,
    	input   wire                rst_n,  // _n means active low
		
    	// AR channel
    	input   wire 	[`ID_W - 1 : 0] 		arid_i,
    	input   wire 	[`ADDR_W - 1 : 0] 		araddr_i,
   	input   wire					arvalid_i,
    	output  wire					arready_o,

   	// R channel
	output	wire	[`ID_W - 1 : 0]			rid_o,
	output	wire	[`TAG_S + `DATA_W - 1 : 0]	rdata_o,
	output	wire					rvalid_o,
	input	wire					rready_i,

    	// AW channel
	input   wire 	[`ID_W - 1 : 0] 		awid_i,
    	input   wire 	[`ADDR_W - 1 : 0] 		awaddr_i,
    	input   wire 					awvalid_i,
    	output  wire					awready_o,

    	// W channel
	input	wire	[`ID_W - 1 : 0]			wid_i,
    	input   wire 	[`DATA_W - 1 : 0] 		wdata_i,
   	input   wire 					wvalid_i,
    	output  wire					wready_o,

	// B channel
	output	wire	[`ID_W - 1 : 0]			bid_o,
	output	wire					bvalid_o,
	input	wire					bready_i
);

// Read
reg					arready;
reg	[`DATA_W - 1 : 0]		rdata,	rdata_n;
reg					rvalid;

// Write
reg					awready;
reg					wready;
reg					bvalid;

logic   [`DATA_W - 1 : 0]             mem_data[`INDEX_W];

function void write_64byte(int index, input bit [511:0] wdata);
    mem_data[index] = wdata;
endfunction

function bit [511:0] read_64byte(int index);
    read_64byte = mem_data[index];
endfunction

//----------------------------------------------------------
// write channels (AW, W, B)
//----------------------------------------------------------
localparam logic [1:0]      S_W_IDLE = 0,
                            S_W_AWREADY = 1,
                            S_W_RUN = 2,
                            S_W_RESP = 3;

logic   [1 : 0]            	wstate,         wstate_n;
logic   [`INDEX_W - 1 : 0] 	windex,         windex_n;

always_ff @(posedge clk)
    if (!rst_n) begin
        wstate          <= S_W_IDLE;

        windex          <= {`INDEX_W{1'b0}};
    end
    else begin
        wstate          <= wstate_n;

        windex          <= windex_n;
    end

always @(*) begin
    wstate_n    = wstate;

    windex_n    = windex;

    awready	= 1'b0;
    wready	= 1'b0;
    bvalid	= 1'b0;

    case (wstate)
        S_W_IDLE: begin
		if (awvalid_i) begin
                	wstate_n                = S_W_AWREADY;
            	end
        end
        S_W_AWREADY: begin
		$display("awaddr : %x", awaddr_i);
                windex_n        = awaddr_i[`INDEX_W + `OFFSET_W - 1 : `OFFSET_W];

                wstate_n        = S_W_RUN;
        end
        S_W_RUN: begin
                $display("windex : %x", windex);
		awready		= 1'b1;
                wready          = 1'b1;
                if (wvalid_i) begin
			$display("wdata_i : %x", wdata_i);
                	write_64byte(windex, wdata_i); // data
			wstate_n   = S_W_RESP;
                end
        end
        S_W_RESP: begin
		bvalid    = 1'b1;
                
		if (bready_i) begin
                	wstate_n    = S_W_IDLE;
                end
        end
    endcase
end

//----------------------------------------------------------
// read channel (AR, R)
//----------------------------------------------------------
localparam logic [1:0]      S_R_IDLE = 0,
                            S_R_ARREADY = 1,
                            S_R_RUN = 2;

logic   [1 : 0]			rstate,		rstate_n;
logic   [`INDEX_W - 1 : 0] 	rindex,         rindex_n;

always_ff @(posedge clk)
	if (!rst_n) begin
            rstate              <= S_R_IDLE;

            rindex              <= {`INDEX_W{1'b0}};
        end
        else begin
            rstate              <= rstate_n;

            rindex              <= rindex_n;
        end

always_comb begin
        rstate_n          = rstate;

        rindex_n          = rindex;

        arready           = 1'b0;
        rvalid            = 1'b0;

        case (rstate)
            S_R_IDLE: begin
            	if (arvalid_i) begin
			$display("cxl valid in");
                        rstate_n                = S_R_ARREADY;
                end
            end
            S_R_ARREADY: begin
            	rindex_n        = araddr_i[`INDEX_W + `OFFSET_W - 1 : `OFFSET_W];
		$display("ARREADY");
                arready         = 1'b1;
                rstate_n        = S_R_RUN;
            end
            S_R_RUN: begin
                rvalid          = 1'b1;
                rdata[`DATA_W - 1 : 0] = read_64byte(rindex);
		$display("cxl -> rmh data : %x", rdata);

                if (rready_i) begin
		    $display("cxl -> rmh data : %x", rdata);
                    rstate_n                = S_R_IDLE;
                end
            end
        endcase
    end

// Write
assign awready_o = awready;
assign wready_o	= wready;
assign bvalid_o = bvalid;

// Read
assign arready_o = arready;
assign rdata_o	= rdata;
assign rvalid_o	= rvalid;

endmodule
