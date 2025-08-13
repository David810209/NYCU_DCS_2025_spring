module AXI_inter(
    // AXI_inter IO
    input                 clk, rst_n,
    input                 in_valid1,
    input                 action_valid1,
    input                 formula_valid1,
    input                 dram_no_valid1,
    input                 index_valid1,
    input         [11:0]  D1,
    output  reg           out_valid1,

    input                 in_valid2,
    input                 action_valid2,
    input                 formula_valid2,
    input                 dram_no_valid2,
    input                 index_valid2,
    input         [11:0]  D2,
    output  reg           out_valid2,
    output  reg   [11:0]  result,
    
    // AXI4 IO
    input                 AR_READY, R_VALID, AW_READY, W_READY, B_VALID,
    input         [63:0]  R_DATA,
    output  reg           AR_VALID, R_READY, AW_VALID, W_VALID, B_READY,
    output  reg   [16:0]  AR_ADDR, AW_ADDR,
    output  reg   [63:0]  W_DATA
);
// (1) 	axi write address channel 
// 		src master: AW_VALID, AW_VALID
// 		src slave: AW_READY
// (2)	axi write data channel 
// 		src master: W_VALID, W_DATA
// 		src slave: W_READY
// (3)	axi write response channel
// 		src master: B_READY
// 		src slave: B_VALID, B_RESP
// (4)	axi read address channel
// 		src master: AR_VALID, AR_ADDR
// 		src slave: AR_READY
// (5)	axi read data channel
// 		src master: R_READY
// 		src slave: R_VALID, R_DATA

// reg wire
localparam IDLE = 4'b0000,
           WAIT_ACTION_1 = 4'b0001,
           WAIT_ACTION_2 = 4'b0010,
           READ = 4'b0011,
           WRITE = 4'b0100,
           WAIT_READ = 4'b0101,
           WAIT_WRITE = 4'b0110,
           CALCULATE = 4'b0111,
           CALCULATE_2 = 4'b1000,
           CALCULATE_3 = 4'b1001,
           CALCULATE_4 = 4'b1010,
           CALCULATE_5 = 4'b1011,
           CALCULATE_6 = 4'b1100,
              CALCULATE_7 = 4'b1101,
              CALCULATE_DONE = 4'b1110;

reg [3:0] state, next_state;
reg current_process_master;
// master 1 reg
reg master1_valid;
reg master1_input_done;
reg master1_action_type;
reg [2:0] master1_formula;
reg [7:0] master1_dram_no;
reg [11:0] master1_index_A;
reg [11:0] master1_index_B;
reg [11:0] master1_index_C;
reg [11:0] master1_index_D;
reg [1:0] master1_index_cnt;
// master 2 reg
reg master2_valid;
reg master2_input_done;
reg master2_action_type;
reg [2:0] master2_formula;
reg [7:0] master2_dram_no;
reg [11:0] master2_index_A;
reg [11:0] master2_index_B;
reg [11:0] master2_index_C;
reg [11:0] master2_index_D;
reg [1:0] master2_index_cnt;

// signal to process write
reg has_wready_m_inf, has_awready_m_inf;
wire [16:0] addr_to_dram; 
reg [7:0] addr_sel;
wire [7:0] rw_addr_sel;
reg action_type_sel;

reg [63:0] dram_data_buffer;

// calculation
reg  [12:0] add_result_A, add_result_B, add_result_C, add_result_D;
wire A_exceed, B_exceed, C_exceed, D_exceed;
reg [11:0] final_result_A, final_result_B, final_result_C, final_result_D;
reg [11:0] I_A, I_B, I_C, I_D;
reg [11:0] TI_A, TI_B, TI_C, TI_D;
reg [12:0] G_A, G_B, G_C, G_D;
wire [12:0] N0, N1, N2;
reg [12:0] N_l1_0_0, N_l1_0_1, N_l1_1_0, N_l1_1_1;
reg [12:0] N_l2_0_1, N_l2_1_0, N_l2_1_1;
reg [12:0] N_l3_0_0, N_l3_0_1;
reg [11:0] I_MAX_1, I_MAX_2;
reg [11:0] I_MAX_3, I_MIN_3;
reg [11:0] I_MIN_1, I_MIN_2;
reg A_GT_2047, B_GT_2047, C_GT_2047, D_GT_2047;
reg A_I_GT_TI, B_I_GT_TI, C_I_GT_TI, D_I_GT_TI;
// wire [11:0] R_A, R_B, R_C, R_D, R_E, R_F, R_G, R_H;
reg [2:0] formula_mux;
reg [13:0] I_sum, G_sum, N_sum;
//design

// master 1 reg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_valid <= 0;
    else if(in_valid1) master1_valid <= 1;
    else if(current_process_master == 0 && (state == CALCULATE_DONE)) master1_valid <= 0;
    else master1_valid <= master1_valid;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_action_type <= 0;
    else if(action_valid1) master1_action_type <= D1[0];
    else master1_action_type <= master1_action_type;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_formula <= 0;
    else if(formula_valid1) master1_formula <= D1[2:0];
    else master1_formula <= master1_formula;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_dram_no <= 0;
    else if(dram_no_valid1) master1_dram_no <= D1[7:0];
    else master1_dram_no <= master1_dram_no;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_index_cnt <= 0;
    else if(index_valid1) master1_index_cnt <= master1_index_cnt + 1;
    else master1_index_cnt <= master1_index_cnt;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_index_A <= 0;
    else if(index_valid1 && master1_index_cnt == 0) master1_index_A <= D1;
    else master1_index_A <= master1_index_A;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_index_B <= 0;
    else if(index_valid1 && master1_index_cnt == 1) master1_index_B <= D1;
    else master1_index_B <= master1_index_B;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_index_C <= 0;
    else if(index_valid1 && master1_index_cnt == 2) master1_index_C <= D1;
    else master1_index_C <= master1_index_C;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_index_D <= 0;
    else if(index_valid1 && master1_index_cnt == 3) master1_index_D <= D1;
    else master1_index_D <= master1_index_D;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master1_input_done <= 0;
    else if(index_valid1 && master1_index_cnt == 3) master1_input_done <= 1;
    else if(out_valid1) master1_input_done <= 0;
    else master1_input_done <= master1_input_done;
end

// master 2 reg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_valid <= 0;
    else if(in_valid2) master2_valid <= 1;
    else if(current_process_master == 1 && (state == CALCULATE_DONE)) master2_valid <= 0;
    else master2_valid <= master2_valid;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_action_type <= 0;
    else if(action_valid2) master2_action_type <= D2[0];
    else master2_action_type <= master2_action_type;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_formula <= 0;
    else if(formula_valid2) master2_formula <= D2[2:0];
    else master2_formula <= master2_formula;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_dram_no <= 0;
    else if(dram_no_valid2) master2_dram_no <= D2[7:0];
    else master2_dram_no <= master2_dram_no;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_index_cnt <= 0;
    else if(index_valid2) master2_index_cnt <= master2_index_cnt + 1;
    else master2_index_cnt <= master2_index_cnt;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_index_A <= 0;
    else if(index_valid2 && master2_index_cnt == 0) master2_index_A <= D2;
    else master2_index_A <= master2_index_A;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_index_B <= 0;
    else if(index_valid2 && master2_index_cnt == 1) master2_index_B <= D2;
    else master2_index_B <= master2_index_B;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_index_C <= 0;
    else if(index_valid2 && master2_index_cnt == 2) master2_index_C <= D2;
    else master2_index_C <= master2_index_C;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_index_D <= 0;
    else if(index_valid2 && master2_index_cnt == 3) master2_index_D <= D2;
    else master2_index_D <= master2_index_D;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) master2_input_done <= 0;
    else if(index_valid2 && master2_index_cnt == 3) master2_input_done <= 1;
    else if(out_valid2) master2_input_done <= 0;
    else master2_input_done <= master2_input_done;
end
// state machine
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case(state)
        IDLE: begin
            if(master1_valid || in_valid1) begin
                next_state = WAIT_ACTION_1;
            end
            else if(master2_valid || in_valid2) begin
                next_state = WAIT_ACTION_2;
            end
            else next_state = IDLE;
        end
        WAIT_ACTION_1: begin
            if((master1_input_done) && !(master2_valid && !master2_input_done)) begin
                next_state = READ;
            end
            else next_state = WAIT_ACTION_1;
        end
        WAIT_ACTION_2: begin
            if((master2_input_done) && !(master1_valid && !master1_input_done)) begin
                next_state = READ;
            end
            else next_state = WAIT_ACTION_2;
        end
        READ: begin
            if(AR_READY) next_state = WAIT_READ;
            else next_state = READ;
        end
        WRITE: begin
            if(has_wready_m_inf && has_awready_m_inf) next_state = WAIT_WRITE;
            else next_state = WRITE;
        end
        WAIT_READ: begin
            if(R_VALID) next_state = CALCULATE;
            else next_state = WAIT_READ;
        end
        WAIT_WRITE: begin
            if(B_VALID) next_state = CALCULATE_DONE;
            else next_state = WAIT_WRITE;
        end
        CALCULATE: next_state = CALCULATE_2;
        CALCULATE_2: next_state = CALCULATE_3;
        CALCULATE_3: next_state = action_type_sel ? WRITE : CALCULATE_4;
        CALCULATE_4: next_state = CALCULATE_5;
        CALCULATE_5: next_state = CALCULATE_6;
        CALCULATE_6: next_state = CALCULATE_7;
        CALCULATE_7: next_state = CALCULATE_DONE;
        CALCULATE_DONE: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// current_process_master
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
         current_process_master <= 1'b0;
         addr_sel <= 8'b0;
         formula_mux <= 3'b0;
         action_type_sel <= 1'b0;
    end
    else if(state == WAIT_ACTION_1) begin
        current_process_master <= 1'b0;
        addr_sel <= master1_dram_no;
        formula_mux <= master1_formula;
        action_type_sel <= master1_action_type;
    end
    else if(state == WAIT_ACTION_2) begin
        current_process_master <= 1'b1;
        addr_sel <= master2_dram_no;
        formula_mux <= master2_formula;
        action_type_sel <= master2_action_type;
    end
    else begin
        current_process_master <= current_process_master;
        addr_sel <= addr_sel;
        formula_mux <= formula_mux;
        action_type_sel <= action_type_sel;
    end
end

// dram_data_buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) dram_data_buffer <= 64'b0;
    else if(state == WAIT_READ && R_VALID)  dram_data_buffer <= R_DATA;
    else dram_data_buffer <= dram_data_buffer;
end

// addr_to_dram
assign addr_to_dram = 17'h10000 + (addr_sel << 3);
// calculation
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        TI_A <= 0;
        TI_B <= 0;
        TI_C <= 0;
        TI_D <= 0;
    end
    else if(state == WAIT_ACTION_1) begin
        TI_A <= master1_index_A;
        TI_B <= master1_index_B;
        TI_C <= master1_index_C;
        TI_D <= master1_index_D;
    end
    else if(state == WAIT_ACTION_2) begin
        TI_A <= master2_index_A;
        TI_B <= master2_index_B;
        TI_C <= master2_index_C;
        TI_D <= master2_index_D;
    end
    else begin
        TI_A <= TI_A;
        TI_B <= TI_B;
        TI_C <= TI_C;
        TI_D <= TI_D;
    end
end
// assign I_A = dram_data_buffer[63:52];
// assign I_B = dram_data_buffer[51:40];
// assign I_C = dram_data_buffer[31:20];
// assign I_D = dram_data_buffer[19:8];
// assign add_result_A = {1'b0, I_A} + {TI_A[11], TI_A};
// assign add_result_B = {1'b0, I_B} + {TI_B[11], TI_B};
// assign add_result_C = {1'b0, I_C} + {TI_C[11], TI_C};
// assign add_result_D = {1'b0, I_D} + {TI_D[11], TI_D};
assign A_exceed = add_result_A[12];
assign B_exceed = add_result_B[12];
assign C_exceed = add_result_C[12];
assign D_exceed = add_result_D[12];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        final_result_A <= 0;
        final_result_B <= 0;
        final_result_C <= 0;
        final_result_D <= 0;
    end
    else begin
        final_result_A <= A_exceed ? (TI_A[11] ? 0 : 4095) : add_result_A[11:0];
        final_result_B <= B_exceed ? (TI_B[11] ? 0 : 4095) : add_result_B[11:0];
        final_result_C <= C_exceed ? (TI_C[11] ? 0 : 4095) : add_result_C[11:0];
        final_result_D <= D_exceed ? (TI_D[11] ? 0 : 4095) : add_result_D[11:0];
    end
end
// assign G_A = (A_I_GT_TI) ? (I_A - TI_A) : (TI_A - I_A);
// assign G_B = (B_I_GT_TI) ? (I_B - TI_B) : (TI_B - I_B);
// assign G_C = (C_I_GT_TI) ? (I_C - TI_C) : (TI_C - I_C);
// assign G_D = (D_I_GT_TI) ? (I_D - TI_D) : (TI_D - I_D);
// assign N_l1_0_0 = G_A > G_B ? G_A : G_B;
// assign N_l1_0_1 = G_A > G_B ? G_B : G_A;
// assign N_l1_1_0 = G_C > G_D ? G_C : G_D;
// assign N_l1_1_1 = G_C > G_D ? G_D : G_C;
// assign N_l2_0_1 = N_l1_0_0 > N_l1_1_0 ? N_l1_1_0 : N_l1_0_0;
// assign N_l2_1_0 = N_l1_0_1 > N_l1_1_1 ? N_l1_0_1 : N_l1_1_1;
// assign N_l2_1_1 = N_l1_0_1 > N_l1_1_1 ? N_l1_1_1 : N_l1_0_1;
// assign N_l3_0_0 = N_l2_0_1 > N_l2_1_0 ? N_l2_0_1 : N_l2_1_0;
// assign N_l3_0_1 = N_l2_0_1 > N_l2_1_0 ? N_l2_1_0 : N_l2_0_1;
assign N2 = N_l3_0_0;
assign N1 = N_l3_0_1;
assign N0 = N_l2_1_1;
// assign I_MAX_1 = (I_A > I_B) ? I_A : I_B;
// assign I_MAX_2 = (I_C > I_D) ? I_C : I_D;
// assign I_MIN_1 = (I_A < I_B) ? I_A : I_B;
// assign I_MIN_2 = (I_C < I_D) ? I_C : I_D;
// assign A_I_GT_TI = I_A >= TI_A;
// assign B_I_GT_TI = I_B >= TI_B;
// assign C_I_GT_TI = I_C >= TI_C;
// assign D_I_GT_TI = I_D >= TI_D;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        I_sum <= 0;
        G_sum <= 0;
        N_sum <= 0;
        I_MAX_1 <= 0;
        I_MAX_2 <= 0;
        I_MIN_1 <= 0;
        I_MIN_2 <= 0;
        I_MAX_3 <= 0;
        I_MIN_3 <= 0;
        A_GT_2047 <= 0;
        B_GT_2047 <= 0;
        C_GT_2047 <= 0;
        D_GT_2047 <= 0;
        G_A <= 0;
        G_B <= 0;
        G_C <= 0;
        G_D <= 0;
        I_A <= 0;
        I_B <= 0;
        I_C <= 0;
        I_D <= 0;
        N_l1_0_0 <= 0;
        N_l1_0_1 <= 0;
        N_l1_1_0 <= 0;
        N_l1_1_1 <= 0;
        N_l2_0_1 <= 0;
        N_l2_1_0 <= 0;
        N_l2_1_1 <= 0;
        N_l3_0_0 <= 0;
        N_l3_0_1 <= 0;
        add_result_A <= 0;
        add_result_B <= 0;
        add_result_C <= 0;
        add_result_D <= 0;
        A_I_GT_TI <= 0;
        B_I_GT_TI <= 0;
        C_I_GT_TI <= 0;
        D_I_GT_TI <= 0;
    end
    else begin
        I_sum <= I_A + I_B + I_C + I_D;
        G_sum <= G_A + G_B + G_C + G_D;
        N_sum <= N0 + N1 + N2;
        I_MAX_1 <= (I_A > I_B) ? I_A : I_B;
        I_MAX_2 <= (I_C > I_D) ? I_C : I_D;
        I_MIN_1 <= (I_A < I_B) ? I_A : I_B;
        I_MIN_2 <= (I_C < I_D) ? I_C : I_D;
        I_MAX_3 <= (I_MAX_1 > I_MAX_2) ? I_MAX_1 : I_MAX_2;
        I_MIN_3 <= (I_MIN_1 < I_MIN_2) ? I_MIN_1 : I_MIN_2;
        A_GT_2047 <= (I_A[11] | (&I_A[10:0])) ? 1 : 0;
        B_GT_2047 <= (I_B[11] | (&I_B[10:0])) ? 1 : 0;
        C_GT_2047 <= (I_C[11] | (&I_C[10:0])) ? 1 : 0;
        D_GT_2047 <= (I_D[11] | (&I_D[10:0])) ? 1 : 0;
        G_A <= (A_I_GT_TI) ? (I_A - TI_A) : (TI_A - I_A);
        G_B <= (B_I_GT_TI) ? (I_B - TI_B) : (TI_B - I_B);
        G_C <= (C_I_GT_TI) ? (I_C - TI_C) : (TI_C - I_C);
        G_D <= (D_I_GT_TI) ? (I_D - TI_D) : (TI_D - I_D);
        I_A <= dram_data_buffer[63:52];
        I_B <= dram_data_buffer[51:40];
        I_C <= dram_data_buffer[31:20];
        I_D <= dram_data_buffer[19:8];
        N_l1_0_0 <= G_A > G_B ? G_A : G_B;
        N_l1_0_1 <= G_A > G_B ? G_B : G_A;
        N_l1_1_0 <= G_C > G_D ? G_C : G_D;
        N_l1_1_1 <= G_C > G_D ? G_D : G_C;
        N_l2_0_1 <= N_l1_0_0 > N_l1_1_0 ? N_l1_1_0 : N_l1_0_0;
        N_l2_1_0 <= N_l1_0_1 > N_l1_1_1 ? N_l1_0_1 : N_l1_1_1;
        N_l2_1_1 <= N_l1_0_1 > N_l1_1_1 ? N_l1_1_1 : N_l1_0_1;
        N_l3_0_0 <= N_l2_0_1 > N_l2_1_0 ? N_l2_0_1 : N_l2_1_0;
        N_l3_0_1 <= N_l2_0_1 > N_l2_1_0 ? N_l2_1_0 : N_l2_0_1;
        add_result_A <= {1'b0, I_A} + {TI_A[11], TI_A};
        add_result_B <= {1'b0, I_B} + {TI_B[11], TI_B};
        add_result_C <= {1'b0, I_C} + {TI_C[11], TI_C};
        add_result_D <= {1'b0, I_D} + {TI_D[11], TI_D};
        A_I_GT_TI <= I_A >= TI_A;
        B_I_GT_TI <= I_B >= TI_B;
        C_I_GT_TI <= I_C >= TI_C;
        D_I_GT_TI <= I_D >= TI_D;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) result <= 0;
    else  begin
        if(action_type_sel) result <= {8'b0, A_exceed, B_exceed, C_exceed, D_exceed};
        else  begin
            case(formula_mux)
                3'b000: result <= I_sum >> 2;
                3'b001: result <= I_MAX_3 - I_MIN_3;
                3'b010: result <= I_MIN_3;
                3'b011: result <= A_GT_2047 + B_GT_2047 + C_GT_2047 + D_GT_2047;
                3'b100: result <= A_I_GT_TI+ B_I_GT_TI + C_I_GT_TI + D_I_GT_TI;
                3'b101: result <= N_sum / 3;
                3'b110: result <= (N0 >> 1) + (N1 >> 2) + (N2 >> 2);
                3'b111: result <= G_sum >> 2;
                default: result <= 0;
            endcase
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid1 <= 0;
    else if(current_process_master == 0 && (state == CALCULATE_DONE)) out_valid1 <= 1;
    else out_valid1 <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid2 <= 0;
    else if(current_process_master == 1 && (state == CALCULATE_DONE)) out_valid2 <= 1;
    else out_valid2 <= 0;
end

// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) AW_VALID <= 1'b0;
    else if(state == WRITE && ((!AW_READY && !has_awready_m_inf))) AW_VALID <= 1'b1;
    else AW_VALID <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) AW_ADDR <= 32'b0;
    else if(state == WRITE) AW_ADDR <= addr_to_dram;
    else AW_ADDR <= 32'b0;
end
// (2)	axi write data channel 
// 		src master

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) W_VALID <= 1'b0;
    else if(state == WRITE && (!has_wready_m_inf && !W_READY))  W_VALID <= 1'b1;
    else W_VALID <= 1'b0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) W_DATA <= 128'b0;
    else if(state == WRITE) W_DATA <= {final_result_A, final_result_B, 8'b0, final_result_C, final_result_D,8'b0};
    else W_DATA <= 128'b0;
end

// (3)	axi write response channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) B_READY <= 1'b0;
    else if(state == WAIT_WRITE && B_VALID) B_READY <= 1'b1;
    else B_READY <= 1'b0;
end

// (4)	axi read address channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) AR_VALID <= 1'b0;
    else if(next_state == READ) AR_VALID <= 1'b1;
    else AR_VALID <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) AR_ADDR <= 32'b0;
    else if(next_state == READ) AR_ADDR <= addr_to_dram;
    else AR_ADDR <= 32'b0;
end

// (5)	axi read data channel

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) R_READY <= 1'b0;
    else if(next_state == WAIT_READ) R_READY <= 1'b1;
    else R_READY <= 1'b0;
end

// has_wready_m_inf
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  has_wready_m_inf <= 1'b0;
    else if(state == WRITE) begin
        if(W_READY) has_wready_m_inf <= 1'b1;
        else has_wready_m_inf <= has_wready_m_inf;
    end
    else has_wready_m_inf <= 1'b0;
end
// has_awready_m_inf
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  has_awready_m_inf <= 1'b0;
    else if(state == WRITE) begin
        if(AW_READY) has_awready_m_inf <= 1'b1;
        else has_awready_m_inf <= has_awready_m_inf;
    end
    else has_awready_m_inf <= 1'b0;
end
endmodule
