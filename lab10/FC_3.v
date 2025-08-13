module FC_3 (
    // === I/O ===
    input  [2:0] in0,   // sw0 ~ sw2
    input  [2:0] in1,   // sw3 ~ sw5
    input  [2:0] in2,   // sw6 ~ sw8
    output [11:0] out0,
    output [11:0] out1,
    output [11:0] out2
);
    assign out0 = 16 * in0 + 9 * in1 + 17 * in2;
    assign out1 = 36 * in0 + 13 * in1 + 33 * in2;
    assign out2 = 35 * in0 + 34 * in1 + 48 * in2;
endmodule
