`timescale 1ns/1ps
// Preamble candidate + 30-bit word/BCH decode. This is not ephemeris recovery.
module d1_word_sync (
    input logic clk,reset_n,bit_valid,data_bit,
    input logic [63:0] bit_ref,
    output logic word_valid,bch_valid,polarity_inverted,
    output logic [29:0] raw_word,
    output logic [25:0] information,
    output logic [3:0] word_number,
    output logic [1:0] corrected_bits,
    output logic [63:0] word_ref
);
    localparam logic [10:0] PREAMBLE=11'b11100010010;
    logic aligned;
    logic [10:0] scan;
    logic [29:0] shift;
    logic [4:0] bit_count;
    logic [3:0] current_word;
    logic [63:0] start_ref;
    logic [10:0] scan_next;
    logic [29:0] assembled;
    logic [14:0] left,right,left_fixed,right_fixed;
    logic [3:0] syndrome_left,syndrome_right;
    logic fix_left,fix_right;
    function automatic logic [3:0] syndrome(input logic [14:0] value);
        logic [3:0] r;
        logic feedback;
        begin
            r=0;
            for(integer k=14;k>=0;k=k-1) begin
                feedback=value[k]^r[3];
                r={r[2],r[1],r[0]^feedback,feedback};
            end
            syndrome=r;
        end
    endfunction
    always_comb begin
        scan_next={scan[9:0],data_bit};
        assembled={shift[28:0],data_bit^polarity_inverted};
        left=0;right=0;
        for(integer k=0;k<15;k=k+1) begin left[14-k]=assembled[29-2*k];right[14-k]=assembled[28-2*k];end
        if(current_word==1) right=assembled[14:0];
        syndrome_left=0;syndrome_right=0;
        if(bit_valid && aligned && bit_count==29) begin
            syndrome_left=syndrome(left);syndrome_right=syndrome(right);
        end
        left_fixed=left;right_fixed=right;fix_left=0;fix_right=0;
        if(bit_valid && aligned && bit_count==29) for(integer k=0;k<15;k=k+1) begin
            if(syndrome_left!=0 && syndrome(15'b1<<k)==syndrome_left) begin left_fixed[k]=!left[k];fix_left=1;end
            if(syndrome_right!=0 && syndrome(15'b1<<k)==syndrome_right) begin right_fixed[k]=!right[k];fix_right=1;end
        end
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            aligned<=0;scan<=0;shift<=0;bit_count<=0;current_word<=1;start_ref<=0;
            word_valid<=0;bch_valid<=0;polarity_inverted<=0;raw_word<=0;information<=0;
            word_number<=0;corrected_bits<=0;word_ref<=0;
        end else begin
            word_valid<=0;
            if(bit_valid) begin
                if(!aligned) begin
                    scan<=scan_next;
                    if(scan_next==PREAMBLE || scan_next==~PREAMBLE) begin
                        polarity_inverted<=scan_next!=PREAMBLE;
                        shift<={19'd0,PREAMBLE}; bit_count<=11;current_word<=1;aligned<=1;
                        start_ref<=bit_ref-64'd3273600; // 10 preceding 20 ms bits
                    end
                end else begin
                    if(bit_count==0) start_ref<=bit_ref;
                    shift<=assembled;
                    if(bit_count==29) begin
                        raw_word<=assembled;word_number<=current_word;word_ref<=start_ref;word_valid<=1;
                        if(current_word==1) begin
                            information<={assembled[29:15],right_fixed[14:4]};
                            corrected_bits<={1'b0,fix_right};
                            bch_valid<=syndrome(right_fixed)==0;
                        end else begin
                            information<={4'd0,left_fixed[14:4],right_fixed[14:4]};
                            corrected_bits<=2'(fix_left)+2'(fix_right);
                            bch_valid<=syndrome(left_fixed)==0 && syndrome(right_fixed)==0;
                        end
                        bit_count<=0;
                        if(current_word==10) begin aligned<=0;current_word<=1;scan<=0;end
                        else current_word<=current_word+1'b1;
                    end else bit_count<=bit_count+1'b1;
                end
            end
        end
    end
endmodule
