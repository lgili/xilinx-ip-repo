`ifndef AXIS_H
`define AXIS_H

`define VECTOR_PORT(MOD_PREFIX, VAR_PREFFIX, CHANNEL_PREFIX) \
.``MOD_PREFIX``(``VAR_PREFFIX``)

// Macros which expand to port declarations:
	// Slave / master
	// Single stream or packed

`define S_AXIS_PORT_NO_USER(PREFIX, AXIS_BYTES) \
output logic                     ``PREFIX``_tready, \
input logic                      ``PREFIX``_tvalid, \
input logic                      ``PREFIX``_tlast, \
input logic [AXIS_BYTES-1:0]     ``PREFIX``_tkeep, \
input logic [(AXIS_BYTES*8)-1:0] ``PREFIX``_tdata

`define S_AXIS_PORT(PREFIX, AXIS_BYTES, AXIS_USER_BITS) \
`S_AXIS_PORT_NO_USER(PREFIX, AXIS_BYTES), \
input logic [AXIS_USER_BITS-1:0] ``PREFIX``_tuser

`define S_AXIS_PORT_TDEST(PREFIX, AXIS_BYTES) \
`S_AXIS_PORT_NO_USER(PREFIX, AXIS_BYTES), \
input logic [AXIS_BYTES-1:0] ``PREFIX``_tdest

`define M_AXIS_PORT_NO_USER(PREFIX, AXIS_BYTES) \
input logic                       ``PREFIX``_tready, \
output logic                      ``PREFIX``_tvalid, \
output logic                      ``PREFIX``_tlast, \
output logic [AXIS_BYTES-1:0]     ``PREFIX``_tkeep, \
output logic [(AXIS_BYTES*8)-1:0] ``PREFIX``_tdata

`define M_AXIS_PORT(PREFIX, AXIS_BYTES, AXIS_USER_BITS) \
`M_AXIS_PORT_NO_USER(PREFIX, AXIS_BYTES), \
output logic [AXIS_USER_BITS-1:0] ``PREFIX``_tuser

`define M_AXIS_PORT_TDEST(PREFIX, AXIS_BYTES) \
`M_AXIS_PORT_NO_USER(PREFIX, AXIS_BYTES), \
output logic [AXIS_BYTES-1:0] ``PREFIX``_tdest

`define S_AXIS_MULTI_PORT(PREFIX, NUM_STREAMS, AXIS_BYTES, AXIS_USER_BITS) \
output logic  [NUM_STREAMS-1 : 0]            ``PREFIX``_tready, \
input logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tvalid, \
input logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tlast,\
input logic [NUM_STREAMS*(AXIS_BYTES*8)-1:0] ``PREFIX``_tdata, \
input logic [NUM_STREAMS*AXIS_BYTES-1:0]     ``PREFIX``_tkeep, \
input logic [NUM_STREAMS*AXIS_USER_BITS-1:0] ``PREFIX``_tuser

`define S_AXIS_MULTI_PORT_TDEST(PREFIX, NUM_STREAMS, AXIS_BYTES, AXIS_USER_BITS) \
output logic  [NUM_STREAMS-1 : 0]            ``PREFIX``_tready, \
input logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tvalid, \
input logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tlast,\
input logic [NUM_STREAMS*(AXIS_BYTES*8)-1:0] ``PREFIX``_tdata, \
input logic [NUM_STREAMS*AXIS_BYTES-1:0]     ``PREFIX``_tkeep, \
input logic [NUM_STREAMS*AXIS_USER_BITS-1:0] ``PREFIX``_tuser, \
input logic [NUM_STREAMS*AXIS_BYTES-1:0]     ``PREFIX``_tdest

`define M_AXIS_MULTI_PORT(PREFIX, NUM_STREAMS, AXIS_BYTES, AXIS_USER_BITS) \
input logic  [NUM_STREAMS-1 : 0]              ``PREFIX``_tready, \
output logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tvalid, \
output logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tlast, \
output logic [NUM_STREAMS*(AXIS_BYTES*8)-1:0] ``PREFIX``_tdata, \
output logic [NUM_STREAMS*AXIS_BYTES-1:0]     ``PREFIX``_tkeep, \
output logic [NUM_STREAMS*AXIS_USER_BITS-1:0] ``PREFIX``_tuser

`define M_AXIS_MULTI_PORT_TDEST(PREFIX, NUM_STREAMS, AXIS_BYTES, AXIS_USER_BITS) \
input logic  [NUM_STREAMS-1 : 0]              ``PREFIX``_tready, \
output logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tvalid, \
output logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tlast, \
output logic [NUM_STREAMS*(AXIS_BYTES*8)-1:0] ``PREFIX``_tdata, \
output logic [NUM_STREAMS*AXIS_BYTES-1:0]     ``PREFIX``_tkeep, \
output logic [NUM_STREAMS*AXIS_USER_BITS-1:0] ``PREFIX``_tuser, \
output logic [NUM_STREAMS*AXIS_BYTES-1:0]      ``PREFIX``_tdest

// Macros to declare an AXI stream instance

`define AXIS_INST_NO_USER(PREFIX, AXIS_BYTES) \
logic ``PREFIX``_tready; \
logic ``PREFIX``_tvalid; \
logic ``PREFIX``_tlast; \
logic [AXIS_BYTES-1:0]     ``PREFIX``_tkeep; \
logic [(AXIS_BYTES*8)-1:0] ``PREFIX``_tdata

`define AXIS_INST_TDEST(PREFIX, AXIS_BYTES) \
logic ``PREFIX``_tready; \
logic ``PREFIX``_tvalid; \
logic ``PREFIX``_tlast; \
logic [AXIS_BYTES-1:0]     ``PREFIX``_tkeep; \
logic [(AXIS_BYTES*8)-1:0]     ``PREFIX``_tdata; \
logic [(AXIS_BYTES)-1:0] ``PREFIX``_tdest

`define AXIS_INST(PREFIX, AXIS_BYTES, AXIS_USER_BITS) \
`AXIS_INST_NO_USER(PREFIX, AXIS_BYTES); \
logic [AXIS_USER_BITS-1:0] ``PREFIX``_tuser

`define AXIS_MULTI_INST_NO_USER(PREFIX, NUM_STREAMS, AXIS_BYTES) \
logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tready; \
logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tvalid; \
logic [NUM_STREAMS-1 : 0]              ``PREFIX``_tlast; \
logic [NUM_STREAMS*(AXIS_BYTES*8)-1:0] ``PREFIX``_tdata; \
logic [NUM_STREAMS*AXIS_BYTES-1:0]     ``PREFIX``_tkeep

`define AXIS_MULTI_INST(PREFIX, NUM_STREAMS, AXIS_BYTES, AXIS_USER_BITS) \
`AXIS_MULTI_INST_NO_USER(PREFIX, NUM_STREAMS, AXIS_BYTES); \
logic [NUM_STREAMS*AXIS_USER_BITS-1:0] ``PREFIX``_tuser

// Macros which expand to port maps:
	// Single stream or packed
	// tuser/null tuser/ignore tuser
// N.B. the multi macros are hardcoded because SV does not support variadic
// We could use a trick like http://ionipti.blogspot.com/2012/08/systemverilog-variable-argument-display.html to emulate this

`define AXIS_MAP_NO_USER(MOD_PREFIX, LOCAL_PREFIX) \
.``MOD_PREFIX``_tready(``LOCAL_PREFIX``_tready), \
.``MOD_PREFIX``_tvalid(``LOCAL_PREFIX``_tvalid), \
.``MOD_PREFIX``_tlast (``LOCAL_PREFIX``_tlast), \
.``MOD_PREFIX``_tkeep (``LOCAL_PREFIX``_tkeep), \
.``MOD_PREFIX``_tdata (``LOCAL_PREFIX``_tdata)


`define AXIS_MAP_TDEST(MOD_PREFIX, LOCAL_PREFIX) \
.``MOD_PREFIX``_tready(``LOCAL_PREFIX``_tready), \
.``MOD_PREFIX``_tvalid(``LOCAL_PREFIX``_tvalid), \
.``MOD_PREFIX``_tlast (``LOCAL_PREFIX``_tlast), \
.``MOD_PREFIX``_tkeep (``LOCAL_PREFIX``_tkeep), \
.``MOD_PREFIX``_tdata (``LOCAL_PREFIX``_tdata), \
.``MOD_PREFIX``_tdest (``LOCAL_PREFIX``_tdest)

`define AXIS_MAP_CHANNEL_NO_USER(MOD_PREFIX, LOCAL_PREFIX, CHANNEL) \
.``MOD_PREFIX``_tready(``LOCAL_PREFIX``_``CHANNEL``_tready), \
.``MOD_PREFIX``_tvalid(``LOCAL_PREFIX``_``CHANNEL``_tvalid), \
.``MOD_PREFIX``_tlast (``LOCAL_PREFIX``_``CHANNEL``_tlast), \
.``MOD_PREFIX``_tkeep (``LOCAL_PREFIX``_``CHANNEL``_tkeep), \
.``MOD_PREFIX``_tdata (``LOCAL_PREFIX``_``CHANNEL``_tdata)

`define AXIS_MAP(MOD_PREFIX, LOCAL_PREFIX) \
`AXIS_MAP_NO_USER(MOD_PREFIX, LOCAL_PREFIX), \
.``MOD_PREFIX``_tuser (``LOCAL_PREFIX``_tuser)

`define AXIS_MAP_NULL_USER(MOD_PREFIX, LOCAL_PREFIX) \
`AXIS_MAP_NO_USER(MOD_PREFIX, LOCAL_PREFIX), \
.``MOD_PREFIX``_tuser (1'b1)

`define AXIS_MAP_IGNORE_USER(MOD_PREFIX, LOCAL_PREFIX) \
`AXIS_MAP_NO_USER(MOD_PREFIX, LOCAL_PREFIX), \
.``MOD_PREFIX``_tuser ()

`define AXIS_MAP_2_NO_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2) \
.``MOD_PREFIX``_tready({``LOCAL_PREFIX_1``_tready, ``LOCAL_PREFIX_2``_tready}), \
.``MOD_PREFIX``_tvalid({``LOCAL_PREFIX_1``_tvalid, ``LOCAL_PREFIX_2``_tvalid}), \
.``MOD_PREFIX``_tlast ({``LOCAL_PREFIX_1``_tlast , ``LOCAL_PREFIX_2``_tlast }), \
.``MOD_PREFIX``_tkeep ({``LOCAL_PREFIX_1``_tkeep , ``LOCAL_PREFIX_2``_tkeep }), \
.``MOD_PREFIX``_tdata ({``LOCAL_PREFIX_1``_tdata , ``LOCAL_PREFIX_2``_tdata })

`define AXIS_MAP_2_NULL_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2) \
`AXIS_MAP_2_NO_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2), \
.``MOD_PREFIX``_tuser (2'b1)

`define AXIS_MAP_2_IGNORE_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2) \
`AXIS_MAP_2_NO_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2), \
.``MOD_PREFIX``_tuser ()

`define AXIS_MAP_3_NO_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3) \
.``MOD_PREFIX``_tready({``LOCAL_PREFIX_1``_tready, ``LOCAL_PREFIX_2``_tready, ``LOCAL_PREFIX_3``_tready}), \
.``MOD_PREFIX``_tvalid({``LOCAL_PREFIX_1``_tvalid, ``LOCAL_PREFIX_2``_tvalid, ``LOCAL_PREFIX_3``_tvalid}), \
.``MOD_PREFIX``_tlast ({``LOCAL_PREFIX_1``_tlast , ``LOCAL_PREFIX_2``_tlast , ``LOCAL_PREFIX_3``_tlast }), \
.``MOD_PREFIX``_tkeep ({``LOCAL_PREFIX_1``_tkeep , ``LOCAL_PREFIX_2``_tkeep , ``LOCAL_PREFIX_3``_tkeep }), \
.``MOD_PREFIX``_tdata ({``LOCAL_PREFIX_1``_tdata , ``LOCAL_PREFIX_2``_tdata , ``LOCAL_PREFIX_3``_tdata })

`define AXIS_MAP_3_NULL_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3) \
`AXIS_MAP_3_NO_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3), \
.``MOD_PREFIX``_tuser (3'b1)

`define AXIS_MAP_4_NO_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3, LOCAL_PREFIX_4) \
.``MOD_PREFIX``_tready({``LOCAL_PREFIX_1``_tready, ``LOCAL_PREFIX_2``_tready, ``LOCAL_PREFIX_3``_tready, ``LOCAL_PREFIX_4``_tready}), \
.``MOD_PREFIX``_tvalid({``LOCAL_PREFIX_1``_tvalid, ``LOCAL_PREFIX_2``_tvalid, ``LOCAL_PREFIX_3``_tvalid, ``LOCAL_PREFIX_4``_tvalid}), \
.``MOD_PREFIX``_tlast ({``LOCAL_PREFIX_1``_tlast , ``LOCAL_PREFIX_2``_tlast , ``LOCAL_PREFIX_3``_tlast , ``LOCAL_PREFIX_4``_tlast }), \
.``MOD_PREFIX``_tkeep ({``LOCAL_PREFIX_1``_tkeep , ``LOCAL_PREFIX_2``_tkeep , ``LOCAL_PREFIX_3``_tkeep , ``LOCAL_PREFIX_4``_tkeep }), \
.``MOD_PREFIX``_tdata ({``LOCAL_PREFIX_1``_tdata , ``LOCAL_PREFIX_2``_tdata , ``LOCAL_PREFIX_3``_tdata , ``LOCAL_PREFIX_4``_tdata })


`define AXIS_MAP_8_TDEST(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3, LOCAL_PREFIX_4, LOCAL_PREFIX_5, LOCAL_PREFIX_6, LOCAL_PREFIX_7, LOCAL_PREFIX_8) \
.``MOD_PREFIX``_tready({``LOCAL_PREFIX_1``_tready, ``LOCAL_PREFIX_2``_tready, ``LOCAL_PREFIX_3``_tready, ``LOCAL_PREFIX_4``_tready, ``LOCAL_PREFIX_5``_tready, ``LOCAL_PREFIX_6``_tready, ``LOCAL_PREFIX_7``_tready, ``LOCAL_PREFIX_8``_tready}), \
.``MOD_PREFIX``_tvalid({``LOCAL_PREFIX_1``_tvalid, ``LOCAL_PREFIX_2``_tvalid, ``LOCAL_PREFIX_3``_tvalid, ``LOCAL_PREFIX_4``_tvalid, ``LOCAL_PREFIX_5``_tvalid, ``LOCAL_PREFIX_6``_tvalid, ``LOCAL_PREFIX_7``_tvalid, ``LOCAL_PREFIX_8``_tvalid}), \
.``MOD_PREFIX``_tlast ({``LOCAL_PREFIX_1``_tlast , ``LOCAL_PREFIX_2``_tlast , ``LOCAL_PREFIX_3``_tlast , ``LOCAL_PREFIX_4``_tlast,  ``LOCAL_PREFIX_5``_tlast , ``LOCAL_PREFIX_6``_tlast , ``LOCAL_PREFIX_7``_tlast , ``LOCAL_PREFIX_8``_tlast }), \
.``MOD_PREFIX``_tkeep ({``LOCAL_PREFIX_1``_tkeep , ``LOCAL_PREFIX_2``_tkeep , ``LOCAL_PREFIX_3``_tkeep , ``LOCAL_PREFIX_4``_tkeep,  ``LOCAL_PREFIX_5``_tkeep , ``LOCAL_PREFIX_6``_tkeep , ``LOCAL_PREFIX_7``_tkeep , ``LOCAL_PREFIX_8``_tkeep }), \
.``MOD_PREFIX``_tdata ({``LOCAL_PREFIX_1``_tdata , ``LOCAL_PREFIX_2``_tdata , ``LOCAL_PREFIX_3``_tdata , ``LOCAL_PREFIX_4``_tdata,  ``LOCAL_PREFIX_5``_tdata , ``LOCAL_PREFIX_6``_tdata , ``LOCAL_PREFIX_7``_tdata , ``LOCAL_PREFIX_8``_tdata }), \
.``MOD_PREFIX``_tdest ({``LOCAL_PREFIX_1``_tdest , ``LOCAL_PREFIX_2``_tdest , ``LOCAL_PREFIX_3``_tdest , ``LOCAL_PREFIX_4``_tdest,  ``LOCAL_PREFIX_5``_tdest , ``LOCAL_PREFIX_6``_tdest , ``LOCAL_PREFIX_7``_tdest , ``LOCAL_PREFIX_8``_tdest })

`define AXIS_MAP_4_NULL_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3, LOCAL_PREFIX_4) \
`AXIS_MAP_4_NO_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3, LOCAL_PREFIX_4), \
.``MOD_PREFIX``_tuser (4'b1)

`define AXIS_MAP_4_IGNORE_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3, LOCAL_PREFIX_4) \
`AXIS_MAP_4_IGNORE_USER(MOD_PREFIX, LOCAL_PREFIX_1, LOCAL_PREFIX_2, LOCAL_PREFIX_3, LOCAL_PREFIX_4), \
.``MOD_PREFIX``_tuser ()

//////////////////////////////////////////
// AXI
///////////////////////////////////////////


`define S_AXI_PORT(PREFIX, AXI_BYTES, AXI_WIDTH) \
input logic [AXI_WIDTH-1 : 0] 			``PREFIX``_awaddr, \
input logic [2 : 0] 						``PREFIX``_awprot, \
input logic 								``PREFIX``_awvalid, \
output logic 								``PREFIX``_awready, \
input logic [(AXI_BYTES*8)-1 : 0]			``PREFIX``_wdata, \
input logic [((AXI_BYTES*8)/8)-1 : 0] 		``PREFIX``_wstrb, \
input logic 								``PREFIX``_wvalid, \
output logic 								``PREFIX``_wready, \
output logic [1 : 0] 						``PREFIX``_bresp, \
output logic 								``PREFIX``_bvalid, \
input logic 								``PREFIX``_bready, \
input logic [AXI_WIDTH-1 : 0]			``PREFIX``_araddr, \
input logic [2 : 0] 						``PREFIX``_arprot, \
input logic  								``PREFIX``_arvalid, \
output logic  								``PREFIX``_arready, \
output logic  [(AXI_BYTES*8)-1 : 0]			``PREFIX``_rdata, \
output logic  [1 : 0]						``PREFIX``_rresp, \
output logic  								``PREFIX``_rvalid, \
input logic 								``PREFIX``_rready



`define AXI_MAP(MOD_PREFIX, LOCAL_PREFIX) \
.``MOD_PREFIX``_awaddr (``LOCAL_PREFIX``_awaddr), \
.``MOD_PREFIX``_awprot (``LOCAL_PREFIX``_awprot), \
.``MOD_PREFIX``_awvalid(``LOCAL_PREFIX``_awvalid), \
.``MOD_PREFIX``_awready(``LOCAL_PREFIX``_awready), \
.``MOD_PREFIX``_wdata  (``LOCAL_PREFIX``_wdata), \
.``MOD_PREFIX``_wstrb  (``LOCAL_PREFIX``_wstrb), \
.``MOD_PREFIX``_wvalid (``LOCAL_PREFIX``_wvalid), \
.``MOD_PREFIX``_wready (``LOCAL_PREFIX``_wready), \
.``MOD_PREFIX``_bresp  (``LOCAL_PREFIX``_bresp), \
.``MOD_PREFIX``_bvalid (``LOCAL_PREFIX``_bvalid), \
.``MOD_PREFIX``_bready (``LOCAL_PREFIX``_bready), \
.``MOD_PREFIX``_araddr (``LOCAL_PREFIX``_araddr), \
.``MOD_PREFIX``_arprot (``LOCAL_PREFIX``_arprot), \
.``MOD_PREFIX``_arvalid(``LOCAL_PREFIX``_arvalid), \
.``MOD_PREFIX``_arready(``LOCAL_PREFIX``_arready), \
.``MOD_PREFIX``_rdata  (``LOCAL_PREFIX``_rdata), \
.``MOD_PREFIX``_rresp  (``LOCAL_PREFIX``_rresp), \
.``MOD_PREFIX``_rvalid (``LOCAL_PREFIX``_rvalid), \
.``MOD_PREFIX``_rready (``LOCAL_PREFIX``_rready)


`endif