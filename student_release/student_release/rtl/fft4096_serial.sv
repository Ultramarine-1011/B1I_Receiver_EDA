`timescale 1ns/1ps
// One normalized radix-2 butterfly/clock; load bit-reversed, read natural order.
module fft4096_serial #(
    parameter COS_FILE="rom/fft_cos_q30.mem", SIN_FILE="rom/fft_sin_q30.mem"
) (
    input logic clk,reset_n,
    input logic load_valid,
    output logic load_ready,
    input logic [11:0] load_address,
    input logic signed [31:0] load_real,load_imag,
    input logic start,inverse,
    output logic busy,done,
    input logic [11:0] read_address,
    output logic signed [31:0] read_real,read_imag
);
    logic signed [31:0] re[0:4095],im[0:4095],cosine[0:4095],sine[0:4095];
    logic [12:0] span,base;
    logic [11:0] half_span,j,twiddle_step,a_address,b_address,w_address,reversed;
    logic inverse_run;
    logic signed [31:0] ar,ai,br,bi,wr,wi;
    logic signed [63:0] tr,ti,ar64,ai64,product_rr,product_ii,product_ri,product_ir;
    always_comb begin
        for(integer k=0;k<12;k=k+1) reversed[k]=load_address[11-k];
        load_ready=reset_n && !busy;
        read_real=re[read_address];read_imag=im[read_address];
        a_address=12'(base+13'(j));b_address=a_address+half_span;
        w_address=j*twiddle_step;
        ar=re[a_address];ai=im[a_address];br=re[b_address];bi=im[b_address];
        wr=cosine[w_address];wi=inverse_run ? sine[w_address] : -sine[w_address];
        product_rr=$signed(br)*$signed(wr);product_ii=$signed(bi)*$signed(wi);
        product_ri=$signed(br)*$signed(wi);product_ir=$signed(bi)*$signed(wr);
        tr=(product_rr-product_ii) >>> 30;ti=(product_ri+product_ir) >>> 30;
        ar64=64'($signed(ar));ai64=64'($signed(ai));
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            busy<=0;done<=0;span<=2;half_span<=1;base<=0;j<=0;twiddle_step<=2048;inverse_run<=0;
        end else begin
            done<=0;
            if(load_valid && load_ready) begin re[reversed]<=load_real;im[reversed]<=load_imag;end
            if(start && !busy) begin
                busy<=1;span<=2;half_span<=1;base<=0;j<=0;twiddle_step<=2048;inverse_run<=inverse;
            end else if(busy) begin
                re[a_address]<=32'((ar64+tr) >>> 1);im[a_address]<=32'((ai64+ti) >>> 1);
                re[b_address]<=32'((ar64-tr) >>> 1);im[b_address]<=32'((ai64-ti) >>> 1);
                if(j==half_span-1'b1) begin
                    j<=0;
                    if(base+span>=4096) begin
                        base<=0;
                        if(span==4096) begin busy<=0;done<=1;end
                        else begin span<=span<<1;half_span<=12'(span);twiddle_step<=twiddle_step>>1;end
                    end else base<=base+span;
                end else j<=j+1'b1;
            end
        end
    end
    initial begin $readmemh(COS_FILE,cosine);$readmemh(SIN_FILE,sine);end
endmodule
