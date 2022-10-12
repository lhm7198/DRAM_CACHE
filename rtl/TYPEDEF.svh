`ifndef __TYPEDEF_SVH__
`define	__TYPEDEF_SVH__

// AXI INTERFACE
`define AXI_ADDR_WIDTH		64
`define AXI_DATA_WIDTH		64*8
`define AXI_ID_WIDTH		16
`define AXI_ID			1

// TAG SIZE
`define TAG_SIZE		8*8
`define TAG_WIDTH		16
`define BLANK_WIDTH		TAG_SIZE - TAG_WIDTH - 2

// ADDRESS (32 bit)
`define INDEX_WIDTH		10
`define OFFSET_WIDTH		AXI_ADDR_WIDTH - TAG_WIDTH - INDEX_WIDTH

// FIFO
`define FIFO_DATA_WIDTH		8
`define FIFO_SIZE		8
`define FIFO_A_FULL_THR		6
`define FIFO_A_EMPTY_THR	2

// TID
`define	TID_WIDTH		10

`endif
