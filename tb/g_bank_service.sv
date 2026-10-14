`timescale 1ns/1ps
// All CHANNELS slots active: numerical work/service measurement, not 12-star IF.
module g_bank_service #(parameter integer CHANNELS=4)(
    input logic clk,reset_n,start,stream_valid,stream_last,record_ready,
    input logic [31:0] stream_data,
    input logic [63:0] sample_index,
    output logic stream_ready,record_valid,drained,overflow,sample_accept,
    output logic [255:0] record_data
);
    logic sample_valid,sample_ready,sample_last,input_drained;
    logic [1:0] sample_bits;logic signed [2:0] sample_data;
    logic [63:0] sample_ref;
    logic [CHANNELS-1:0] ready,valid,take,slot_drained,slot_overflow;
    logic [255:0] data[0:CHANNELS-1];
    integer chosen,round_robin=0,held=0;
    logic holding=0;
    stream_unpacker unpacker(.clk,.reset_n,.enable(reset_n),.stream_data,.stream_valid,.stream_ready,.stream_last,.sample_index,
      .sample_valid,.sample_ready,.sample_bits,.sample_data,.sample_ref,.sample_last,.input_drained);
    assign sample_ready=&ready;assign sample_accept=sample_valid&&sample_ready;
    assign drained=&slot_drained&&input_drained;assign overflow=|slot_overflow;
    always_comb begin
        chosen=holding ? held : -1;record_valid=0;record_data=0;take='0;
        if(!holding)for(integer k=0;k<CHANNELS;k++) begin
            if(chosen<0 && valid[(round_robin+k)%CHANNELS])chosen=(round_robin+k)%CHANNELS;
        end
        if(chosen>=0)begin record_valid=1;record_data=data[chosen];take[chosen]=record_ready;end
    end
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin round_robin<=0;holding<=0;held<=0;end
        else if(record_valid&&record_ready)begin round_robin<=(chosen+1)%CHANNELS;holding<=0;end
        else if(record_valid&&!record_ready)begin holding<=1;held<=chosen;end
    end
    for(genvar c=0;c<CHANNELS;c++)begin:slots
        receiver_channel #(.CHANNEL_ID(c)) slot(.clk,.reset_n,.assign_valid(start),.release_valid(1'b0),
          .assign_prn(6'(6+c)),.assign_code_phase(43'(c*17)<<32),.assign_code_epoch(32'(c)),
          .assign_carrier_phase(32'(c)*32'h07123456),.assign_doppler(32'(c*26240)),.assign_effective_ref(64'd0),
          .sample_valid(sample_accept),.sample_ready(ready[c]),.sample_data,.sample_ref,
          .epoch_event(sample_accept&&sample_ref!=0&&sample_ref%64'd16368000==0),.epoch_id(32'(sample_ref/16368000)),
          .record_valid(valid[c]),.record_ready(take[c]),.record_data(data[c]),.drained(slot_drained[c]),.overflow(slot_overflow[c]),
          .active(),.locked(),.nh_valid(),.frame_valid(),.time_valid(),.prn_saved(),.generation());
        always @(posedge clk) if(reset_n && sample_accept &&
            (!slot.active || !slot.tracking.frontend.sample_accepted))
            $fatal(1,"all-active service bank missed common sample slot=%0d ref=%0d",c,sample_ref);
    end
endmodule
