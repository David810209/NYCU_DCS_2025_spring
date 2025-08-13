module VM(
    input wire clk,
    input wire rst_n,
    input wire in_price_valid,
    input wire in_coin_valid,
    input wire [4:0] in_price,
    input wire [5:0] in_coin,
    input wire in_refund_coin,
    input wire [2:0] in_buy_item,
    output reg out_valid,
    output reg [3:0] out_result,
    output reg [5:0] out_num
);
//==================================================================
// parameter & integer
//==================================================================
localparam  IDLE = 2'b00;
localparam  INPUT = 2'b01;
localparam  OUTPUT = 2'b10;

/*
A = [10,20,23,25,28]
B = [5,6,7,8,9]
assign C[0] = A[0] * B[0];
assign C[1] = A[1] * B[1];
assign C[2] = A[2] * B[2];
assign C[3] = A[3] * B[3];
assign C[4] = A[4] * B[4];

// c code
C[0] = A[0] * B[0];
C[1] = A[1] * B[1]; 
C[2] = A[2] * B[2];
C[3] = A[3] * B[3];
C[4] = A[4] * B[4];
*/

integer i;
//==================================================================
// Regs declartion
//==================================================================
reg [1:0] state, next_state;
reg [4:0] price[0:6];
reg [5:0] buy_cnt[0:5];
reg [2:0] input_cnt;
reg [8:0] current_money;

reg [2:0] output_cnt;
reg [2:0] in_buy_item_reg;

reg insufficient_coin_reg;

reg not_refund_coin;

reg [3:0] div_result_50_reg, div_result_20_reg, div_result_10_reg, div_result_5_reg, rem_result_5_reg;
//==================================================================
// Wires declartion
//==================================================================
wire insufficient_coin;
wire [4:0] item_price;
wire [5:0] rem_result_50 , rem_result_20, rem_result_10, rem_result_5;
wire [3:0] div_result_50, div_result_20, div_result_10, div_result_5;
//==================================================================
// Design
//==================================================================
// FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case (state)
        IDLE: next_state = in_coin_valid ? INPUT : IDLE;
        INPUT: next_state = !in_coin_valid ? OUTPUT : INPUT;
        OUTPUT: next_state = output_cnt == 3'd5 ? IDLE : OUTPUT;
        default: next_state = IDLE;
    endcase
end

// input_cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) input_cnt <= 0;
    else if(state == IDLE && in_price_valid) input_cnt <= input_cnt + 1;
    else  input_cnt <= 0;
end

// price
always @(posedge clk) begin
    price[0] <= 0;
    if(state == IDLE && in_price_valid) price[input_cnt + 1] <= in_price;
end

// buy_cnt
always @(posedge clk) begin
    if(state == IDLE && in_price_valid) for(i = 0; i < 6; i = i + 1) buy_cnt[i] <= 0;
    else if(state == INPUT && !in_coin_valid && !insufficient_coin && !in_refund_coin) buy_cnt[in_buy_item-1] <= buy_cnt[in_buy_item-1] + 1;
end

// current_money

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) current_money <= 0;
    else if(next_state == INPUT) current_money <= current_money + in_coin;
    else if(state == INPUT && !in_coin_valid && !insufficient_coin) current_money <= current_money - item_price;
    else if(state == IDLE && !not_refund_coin) current_money <= 0;
    else current_money <= current_money; 
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) in_buy_item_reg <= 0;
    else in_buy_item_reg <= in_buy_item;
end

assign item_price = price[in_buy_item];
assign insufficient_coin = current_money < item_price;

div_rem div_rem_50 (.current_money(current_money), .div_num(6'd50), .div_result(div_result_50), .rem_result(rem_result_50));
div_rem div_rem_20 (.current_money({3'b0, rem_result_50}), .div_num(6'd20), .div_result(div_result_20), .rem_result(rem_result_20));
div_rem div_rem_10 (.current_money({3'b0, rem_result_20}), .div_num(6'd10), .div_result(div_result_10), .rem_result(rem_result_10));
div_rem div_rem_5 (.current_money({3'b0, rem_result_10}), .div_num(6'd5), .div_result(div_result_5), .rem_result(rem_result_5));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div_result_50_reg <= 0;
        div_result_20_reg <= 0;
        div_result_10_reg <= 0;
        div_result_5_reg <= 0;
        rem_result_5_reg <= 0;
    end
    else   begin
        div_result_50_reg <= div_result_50;
        div_result_20_reg <= div_result_20;
        div_result_10_reg <= div_result_10;
        div_result_5_reg <= div_result_5;
        rem_result_5_reg <= rem_result_5[3:0];
    end
end
// insufficient_coin_reg

always @(posedge clk) begin
    if(state == INPUT) insufficient_coin_reg <= insufficient_coin;
    else insufficient_coin_reg <= insufficient_coin_reg;
end

// not_refund_coin
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) not_refund_coin <= 0;
    else if(state == INPUT && !in_coin_valid && insufficient_coin) not_refund_coin <= 1;
    else if(state == INPUT && !in_coin_valid && !insufficient_coin) not_refund_coin <= 0;
    else not_refund_coin <= not_refund_coin;
end

//output_cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) output_cnt <= 0;
    else if(state == OUTPUT) output_cnt <= output_cnt + 1;
    else output_cnt <= 0;
end

// out_num
always @(*) begin
    if(!rst_n) out_num = 0;
    else out_num = buy_cnt[output_cnt];
end

// out_result
always @(*) begin
    if(insufficient_coin_reg) out_result = 0;
    else begin
        case(output_cnt) 
            0: out_result = in_buy_item_reg;
            1: out_result = div_result_50_reg;
            2: out_result = div_result_20_reg;
            3: out_result = div_result_10_reg;
            4: out_result = div_result_5_reg;
            5: out_result = rem_result_5_reg;
            default: out_result = 0;
    endcase
    end
end

// out_valid
always @(*) begin
    if(state == OUTPUT) out_valid = 1;
    else out_valid = 0;
end

endmodule

module div_rem(
    input [8:0] current_money,
    input [5:0] div_num,
    output [3:0] div_result,
    output [5:0] rem_result
)
;
    assign div_result = current_money / div_num;
    assign rem_result = current_money % div_num;

endmodule