`timescale 1ns/1ps
// Actual Prompt -> NH20 -> BCH/D1 -> two consecutive complete-frame confirmation.
// Ten-word buffer allows word1 SOW to be filled from word2 before publication.
module navigation_d1 (
    input logic clk,reset_n,locked,prompt_valid,
    input logic signed [27:0] prompt_i,
    input logic [63:0] prompt_ref,prompt_end_ref,
    input logic [42:0] end_code_phase_q,
    input logic [31:0] end_code_period_count,
    input logic [32:0] end_code_step_q,
    input logic [5:0] prn,
    input logic [3:0] channel,
    input logic [7:0] generation,
    output logic nh_valid,frame_valid,time_valid,bch_valid,
    output logic [4:0] nh_phase,
    output logic record_valid,
    input logic record_ready,
    output logic [255:0] record_data
);
    localparam logic [63:0] MODULUS=64'h7fe00000000;
    logic sync_reset_n,bit_valid,data_bit,word_valid,word_bch,polarity;
    logic signed [33:0] bit_soft;
    logic [63:0] bit_ref,word_ref;
    logic [29:0] raw_word;
    logic [25:0] information;
    logic [3:0] word_number;
    logic [1:0] corrected_bits;
    logic [255:0] words[0:9],word_record;
    logic publishing,frame_good,previous_good;
    logic [3:0] publish_index;
    logic [2:0] subframe,previous_subframe;
    logic [7:0] sow_high;
    logic [19:0] sow,previous_sow,assembled_sow;
    logic [63:0] frame_start_ref,previous_frame_ref,samples_from_boundary,anchor_ref,residual_q;
    logic [31:0] anchor_epoch;
    logic [63:0] prompt_meta_ref,bit_meta_ref;
    logic [42:0] prompt_meta_phase,bit_meta_phase;
    logic [31:0] prompt_meta_epoch,bit_meta_epoch;
    logic [32:0] prompt_meta_step,bit_meta_step;
    logic continuity,header_good;
    assign sync_reset_n=reset_n && locked;
    nh20_sync nh(.clk(clk),.reset_n(sync_reset_n),.prompt_valid(prompt_valid && locked),
        .prompt_i(prompt_i),.prompt_ref(prompt_ref),.nh_locked(nh_valid),.nh_phase(nh_phase),
        .bit_valid(bit_valid),.data_bit(data_bit),.bit_soft(bit_soft),.bit_ref(bit_ref));
    d1_word_sync decoder(.clk(clk),.reset_n(sync_reset_n),.bit_valid(bit_valid),.data_bit(data_bit),
        .bit_ref(bit_ref),.word_valid(word_valid),.bch_valid(word_bch),.polarity_inverted(polarity),
        .raw_word(raw_word),.information(information),.word_number(word_number),
        .corrected_bits(corrected_bits),.word_ref(word_ref));
    always_comb begin
        record_valid=publishing && locked;
        record_data=words[publish_index];
        header_good=word_bch && raw_word[29:19]==11'b11100010010 && information[10:8]>=1 && information[10:8]<=5;
        assembled_sow={sow_high,information[21:10]};
        continuity=previous_good && subframe==(previous_subframe==5 ? 3'd1 : previous_subframe+1'b1) &&
            sow==20'((32'(previous_sow)+6)%604800) && frame_start_ref==previous_frame_ref+64'd98208000;
        anchor_ref=bit_meta_ref;anchor_epoch=bit_meta_epoch;residual_q=64'(bit_meta_phase);
        samples_from_boundary=0;
        // Associate D1 word end with the nearest *local* primary-code wrap.
        // Preserve fractional residual at the first integer sample after it.
        if(bit_meta_step!=0) begin
            if(64'(bit_meta_phase)<MODULUS/2) begin
                samples_from_boundary=64'(bit_meta_phase)/64'(bit_meta_step);
                anchor_ref=bit_meta_ref-samples_from_boundary;
                residual_q=64'(bit_meta_phase)-samples_from_boundary*64'(bit_meta_step);
            end else begin
                samples_from_boundary=(MODULUS-64'(bit_meta_phase)+64'(bit_meta_step)-1)/64'(bit_meta_step);
                anchor_ref=bit_meta_ref+samples_from_boundary;anchor_epoch=bit_meta_epoch+1'b1;
                residual_q=64'(bit_meta_phase)+samples_from_boundary*64'(bit_meta_step)-MODULUS;
            end
        end
        word_record=0;
        word_record[7:0]=8'd2;word_record[13:8]=prn;word_record[17:14]=channel;
        word_record[22:18]=5'b11111;word_record[31:24]=generation;
        word_record[95:32]=anchor_ref;word_record[125:96]=raw_word;
        word_record[151:126]=information;word_record[155:152]=word_number;
        word_record[158:156]=word_number==1 ? information[10:8] : subframe;
        word_record[178:159]=word_number==2 ? assembled_sow : sow;
        word_record[180:179]=corrected_bits;word_record[196:181]=anchor_epoch[15:0];
        word_record[207:197]=11'd0;word_record[239:208]=residual_q[31:0];
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            publishing<=0;publish_index<=0;frame_good<=0;previous_good<=0;
            subframe<=0;previous_subframe<=0;sow_high<=0;sow<=0;previous_sow<=0;
            frame_start_ref<=0;previous_frame_ref<=0;frame_valid<=0;time_valid<=0;bch_valid<=0;
            prompt_meta_ref<=0;bit_meta_ref<=0;prompt_meta_phase<=0;bit_meta_phase<=0;
            prompt_meta_epoch<=0;bit_meta_epoch<=0;prompt_meta_step<=0;bit_meta_step<=0;
        end else if(!locked) begin
            publishing<=0;publish_index<=0;frame_good<=0;previous_good<=0;
            frame_valid<=0;time_valid<=0;bch_valid<=0;
        end else begin
            if(prompt_valid) begin
                prompt_meta_ref<=prompt_end_ref;prompt_meta_phase<=end_code_phase_q;
                prompt_meta_epoch<=end_code_period_count;prompt_meta_step<=end_code_step_q;
            end
            if(bit_valid) begin
                bit_meta_ref<=prompt_meta_ref;bit_meta_phase<=prompt_meta_phase;
                bit_meta_epoch<=prompt_meta_epoch;bit_meta_step<=prompt_meta_step;
            end
            if(record_valid && record_ready) begin
                if(publish_index==9) begin publishing<=0;publish_index<=0;end
                else publish_index<=publish_index+1'b1;
            end
            if(word_valid) begin
                bch_valid<=word_bch;
                if(word_number>=1 && word_number<=10) words[word_number-1'b1]<=word_record;
                if(word_number==1) begin
                    frame_good<=header_good;subframe<=information[10:8];sow_high<=information[7:0];
                    frame_start_ref<=word_ref;
                    if(!header_good) begin frame_valid<=0;time_valid<=0;previous_good<=0;end
                end else if(word_number==2) begin
                    sow<=assembled_sow;words[0][178:159]<=assembled_sow;
                    frame_good<=frame_good && word_bch && assembled_sow<604800;
                end else frame_good<=frame_good && word_bch;
                if(word_number==10) begin
                    if(frame_good && word_bch) begin
                        previous_good<=1;previous_subframe<=subframe;previous_sow<=sow;previous_frame_ref<=frame_start_ref;
                        if(continuity && !publishing) begin
                            frame_valid<=1;time_valid<=1;publishing<=1;publish_index<=0;
                        end else begin frame_valid<=0;time_valid<=0;end
                    end else begin previous_good<=0;frame_valid<=0;time_valid<=0;end
                end
            end
        end
    end
endmodule
