`timescale 1ns/1ps
// M2 only. Four codings of the same 16x32 table.
// y follows a free address. y1 and y15 are separate instances with the
// address tied to 1 and 15, so a preserved table becomes those constants
// and a dropped table becomes zero.
//   mem[1]  = 32'h000001A5
//   mem[15] = 32'h80000001

module rom_readmem_word (
    input [3:0] a,
    output [31:0] y
);
    reg [31:0] mem [0:15];
    initial $readmemh("tiny.mem", mem);
    assign y = mem[a];
endmodule

module rom_case_word (
    input [3:0] a,
    output reg [31:0] y
);
    always @(*) begin
        case (a)
            4'h0: y = 32'h00000011;
            4'h1: y = 32'h000001A5;
            4'h2: y = 32'h0000005A;
            4'h3: y = 32'hFFFFFFF0;
            4'h4: y = 32'h0000000F;
            4'h5: y = 32'h11111111;
            4'h6: y = 32'h22222222;
            4'h7: y = 32'h33333333;
            4'h8: y = 32'h44444444;
            4'h9: y = 32'h55555555;
            4'hA: y = 32'h66666666;
            4'hB: y = 32'h77777777;
            4'hC: y = 32'h88888888;
            4'hD: y = 32'h99999999;
            4'hE: y = 32'hAAAAAAAA;
            4'hF: y = 32'h80000001;
            default: y = 32'h00000000;
        endcase
    end
endmodule

module rom_func_word (
    input [3:0] a,
    output [31:0] y
);
    function [31:0] lut;
        input [3:0] i;
        begin
            case (i)
                4'h0: lut = 32'h00000011;
                4'h1: lut = 32'h000001A5;
                4'h2: lut = 32'h0000005A;
                4'h3: lut = 32'hFFFFFFF0;
                4'h4: lut = 32'h0000000F;
                4'h5: lut = 32'h11111111;
                4'h6: lut = 32'h22222222;
                4'h7: lut = 32'h33333333;
                4'h8: lut = 32'h44444444;
                4'h9: lut = 32'h55555555;
                4'hA: lut = 32'h66666666;
                4'hB: lut = 32'h77777777;
                4'hC: lut = 32'h88888888;
                4'hD: lut = 32'h99999999;
                4'hE: lut = 32'hAAAAAAAA;
                4'hF: lut = 32'h80000001;
                default: lut = 32'h00000000;
            endcase
        end
    endfunction
    assign y = lut(a);
endmodule

module rom_param_word (
    input [3:0] a,
    output [31:0] y
);
    // Word 0 is bits [31:0]. Word 15 is bits [511:480].
    parameter [511:0] MEM = {
        32'h80000001, 32'hAAAAAAAA, 32'h99999999, 32'h88888888,
        32'h77777777, 32'h66666666, 32'h55555555, 32'h44444444,
        32'h33333333, 32'h22222222, 32'h11111111, 32'h0000000F,
        32'hFFFFFFF0, 32'h0000005A, 32'h000001A5, 32'h00000011
    };
    assign y = MEM[a * 32 +: 32];
endmodule

// Constant addresses are in the same module so DC folds them to tie cells.
// A separate instance kept the address tied but did not propagate the value.
module rom_readmem (input [3:0] a, output [31:0] y, y1, y15);
    reg [31:0] mem [0:15];
    initial $readmemh("tiny.mem", mem);
    assign y = mem[a];
    assign y1 = mem[4'h1];
    assign y15 = mem[4'hF];
endmodule

module rom_case (input [3:0] a, output reg [31:0] y, y1, y15);
    always @(*) begin
        case (a)
            4'h0: y = 32'h00000011;
            4'h1: y = 32'h000001A5;
            4'h2: y = 32'h0000005A;
            4'h3: y = 32'hFFFFFFF0;
            4'h4: y = 32'h0000000F;
            4'h5: y = 32'h11111111;
            4'h6: y = 32'h22222222;
            4'h7: y = 32'h33333333;
            4'h8: y = 32'h44444444;
            4'h9: y = 32'h55555555;
            4'hA: y = 32'h66666666;
            4'hB: y = 32'h77777777;
            4'hC: y = 32'h88888888;
            4'hD: y = 32'h99999999;
            4'hE: y = 32'hAAAAAAAA;
            4'hF: y = 32'h80000001;
            default: y = 32'h00000000;
        endcase
        case (4'h1)
            4'h0: y1 = 32'h00000011;
            4'h1: y1 = 32'h000001A5;
            4'h2: y1 = 32'h0000005A;
            4'h3: y1 = 32'hFFFFFFF0;
            4'h4: y1 = 32'h0000000F;
            4'h5: y1 = 32'h11111111;
            4'h6: y1 = 32'h22222222;
            4'h7: y1 = 32'h33333333;
            4'h8: y1 = 32'h44444444;
            4'h9: y1 = 32'h55555555;
            4'hA: y1 = 32'h66666666;
            4'hB: y1 = 32'h77777777;
            4'hC: y1 = 32'h88888888;
            4'hD: y1 = 32'h99999999;
            4'hE: y1 = 32'hAAAAAAAA;
            4'hF: y1 = 32'h80000001;
            default: y1 = 32'h00000000;
        endcase
        case (4'hF)
            4'h0: y15 = 32'h00000011;
            4'h1: y15 = 32'h000001A5;
            4'h2: y15 = 32'h0000005A;
            4'h3: y15 = 32'hFFFFFFF0;
            4'h4: y15 = 32'h0000000F;
            4'h5: y15 = 32'h11111111;
            4'h6: y15 = 32'h22222222;
            4'h7: y15 = 32'h33333333;
            4'h8: y15 = 32'h44444444;
            4'h9: y15 = 32'h55555555;
            4'hA: y15 = 32'h66666666;
            4'hB: y15 = 32'h77777777;
            4'hC: y15 = 32'h88888888;
            4'hD: y15 = 32'h99999999;
            4'hE: y15 = 32'hAAAAAAAA;
            4'hF: y15 = 32'h80000001;
            default: y15 = 32'h00000000;
        endcase
    end
endmodule

module rom_func (input [3:0] a, output [31:0] y, y1, y15);
    function [31:0] lut;
        input [3:0] i;
        begin
            case (i)
                4'h0: lut = 32'h00000011;
                4'h1: lut = 32'h000001A5;
                4'h2: lut = 32'h0000005A;
                4'h3: lut = 32'hFFFFFFF0;
                4'h4: lut = 32'h0000000F;
                4'h5: lut = 32'h11111111;
                4'h6: lut = 32'h22222222;
                4'h7: lut = 32'h33333333;
                4'h8: lut = 32'h44444444;
                4'h9: lut = 32'h55555555;
                4'hA: lut = 32'h66666666;
                4'hB: lut = 32'h77777777;
                4'hC: lut = 32'h88888888;
                4'hD: lut = 32'h99999999;
                4'hE: lut = 32'hAAAAAAAA;
                4'hF: lut = 32'h80000001;
                default: lut = 32'h00000000;
            endcase
        end
    endfunction
    assign y = lut(a);
    assign y1 = lut(4'h1);
    assign y15 = lut(4'hF);
endmodule

module rom_param (input [3:0] a, output [31:0] y, y1, y15);
    parameter [511:0] MEM = {
        32'h80000001, 32'hAAAAAAAA, 32'h99999999, 32'h88888888,
        32'h77777777, 32'h66666666, 32'h55555555, 32'h44444444,
        32'h33333333, 32'h22222222, 32'h11111111, 32'h0000000F,
        32'hFFFFFFF0, 32'h0000005A, 32'h000001A5, 32'h00000011
    };
    assign y = MEM[a * 32 +: 32];
    assign y1 = MEM[32 +: 32];
    assign y15 = MEM[480 +: 32];
endmodule

module pad_logic_probe (
    inout PAD,
    output C
);
    PDDW08DGZ_H_G u (
        .I(1'b0), .OEN(1'b1), .REN(1'b0), .PAD(PAD), .C(C)
    );
endmodule

module pad_pg_probe (
    inout PAD,
    output C,
    inout POC,
    inout VDD,
    inout VSS,
    inout VDDPST,
    inout VSSPST
);
    PDDW08DGZ_H_G u (
        .I(1'b0), .OEN(1'b1), .REN(1'b0), .PAD(PAD), .C(C),
        .POC(POC), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST)
    );
endmodule
