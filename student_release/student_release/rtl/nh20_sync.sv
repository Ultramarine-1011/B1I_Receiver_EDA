`timescale 1ns/1ps
// 20 phase hypotheses, scores from 400 actual 1 ms Prompt events.
module nh20_sync (
    input logic clk,reset_n,
    input logic prompt_valid,
    input logic signed [27:0] prompt_i,
    input logic [63:0] prompt_ref,
    output logic nh_locked,
    output logic [4:0] nh_phase,
    output logic bit_valid, data_bit,
    output logic signed [33:0] bit_soft,
    output logic [63:0] bit_ref
);
    localparam logic [19:0] NH=20'b00000100110101001110; // ICD 5.2.1, MSB first
    logic [4:0] tick_mod;
    logic [8:0] training_count;
    logic signed [33:0] sums[0:19], sums_next[0:19];
    logic [63:0] scores[0:19],scores_next[0:19];
    logic [63:0] best,second;
    logic [4:0] best_phase;
    logic signed [33:0] term,total,run_sum;
    logic bit_started;
    logic [63:0] start_ref;
    integer position;
    always_comb begin
        best=0;second=0;best_phase=0;term=0;total=0;position=0;
        for(integer h=0;h<20;h=h+1) begin
            position=(int'(tick_mod)+h)%20;
            term=34'($signed(prompt_i));
            if(NH[19-position]) term=-term;
            total=sums[h]+term;
            sums_next[h]=total; scores_next[h]=scores[h];
            if(position==19) begin
                sums_next[h]=0;
                if(training_count>=20) scores_next[h]=scores[h]+64'(total<0 ? -total : total);
            end
            if(scores_next[h]>best) begin second=best;best=scores_next[h];best_phase=5'(h);end
            else if(scores_next[h]>second) second=scores_next[h];
        end
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            tick_mod<=0;training_count<=0;nh_locked<=0;nh_phase<=0;
            bit_valid<=0;data_bit<=0;bit_soft<=0;bit_ref<=0;
            run_sum<=0;bit_started<=0;start_ref<=0;
            for(integer h=0;h<20;h=h+1) begin sums[h]<=0;scores[h]<=0;end
        end else begin
            bit_valid<=0;
            if(prompt_valid) begin
                tick_mod<=tick_mod==19 ? 5'd0 : tick_mod+1'b1;
                if(!nh_locked) begin
                    for(integer h=0;h<20;h=h+1) begin sums[h]<=sums_next[h];scores[h]<=scores_next[h];end
                    if(training_count==399) begin
                        if(best>0 && best>2*second) begin nh_locked<=1;nh_phase<=best_phase;end
                        // Failed confidence restarts training, never asserts fake sync.
                        training_count<=0;
                        for(integer h=0;h<20;h=h+1) begin sums[h]<=0;scores[h]<=0;end
                    end else training_count<=training_count+1'b1;
                end else begin
                    if((int'(tick_mod)+int'(nh_phase))%20==0) begin
                        run_sum<=34'($signed(prompt_i)); // NH[0]=0
                        start_ref<=prompt_ref;bit_started<=1;
                    end else begin
                        if(NH[19-((int'(tick_mod)+int'(nh_phase))%20)])
                            run_sum<=run_sum-34'($signed(prompt_i));
                        else run_sum<=run_sum+34'($signed(prompt_i));
                        if((int'(tick_mod)+int'(nh_phase))%20==19 && bit_started) begin
                            bit_soft<=run_sum+34'($signed(prompt_i)); // NH[19]=0
                            data_bit<=(run_sum+34'($signed(prompt_i)))<0;
                            bit_ref<=start_ref;bit_valid<=1;bit_started<=0;run_sum<=0;
                        end
                    end
                end
            end
        end
    end
endmodule
