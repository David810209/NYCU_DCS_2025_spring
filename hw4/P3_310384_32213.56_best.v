//############################################################################
//   2025 Digital Circuit and System Lab
//   HW04        : Simplified Direct Memory Access
//   Author      : Ceres Lab 2025 MS1
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Date        : 2025/04/19
//   Version     : v1.0
//   File Name   : SDMA.v
//   Module Name : SDMA
//############################################################################
//==============================================//
//           Top DMA Module Declaration         //
//==============================================//
// 9.66235 E14
module SDMA(
	// SDMA IO 
	clk            	,	
	rst_n          	,	
	pat_valid       ,	
	pat_ready       ,
    cmd             ,	

    sdma_valid     	,
    sdma_ready      ,    
	dout			,

	// AXI4 IO
    awaddr_m_inf    ,
    awvalid_m_inf   ,
    awready_m_inf   ,
                
    wdata_m_inf     ,
    wvalid_m_inf    ,
    wready_m_inf    ,
                
    
    bresp_m_inf     ,
    bvalid_m_inf    ,
    bready_m_inf    ,
                
    araddr_m_inf    ,
    arvalid_m_inf   ,         
    arready_m_inf   , 
    
    rdata_m_inf     ,
    rvalid_m_inf    ,
    rready_m_inf 
);
// ===============================================================
//  			   		Parameters
// ===============================================================
parameter ADDR_WIDTH = 32;      // Do not modify
parameter DATA_WIDTH = 128;     // Do not modify


// ===============================================================
//  					Input / Output 
// ===============================================================
// << SDMA io port with system >>					
input clk, rst_n;
input pat_valid, pat_ready;
input [31:0] cmd;

output reg sdma_valid, sdma_ready;
output reg [7:0] dout;

// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     awaddr_m_inf;
output reg                      awvalid_m_inf;
// 		src slave   
input  wire                      awready_m_inf;
// -----------------------------

// (2)	axi write data channel 
// 		src master
output reg [DATA_WIDTH-1:0]  wdata_m_inf;
output reg                   wvalid_m_inf;
// 		src slave
input  wire                   wready_m_inf;

// (3)	axi write response channel 
// 		src slave
input  wire  [1:0]            bresp_m_inf;
input  wire                   bvalid_m_inf;
// 		src master 
output reg                   bready_m_inf;
// -----------------------------

// (4)	axi read address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     araddr_m_inf;
output reg                      arvalid_m_inf;
// 		src slave
input  wire                      arready_m_inf;
// -----------------------------

// (5)	axi read data channel 
// 		src slave
input wire [DATA_WIDTH-1:0]      rdata_m_inf;
input wire                       rvalid_m_inf;
// 		src master
output reg                      rready_m_inf;

// ===============================================================
//  					Signal Declaration 
// ===============================================================
localparam IDLE = 3'b00,
            READ = 3'b001, 
            WRITE = 3'b010,
            WAIT_READ = 3'b011,
            WAIT_WRITE = 3'b100,
            WAIT_PAT = 3'b101;

reg [2:0] state , next_state;

reg [127:0] dram_data_buffer;

reg [31:0] cmd_buffer;
reg [7:0] addr_buffer;
wire op;
wire [3:0] word_byte_offset;
wire [7:0] data;

wire [7:0] addr_9_2;;
wire [31:0] addr_to_dram; 
reg [127:0] data_to_dram;

reg has_wready_m_inf, has_awready_m_inf;

wire cache_hit;
// ===============================================================
//  					Start Your Design
// ===============================================================

//FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case(state)
        IDLE: begin
            if(pat_valid) begin
                if(cache_hit) next_state = cmd[31] ? WRITE : WAIT_PAT;
                else next_state = READ;
            end
            else next_state = IDLE;
        end
        READ: begin
            if(arready_m_inf) next_state = WAIT_READ;
            else next_state = READ;
        end
        WRITE: begin
            if(has_wready_m_inf && has_awready_m_inf) next_state = WAIT_WRITE;
            else next_state = WRITE;
        end
        WAIT_READ: begin
            if(rvalid_m_inf) next_state = (op) ? WRITE : WAIT_PAT;
            else next_state = WAIT_READ;
        end
        WAIT_WRITE: begin
            if(bvalid_m_inf) next_state = WAIT_PAT;
            else next_state = WAIT_WRITE;
        end
        WAIT_PAT: begin
            if(pat_ready) next_state = IDLE;
            else next_state = WAIT_PAT;
        end
        default: next_state = IDLE;
    endcase
end
// cmd_buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cmd_buffer <= 32'b0;
    else if(state == IDLE && pat_valid) cmd_buffer <= cmd;
    else cmd_buffer <= cmd_buffer;
end

// operation decoder
assign op = cmd_buffer[31];
assign data = cmd_buffer[7:0];
assign word_byte_offset = cmd_buffer[22:19];
assign addr_9_2 = cmd_buffer[30:23];
assign addr_to_dram = state == IDLE ? {20'b0, 2'b10, cmd[30:23], 2'b00} : {20'b0, 2'b10, addr_9_2, 2'b00};

always @(*) begin
    data_to_dram = dram_data_buffer;
    data_to_dram[word_byte_offset * 8 +: 8] = data;
end

// dram_data_buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) dram_data_buffer <= 128'b0;
    else if(state == WAIT_READ && rvalid_m_inf)dram_data_buffer <= rdata_m_inf;
    else if(state == WAIT_WRITE) dram_data_buffer <= data_to_dram;
    else dram_data_buffer <= dram_data_buffer;
end
//addr_buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_buffer <= 8'b0;
    else if(state == WAIT_READ && rvalid_m_inf) addr_buffer <= addr_9_2;
    else addr_buffer <= addr_buffer;
end

assign cache_hit = (addr_buffer == cmd[30:23]) ? 1'b1 : 1'b0;


// << SDMA io port with system >>	
always @(*) begin
    sdma_ready = state == IDLE;
end
// sdma_valid
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) sdma_valid <= 1'b0;
    else if(state == WAIT_WRITE && bvalid_m_inf) sdma_valid <= 1'b1;
    else if(state == WAIT_PAT && !pat_ready) sdma_valid <= 1'b1;
    else sdma_valid <= 1'b0;
end

// sdma dout

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) dout <= 8'b0;
    else if((state == IDLE && pat_valid && cache_hit) || (state == WAIT_PAT && !pat_ready)) begin
        case (word_byte_offset)
            0: dout <= dram_data_buffer[7:0];
            1: dout <= dram_data_buffer[15:8];
            2: dout <= dram_data_buffer[23:16];
            3: dout <= dram_data_buffer[31:24];
            4: dout <= dram_data_buffer[39:32];
            5: dout <= dram_data_buffer[47:40];
            6: dout <= dram_data_buffer[55:48];
            7: dout <= dram_data_buffer[63:56];
            8: dout <= dram_data_buffer[71:64];
            9: dout <= dram_data_buffer[79:72];
            10: dout <= dram_data_buffer[87:80];
            11: dout <= dram_data_buffer[95:88];
            12: dout <= dram_data_buffer[103:96];
            13: dout <= dram_data_buffer[111:104];
            14: dout <= dram_data_buffer[119:112];
            15: dout <= dram_data_buffer[127:120];
            default: dout <= 8'b0;
        endcase
    end
    else if(state == WAIT_PAT && !pat_ready)  dout <= dout;
    else dout <= 8'b0;
end

// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) awvalid_m_inf <= 1'b0;
    else if(state == WRITE && ((!awready_m_inf && !has_awready_m_inf))) awvalid_m_inf <= 1'b1;
    else awvalid_m_inf <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) awaddr_m_inf <= 32'b0;
    else if(state == WRITE) awaddr_m_inf <= addr_to_dram;
    else awaddr_m_inf <= 32'b0;
end
// (2)	axi write data channel 
// 		src master

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wvalid_m_inf <= 1'b0;
    else if(state == WRITE && (!has_wready_m_inf && !wready_m_inf))  wvalid_m_inf <= 1'b1;
    else wvalid_m_inf <= 1'b0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wdata_m_inf <= 128'b0;
    else if(state == WRITE) wdata_m_inf <= data_to_dram;
    else wdata_m_inf <= 128'b0;
end

// (3)	axi write response channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) bready_m_inf <= 1'b0;
    else if(state == WAIT_WRITE && bvalid_m_inf) bready_m_inf <= 1'b1;
    else bready_m_inf <= 1'b0;
end

// (4)	axi read address channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) arvalid_m_inf <= 1'b0;
    else if(next_state == READ) arvalid_m_inf <= 1'b1;
    else arvalid_m_inf <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) araddr_m_inf <= 32'b0;
    else if(next_state == READ) araddr_m_inf <= addr_to_dram;
    else araddr_m_inf <= 32'b0;
end

// (5)	axi read data channel

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rready_m_inf <= 1'b0;
    else if(next_state == WAIT_READ) rready_m_inf <= 1'b1;
    else rready_m_inf <= 1'b0;
end

// has_wready_m_inf
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  has_wready_m_inf <= 1'b0;
    else if(state == WRITE) begin
        if(wready_m_inf) has_wready_m_inf <= 1'b1;
        else has_wready_m_inf <= has_wready_m_inf;
    end
    else has_wready_m_inf <= 1'b0;
end
// has_awready_m_inf
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  has_awready_m_inf <= 1'b0;
    else if(state == WRITE) begin
        if(awready_m_inf) has_awready_m_inf <= 1'b1;
        else has_awready_m_inf <= has_awready_m_inf;
    end
    else has_awready_m_inf <= 1'b0;
end



endmodule
