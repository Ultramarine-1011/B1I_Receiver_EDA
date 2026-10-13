`timescale 1ns/1ps
module tb_nh_d1;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,prompt_valid=0;
    logic signed [27:0] prompt_i=0;
    logic [63:0] prompt_ref=0;
    logic nh_locked,bit_valid,data_bit;
    logic [4:0] nh_phase;
    logic signed [33:0] bit_soft;
    logic [63:0] bit_ref;
    logic word_valid,bch_valid,polarity_inverted;
    logic [29:0] raw_word;
    logic [25:0] information;
    logic [3:0] word_number;
    logic [1:0] corrected_bits;
    logic [63:0] word_ref;
    localparam logic [19:0] NH=20'b00000100110101001110;
    logic nav_bits[0:131];
    logic [57:0] expected_words[0:2];
    integer phase=0,inverted=0,case_number=0,words_seen=0,bits_seen=0,total_words=0,fd;
    nh20_sync sync(.*);
    d1_word_sync decode(.*);
    always @(negedge clk) if(reset_n) begin
        if(bit_valid) begin
            if(nh_phase!=5'(phase)) $fatal(1,"NH phase mismatch");
            if(data_bit != (nav_bits[(int'(bit_ref/16368)+phase)/20]^1'(inverted)))
                $fatal(1,"recovered bit mismatch ref=%0d",bit_ref);
            bits_seen=bits_seen+1;
        end
        if(word_valid) begin
            if(words_seen>=3 || word_number!=4'(words_seen+1) || !bch_valid
               || polarity_inverted!=1'(inverted) || raw_word!=expected_words[words_seen][57:28]
               || information!=expected_words[words_seen][27:2] || corrected_bits!=expected_words[words_seen][1:0])
                $fatal(1,"D1 word mismatch case=%0d word=%0d raw=%h info=%h corrected=%0d",case_number,word_number,raw_word,information,corrected_bits);
            if(word_ref != 64'((40+30*words_seen)*20-phase)*64'd16368)
                $fatal(1,"word timestamp mismatch %0d",word_ref);
            $fwrite(fd,"%0d,%0d,%0d,%0d,%h,%h,%0d,%0d\n",case_number,phase,inverted,word_number,raw_word,information,corrected_bits,word_ref);
            words_seen=words_seen+1;total_words=total_words+1;
        end
    end
    task automatic run_case(input integer c,input integer initial_phase,input integer inverse);
        integer sign_value,bit_index;
        begin
            @(negedge clk);reset_n=0;prompt_valid=0;
            repeat(3) @(negedge clk);
            case_number=c;phase=initial_phase;inverted=inverse;words_seen=0;bits_seen=0;
            reset_n=1;
            for(integer epoch=0;epoch<2620;epoch=epoch+1) begin
                if(epoch%67==0) begin prompt_valid=0;@(negedge clk);end
                bit_index=(epoch+phase)/20;
                sign_value=(nav_bits[bit_index]^NH[19-((epoch+phase)%20)]^1'(inverse)) ? -1 : 1;
                prompt_i=28'(sign_value*100000);prompt_ref=64'(epoch)*64'd16368;prompt_valid=1;
                @(negedge clk);
            end
            prompt_valid=0;repeat(6) @(negedge clk);
            if(!nh_locked || nh_phase!=5'(phase) || words_seen!=3 || bits_seen<110)
                $fatal(1,"missing NH/bit/word events");
            $display("NH_D1_CASE_PASS case=%0d phase=%0d inverted=%0d bits=%0d words=%0d",c,phase,inverse,bits_seen,words_seen);
        end
    endtask
    initial begin
        $readmemh("../../tb/vectors/nh_d1/nav_bits.mem",nav_bits);
        $readmemh("../../tb/vectors/nh_d1/expected_words.mem",expected_words);
        fd=$fopen("../../reports/local/nh_d1_words.csv","w");
        if(fd==0) $fatal(1,"CSV open failure");
        $fwrite(fd,"case,phase,inverted,word,raw,information,corrected_bits,word_ref\n");
        run_case(0,0,0);run_case(1,7,1);run_case(2,19,0);
        $fclose(fd);
        if(total_words!=9) $fatal(1,"missing words");
        $display("NH_D1_MODULE_PASS cases=3 words=9 phases=0,7,19 polarity=normal,inverted");
        $finish;
    end
    initial begin #1000000; $fatal(1,"NH_D1_TIMEOUT"); end
endmodule
