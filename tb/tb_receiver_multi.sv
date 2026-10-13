`timescale 1ns/1ps
module tb_receiver_multi;
    receiver_tb_template public_tb();
    logic [63:0] samples=0;
    integer transfers=0,acquisitions=0,ends=0,locked_records[0:3],prompts[0:3],navs[0:3],observations[0:3];
    logic [63:0] last_ref[0:3];
    integer fd;
    initial begin
        for(integer c=0;c<4;c=c+1) begin locked_records[c]=0;prompts[c]=0;navs[c]=0;observations[c]=0;last_ref[c]=0;end
        fd=$fopen("../../reports/e_stage/multi_tracking_loop.csv","w");
        $fwrite(fd,"channel,prn,ref,ip,qp,locked,nh,frame,time,fcw,code_q,code_epoch\n");
    end
    for(genvar c=0;c<4;c=c+1) begin: monitors
        always @(posedge public_tb.clk) if(public_tb.reset_n && public_tb.dut.multi.receiver.state==public_tb.dut.multi.receiver.RUN) begin
            if(public_tb.dut.multi.receiver.channels[c].slot.tracking.frontend.sample_accepted !=
               (public_tb.dut.multi.receiver.sample_valid && public_tb.dut.multi.receiver.sample_ready))
                $fatal(1,"common IF acceptance mismatch channel=%0d",c);
        end
    end
    always @(posedge public_tb.clk) if(public_tb.reset_n) begin
        if(public_tb.stream_valid && public_tb.stream_ready) transfers=transfers+1;
        if(public_tb.dut.multi.receiver.sample_valid && public_tb.dut.multi.receiver.sample_ready) begin
            if(public_tb.dut.multi.receiver.sample_ref!=samples) $fatal(1,"multi sample loss/duplication");
            samples=samples+1'b1;
        end
        if(public_tb.record_valid && public_tb.record_ready) begin
            if(ends!=0) $fatal(1,"multi record after end");
            case(public_tb.record_data[7:0])
                5: begin
                    if(public_tb.record_data[18]) acquisitions=acquisitions+1;
                    $display("MULTI_ACQUISITION prn=%0d channel=%0d detected=%0d lag=%0d fcw=%0d cycles=%0d",
                        public_tb.record_data[13:8],public_tb.record_data[17:14],public_tb.record_data[18],
                        public_tb.record_data[109:96],$signed(public_tb.record_data[159:128]),public_tb.record_data[255:224]);
                end
                1: begin
                    integer c;
                    c=int'(public_tb.record_data[17:14]);
                    if(c>=4) $fatal(1,"invalid physical channel");
                    if(prompts[c]!=0 && (public_tb.record_data[95:32]<last_ref[c]+16366 || public_tb.record_data[95:32]>last_ref[c]+16370)) $fatal(1,"multi Prompt boundary discontinuity");
                    last_ref[c]=public_tb.record_data[95:32];prompts[c]=prompts[c]+1;
                    if(public_tb.record_data[18]) locked_records[c]=locked_records[c]+1;
                    $fwrite(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",c,public_tb.record_data[13:8],
                        public_tb.record_data[95:32],$signed(public_tb.record_data[119:96]),$signed(public_tb.record_data[143:120]),
                        public_tb.record_data[18],public_tb.record_data[19],public_tb.record_data[20],public_tb.record_data[21],
                        $signed(public_tb.record_data[175:144]),{public_tb.record_data[242:232],public_tb.record_data[231:208],8'd0},
                        public_tb.record_data[255:243]);
                end
                2: begin
                    navs[public_tb.record_data[17:14]]=navs[public_tb.record_data[17:14]]+1;
                    if(public_tb.record_data[155:152]==1)
                        $display("MULTI_NAV prn=%0d sfid=%0d sow=%0d ref=%0d",public_tb.record_data[13:8],
                            public_tb.record_data[158:156],public_tb.record_data[178:159],public_tb.record_data[95:32]);
                end
                4: begin
                    observations[public_tb.record_data[17:14]]=observations[public_tb.record_data[17:14]]+1;
                    if(public_tb.record_data[95:32]!=64'(public_tb.record_data[127:96])*16368000)
                        $fatal(1,"common epoch mismatch");
                end
                6: begin
                    if(public_tb.record_data[95:32]!=samples || public_tb.record_data[19:18]!=0 || transfers*16!=samples || acquisitions<4)
                        $fatal(1,"multi end/drain/acquisition count");
                    ends=ends+1;$fclose(fd);
                    for(integer c=0;c<4;c=c+1)
                        $display("MULTI_CHANNEL_SUMMARY channel=%0d prompts=%0d locked=%0d nav=%0d obs=%0d",c,prompts[c],locked_records[c],navs[c],observations[c]);
                    $display("MULTI_REAL_STREAM_PASS samples=%0d transfers=%0d",samples,transfers);
                end
                default: $fatal(1,"multi unexpected record kind");
            endcase
        end
    end
endmodule
