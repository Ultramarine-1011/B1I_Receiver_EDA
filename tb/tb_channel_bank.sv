`timescale 1ns/1ps
// Direct channel initialization tests digital independence, not IF acquisition.
module channel_test_bank #(parameter integer CHANNELS=4)(
    input logic clk,reset_n,assign_valid,sample_valid,epoch_event,
    input logic signed [2:0] sample_data,
    input logic [63:0] sample_ref,
    input logic [31:0] epoch_id,
    output logic ready,drained,
    output logic [CHANNELS-1:0] valid,
    input logic [CHANNELS-1:0] take,
    output logic [255:0] data[0:CHANNELS-1]
);
    logic [CHANNELS-1:0] r,d,overflow,active;
    assign ready=&r;
    assign drained=&d;
    for(genvar c=0;c<CHANNELS;c++) begin: channels
        logic [7:0] generation;
        logic [5:0] prn;
        receiver_channel #(.CHANNEL_ID(c)) channel(.clk(clk),.reset_n(reset_n),
            .assign_valid(assign_valid),.release_valid(1'b0),.assign_prn(6'(6+c)),.assign_effective_ref(64'd0),
            .assign_code_phase(43'(c*17)<<32),.assign_code_epoch(32'(c)),
            .assign_carrier_phase(32'(c)*32'h07123456),.assign_doppler(32'(c*26240)),
            .sample_valid(sample_valid),.sample_ready(r[c]),.sample_data(sample_data),.sample_ref(sample_ref),
            .epoch_event(epoch_event),.epoch_id(epoch_id),.record_valid(valid[c]),.record_ready(take[c]),
            .record_data(data[c]),.drained(d[c]),.overflow(overflow[c]),.active(active[c]),
            .locked(),.nh_valid(),.frame_valid(),.time_valid(),.prn_saved(prn),.generation(generation));
        always @(negedge clk) if(reset_n && overflow[c]) $fatal(1,"bank overflow channels=%0d slot=%0d",CHANNELS,c);
        always @(posedge clk) if(reset_n && sample_valid && !channel.tracking.frontend.sample_accepted)
            $fatal(1,"common sample not consumed channels=%0d slot=%0d ref=%0d",CHANNELS,c,sample_ref);
    end
endmodule

module tb_channel_bank;
    logic clk=0,reset_n=0,assign_valid=0,sample_valid=0,epoch_event=0;
    logic signed [2:0] sample_data;
    logic [63:0] sample_ref=0;
    logic [31:0] epoch_id=0;
    logic r1,r2,r4,r12,d1,d2,d4,d12;
    logic [0:0] v1,t1;
    logic [1:0] v2,t2;
    logic [3:0] v4,t4;
    logic [11:0] v12,t12;
    logic [255:0] q1[0:0],q2[0:1],q4[0:3],q12[0:11];
    logic [255:0] saved[0:3][0:11];
    logic [31:0] code[0:2045];
    integer cycles=0,n=0,prompts[0:11],observations[0:11];
    integer file_handle;
    logic stalled[0:3][0:11];
    logic [255:0] previous[0:3][0:11];
    logic [255:0] latest1[0:63],latest2[0:63],latest4[0:63];
    integer counts1=0,counts2=0,counts4=0,counts12=0;
    always #5 clk=~clk;
    channel_test_bank #(.CHANNELS(1)) b1(.clk,.reset_n,.assign_valid,.sample_valid,.sample_data,.sample_ref,.epoch_event,.epoch_id,.ready(r1),.drained(d1),.valid(v1),.take(t1),.data(q1));
    channel_test_bank #(.CHANNELS(2)) b2(.clk,.reset_n,.assign_valid,.sample_valid,.sample_data,.sample_ref,.epoch_event,.epoch_id,.ready(r2),.drained(d2),.valid(v2),.take(t2),.data(q2));
    channel_test_bank #(.CHANNELS(4)) b4(.clk,.reset_n,.assign_valid,.sample_valid,.sample_data,.sample_ref,.epoch_event,.epoch_id,.ready(r4),.drained(d4),.valid(v4),.take(t4),.data(q4));
    channel_test_bank #(.CHANNELS(12)) b12(.clk,.reset_n,.assign_valid,.sample_valid,.sample_data,.sample_ref,.epoch_event,.epoch_id,.ready(r12),.drained(d12),.valid(v12),.take(t12),.data(q12));
    task automatic check_record(input integer bank,ch,input logic valid,take,input logic [255:0] data);
        if(stalled[bank][ch] && (!valid || data!==previous[bank][ch])) $fatal(1,"unstable bank=%0d ch=%0d",bank,ch);
        stalled[bank][ch]=valid&&!take;previous[bank][ch]=data;
        if(valid&&take) begin
            if(data[13:8]!=6+ch || data[17:14]!=ch) $fatal(1,"identity bank=%0d ch=%0d",bank,ch);
            if(data[7:0]==1) begin
                if(data[29:24]!=1) $fatal(1,"prompt generation");
                if(ch==0) begin
                    case(bank)
                        0: begin latest1[counts1]=data;counts1++;end
                        1: begin latest2[counts2]=data;counts2++;end
                        2: begin latest4[counts4]=data;counts4++;end
                        3: begin
                            if(data!==latest1[counts12] || data!==latest2[counts12] || data!==latest4[counts12])
                                $fatal(1,"same PRN numerical mismatch window=%0d",counts12);
                            counts12++;
                        end
                    endcase
                end
                if(bank==3) prompts[ch]++;
            end else if(data[7:0]==4) begin
                if(data[143:128]!=1 || data[22] || data[95:32]!=data[127:96]*64'd4096)
                    $fatal(1,"observation identity/time/false validity");
                if(bank==3) observations[ch]++;
            end else $fatal(1,"unexpected record %0d",data[7:0]);
        end
    endtask
    always @(posedge clk) if(reset_n) begin
        cycles++;
        for(integer c=0;c<12;c++) begin
            if(c<1) check_record(0,c,v1[c],t1[c],q1[c]);
            if(c<2) check_record(1,c,v2[c],t2[c],q2[c]);
            if(c<4) check_record(2,c,v4[c],t4[c],q4[c]);
            check_record(3,c,v12[c],t12[c],q12[c]);
        end
        if(sample_valid) n++;
        if(cycles>1000000) $fatal(1,"timeout");
    end
    initial begin
        $readmemh("b1i_prn_06.mem",code);
        for(integer b=0;b<4;b++) for(integer c=0;c<12;c++) stalled[b][c]=0;
        for(integer c=0;c<12;c++) begin prompts[c]=0;observations[c]=0;end
        sample_data=0;t1='1;t2='1;t4='1;t12='1;
        repeat(4) @(negedge clk);reset_n=1;assign_valid=1;
        @(negedge clk);assign_valid=0;
        while(n<16368*12) begin
            @(negedge clk);
            t1='1;t2='1;t4='1;
            for(integer c=0;c<12;c++) t12[c]=(cycles+c)%47>=17;
            sample_valid=n<16368*12 && r1&&r2&&r4&&r12 && cycles%29!=0;
            sample_ref=64'(n);
            sample_data=(code[(n/8)%2046][0] ^ (n%4>=2)) ? -3'sd3 : 3'sd3;
            epoch_event=sample_valid && n>0 && n%4096==0;epoch_id=32'(n/4096);
        end
        @(negedge clk);sample_valid=0;epoch_event=0;t12='1;
        repeat(20) @(negedge clk);
        if(!(d1&&d2&&d4&&d12) || counts1!=12 || counts12!=12) $fatal(1,"drain/count");
        // ALIGN_FIRST_WINDOW discards the first partial primary-code period.
        // c=0 starts at zero; the other eleven begin c*17 chips into a period.
        for(integer c=0;c<12;c++) if(prompts[c]!=(c==0 ? 12 : 11) || observations[c]!=47)
            $fatal(1,"missing records ch=%0d prompt=%0d obs=%0d",c,prompts[c],observations[c]);
        $display("CHANNEL_BANK_PASS configurations=1/2/4/12 samples=%0d cycles=%0d common_prompt_windows=12 observations_per_channel=47",n,cycles);
        $finish;
    end
endmodule
