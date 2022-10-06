`ifndef __TYPEDEF_SVH__
`define	__TYPEDEF_SVH__

// AXI_INTERFACE
`define AXI_ADDR_WIDTH		64
`define AXI_DATA_WIDTH		32
`define AXI_ID_WIDTH		16
`define AXI_ID			1

// FIFO
`define FIFO_DATA_WIDTH		8
`define FIFO_SIZE		8
`define FIFO_A_FULL_THR		6
`define FIFO_A_EMPTY_THR	2

// ADDRESS
`define INDEX_WIDTH		4
`define OFFSET_WIDTH		6
`define	TID_WIDTH		10

// DRAM TAG
`define BURST_SIZE	 	64
`define BLANK_WIDTH		46

`define TOTAL_CYCLE		8

`endif
