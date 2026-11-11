`timescale 1ns/1ps

// BeiDou B1I ranging-code generator for MEO/IGSO PRNs 6 through 37.
//
// Source: BDS-SIS-ICD-2.1, section 4.3, figure 4-1 and table 4-2.
// Stage numbering in this module follows the ICD: state[10] is stage 1 and
// state[0] is stage 11.  The current chip is consumed before chip_enable
// advances the LFSRs.  After chip index 2045 is consumed, the omitted 2047th
// Gold-code chip is skipped and the generator returns to the initial phase.
module b1i_prn_gen (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        load,
  input  logic        chip_enable,
  input  logic [5:0]  prn_select,
  output logic        chip,
  output logic [10:0] chip_index,
  output logic        configured,
  output logic        epoch
);

  localparam logic [10:0] LFSR_INITIAL = 11'b01010101010;

  logic [10:0] g1_state;
  logic [10:0] g2_state;
  logic [5:0]  active_prn;
  logic        g1_feedback;
  logic        g2_feedback;
  logic        g2_phase;
  logic        selected_prn_valid;

  function automatic logic prn_is_supported(input logic [5:0] prn);
    begin
      prn_is_supported = (prn >= 6) && (prn <= 37);
    end
  endfunction

  // Table 4-2 G2 phase selection.  Array bit [10] is ICD stage 1.
  function automatic logic select_g2_phase(
    input logic [10:0] state,
    input logic [5:0]  prn
  );
    begin
      case (prn)
        6:  select_g2_phase = state[10] ^ state[2];  // 1 xor 9
        7:  select_g2_phase = state[10] ^ state[1];  // 1 xor 10
        8:  select_g2_phase = state[10] ^ state[0];  // 1 xor 11
        9:  select_g2_phase = state[9]  ^ state[4];  // 2 xor 7
        10: select_g2_phase = state[8]  ^ state[7];  // 3 xor 4
        11: select_g2_phase = state[8]  ^ state[6];  // 3 xor 5
        12: select_g2_phase = state[8]  ^ state[5];  // 3 xor 6
        13: select_g2_phase = state[8]  ^ state[3];  // 3 xor 8
        14: select_g2_phase = state[8]  ^ state[2];  // 3 xor 9
        15: select_g2_phase = state[8]  ^ state[1];  // 3 xor 10
        16: select_g2_phase = state[8]  ^ state[0];  // 3 xor 11
        17: select_g2_phase = state[7]  ^ state[6];  // 4 xor 5
        18: select_g2_phase = state[7]  ^ state[5];  // 4 xor 6
        19: select_g2_phase = state[7]  ^ state[3];  // 4 xor 8
        20: select_g2_phase = state[7]  ^ state[2];  // 4 xor 9
        21: select_g2_phase = state[7]  ^ state[1];  // 4 xor 10
        22: select_g2_phase = state[7]  ^ state[0];  // 4 xor 11
        23: select_g2_phase = state[6]  ^ state[5];  // 5 xor 6
        24: select_g2_phase = state[6]  ^ state[3];  // 5 xor 8
        25: select_g2_phase = state[6]  ^ state[2];  // 5 xor 9
        26: select_g2_phase = state[6]  ^ state[1];  // 5 xor 10
        27: select_g2_phase = state[6]  ^ state[0];  // 5 xor 11
        28: select_g2_phase = state[5]  ^ state[3];  // 6 xor 8
        29: select_g2_phase = state[5]  ^ state[2];  // 6 xor 9
        30: select_g2_phase = state[5]  ^ state[1];  // 6 xor 10
        31: select_g2_phase = state[5]  ^ state[0];  // 6 xor 11
        32: select_g2_phase = state[3]  ^ state[2];  // 8 xor 9
        33: select_g2_phase = state[3]  ^ state[1];  // 8 xor 10
        34: select_g2_phase = state[3]  ^ state[0];  // 8 xor 11
        35: select_g2_phase = state[2]  ^ state[1];  // 9 xor 10
        36: select_g2_phase = state[2]  ^ state[0];  // 9 xor 11
        37: select_g2_phase = state[1]  ^ state[0];  // 10 xor 11
        default: select_g2_phase = 1'b0;
      endcase
    end
  endfunction

  always_comb begin
    selected_prn_valid = prn_is_supported(prn_select);

    // G1(X) = 1 + X + X^7 + X^8 + X^9 + X^10 + X^11
    g1_feedback = g1_state[10] ^ g1_state[4] ^ g1_state[3]
                ^ g1_state[2] ^ g1_state[1] ^ g1_state[0];

    // G2(X) = 1 + X + X^2 + X^3 + X^4 + X^5 + X^8 + X^9 + X^11
    g2_feedback = g2_state[10] ^ g2_state[9] ^ g2_state[8]
                ^ g2_state[7] ^ g2_state[6] ^ g2_state[3]
                ^ g2_state[2] ^ g2_state[0];

    g2_phase = select_g2_phase(g2_state, active_prn);
    chip = configured ? (g1_state[0] ^ g2_phase) : 1'b0;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      g1_state   <= LFSR_INITIAL;
      g2_state   <= LFSR_INITIAL;
      active_prn <= 6'd0;
      chip_index <= 11'd0;
      configured <= 1'b0;
      epoch      <= 1'b0;
    end else begin
      epoch <= 1'b0;

      if (load) begin
        g1_state   <= LFSR_INITIAL;
        g2_state   <= LFSR_INITIAL;
        active_prn <= prn_select;
        chip_index <= 11'd0;
        configured <= selected_prn_valid;
      end else if (chip_enable && configured) begin
        if (chip_index == 11'd2045) begin
          g1_state   <= LFSR_INITIAL;
          g2_state   <= LFSR_INITIAL;
          chip_index <= 11'd0;
          epoch      <= 1'b1;
        end else begin
          g1_state   <= {g1_feedback, g1_state[10:1]};
          g2_state   <= {g2_feedback, g2_state[10:1]};
          chip_index <= chip_index + 1'b1;
        end
      end
    end
  end

endmodule
