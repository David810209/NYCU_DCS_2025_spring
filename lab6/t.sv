`timescale 1ns/10ps
module pattern(
  // output signals
	clk,
	rst_n,
    in_number,
    mode,
    in_valid,
  // input signals
	out_valid,
	out_result
);

output logic  clk,rst_n,in_valid;
output logic signed [3:0] in_number ;
output logic [1:0] mode;
logic signed [3:0] in1,in2,in3,in4,tmp;
logic signed [3:0] innumber [3:0] ;
input out_valid;
input signed [5:0] out_result;
logic signed [5:0] golden;
integer i;
logic valid_reg;
//================================================================
// parameters & integer
//================================================================
//REMIND :do not move PATNUM && CYCLE
integer PATNUM = 100;
integer CYCLE = 10;
integer total_latency;
integer patcount;
integer latency;
integer lat_en;
//================================================================
// initial
//================================================================

always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;


initial begin
	in_valid = 0;
	rst_n = 1;
	force clk = 0;
	reset_task;
	release clk;
	total_latency = 0; 
	latency = 0;
    @(negedge clk);
	patcount = 0;

	for (patcount=0;patcount<PATNUM;patcount=patcount+1)begin
		input_task;
		wait_outvalid;
		check_ans;
		outvalid_rst;
		@(negedge clk);
	end

	YOU_PASS_task;  
    $finish;
end

//================================================================
// task
//================================================================

// let rst_n = 0 for 3 cycles & check SPEC1(All output signals should be reset after the reset signal is asserted)
task reset_task ; begin
    //finish the task here vvv
    rst_n = 1'b0; 
	#(CYCLE*3.0); 
	rst_n = 1'b1; 
	//finish the task here vvv
	if(out_valid != 'b0 || out_result != 'b0)begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                    SPEC 1 FAIL                                                              ");
		$display ("                                                                       Reset                                                                ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		repeat (2) #(CYCLE);
		$finish ;
	end
	#(CYCLE*2.0);
end endtask

//generate random inputs & assign to in_number in the specific cycle & calculate the golden value
task input_task ; begin
    //finish the task here vvv
	for(i=0;i<4;i=i+1)begin
		innumber[i] = $urandom_range(-8,7);
	end
	in1 = innumber[0];
	in2 = innumber[1];
	in3 = innumber[2];
	in4 = innumber[3];
	if (in1 > in2) begin
		tmp = in1;
		in1 = in2;
		in2 = tmp;
	end
	if (in2 > in3) begin
		tmp = in2;
		in2 = in3;
		in3 = tmp;
	end
	if (in3 > in4) begin
		tmp = in3;
		in3 = in4;
		in4 = tmp;
	end
	if (in1 > in2) begin
		tmp = in1;
		in1 = in2;
		in2 = tmp;
	end
	if (in2 > in3) begin
		tmp = in2;
		in2 = in3;
		in3 = tmp;
	end
	if (in1 > in2) begin
		tmp = in1;
		in1 = in2;
		in2 = tmp;
	end
	mode = $urandom_range(0,3);
	if(mode == 0) begin
		golden = in1 + in2;
	end
	else if(mode == 1) begin
		golden = in2 - in1;
	end
	else if(mode == 2) begin
		golden = in4 - in3;
	end
	else if(mode == 3) begin
		golden = in1 - in4;
	end
	repeat (3) @(negedge clk);
	in_valid = 1'b1;
	latency = 0;
	lat_en  = 1;
	for(i=0;i<4;i=i+1)begin
		in_number = innumber[i];
		no_outvalid;
		@(negedge clk);
	end
	in_valid = 1'b0;
	in_number = 4'bx;
	mode = 2'bx;
	//finish the task here vvv
end endtask

// Wait until out_valid is high
always @(negedge clk) begin
    if (lat_en) begin
        latency <= latency + 1;
    end
end

always @(posedge clk) begin
	if (out_valid === 1) begin
		valid_reg = 1;
	end
	else  begin
		valid_reg = 0;
	end
end

// check SPEC2 (The out_valid must be high for exact 1 cycles during output)
task outvalid_rst;begin
    //finish the task here vvv
	@(negedge clk);
	if (valid_reg === 1 && out_valid === 1) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                    SPEC 2 FAIL                                                              ");
		$display ("                                                         Output should be zero after check                                                  ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish ;
	end
	//finish the task here vvv
    
	//finish the task here vvv
end endtask

// check SPEC3 (Outvalid cannot overlap with in_valid)
task no_outvalid ; begin
    //finish the task here vvv
    if (in_valid === 1'b1 && out_valid === 1'b1) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                    SPEC 3 FAIL                                                              ");
		$display ("                                                Outvalid should be zero before give data finish                                            ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish ;
	end
    
	//finish the task here vvv
end endtask

//check SPEC4 (The execution latency should not over 100 cycles)
task wait_outvalid ; begin
    //finish the task here vvv
    while(out_valid !== 1'b1) begin
		if(latency > 100) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                    SPEC 4 FAIL                                                              ");
			$display ("                                                  The execution latency are over 100  cycles                                            ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			repeat (2) @(negedge clk);
			$finish ;
		end
		@(negedge clk);
	end
	lat_en  = 0;
	//finish the task here vvv
end endtask

// check SPEC5 (The output should be correct when out_valid is high)
task check_ans ; begin
    if(out_valid === 1) begin
        if (golden!== out_result)begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                    SPEC 5 FAIL                                                             ");
            $display ("                                                                    YOUR:  %d                                                 ",out_result);
            $display ("                                                                    GOLDEN: %d                                                    ",golden);
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	    $finish ;
        end
    end
end endtask



/*
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 1 FAIL                                                              ");
$display ("                                                                       Reset                                                                ");
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 2 FAIL                                                              ");
$display ("                                                         Output should be zero after check                                                  ");
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 3 FAIL                                                               ");
$display ("                                                Outvalid should be zero before give data finish                                            ");
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 4 FAIL                                                               ");
$display ("                                                  The execution latency are over 100  cycles                                            ");
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                                    SPEC 5 FAIL                                                             ");
$display ("                                                                    YOUR:  %d                                                 ",out_result);
$display ("                                                                    GOLDEN: %d                                                    ",golden);
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
*/

task YOU_PASS_task;begin

$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                               Congratulations!                						             ");
$display ("                                                        You have passed all patterns!          						             ");
$display ("                                                                time: %8t ns                                                        ",$time);
$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

$finish;	
end endtask

endmodule


