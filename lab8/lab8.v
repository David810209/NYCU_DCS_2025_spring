module SRAM_Controller(
    input           clk,
    input           rst_n,
    input           in_valid,
    input   [7:0]   in_data,
    input           addr_valid,
    input   [5:0]   addr,
    output  reg        out_valid,
    output  reg [31:0]  out_data
);

//==================================================================
// SRAM
//==================================================================
wire        SRAM_64X32_CLK; // SRAM Clock
wire        SRAM_64X32_CS;  // SRAM Chip Select
wire        SRAM_64X32_OE;  // SRAM Output Enable
wire        SRAM_64X32_WE;  // SRAM Write Enable
wire [5:0]  SRAM_64X32_A;   // SRAM address
wire [31:0] SRAM_64X32_DI;  // SRAM Data In
wire [31:0] SRAM_64X32_DO;  // SRAM Data Out

SRAM_64_32  SRAM_64_32_inst  (
    .CLK    (SRAM_64X32_CLK ),
    .CS     (SRAM_64X32_CS  ),
    .OE     (SRAM_64X32_OE  ),
    .WEB    (!SRAM_64X32_WE ),
    .A      (SRAM_64X32_A   ),
    .DI     (SRAM_64X32_DI  ),
    .DO     (SRAM_64X32_DO  )
);

//==================================================================
// parameter & integer
//==================================================================
localparam write = 0;
localparam read = 1;
localparam delay1 = 2;
localparam response = 3;

//==================================================================
// Regs
//==================================================================

reg [1:0] state, next_state;
reg [1:0] each_read_cnt;
reg [6:0] write_addr_cnt;

reg [5:0] sram_addr_reg;
reg sram_we_reg;
reg [31:0] sram_in_data_reg;
//==================================================================
// Wires
//==================================================================
assign SRAM_64X32_CLK   = clk;
assign SRAM_64X32_CS    = 1'b1;
assign SRAM_64X32_OE    = 1'b1;
assign SRAM_64X32_WE    = sram_we_reg;
assign SRAM_64X32_A     = sram_addr_reg;
assign SRAM_64X32_DI    = sram_in_data_reg;

//==================================================================
// Design
//==================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= write;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case(state)
        write: begin
            if(write_addr_cnt == 64) begin
                next_state = read;
            end else begin
                next_state = write;
            end
        end
        read: begin
            if(addr_valid) begin
                next_state = delay1;
            end else begin
                next_state = read;
            end
        end
        delay1: begin
            next_state = response;
        end
        response: begin
                next_state = read;
        end
        default: next_state = read;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        each_read_cnt <= 0;
    end else if(in_valid) begin
        each_read_cnt <= each_read_cnt + 1;
    end else begin
        each_read_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_addr_cnt <= 0;
    end else if(each_read_cnt == 3) begin
        write_addr_cnt <= write_addr_cnt + 1;
    end else begin
        write_addr_cnt <= write_addr_cnt;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sram_addr_reg <= 0;
    end else if(state == write && each_read_cnt == 3) begin
        sram_addr_reg <= write_addr_cnt;
    end else if(state == read) begin
        sram_addr_reg <= addr;
    end else begin
        sram_addr_reg <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sram_in_data_reg <= 0;
    end else if(state == write && in_valid) begin
        sram_in_data_reg <= {in_data, sram_in_data_reg[31:8]};
    end else begin
        sram_in_data_reg <= sram_in_data_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sram_we_reg <= 0;
    end else if(state == write && each_read_cnt == 3 ) begin
        sram_we_reg <= 1;
    end  else begin
        sram_we_reg <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_data <= 0;
    end else if(state == response) begin
        out_data <= SRAM_64X32_DO;
    end else begin
        out_data <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end else if(state == response) begin
        out_valid <= 1;
    end else begin
        out_valid <= 0;
    end
end

endmodule

module SRAM_64_32 (
    input CLK, CS, OE, WEB,
    input [5:0]  A,
    input [31:0] DI,
    output[31:0] DO
);
SRAM_64X32 SRAM_64X32_inst (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  .DO12(DO[12]),  .DO13(DO[13]),  .DO14(DO[14]),  .DO15(DO[15]), 
    .DO16(DO[16]),  .DO17(DO[17]),  .DO18(DO[18]),  .DO19(DO[19]),  .DO20(DO[20]),  .DO21(DO[21]),  .DO22(DO[22]),  .DO23(DO[23]), 
    .DO24(DO[24]),  .DO25(DO[25]),  .DO26(DO[26]),  .DO27(DO[27]),  .DO28(DO[28]),  .DO29(DO[29]),  .DO30(DO[30]),  .DO31(DO[31]),
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  .DI12(DI[12]),  .DI13(DI[13]),  .DI14(DI[14]),  .DI15(DI[15]), 
    .DI16(DI[16]),  .DI17(DI[17]),  .DI18(DI[18]),  .DI19(DI[19]),  .DI20(DI[20]),  .DI21(DI[21]),  .DI22(DI[22]),  .DI23(DI[23]), 
    .DI24(DI[24]),  .DI25(DI[25]),  .DI26(DI[26]),  .DI27(DI[27]),  .DI28(DI[28]),  .DI29(DI[29]),  .DI30(DI[30]),  .DI31(DI[31]),
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule
