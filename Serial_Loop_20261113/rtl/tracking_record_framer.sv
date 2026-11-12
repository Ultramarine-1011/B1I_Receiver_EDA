`timescale 1ns/1ps
// Schema3 records name the nearest local primary-code boundary at window end.
// Snapshot is at its first integer sample; fractional code residual supplies
// the sub-sample correction used by the unmodified teacher prompt_d1 tool.
module tracking_record_framer (
    input logic event_valid,
    input logic [5:0] prn,
    input logic [3:0] channel,
    input logic [7:0] generation,
    input logic locked,nh_valid,frame_valid,time_valid,
    input logic signed [27:0] ip,qp,
    input logic [63:0] end_ref,
    input logic [42:0] end_code_phase,
    input logic [31:0] end_code_epoch,end_carrier_phase,carrier_step,
    input logic [32:0] end_code_step,
    output logic [255:0] record_data
);
    localparam logic [63:0] MODULUS=64'h7fe00000000;
    logic [63:0] boundary_ref,residual,samples;
    logic [31:0] boundary_epoch,boundary_carrier;
    logic signed [63:0] delta_samples,carrier_shift;
    always_comb begin
        boundary_ref=end_ref;boundary_epoch=end_code_epoch;residual=64'(end_code_phase);
        samples=0;delta_samples=0;carrier_shift=0;boundary_carrier=end_carrier_phase;
        record_data=0;
        if(event_valid && end_code_step!=0) begin
            if(64'(end_code_phase)<MODULUS/2) begin
                samples=64'(end_code_phase)/64'(end_code_step);
                boundary_ref=end_ref-samples;residual=64'(end_code_phase)-samples*64'(end_code_step);
            end else begin
                samples=(MODULUS-64'(end_code_phase)+64'(end_code_step)-1)/64'(end_code_step);
                boundary_ref=end_ref+samples;boundary_epoch=end_code_epoch+1'b1;
                residual=64'(end_code_phase)+samples*64'(end_code_step)-MODULUS;
            end
            delta_samples=$signed(boundary_ref)-$signed(end_ref);
            carrier_shift=delta_samples*$signed({32'd0,carrier_step});
            boundary_carrier=end_carrier_phase+carrier_shift[31:0];
            record_data[7:0]=8'd1;record_data[13:8]=prn;record_data[17:14]=channel;
            record_data[18]=locked;record_data[19]=nh_valid;record_data[20]=frame_valid;record_data[21]=time_valid;
            record_data[23]=1;record_data[31:24]={2'b11,generation[5:0]};
            record_data[95:32]=boundary_ref;record_data[119:96]=24'($signed(ip) >>> 4);
            record_data[143:120]=24'($signed(qp) >>> 4);record_data[175:144]=carrier_step-32'h40000000;
            record_data[207:176]=boundary_carrier;record_data[231:208]=residual[31:8];
            record_data[242:232]=11'd0;record_data[255:243]=boundary_epoch[12:0];
        end
    end
endmodule
