module CNN(
    input                       clk,
    input                       rst_n,
    input                       in_valid,
    input                       mode,
    input       signed  [7:0]   in_data_ch1,
    input       signed  [7:0]   in_data_ch2,
    input       signed  [7:0]   kernel_ch1,
    input       signed  [7:0]   kernel_ch2,
    input       signed  [7:0]   weight,
    output reg                  out_valid,
    output reg  signed  [19:0]  out_data
);

//==================================================================
// parameter & integer
//==================================================================
integer i;

//==================================================================
// Regs
//==================================================================
reg [6:0] input_cnt;

reg signed [7:0] image[0:3];
reg signed [7:0] weight_arr_reg0, weight_arr_reg1, weight_arr_reg2, weight_arr_reg3,
                    weight_arr_reg4, weight_arr_reg5, weight_arr_reg6, weight_arr_reg7,
                    weight_arr_reg8, weight_arr_reg9, weight_arr_reg10, weight_arr_reg11,
                    weight_arr_reg12, weight_arr_reg13, weight_arr_reg14, weight_arr_reg15;
reg [2:0] fcn_in_cnt;
reg [2:0] fcn_calc_cnt;

reg signed [7:0] weight_arr[0:31];

reg signed [7:0] img_reg0, img_reg1, img_reg2, img_reg3;

reg signed [15:0] tmp_mul_result[0:15];
reg signed [16:0] tmp_add_result1[0:7];
reg signed [17:0] tmp_add_result2[0:3];
reg signed [19:0] out_result[0:3]; 

reg [1:0] out_cnt;

reg [1:0] compute_status, compute_status_next; // 0 idle, 1 first half, 2 second half, 3 output
//==================================================================
// Wires
//==================================================================
wire [7:0]  conv_out_ch1;
wire conv_out_valid_ch1;

//==================================================================
// Design
//==================================================================

// Input Counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        input_cnt <= 0;
    end else if(in_valid) begin
        input_cnt <= input_cnt + 1;
    end else  begin
        input_cnt <= 0;
    end
end

// weight buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 32; i = i + 1) begin
            weight_arr[i] <= 0;
        end
    end else if(in_valid && input_cnt < 32) begin
        weight_arr[input_cnt] <= weight;
    end
end

always @(posedge clk) begin
    if(compute_status == 1) begin
        weight_arr_reg0 <= weight_arr[0];
        weight_arr_reg1 <= weight_arr[1];
        weight_arr_reg2 <= weight_arr[2];
        weight_arr_reg3 <= weight_arr[3];
        weight_arr_reg4 <= weight_arr[8];
        weight_arr_reg5 <= weight_arr[9];
        weight_arr_reg6 <= weight_arr[10];
        weight_arr_reg7 <= weight_arr[11];
        weight_arr_reg8 <= weight_arr[16];
        weight_arr_reg9 <= weight_arr[17];
        weight_arr_reg10 <= weight_arr[18];
        weight_arr_reg11 <= weight_arr[19];
        weight_arr_reg12 <= weight_arr[24];
        weight_arr_reg13 <= weight_arr[25];
        weight_arr_reg14 <= weight_arr[26];
        weight_arr_reg15 <= weight_arr[27];
    end
    else if(compute_status == 2) begin 
        weight_arr_reg0 <= weight_arr[4];
        weight_arr_reg1 <= weight_arr[5];
        weight_arr_reg2 <= weight_arr[6];
        weight_arr_reg3 <= weight_arr[7];
        weight_arr_reg4 <= weight_arr[12];
        weight_arr_reg5 <= weight_arr[13];
        weight_arr_reg6 <= weight_arr[14];
        weight_arr_reg7 <= weight_arr[15];
        weight_arr_reg8 <= weight_arr[20];
        weight_arr_reg9 <= weight_arr[21];
        weight_arr_reg10 <= weight_arr[22];
        weight_arr_reg11 <= weight_arr[23];
        weight_arr_reg12 <= weight_arr[28];
        weight_arr_reg13 <= weight_arr[29];
        weight_arr_reg14 <= weight_arr[30];
        weight_arr_reg15 <= weight_arr[31];
    end
end

always @(posedge clk) begin
    img_reg0 <= image[0];
    img_reg1 <= image[1];
    img_reg2 <= image[2];
    img_reg3 <= image[3];
end

// INPUT FROM CONV_LAYER
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 8; i = i + 1) begin
            image[i] <= 0;
        end
    end else if(conv_out_valid_ch1) begin
        image[fcn_in_cnt[1:0]] <= conv_out_ch1;
    end
end

// fcn_in_cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fcn_in_cnt <= 0;
    end else if(conv_out_valid_ch1) begin
        fcn_in_cnt <= fcn_in_cnt + 1;
    end 
    else begin
        fcn_in_cnt <= fcn_in_cnt;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) compute_status <= 0;
    else compute_status <= compute_status_next;
end

// compute_status
always @(*) begin
    case ( compute_status )
        0 :  compute_status_next = (fcn_in_cnt == 3) ? 1 : (fcn_in_cnt == 7) ? 2 : 0;
        1 :  compute_status_next = (fcn_calc_cnt == 4) ? 0 : 1;
        2 :  compute_status_next = (fcn_calc_cnt == 4) ? 3 : 2;
        3 :  compute_status_next = (out_cnt == 3) ? 0 : 3;
        default: compute_status_next = 0;
    endcase
end

// multiply
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 15; i = i + 1) begin
            tmp_mul_result[i] <= 0;
        end
    end else   begin
        tmp_mul_result[0] <= img_reg0 * weight_arr_reg0;
        tmp_mul_result[1] <= img_reg1 * weight_arr_reg1;
        tmp_mul_result[2] <= img_reg2 * weight_arr_reg2;
        tmp_mul_result[3] <= img_reg3 * weight_arr_reg3;

        tmp_mul_result[4] <= img_reg0 * weight_arr_reg4;
        tmp_mul_result[5] <= img_reg1 * weight_arr_reg5;
        tmp_mul_result[6] <= img_reg2 * weight_arr_reg6;
        tmp_mul_result[7] <= img_reg3 * weight_arr_reg7;
        tmp_mul_result[8] <= img_reg0 * weight_arr_reg8;
        tmp_mul_result[9] <= img_reg1 * weight_arr_reg9;
        tmp_mul_result[10] <= img_reg2 * weight_arr_reg10;
        tmp_mul_result[11] <= img_reg3 * weight_arr_reg11;
        tmp_mul_result[12] <= img_reg0 * weight_arr_reg12;
        tmp_mul_result[13] <= img_reg1 * weight_arr_reg13;
        tmp_mul_result[14] <= img_reg2 * weight_arr_reg14;
        tmp_mul_result[15] <= img_reg3 * weight_arr_reg15;
    end
end

// add 1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 8; i = i + 1) begin
            tmp_add_result1[i] <= 0;
        end
    end else   begin
        tmp_add_result1[0] <= tmp_mul_result[0] + tmp_mul_result[1];
        tmp_add_result1[1] <= tmp_mul_result[2] + tmp_mul_result[3];
        tmp_add_result1[2] <= tmp_mul_result[4] + tmp_mul_result[5];
        tmp_add_result1[3] <= tmp_mul_result[6] + tmp_mul_result[7];
        tmp_add_result1[4] <= tmp_mul_result[8] + tmp_mul_result[9];
        tmp_add_result1[5] <= tmp_mul_result[10] + tmp_mul_result[11];
        tmp_add_result1[6] <= tmp_mul_result[12] + tmp_mul_result[13];
        tmp_add_result1[7] <= tmp_mul_result[14] + tmp_mul_result[15];
    end
end

// add 2 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            tmp_add_result2[i] <= 0;
        end
    end else   begin
        tmp_add_result2[0] <= tmp_add_result1[0] + tmp_add_result1[1];
        tmp_add_result2[1] <= tmp_add_result1[2] + tmp_add_result1[3];
        tmp_add_result2[2] <= tmp_add_result1[4] + tmp_add_result1[5];
        tmp_add_result2[3] <= tmp_add_result1[6] + tmp_add_result1[7];
    end
end

// add 3
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            out_result[i] <= 0;
        end
    end else  if(fcn_calc_cnt == 4) begin
        if(compute_status == 1) begin
            out_result[0] <= tmp_add_result2[0];
            out_result[1] <= tmp_add_result2[1];
            out_result[2] <= tmp_add_result2[2];
            out_result[3] <= tmp_add_result2[3];
        end else if(compute_status == 2) begin
            out_result[0] <= out_result[0] + tmp_add_result2[0];
            out_result[1] <= out_result[1] +tmp_add_result2[1];
            out_result[2] <= out_result[2] +tmp_add_result2[2];
            out_result[3] <= out_result[3] +tmp_add_result2[3];
        end
    end
end

// fcn calc cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fcn_calc_cnt <= 0;
    end else if((compute_status == 1 || compute_status == 2)) begin
        fcn_calc_cnt <= fcn_calc_cnt + 1;
    end 
    else begin
        fcn_calc_cnt <= 0;
    end
end

// output logic
// output cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_cnt <= 0;
    end else if(compute_status == 3) begin
        out_cnt <= out_cnt + 1;
    end else begin
        out_cnt <= 0;
    end
end

always @( posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
    end
    else if(compute_status == 3) begin
        out_valid <= 1;
        out_data <= out_result[out_cnt];
    end
    else begin
        out_valid <= 0;
        out_data <= 0;
    end
end

CONV_LAYER conv_layer_ch1 (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_data_ch1(in_data_ch1),
    .in_data_ch2(in_data_ch2),
    .in_kernel_1(kernel_ch1),
    .in_kernel_2(kernel_ch2),
    .mode(mode),
    .out_valid(conv_out_valid_ch1),
    .out_data(conv_out_ch1)
);

endmodule

module CONV_LAYER (
    input                       clk,
    input                       rst_n,
    input                       in_valid,
    input       signed  [7:0]   in_data_ch1,
    input       signed  [7:0]   in_data_ch2,
    input       signed  [7:0]   in_kernel_1,
    input       signed  [7:0]   in_kernel_2,
    input                       mode,
    output reg                  out_valid,
    output reg  signed  [7:0]  out_data
);
//==================================================================
// parameter & integer
//==================================================================

integer i;

//==================================================================
// Regs
//==================================================================
reg signed [7:0] input_image1 [0:35];
reg signed [7:0] input_image2 [0:35];
reg signed [7:0] kernel_arr1[0:8];
reg signed [7:0] kernel_arr2[0:8];
reg signed [7:0] tmp_in_imge1_0, tmp_in_imge1_1, tmp_in_imge1_2, tmp_in_imge1_3,
                    tmp_in_imge1_4, tmp_in_imge1_5, tmp_in_imge1_6, tmp_in_imge1_7,
                    tmp_in_imge1_8;
reg signed [7:0] tmp_in_imge2_0, tmp_in_imge2_1, tmp_in_imge2_2, tmp_in_imge2_3,
                    tmp_in_imge2_4, tmp_in_imge2_5, tmp_in_imge2_6, tmp_in_imge2_7,
                    tmp_in_imge2_8;
reg [6:0] input_cnt;

reg mode_reg;

reg [5:0] compute_idx;
reg [1:0] compute_inner_cnt;

reg prepare_done;
// stage 1 multiply
reg mul_done;
reg signed [15:0] mul_tmp_result1[0:8];
reg signed [15:0] mul_tmp_result2[0:8];
// stage 2 add 9 -> 3
reg add1_done;
reg signed [17:0] add_tmp_result_1_1;
reg signed [17:0] add_tmp_result_1_2;
reg signed [17:0] add_tmp_result_1_3;
reg signed [17:0] add_tmp_result_2_1;
reg signed [17:0] add_tmp_result_2_2;
reg signed [17:0] add_tmp_result_2_3;
// stage 3 add 3 -> 1
reg add2_done;
reg signed [19:0] add_tmp_result_1_4;
reg signed [19:0] add_tmp_result_2_4;

// stage 4 activation function
reg activation_done;
reg activation_done_delay;
reg signed [20:0] activation_result;


//  store image
reg signed [7:0] store_result[0:15];
reg [3:0] store_cnt;
wire conv_done;

//  max pooling
wire signed [7:0] max0_0, max0_1, max0_01;
wire signed [7:0] max1_0, max1_1, max1_01;
wire signed [7:0] max2_0, max2_1, max2_01;
wire signed [7:0] max3_0, max3_1, max3_01;

reg signed [7:0] max_pooling_result[0:3]; 
reg max_pooling_done;

// output 
reg [1:0] output_cnt;
//==================================================================
// Wires
//==================================================================

wire more_than_127;
wire [5:0] input_cnt_mux;
wire calc_valid;
wire signed [20:0] add_tmp_result;
//==================================================================
// Design
//==================================================================

// Input Counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        input_cnt <= 0;
    end else if(in_valid) begin
        input_cnt <= input_cnt + 1;
    end else  begin
        input_cnt <= 0;
    end
end

assign input_cnt_mux = input_cnt > 35 ? input_cnt - 36 : input_cnt;
// input image buffer   
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 36; i = i + 1) begin
            input_image1[i] <= 0;
            input_image2[i] <= 0;
        end
    end else if(in_valid) begin
        input_image1[input_cnt_mux] <= in_data_ch1;
        input_image2[input_cnt_mux] <= in_data_ch2;
    end
end

// mode reg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mode_reg <= 0;
    else if(in_valid && input_cnt == 0)mode_reg <= mode;
    else  mode_reg <= mode_reg;
end

// kernel buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 9; i = i + 1) begin
            kernel_arr1[i] <= 0;
            kernel_arr2[i] <= 0;
        end
    end else if(in_valid && input_cnt < 9) begin
        kernel_arr1[input_cnt] <= in_kernel_1;
        kernel_arr2[input_cnt] <= in_kernel_2;
    end
end

// stage 1 multiply
assign calc_valid = (input_cnt > 20 && input_cnt < 36) || (input_cnt > 56);
// compute_idx 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) compute_idx <= 0;
    else if(calc_valid) compute_idx <= compute_inner_cnt == 3 ? compute_idx + 3 : compute_idx + 1;
    else compute_idx <= 0;
end

// compute_inner_cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) compute_inner_cnt <= 0;
    else if(calc_valid) compute_inner_cnt <= compute_inner_cnt + 1;
    else compute_inner_cnt <= 0;
end

always @(posedge clk) begin
     begin
        tmp_in_imge1_0 <= input_image1[compute_idx];
        tmp_in_imge1_1 <= input_image1[compute_idx + 1];
        tmp_in_imge1_2 <= input_image1[compute_idx + 2];
        tmp_in_imge1_3 <= input_image1[compute_idx + 6];
        tmp_in_imge1_4 <= input_image1[compute_idx + 7];
        tmp_in_imge1_5 <= input_image1[compute_idx + 8];
        tmp_in_imge1_6 <= input_image1[compute_idx + 12];
        tmp_in_imge1_7 <= input_image1[compute_idx + 13];
        tmp_in_imge1_8 <= input_image1[compute_idx + 14];

        tmp_in_imge2_0 <= input_image2[compute_idx];
        tmp_in_imge2_1 <= input_image2[compute_idx + 1];
        tmp_in_imge2_2 <= input_image2[compute_idx + 2];
        tmp_in_imge2_3 <= input_image2[compute_idx + 6];
        tmp_in_imge2_4 <= input_image2[compute_idx + 7];
        tmp_in_imge2_5 <= input_image2[compute_idx + 8];
        tmp_in_imge2_6 <= input_image2[compute_idx + 12];
        tmp_in_imge2_7 <= input_image2[compute_idx + 13];
        tmp_in_imge2_8 <= input_image2[compute_idx + 14];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 9; i = i + 1) begin
            mul_tmp_result1[i] <= 0;
            mul_tmp_result2[i] <= 0;
        end
    end else  begin
        mul_tmp_result1[0] <= tmp_in_imge1_0 * kernel_arr1[0];
        mul_tmp_result1[1] <= tmp_in_imge1_1 * kernel_arr1[1];
        mul_tmp_result1[2] <= tmp_in_imge1_2 * kernel_arr1[2];
        mul_tmp_result1[3] <= tmp_in_imge1_3 * kernel_arr1[3];
        mul_tmp_result1[4] <= tmp_in_imge1_4 * kernel_arr1[4];
        mul_tmp_result1[5] <= tmp_in_imge1_5 * kernel_arr1[5];
        mul_tmp_result1[6] <= tmp_in_imge1_6 * kernel_arr1[6];
        mul_tmp_result1[7] <= tmp_in_imge1_7 * kernel_arr1[7];
        mul_tmp_result1[8] <= tmp_in_imge1_8 * kernel_arr1[8];

        mul_tmp_result2[0] <= tmp_in_imge2_0 * kernel_arr2[0];
        mul_tmp_result2[1] <= tmp_in_imge2_1 * kernel_arr2[1];
        mul_tmp_result2[2] <= tmp_in_imge2_2 * kernel_arr2[2];
        mul_tmp_result2[3] <= tmp_in_imge2_3 * kernel_arr2[3];
        mul_tmp_result2[4] <= tmp_in_imge2_4 * kernel_arr2[4];
        mul_tmp_result2[5] <= tmp_in_imge2_5 * kernel_arr2[5];
        mul_tmp_result2[6] <= tmp_in_imge2_6 * kernel_arr2[6];
        mul_tmp_result2[7] <= tmp_in_imge2_7 * kernel_arr2[7];
        mul_tmp_result2[8] <= tmp_in_imge2_8 * kernel_arr2[8];
    end
end


// mul done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) prepare_done <= 0;
    else if(calc_valid)  prepare_done <= 1;
    else prepare_done <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mul_done <= 0;
    else if(prepare_done) mul_done <= 1;
    else mul_done <= 0;
end

// stage 2 add 9 -> 3
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_tmp_result_1_1 <= 0;
        add_tmp_result_1_2 <= 0;
        add_tmp_result_1_3 <= 0;
        add_tmp_result_2_1 <= 0;
        add_tmp_result_2_2 <= 0;
        add_tmp_result_2_3 <= 0;
    end else begin
        add_tmp_result_1_1 <= (mul_tmp_result1[0] + mul_tmp_result1[1]) + mul_tmp_result1[2];
        add_tmp_result_1_2 <= (mul_tmp_result1[3] + mul_tmp_result1[4]) + mul_tmp_result1[5];
        add_tmp_result_1_3 <= (mul_tmp_result1[6] + mul_tmp_result1[7]) + mul_tmp_result1[8];
        add_tmp_result_2_1 <= (mul_tmp_result2[0] + mul_tmp_result2[1]) + mul_tmp_result2[2];
        add_tmp_result_2_2 <= (mul_tmp_result2[3] + mul_tmp_result2[4]) + mul_tmp_result2[5];
        add_tmp_result_2_3 <= (mul_tmp_result2[6] + mul_tmp_result2[7]) + mul_tmp_result2[8];
    end
end

// add1 done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) add1_done <= 0;
    else if(mul_done)  add1_done <= 1;
    else add1_done <= 0;
end

// stage 3 add 3x1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_tmp_result_1_4 <= 0;
        add_tmp_result_2_4 <= 0;
    end else  begin
        add_tmp_result_1_4 <= (add_tmp_result_1_1 + add_tmp_result_1_2) + add_tmp_result_1_3;
        add_tmp_result_2_4 <= (add_tmp_result_2_1 + add_tmp_result_2_2) + add_tmp_result_2_3;
    end
end

// add2 done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) add2_done <= 0;
    else if(add1_done) add2_done <= 1;
    else add2_done <= 0;
end

// stage 4 activation function
assign add_tmp_result = add_tmp_result_1_4 + add_tmp_result_2_4;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        activation_result <= 0;
    end else   begin
        if(mode_reg) begin
            activation_result <= add_tmp_result[20] ? ~add_tmp_result + 1 :  add_tmp_result;
        end else begin
            activation_result <= add_tmp_result[20] ? 0 : add_tmp_result;
        end
    end
end

// activation done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) activation_done <= 0;
    else if(add2_done) activation_done <= 1;
    else activation_done <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) activation_done_delay <= 0;
    else if(activation_done) activation_done_delay <= 1;
    else activation_done_delay <= 0;
end

assign more_than_127 = activation_result[19] | activation_result[18] | activation_result[17] | activation_result[16];
// stage 5 store image
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            store_result[i] <= 0;
        end
    end else if(activation_done || activation_done_delay) begin
        store_result[store_cnt] <= more_than_127 ? 8'd127 : {1'b0, activation_result[15:9]};
    end
end

// store cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) store_cnt <= 0;
    else if(activation_done) store_cnt <= store_cnt + 1;
    else store_cnt <= 0;
end

assign conv_done = store_cnt == 15 ? 1 : 0;
// stage 6 max pooling

assign max0_0 = store_result[0] > store_result[1] ? store_result[0] : store_result[1];
assign max0_1 = store_result[4] > store_result[5] ? store_result[4] : store_result[5];
assign max0_01 = max0_0 > max0_1 ? max0_0 : max0_1;

assign max1_0 = store_result[2] > store_result[3] ? store_result[2] : store_result[3];
assign max1_1 = store_result[6] > store_result[7] ? store_result[6] : store_result[7];
assign max1_01 = max1_0 > max1_1 ? max1_0 : max1_1;

assign max2_0 = store_result[8] > store_result[9] ? store_result[8] : store_result[9];
assign max2_1 = store_result[12] > store_result[13] ? store_result[12] : store_result[13];
assign max2_01 = max2_0 > max2_1 ? max2_0 : max2_1;

assign max3_0 = store_result[10] > store_result[11] ? store_result[10] : store_result[11];
assign max3_1 = store_result[14] > store_result[15] ? store_result[14] : store_result[15];
assign max3_01 = max3_0 > max3_1 ? max3_0 : max3_1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        max_pooling_result[0] <= 0;
        max_pooling_result[1] <= 0;
        max_pooling_result[2] <= 0;
        max_pooling_result[3] <= 0;
    end else begin
        max_pooling_result[0] <= max0_01;
        max_pooling_result[1] <= max1_01;
        max_pooling_result[2] <= max2_01;
        max_pooling_result[3] <= max3_01;
    end
end

// max pooling done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) max_pooling_done <= 0;
    else if(conv_done) max_pooling_done <= 1;
    else if(output_cnt == 3) max_pooling_done <= 0;
    else max_pooling_done <= max_pooling_done;
end

// output
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
    end else if(max_pooling_done) begin
        out_valid <= 1;
        out_data <= max_pooling_result[output_cnt];
    end else begin
        out_valid <= 0;
        out_data <= 0;
    end
end

// output cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) output_cnt <= 0;
    else if(max_pooling_done) output_cnt <= output_cnt + 1;
    else output_cnt <= 0;
end

endmodule
