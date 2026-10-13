`timescale 1ns/1ps
// Deterministic control-layer injection; not IF capture or D1 recovery evidence.
module tb_satellite_manager;
    localparam integer CHANNELS=12;
    logic clk=0,reset_n=0,enable=1,task_start=0,sample_event=0;
    logic [15:0] task_id=0,candidate_task_id=0;
    logic [63:0] task_window_ref=0,current_sample=0,candidate_ref=0;
    logic [11:0] slot_active=0,slot_locked=0,slot_available='1,release_event,ever_locked;
    logic [5:0] slot_prn[0:11];logic [7:0] slot_generation[0:11];
    logic candidate_valid=0,candidate_detected=1,result_allow=1,candidate_ready,assign_event,duplicate,full,stale;
    logic [5:0] candidate_prn=6;
    logic [3:0] assign_slot;
    logic [31:0] assigned_total,released_total,rejected_total;
    integer cycles=0;
    satellite_manager #(.CHANNELS(12),.STARTUP_TIMEOUT_SAMPLES(64'd100)) dut(.*);
    always #5 clk=~clk;
    always @(posedge clk) if(reset_n) begin
        cycles++;if(cycles>1000) $fatal(1,"timeout");
        for(integer c=0;c<12;c++) if(release_event[c]) begin slot_active[c]<=0;slot_locked[c]<=0;end
        if(assign_event) begin slot_active[assign_slot]<=1;slot_prn[assign_slot]<=candidate_prn;slot_generation[assign_slot]<=slot_generation[assign_slot]+1'b1;end
    end
    task automatic search(input integer id,input integer ref_sample);
        @(negedge clk);task_start=1;task_id=16'(id);task_window_ref=64'(ref_sample);current_sample=64'(ref_sample);
        @(negedge clk);task_start=0;
    endtask
    task automatic candidate(input integer prn,id,ref_sample,input bit expected);
        @(negedge clk);candidate_valid=1;candidate_prn=6'(prn);candidate_task_id=16'(id);candidate_ref=64'(ref_sample);
        #1;if(assign_event!==expected || !candidate_ready) $fatal(1,"candidate prn=%0d expected=%0d duplicate=%0d full=%0d stale=%0d",prn,expected,duplicate,full,stale);
        @(negedge clk);candidate_valid=0;
    endtask
    initial begin
        for(integer c=0;c<12;c++) begin slot_prn[c]=0;slot_generation[c]=0;end
        repeat(3) @(negedge clk);reset_n=1;search(1,0);
        for(integer c=0;c<12;c++) candidate(6+c,1,0,1);
        if(slot_active!='1) $fatal(1,"12 assignments missing");
        candidate(6,1,0,0); // duplicate
        candidate(23,1,0,0); // full: do not evict a healthy slot
        @(negedge clk);slot_locked='1;
        repeat(2) @(negedge clk);
        slot_locked[3]=0;current_sample=50;
        #1;if(release_event!=12'h008) $fatal(1,"loss locality");
        @(negedge clk);
        candidate(9,1,0,0); // old window predates loss
        search(2,60);candidate(9,1,60,0); // old task
        candidate(9,2,60,1);
        if(slot_generation[3]!=2 || slot_active!='1) $fatal(1,"generation/recovery");
        @(negedge clk);slot_locked[3]=1;
        repeat(2) @(negedge clk);
        // Reclaim another slot, then reject generation exhaustion and non-drained slot.
        slot_locked[5]=0;current_sample=80;
        @(negedge clk);slot_generation[5]=63;
        search(3,90);candidate(23,3,90,0);
        @(negedge clk);slot_generation[5]=2;slot_available[5]=0;
        candidate(23,3,90,0);
        @(negedge clk);slot_available[5]=1;result_allow=0;candidate_valid=1;candidate_prn=23;candidate_task_id=3;candidate_ref=90;
        #1;if(candidate_ready || assign_event) $fatal(1,"result backpressure");
        @(negedge clk);result_allow=1;
        @(negedge clk);candidate_valid=0;
        if(slot_generation[5]!=3 || slot_prn[5]!=23) $fatal(1,"new star assignment");
        // Initial pull-in timeout uses samples, idle hardware clocks do not age it.
        repeat(6) @(negedge clk);
        if(release_event!=0) $fatal(1,"hardware stall falsely ages channel");
        current_sample=200;sample_event=1;
        #1;if(release_event!=12'h020) $fatal(1,"pull-in timeout");
        @(negedge clk);sample_event=0;
        if(slot_active[5] || assigned_total!=14 || released_total!=3) $fatal(1,"event counts");
        @(negedge clk);reset_n=0;
        @(negedge clk);reset_n=1;
        if(assigned_total || released_total || ever_locked) $fatal(1,"reset state");
        $display("SATELLITE_MANAGER_PASS control_only=1 slots=12 duplicate/full/stale/generation/backpressure/loss/timeout/reset");$finish;
    end
endmodule
