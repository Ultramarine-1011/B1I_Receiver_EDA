`timescale 1ns/1ps
module tb_divider_equivalence;
    logic window_done=1;
    logic signed [27:0] ie,qe,ip,qp,il,ql;
    logic signed [63:0] original_code,original_phase,optimized_code,optimized_phase;
    logic signed [27:0] edges[0:10];
    logic [31:0] random_state=32'hb1d12026;
    integer checks=0;
    integer replay_file,scan_count,replay_count=0;
    longint signed expected_phase;
    string replay_path;
    norm_original reference_dut(.*,.dcode(original_code),.dphase(original_phase));
    norm_optimized optimized_dut(.*,.dcode(optimized_code),.dphase(optimized_phase));
    function automatic logic [31:0] random_word();
        random_state=random_state^(random_state<<13);
        random_state=random_state^(random_state>>17);
        random_state=random_state^(random_state<<5);
        return random_state;
    endfunction
    task automatic check_result;
        #1;
        if(original_code!==optimized_code || original_phase!==optimized_phase)
            $fatal(1,"DIVIDER_MISMATCH check=%0d ie=%0d qe=%0d il=%0d ql=%0d ip=%0d qp=%0d old=%0d/%0d new=%0d/%0d",
                checks,ie,qe,il,ql,ip,qp,original_code,original_phase,optimized_code,optimized_phase);
        checks=checks+1;
    endtask
    initial begin
        edges[0]=0;edges[1]=1;edges[2]=-1;edges[3]=2;edges[4]=-2;
        edges[5]=28'sh8000000;edges[6]=28'sh7ffffff;
        edges[7]=28'sh8000001;edges[8]=28'sh7fffffe;
        edges[9]=65536;edges[10]=-65536;
        // Full Cartesian DLL corner set, with independently changing Prompt signs.
        for(integer a=0;a<11;a=a+1)
            for(integer b=0;b<11;b=b+1)
                for(integer c=0;c<11;c=c+1)
                    for(integer d=0;d<11;d=d+1) begin
                        ie=edges[a];qe=edges[b];il=edges[c];ql=edges[d];
                        ip=edges[(a+c)%11];qp=edges[(b+d)%11];
                        check_result();
                    end
        for(integer a=0;a<11;a=a+1)
            for(integer b=0;b<11;b=b+1) begin
                ie=0;qe=0;il=0;ql=0;ip=edges[a];qp=edges[b];
                check_result();
                window_done=0;check_result();window_done=1;
            end
        for(integer n=0;n<200000;n=n+1) begin
            ie=28'(random_word());qe=28'(random_word());il=28'(random_word());ql=28'(random_word());
            ip=28'(random_word());qp=28'(random_word());window_done=(n%17)!=0;
            check_result();
        end
        $display("DIVIDER_EQUIVALENCE_PASS checks=%0d seed=b1d12026",checks);
        if($value$plusargs("PROMPT_REPLAY=%s",replay_path)) begin
            replay_file=$fopen(replay_path,"r");
            if(replay_file==0) $fatal(1,"Prompt replay open failed");
            ie=0;qe=0;il=0;ql=0;window_done=1;
            while(!$feof(replay_file)) begin
                scan_count=$fscanf(replay_file,"%d %d %d\n",ip,qp,expected_phase);
                if(scan_count==3) begin
                    check_result();
                    if(optimized_phase!==expected_phase)
                        $fatal(1,"PUBLIC_PROMPT_MISMATCH window=%0d",replay_count);
                    replay_count=replay_count+1;
                end else if(!$feof(replay_file)) $fatal(1,"Prompt replay parse failed");
            end
            $fclose(replay_file);
            if(replay_count!=995) $fatal(1,"Prompt replay coverage missing");
            $display("PUBLIC_PROMPT_REPLAY_PASS windows=%0d",replay_count);
        end
        $finish;
    end
endmodule
