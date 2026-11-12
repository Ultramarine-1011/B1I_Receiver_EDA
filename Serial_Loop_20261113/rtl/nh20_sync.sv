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
    // A training window has 400 signed 28-bit samples. Even the sum of all
    // magnitudes is at most 400*2^27, strictly below 2^36.
    logic [35:0] scores[0:19],scores_next[0:19];
    logic [35:0] best,second;
    logic [4:0] best_phase;
    logic [35:0] best_tree[1:63],second_tree[1:63];
    logic [4:0] phase_tree[1:63];
    logic signed [33:0] term,total,run_sum;
    logic bit_started;
    logic [63:0] start_ref;
    integer position;
    // Both five-bit phase operands are nonnegative. Their sum is at most 62.
    function automatic logic [4:0] modulo20(input logic [5:0] value);
        if(value>=6'd60) modulo20=5'(value-6'd60);
        else if(value>=6'd40) modulo20=5'(value-6'd40);
        else if(value>=6'd20) modulo20=5'(value-6'd20);
        else modulo20=5'(value);
    endfunction
    always_comb begin
        best=0;second=0;best_phase=0;term=0;total=0;position=0;
        for(integer h=0;h<20;h=h+1) begin
            sums_next[h]=0;scores_next[h]=0;
            if(prompt_valid && !nh_locked) begin
            position=modulo20(6'(tick_mod)+6'(h));
            term=34'($signed(prompt_i));
            if(NH[19-position]) term=-term;
            total=sums[h]+term;
            sums_next[h]=total; scores_next[h]=scores[h];
            if(position==19) begin
                sums_next[h]=0;
                if(training_count>=20) scores_next[h]=scores[h]+36'(total<0 ? -total : total);
            end
            end
        end
        // A balanced top-two reduction preserves the original earliest-phase
        // tie rule and confidence score with five comparator levels.
        for(integer h=0;h<32;h=h+1) begin
            best_tree[32+h]=0;second_tree[32+h]=0;phase_tree[32+h]=5'(h);
            if(h<20) best_tree[32+h]=scores_next[h];
        end
        for(integer node=31;node>0;node=node-1) begin
            if(best_tree[2*node]>=best_tree[2*node+1]) begin
                best_tree[node]=best_tree[2*node];phase_tree[node]=phase_tree[2*node];
                second_tree[node]=second_tree[2*node]>best_tree[2*node+1] ?
                    second_tree[2*node] : best_tree[2*node+1];
            end else begin
                best_tree[node]=best_tree[2*node+1];phase_tree[node]=phase_tree[2*node+1];
                second_tree[node]=second_tree[2*node+1]>best_tree[2*node] ?
                    second_tree[2*node+1] : best_tree[2*node];
            end
        end
        best=best_tree[1];second=second_tree[1];best_phase=phase_tree[1];
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
                        if(best>0 && {1'b0,best}>{second,1'b0}) begin nh_locked<=1;nh_phase<=best_phase;end
                        // Failed confidence restarts training, never asserts fake sync.
                        training_count<=0;
                        for(integer h=0;h<20;h=h+1) begin sums[h]<=0;scores[h]<=0;end
                    end else training_count<=training_count+1'b1;
                end else begin
                    if(modulo20(6'(tick_mod)+6'(nh_phase))==0) begin
                        run_sum<=34'($signed(prompt_i)); // NH[0]=0
                        start_ref<=prompt_ref;bit_started<=1;
                    end else begin
                        if(NH[19-(modulo20(6'(tick_mod)+6'(nh_phase)))])
                            run_sum<=run_sum-34'($signed(prompt_i));
                        else run_sum<=run_sum+34'($signed(prompt_i));
                        if(modulo20(6'(tick_mod)+6'(nh_phase))==19 && bit_started) begin
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
