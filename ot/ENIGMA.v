//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Ceres Lab
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   DCS 2025 Spring
//   OT         		: Enigma
//   Author     		: Bo-Yu, Pan
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ENIGMA.v
//   Module Name : ENIGMA
//   Release version : V1.0 (Release Date: 2025-06)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
 
module ENIGMA(
	// Input Ports
	clk, 
	rst_n, 
	in_valid, 
	in_valid_2, 
	crypt_mode, 
	code_in, 

	// Output Ports
	out_code, 
	out_valid
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk;              // clock input
input rst_n;            // asynchronous reset (active low)
input in_valid;         // code_in valid signal for Rotor (level sensitive). 0/1: inactive/active
input in_valid_2;       // code_in valid signal for code  (level sensitive). 0/1: inactive/active
input crypt_mode;       // 0: encrypt; 1:decrypt; only valid for 1 cycle when in_valid is active

input [5:0] code_in;	// When in_valid   is active, then code_in is input of rotors. 
						// When in_valid_2 is active, then code_in is input of code words.
							
output reg out_valid;       	// 0: out_code is not valid; 1: out_code is valid
output  reg [5:0] out_code;	// encrypted/decrypted code word

// ===============================================================
// Design
// ===============================================================
integer i;

/*
for loop example:

for(i=64; i<128; i=i+4) begin
	Rotor[i] <= Rotor[i+2];
	Rotor[i+2] <= Rotor[i];
end

*/
reg [5:0] rotorA [0:63];
reg [5:0] rotorA_inverse [0:63];
reg [5:0] rotorB [0:63];
reg [5:0] rotorB_inverse [0:63];
reg [7:0] input_cnt;
reg mode_reg;

// stage 1
reg stage1_valid;
reg [5:0] stage1_out;
// stage 2 find rotor A
wire [5:0] stage2_out_wire;
wire [1:0] shift_num;
// stage 3 find rotor B
wire [5:0] stage3_out_wire;
wire [5:0] stage4_out_wire;
wire [5:0] stage5_out_wire;
wire [5:0] stage6_out_wire;
wire [2:0] type_num;
// stage 4 reflector

// stage 7 output
// reg [5:0] stage7_out;
// reg stage7_valid;

// rotor A, rotor B
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) input_cnt <= 0;
	else if(in_valid) input_cnt <= input_cnt + 1;
	else input_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0;i < 64;i = i + 1) begin
			rotorA[i] <= 0;
		end
	end
	else if(in_valid && input_cnt < 64) begin
		rotorA[input_cnt] <= code_in;
	end
	else if(stage1_valid) begin
		case (shift_num)
			1: begin
				rotorA[0] <= rotorA[63];
				for(i = 1;i < 64;i = i + 1) begin
					rotorA[i] <= rotorA[i - 1];
				end
			end
			2: begin
				rotorA[0] <= rotorA[62];
				rotorA[1] <= rotorA[63];
				for(i = 2;i < 64;i = i + 1) begin
					rotorA[i] <= rotorA[i - 2];
				end
			end
			3: begin
				rotorA[0] <= rotorA[61];
				rotorA[1] <= rotorA[62];
				rotorA[2] <= rotorA[63];
				for(i = 3;i < 64;i = i + 1) begin
					rotorA[i] <= rotorA[i - 3];
				end
			end
			default:  begin
				for(i = 0;i < 64;i = i + 1) begin
					rotorA[i] <= rotorA[i];
				end
			end
		endcase
	end
	else begin
		for(i = 0;i < 64;i = i + 1) begin
			rotorA[i] <= rotorA[i];
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0;i < 64;i = i + 1) begin
			rotorA_inverse[i] <= 0;
		end
	end
	else if(in_valid && input_cnt < 64) begin
		rotorA_inverse[code_in] <= input_cnt;
	end
	else if(stage1_valid) begin
		case (shift_num)
			1: begin
				for(i = 0;i < 64;i = i + 1) begin
					if(rotorA_inverse[i] == 63) rotorA_inverse[i] <= 0;
					else rotorA_inverse[i] <= rotorA_inverse[i] + 1;
				end
			end
			2: begin
				for(i = 0;i < 64;i = i + 1) begin
					if(rotorA_inverse[i] == 63) rotorA_inverse[i] <= 1;
					else if(rotorA_inverse[i] == 62) rotorA_inverse[i] <= 0;
					else rotorA_inverse[i] <= rotorA_inverse[i] + 2;
				end
			end
			3: begin
				for(i = 0;i < 64;i = i + 1) begin
					if(rotorA_inverse[i] == 63) rotorA_inverse[i] <= 2;
					else if(rotorA_inverse[i] == 62) rotorA_inverse[i] <= 1;
					else if(rotorA_inverse[i] == 61) rotorA_inverse[i] <= 0;
					else rotorA_inverse[i] <= rotorA_inverse[i] + 3;
				end
			end
			default:  begin
				for(i = 0;i < 64;i = i + 1) begin
					rotorA_inverse[i] <= rotorA_inverse[i];
				end
			end
		endcase
	end
	else begin
		for(i = 0;i < 64;i = i + 1) begin
			rotorA_inverse[i] <= rotorA_inverse[i];
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0;i < 64;i = i + 1) begin
			rotorB[i] <= 0;
			rotorB_inverse[i] <= 0;
		end
	end
	else if(in_valid && input_cnt >= 64) begin
		rotorB[input_cnt - 64] <= code_in;
		rotorB_inverse[code_in] <= input_cnt - 64;
	end
	else if(stage1_valid) begin
		case (type_num) 
			1: begin
				for(i = 0;i < 64;i = i + 8)begin
					rotorB[i] <= rotorB[i + 1];
					rotorB[i+1] <= rotorB[i];
					rotorB[i+2] <= rotorB[i + 3];
					rotorB[i+3] <= rotorB[i + 2];
					rotorB[i+4] <= rotorB[i + 5];
					rotorB[i+5] <= rotorB[i + 4];
					rotorB[i+6] <= rotorB[i + 7];
					rotorB[i+7] <= rotorB[i + 6];
					rotorB_inverse[rotorB[i + 1]] <= i;
					rotorB_inverse[rotorB[i]] <= i + 1;
					rotorB_inverse[rotorB[i + 3]] <= i + 2;
					rotorB_inverse[rotorB[i + 2]] <= i + 3;
					rotorB_inverse[rotorB[i + 5]] <= i + 4;
					rotorB_inverse[rotorB[i + 4]] <= i + 5;
					rotorB_inverse[rotorB[i + 7]] <= i + 6;
					rotorB_inverse[rotorB[i + 6]] <= i + 7;
				end
			end
			2: begin
				for(i = 0;i < 64;i = i + 8)begin
					rotorB[i] <= rotorB[i + 2];
					rotorB[i+1] <= rotorB[i + 3];
					rotorB[i+2] <= rotorB[i];
					rotorB[i+3] <= rotorB[i + 1];
					rotorB[i+4] <= rotorB[i + 6];
					rotorB[i+5] <= rotorB[i + 7];
					rotorB[i+6] <= rotorB[i + 4];
					rotorB[i+7] <= rotorB[i + 5];
					rotorB_inverse[rotorB[i + 2]] <= i;
					rotorB_inverse[rotorB[i + 3]] <= i + 1;
					rotorB_inverse[rotorB[i]]     <= i + 2;
					rotorB_inverse[rotorB[i + 1]] <= i + 3;
					rotorB_inverse[rotorB[i + 6]] <= i + 4;
					rotorB_inverse[rotorB[i + 7]] <= i + 5;
					rotorB_inverse[rotorB[i + 4]] <= i + 6;
					rotorB_inverse[rotorB[i + 5]] <= i + 7;
				end
			end
			3: begin
				for(i = 0;i < 64;i = i + 8)begin
					rotorB[i]   <= rotorB[i];
					rotorB[i+1] <= rotorB[i + 4];
					rotorB[i+2] <= rotorB[i + 5];
					rotorB[i+3] <= rotorB[i + 6];
					rotorB[i+4] <= rotorB[i + 1];
					rotorB[i+5] <= rotorB[i + 2];
					rotorB[i+6] <= rotorB[i + 3];
					rotorB[i+7] <= rotorB[i + 7];
					rotorB_inverse[rotorB[i]]     <= i;
					rotorB_inverse[rotorB[i + 4]] <= i + 1;
					rotorB_inverse[rotorB[i + 5]] <= i + 2;
					rotorB_inverse[rotorB[i + 6]] <= i + 3;
					rotorB_inverse[rotorB[i + 1]] <= i + 4;
					rotorB_inverse[rotorB[i + 2]] <= i + 5;
					rotorB_inverse[rotorB[i + 3]] <= i + 6;
					rotorB_inverse[rotorB[i + 7]] <= i + 7;
				end
			end
			4: begin
				for(i = 0;i < 64;i = i + 8)begin
					rotorB[i] <= rotorB[i + 4];
					rotorB[i+1] <= rotorB[i + 5];
					rotorB[i+2] <= rotorB[i + 6];
					rotorB[i+3] <= rotorB[i + 7];
					rotorB[i+4] <= rotorB[i];
					rotorB[i+5] <= rotorB[i + 1];
					rotorB[i+6] <= rotorB[i + 2];
					rotorB[i+7] <= rotorB[i + 3];
					rotorB_inverse[rotorB[i + 4]] <= i;
					rotorB_inverse[rotorB[i + 5]] <= i + 1;
					rotorB_inverse[rotorB[i + 6]] <= i + 2;
					rotorB_inverse[rotorB[i + 7]] <= i + 3;
					rotorB_inverse[rotorB[i]]     <= i + 4;
					rotorB_inverse[rotorB[i + 1]] <= i + 5;
					rotorB_inverse[rotorB[i + 2]] <= i + 6;
					rotorB_inverse[rotorB[i + 3]] <= i + 7;
				end
			end
			5: begin
				for(i = 0;i < 64;i = i + 8)begin
					rotorB[i] <= rotorB[i + 5];
					rotorB[i+1] <= rotorB[i + 6];
					rotorB[i+2] <= rotorB[i + 7];
					rotorB[i+3] <= rotorB[i + 3];
					rotorB[i+4] <= rotorB[i + 4];
					rotorB[i+5] <= rotorB[i];
					rotorB[i+6] <= rotorB[i + 1];
					rotorB[i+7] <= rotorB[i + 2];
					rotorB_inverse[rotorB[i + 5]] <= i;
					rotorB_inverse[rotorB[i + 6]] <= i + 1;
					rotorB_inverse[rotorB[i + 7]] <= i + 2;
					rotorB_inverse[rotorB[i + 3]] <= i + 3;
					rotorB_inverse[rotorB[i + 4]] <= i + 4;
					rotorB_inverse[rotorB[i]]     <= i + 5;
					rotorB_inverse[rotorB[i + 1]] <= i + 6;
					rotorB_inverse[rotorB[i + 2]] <= i + 7;

				end
			end
			6: begin
				for(i = 0;i < 64;i = i + 8)begin
					rotorB[i] <= rotorB[i + 6];
					rotorB[i+1] <= rotorB[i + 7];
					rotorB[i+2] <= rotorB[i + 3];
					rotorB[i+3] <= rotorB[i + 2];
					rotorB[i+4] <= rotorB[i + 5];
					rotorB[i+5] <= rotorB[i + 4];
					rotorB[i+6] <= rotorB[i];
					rotorB[i+7] <= rotorB[i + 1];
					rotorB_inverse[rotorB[i + 6]] <= i;
					rotorB_inverse[rotorB[i + 7]] <= i + 1;
					rotorB_inverse[rotorB[i + 3]] <= i + 2;
					rotorB_inverse[rotorB[i + 2]] <= i + 3;
					rotorB_inverse[rotorB[i + 5]] <= i + 4;
					rotorB_inverse[rotorB[i + 4]] <= i + 5;
					rotorB_inverse[rotorB[i]]     <= i + 6;
					rotorB_inverse[rotorB[i + 1]] <= i + 7;
				end
			end
			7: begin
				for(i = 0;i < 64;i = i + 8)begin
					rotorB[i]   <= rotorB[i + 7];
					rotorB[i+1] <= rotorB[i + 6];
					rotorB[i+2] <= rotorB[i + 5];
					rotorB[i+3] <= rotorB[i + 4];
					rotorB[i+4] <= rotorB[i + 3];
					rotorB[i+5] <= rotorB[i + 2];
					rotorB[i+6] <= rotorB[i + 1];
					rotorB[i+7] <= rotorB[i];
					rotorB_inverse[rotorB[i + 7]] <= i;
					rotorB_inverse[rotorB[i + 6]] <= i + 1;
					rotorB_inverse[rotorB[i + 5]] <= i + 2;
					rotorB_inverse[rotorB[i + 4]] <= i + 3;
					rotorB_inverse[rotorB[i + 3]] <= i + 4;
					rotorB_inverse[rotorB[i + 2]] <= i + 5;
					rotorB_inverse[rotorB[i + 1]] <= i + 6;
					rotorB_inverse[rotorB[i]]     <= i + 7;
				end
			end
			default:  begin
				for(i = 0;i < 64;i = i + 1)begin
					rotorB[i] <= rotorB[i];
					rotorB_inverse[i] <= rotorB_inverse[i];
				end
			end
		endcase
	end
	else begin
		for(i = 0;i < 64;i = i + 1)begin
			rotorB[i] <= rotorB[i];
			rotorB_inverse[i] <= rotorB_inverse[i];
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mode_reg <= 0;
	else if(in_valid && input_cnt == 0) mode_reg <= crypt_mode;
	else mode_reg <= mode_reg;
end

// stage 1
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) stage1_valid <= 0;
	else if(in_valid_2) stage1_valid <= 1;
	else stage1_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) stage1_out <= 0;
	else if(in_valid_2) stage1_out <= code_in;
	else stage1_out <= stage1_out;
end
// stage 2 find rotor A


assign stage2_out_wire = rotorA[stage1_out];
assign shift_num = mode_reg == 1 ?  stage5_out_wire[1:0] : stage2_out_wire[1:0];

assign stage3_out_wire = rotorB[stage2_out_wire];
assign type_num = mode_reg == 1 ?  stage4_out_wire[2:0] :  stage3_out_wire[2:0];

assign stage4_out_wire = 'd63 - stage3_out_wire;
assign stage5_out_wire = rotorB_inverse[stage4_out_wire];
assign stage6_out_wire = rotorA_inverse[stage5_out_wire];
// stage 5 reverse find rotor B
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else if(stage1_valid) out_valid <= 1;
	else out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_code <= 0;
	else if(stage1_valid) out_code <= stage6_out_wire;
	else out_code <= 0;
end


endmodule
