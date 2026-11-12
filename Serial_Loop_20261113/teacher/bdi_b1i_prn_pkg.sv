`timescale 1ns/1ps

// BeiDou B1I PRN code definitions for SV IDs 6 through 11.
//
// Stage numbering follows BDS-SIS-ICD-B1I: the seed string is written as
// stages [1:11].  A code chip is G1[11] XOR the selected G2 stages.  The
// balanced Gold sequence is truncated to 2046 chips and then repeated.
package bdi_b1i_prn_pkg;
    localparam int PRN_CODE_LEN = 2046;
    localparam logic [10:0] LFSR_SEED = 11'b01010101010;

    function automatic logic [PRN_CODE_LEN-1:0] make_b1i_code(
        input integer tap_a,
        input integer tap_b
    );
        logic [10:0] g1;
        logic [10:0] g2;
        logic g1_feedback;
        logic g2_feedback;
        integer chip;
        begin
            g1 = LFSR_SEED;
            g2 = LFSR_SEED;
            make_b1i_code = '0;
            for (chip = 0; chip < PRN_CODE_LEN; chip = chip + 1) begin
                // Packed bit 10 is stage 1 and packed bit 0 is stage 11.
                make_b1i_code[PRN_CODE_LEN-1-chip] =
                    g1[0] ^ g2[11-tap_a] ^ g2[11-tap_b];

                // G1(X)=1+X+X^7+X^8+X^9+X^10+X^11
                g1_feedback = g1[10] ^ g1[4] ^ g1[3] ^
                              g1[2] ^ g1[1] ^ g1[0];
                // G2(X)=1+X+X^2+X^3+X^4+X^5+X^8+X^9+X^11
                g2_feedback = g2[10] ^ g2[9] ^ g2[8] ^ g2[7] ^
                              g2[6] ^ g2[3] ^ g2[2] ^ g2[0];
                g1 = {g1_feedback, g1[10:1]};
                g2 = {g2_feedback, g2[10:1]};
            end
        end
    endfunction

    localparam logic [PRN_CODE_LEN-1:0] B1I_CODE_SV6  = make_b1i_code(1, 9);
    localparam logic [PRN_CODE_LEN-1:0] B1I_CODE_SV7  = make_b1i_code(1, 10);
    localparam logic [PRN_CODE_LEN-1:0] B1I_CODE_SV8  = make_b1i_code(1, 11);
    localparam logic [PRN_CODE_LEN-1:0] B1I_CODE_SV9  = make_b1i_code(2, 7);
    localparam logic [PRN_CODE_LEN-1:0] B1I_CODE_SV10 = make_b1i_code(3, 4);
    localparam logic [PRN_CODE_LEN-1:0] B1I_CODE_SV11 = make_b1i_code(3, 5);

    function automatic logic b1i_code_bit(
        input integer sv_id,
        input logic [10:0] index
    );
        begin
            case (sv_id)
                6:  b1i_code_bit = B1I_CODE_SV6 [PRN_CODE_LEN-1-index];
                7:  b1i_code_bit = B1I_CODE_SV7 [PRN_CODE_LEN-1-index];
                8:  b1i_code_bit = B1I_CODE_SV8 [PRN_CODE_LEN-1-index];
                9:  b1i_code_bit = B1I_CODE_SV9 [PRN_CODE_LEN-1-index];
                10: b1i_code_bit = B1I_CODE_SV10[PRN_CODE_LEN-1-index];
                11: b1i_code_bit = B1I_CODE_SV11[PRN_CODE_LEN-1-index];
                default: b1i_code_bit = 1'b0;
            endcase
        end
    endfunction
endpackage

