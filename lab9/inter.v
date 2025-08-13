module inter(
	// Input signals
	clk,
	rst_n,
	in_valid_1,
	in_valid_2,
	in_valid_3,
	data_in_1,
	data_in_2,
	data_in_3,
	ready_slave1,
	ready_slave2,
	// Output signals
	valid_slave1,
	valid_slave2,
	addr_out,
	value_out,
	handshake_slave1,
	handshake_slave2
);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
input				clk, rst_n, in_valid_1, in_valid_2, in_valid_3;
input 		[6:0]	data_in_1, data_in_2, data_in_3; 
input 				ready_slave1, ready_slave2;
output	reg			valid_slave1, valid_slave2;
output	reg	[2:0] 	addr_out, value_out;
output	reg			handshake_slave1, handshake_slave2;

//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------

reg [1:0] state;
reg [1:0] next_state;

reg slave_sel_reg_3, slave_sel_reg_1, slave_sel_reg_2;
reg [2:0] data_reg_3, data_reg_1, data_reg_2;
reg [2:0] addr_reg_3, addr_reg_1, addr_reg_2;
reg strobe_reg_3, strobe_reg_1, strobe_reg_2;
reg [1:0] current_process_master;
reg current_slave;

parameter S_idle = 2'b00,
            S_master1 = 2'b01,
            S_master2 = 2'b10,  
            S_master3 = 2'b11;
    
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_idle;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        S_idle: begin
            if (in_valid_1 || strobe_reg_1) begin
                next_state = S_master1;
            end else if (in_valid_2 || strobe_reg_2) begin
                next_state = S_master2;
            end else if (in_valid_3 || strobe_reg_3) begin
                next_state = S_master3;
            end else begin
                next_state = S_idle;
            end
        end

        S_master1: begin
            if ((ready_slave1 && valid_slave1) || (ready_slave2 && valid_slave2)) begin
                next_state = S_idle;
            end else begin
                next_state = S_master1;
            end
        end

        S_master2: begin
            if ((ready_slave1 && valid_slave1) || (ready_slave2 && valid_slave2))  begin
                next_state = S_idle;
            end else begin
                next_state = S_master2;
            end
        end

        S_master3: begin
            if((ready_slave1 && valid_slave1) || (ready_slave2 && valid_slave2))  begin
                next_state = S_idle;
            end else begin
                next_state = S_master3;
            end
        end
        default: next_state = S_idle;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_process_master <= 0;
    end else if (state == S_idle && next_state == S_master1) begin
        current_process_master <= 1;
    end else if (state == S_idle && next_state == S_master2) begin
        current_process_master <= 2;
    end else if (state == S_idle && next_state == S_master3) begin
        current_process_master <= 3;
    end else begin
        current_process_master <= current_process_master;
    end
end

assign current_slave = (current_process_master == 1) ? slave_sel_reg_1 :
                       (current_process_master == 2) ? slave_sel_reg_2 : slave_sel_reg_3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        strobe_reg_1 <= 0;
        slave_sel_reg_1 <= 0;
        addr_reg_1 <= 0;
        data_reg_1 <= 0;
    end else if(in_valid_1) begin
        strobe_reg_1 <= 1;
        slave_sel_reg_1 <= data_in_1[6];
        addr_reg_1 <= data_in_1[5:3];
        data_reg_1 <= data_in_1[2:0];
    end  else if(state == S_master1 && next_state == S_idle) begin
        strobe_reg_1 <= 0;
        slave_sel_reg_1 <= 0;
        addr_reg_1 <= 0;
        data_reg_1 <= 0;
    end  else begin
        strobe_reg_1 <= strobe_reg_1;
        slave_sel_reg_1 <= slave_sel_reg_1;
        addr_reg_1 <= addr_reg_1;
        data_reg_1 <= data_reg_1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        strobe_reg_2 <= 0;
        slave_sel_reg_2 <= 0;
        addr_reg_2 <= 0;
        data_reg_2 <= 0;
    end else if(in_valid_2) begin
        strobe_reg_2 <= 1;
        slave_sel_reg_2 <= data_in_2[6];
        addr_reg_2 <= data_in_2[5:3];
        data_reg_2 <= data_in_2[2:0];
    end  else if(state == S_master2 && next_state == S_idle) begin
        strobe_reg_2 <= 0;
        slave_sel_reg_2 <= 0;
        addr_reg_2 <= 0;
        data_reg_2 <= 0;
    end  else begin
        strobe_reg_2 <= strobe_reg_2;
        slave_sel_reg_2 <= slave_sel_reg_2;
        addr_reg_2 <= addr_reg_2;
        data_reg_2 <= data_reg_2;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        strobe_reg_3 <= 0;
        slave_sel_reg_3 <= 0;
        addr_reg_3 <= 0;
        data_reg_3 <= 0;
    end else if(in_valid_3) begin
        strobe_reg_3 <= 1;
        slave_sel_reg_3 <= data_in_3[6];
        addr_reg_3 <= data_in_3[5:3];
        data_reg_3 <= data_in_3[2:0];
    end  else if(state == S_master3 && next_state == S_idle) begin
        strobe_reg_3 <= 0;
        slave_sel_reg_3 <= 0;
        addr_reg_3 <= 0;
        data_reg_3 <= 0;
    end  else begin
        strobe_reg_3 <= strobe_reg_3;
        slave_sel_reg_3 <= slave_sel_reg_3;
        addr_reg_3 <= addr_reg_3;
        data_reg_3 <= data_reg_3;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        handshake_slave1 <= 0;
    end else if(state != S_idle && next_state == S_idle && current_slave == 0) begin
        handshake_slave1 <= 1;
    end  else begin
        handshake_slave1 <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        handshake_slave2 <= 0;
    end else if(state != S_idle && next_state == S_idle && current_slave == 1) begin
        handshake_slave2 <= 1;
    end  else begin
        handshake_slave2 <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_slave1 <= 0;
    end else if((state != S_idle && current_slave == 0)) begin
        valid_slave1 <= 1;
    end  else begin
        valid_slave1 <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_slave2 <= 0;
    end else if(state != S_idle && current_slave == 1) begin
        valid_slave2 <= 1;
    end  else begin
        valid_slave2 <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_out <= 0;
        value_out <= 0;
    end else if(current_process_master == 1) begin
        addr_out <= addr_reg_1;
        value_out <= data_reg_1;
    end else if(current_process_master == 2) begin
        addr_out <= addr_reg_2;
        value_out <= data_reg_2;
    end else   begin
        addr_out <= addr_reg_3;
        value_out <= data_reg_3;
    end
end

endmodule




