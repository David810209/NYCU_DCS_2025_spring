//############################################################################
//   2025 Digital Circuit and System Lab
//   Lab05       : Nonlinear function
//   Author      : Ceres Lab 2025 MS1
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Date        : 2025/03/03
//   Version     : v1.0
//   File Name   : nonlinear.v
//   Module Name : nonlinear
//############################################################################
//==============================================//
//           Top CPU Module Declaration         //
//==============================================//
module nonlinear(
	// Input Ports
    clk,
    rst_n,
    in_valid,
    mode,
    data_in,
    // Output Ports
    out_valid,
    data_out
);
					
input clk;
input rst_n;
input in_valid;
input mode;
input [31:0] data_in;

output reg out_valid;
output reg [31:0] data_out;

//Do not modify IEEE floating point parameter
parameter FP_ONE = 32'h3f800000;        // This is " 1.0 " in IEEE754 single precision
parameter FP_ZERO = 32'h00000000;       // This is " 0.0 " in IEEE754 single precision

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
//Do not modify IEEE floating point parameter

// start your design 
// stage  1 mul
reg [inst_sig_width + inst_exp_width : 0] mul_inst_a_1, mul_inst_b_1;
wire [inst_sig_width + inst_exp_width : 0] mul_inst_z_1;
reg mul_done;
reg mode_reg_1;

//stage 2 exp
reg exp_done;
reg [inst_sig_width + inst_exp_width : 0] exp_inst_a;
wire [inst_sig_width + inst_exp_width : 0] exp_inst_z;
reg mode_reg_2;

//stage 3 add/sub
reg [inst_sig_width + inst_exp_width : 0] add_inst_a_1, sub_inst_a_1;
reg [inst_sig_width + inst_exp_width : 0] add_inst_b_1, sub_inst_b_1;
wire [inst_sig_width + inst_exp_width : 0] add_inst_z_1, sub_inst_z_1;
reg add_done;
reg sub_done;
reg mode_reg_3;

// stage 4 div
reg [inst_sig_width + inst_exp_width : 0] div_inst_a_1, div_inst_b_1;
wire [inst_sig_width + inst_exp_width : 0] div_inst_z_1;
reg div_done;

//done loglc
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mul_done <= 0;
        exp_done <= 0;
        add_done <= 0;
        div_done <= 0;
    end
    else begin
        mul_done <= in_valid;
        exp_done <= mul_done;
        add_done <= exp_done;
        div_done <= add_done;
    end
end

// stage  1 mul
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mul_inst_a_1 <= 0;
        mul_inst_b_1 <= 0;
        mode_reg_1 <= 0;
    end
    else begin
        if(in_valid) begin
            mul_inst_a_1 <= data_in;
            mul_inst_b_1 <= (mode) ? 32'h40000000 : 32'hBF800000; 
            // 2 = 32'h40000000 , -1 = 32'hBF800000
            mode_reg_1 <= mode;
        end
        else begin
            mul_inst_a_1 <= 0;
            mul_inst_b_1 <= 0;
            mode_reg_1 <= 0;
        end
    end
end

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
FP_mult_1 (
    .a(mul_inst_a_1),
    .b(mul_inst_b_1),
    .z(mul_inst_z_1),
    .rnd(3'b0)
);

// stage 2 exp
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exp_inst_a <= 0;
        mode_reg_2 <= 0;
    end
    else begin
        exp_inst_a <= mul_inst_z_1;
        mode_reg_2 <= mode_reg_1;
    end
end

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
DW_fp_exp (
    .a(exp_inst_a),
    .z(exp_inst_z)
);

// stage 3 add/sub
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_inst_a_1 <= 0;
        add_inst_b_1 <= 0;
        mode_reg_3 <= 0;
    end
    else begin
        add_inst_a_1 <= exp_inst_z;
        add_inst_b_1 <= 32'h3f800000; // 1.0
        mode_reg_3 <= mode_reg_2;
    end
end

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
FP_add_1 (
    .a(add_inst_a_1),
    .b(add_inst_b_1),
    .z(add_inst_z_1),
    .rnd(3'b0)
);


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sub_inst_a_1 <= 0;
        sub_inst_b_1 <= 0;
    end
    else begin
        sub_inst_a_1 <= exp_inst_z;
        sub_inst_b_1 <= 32'h3f800000; // 1.0
        sub_done <= 1;
    end
end

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
FP_sub_1 (
    .a(sub_inst_a_1),
    .b(sub_inst_b_1),
    .z(sub_inst_z_1),
    .rnd(3'b0)
);

// stage 4 div
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div_inst_a_1 <= 0;
        div_inst_b_1 <= 0;
    end
    else begin
        div_inst_a_1 <= (mode_reg_3) ? sub_inst_z_1 : 32'h3f800000;
        div_inst_b_1 <= add_inst_z_1;
    end
end

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
FP_div_1 (
    .a(div_inst_a_1),
    .b(div_inst_b_1),
    .z(div_inst_z_1),
    .rnd(3'b0)
);


// output 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        data_out <= 0;
    end
    else begin
        if(div_done) begin
            out_valid <= 1;
            data_out <= div_inst_z_1;
        end
        else begin
            out_valid <= 0;
            data_out <= 0;
        end
    end
end

endmodule
// reg [31:0] A;
// A[31]       -->    sign bit    
// A[30:23]    -->    exponent
// A[22:0]     -->    significand/mantissa  