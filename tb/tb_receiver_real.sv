`timescale 1ns/1ps
// Diagnostic wrapper only: unmodified public input/TB/record writer, no truth.
module tb_receiver_real;
    receiver_tb_template public_tb();
    integer fd;
    logic [63:0] samples=0;
    initial begin
        fd=$fopen("../../reports/e_stage/real_tracking_loop.csv","w");
        $fwrite(fd,"ref,ip,qp,locked,usable,dll_q16,pll_q16,fcw,code_q,code_period,energy,fll_q16,fll_active\n");
    end
    always @(posedge public_tb.clk) if(public_tb.reset_n) begin
        if(public_tb.dut.sample_valid && public_tb.dut.sample_ready) begin
            if(public_tb.dut.sample_ref!=samples) $fatal(1,"real stream lost/duplicated sample");
            samples=samples+1'b1;
        end
        if(public_tb.dut.tracking.feedback_valid)
            $fwrite(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
                public_tb.dut.tracking.window_ref,public_tb.dut.tracking.ip,public_tb.dut.tracking.qp,
                public_tb.dut.tracking.locked,public_tb.dut.tracking.usable,
                public_tb.dut.tracking.dll_error_q16,public_tb.dut.tracking.pll_error_q16,
                public_tb.dut.tracking.carrier_step_word-32'h40000000,
                public_tb.dut.tracking.code_phase_q,public_tb.dut.tracking.code_period_count,
                public_tb.dut.tracking.window_energy,public_tb.dut.tracking.fll_error_q16,
                public_tb.dut.tracking.fll_active);
        if(public_tb.record_valid && public_tb.record_ready && public_tb.record_data[7:0]==5)
            $display("REAL_RTL_ACQUISITION prn=%0d detected=%0d lag=%0d fcw=%0d cycles=%0d",
                public_tb.record_data[13:8],public_tb.record_data[18],public_tb.record_data[109:96],
                $signed(public_tb.record_data[159:128]),public_tb.record_data[255:224]);
        if(public_tb.dut.navigation.word_valid)
            $display("REAL_D1_WORD number=%0d raw=%h info=%h bch=%0d start=%0d frame=%0d time=%0d",
                public_tb.dut.navigation.word_number,public_tb.dut.navigation.raw_word,
                public_tb.dut.navigation.information,public_tb.dut.navigation.word_bch,
                public_tb.dut.navigation.word_ref,public_tb.dut.navigation.frame_valid,public_tb.dut.navigation.time_valid);
        if(public_tb.record_valid && public_tb.record_ready && public_tb.record_data[7:0]==6) begin
            if(public_tb.record_data[95:32]!=samples) $fatal(1,"real end count");
            $fclose(fd);$display("REAL_RTL_STREAM_PASS samples=%0d",samples);
        end
    end
endmodule
