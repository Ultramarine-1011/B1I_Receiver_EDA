// Direct Verilator clock driver. All receiver computation stays in the RTL.
// Public IF2 pair order and record LE packing are cross-checked against the
// unchanged teacher player/writer in the timing-TB regression.
#include "Vg_receiver_probe.h"
#include "verilated.h"
#include <array>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <stdexcept>
#include <string>
#include <algorithm>

int main(int argc,char** argv) {
    try {
        if(argc!=6) throw std::runtime_error("usage: g_receiver INPUT OUTPUT MAX_BYTES FIXED_CLOCK_HZ FIFO_WORDS");
        const double fixed_clock=std::stod(argv[4]);const uint64_t fifo_words=std::stoull(argv[5]);
        const bool stall_output=false,stall_input=false;
        const uint64_t max_bytes=std::stoull(argv[3]);
        if(!max_bytes || max_bytes%4) throw std::runtime_error("MAX_BYTES must be positive /4");
        FILE* input=std::fopen(argv[1],"rb");FILE* output=std::fopen(argv[2],"wb");
        FILE* availability=std::fopen((std::string(argv[2])+".availability.jsonl").c_str(),"wb");
        FILE* events=std::fopen((std::string(argv[2])+".events.jsonl").c_str(),"wb");
        FILE* stats=std::fopen((std::string(argv[2])+".service.json").c_str(),"wb");
        if(!input || !output || !availability || !events || !stats) throw std::runtime_error("file open failed");
        std::array<uint8_t,256> pairs{};
        for(unsigned b=0;b<256;++b) for(unsigned k=0;k<4;++k)
            pairs[b]|=((b>>(6-2*k))&3)<<(2*k);
        auto context=std::make_unique<VerilatedContext>();
        context->commandArgs(argc,argv);
        auto dut=std::make_unique<Vg_receiver_probe>(context.get());
        dut->clk=0;dut->reset_n=0;dut->start=0;dut->stream_valid=0;dut->stream_last=0;
        dut->stream_data=0;dut->sample_index=0;dut->record_ready=1;
        uint64_t bytes_loaded=0,bytes_accepted=0,cycles=0,records=0,last_second=0,end_wait=0;
        bool end_seen=false,input_available=false,input_offered=false;
        bool output_stalled=false;
        std::array<uint32_t,8> stalled_payload{};
        const auto begun=std::chrono::steady_clock::now();
        uint64_t ready_cycles=0,valid_cycles=0,record_ready_cycles=0,record_valid_cycles=0;
        uint64_t state_cycles[16]{},bg_cycles[8]{},state_samples[16]{},accepted_samples=0;
        uint64_t max_block=0,block=0,max_run_block=0,run_block=0,run_cycles=0,run_samples=0;
        uint64_t max_buffer=0,previous_task=0,previous_prn=0;
        bool previous_code_init=false,previous_coarse=false,previous_fine=false,previous_task_start=false,previous_refine=false;
        std::array<uint64_t,4> backlog_max{};
        const std::array<uint64_t,4> clocks{20000000,25000000,50000000,100000000};
        auto event=[&](const char* kind,unsigned prn) {
            std::fprintf(events,"{\"kind\":\"%s\",\"task_id\":%u,\"prn\":%u,\"hardware_cycle\":%llu,\"available_sample\":%llu,\"processed_sample\":%llu,\"state\":%u,\"bg_state\":%u,\"detected\":%u}\n",
                kind,dut->probe_task_id,prn,(unsigned long long)(cycles+1),(unsigned long long)(bytes_accepted*4),
                (unsigned long long)dut->probe_processed,dut->probe_state,dut->probe_bg,
                std::string(kind)=="coarse_result" ? dut->probe_coarse_detected : dut->probe_fine_detected);
        };
        auto load_word=[&]() {
            input_offered=false;
            if(bytes_loaded==max_bytes) {input_available=false;dut->stream_valid=0;dut->stream_last=0;return;}
            std::array<uint8_t,4> raw{};
            if(std::fread(raw.data(),1,4,input)!=4) throw std::runtime_error("early IF EOF");
            uint32_t word=0;
            for(unsigned b=0;b<4;++b) word|=uint32_t(pairs[raw[b]])<<(8*b);
            dut->stream_data=word;dut->sample_index=bytes_loaded*4;
            bytes_loaded+=4;dut->stream_last=bytes_loaded==max_bytes;input_available=true;dut->stream_valid=1;
        };
        auto tick=[&]() {
            dut->clk=0;dut->record_ready=!stall_output || cycles%47>=17;
            if(input_available && !input_offered && (!stall_input || cycles%31>=4)) input_offered=true;
            dut->stream_valid=input_available && input_offered;
            if(fixed_clock>0 && bytes_accepted/4>=std::min(max_bytes/4,uint64_t((cycles>10 ? cycles-10 : 0)*16368000.0/(16*fixed_clock)))) dut->stream_valid=0;
            context->timeInc(1);dut->eval();
            if(dut->reset_n && cycles>=10 && !end_seen) {
                const unsigned state=dut->probe_state,bg=dut->probe_bg;
                ++state_cycles[state];++bg_cycles[bg];ready_cycles+=dut->stream_ready;valid_cycles+=dut->stream_valid;
                record_ready_cycles+=dut->record_ready;record_valid_cycles+=dut->record_valid;
                if(dut->probe_sample_accept){++accepted_samples;++state_samples[state];}
                if(dut->stream_valid && !dut->stream_ready){++block;max_block=std::max(max_block,block);}else block=0;
                if(state==8) {
                    ++run_cycles;run_samples+=dut->probe_sample_accept;
                    if(!dut->probe_sample_accept){++run_block;max_run_block=std::max(max_run_block,run_block);}else run_block=0;
                } else run_block=0;
                if(dut->probe_task_start && !previous_task_start){event("capture_task_accepted",6);previous_task=cycles+1;}
                if(dut->probe_code_init && (!previous_code_init || previous_prn!=dut->probe_search_prn))event("prn_compute_start",dut->probe_search_prn);
                if(dut->probe_coarse_valid && !previous_coarse)event("coarse_result",dut->probe_result_prn);
                if(dut->probe_refine_start && !previous_refine)event("refine_start",dut->probe_result_prn);
                if(dut->probe_fine_valid && !previous_fine)event("verified_result",dut->probe_result_prn);
                if(dut->probe_assign)event("channel_assignment",dut->probe_result_prn);
                if(dut->probe_release)event("channel_release",0);
                previous_task_start=dut->probe_task_start;previous_code_init=dut->probe_code_init;previous_prn=dut->probe_search_prn;
                previous_coarse=dut->probe_coarse_valid;previous_refine=dut->probe_refine_start;previous_fine=dut->probe_fine_valid;
                for(unsigned k=0;k<clocks.size();++k) {
                    const uint64_t produced=std::min(max_bytes/4,uint64_t((cycles-10)*16368000.0/(16*clocks[k])));
                    backlog_max[k]=std::max(backlog_max[k],produced>bytes_accepted/4 ? produced-bytes_accepted/4 : 0);
                }
                if(fixed_clock>0) {
                    const uint64_t produced=std::min(max_bytes/4,uint64_t((cycles-10)*16368000.0/(16*fixed_clock)));
                    const uint64_t occupancy=produced>bytes_accepted/4 ? produced-bytes_accepted/4 : 0;
                    max_buffer=std::max(max_buffer,occupancy);
                    if(fifo_words && occupancy>fifo_words) {
                        std::printf("G_FIXED_SOURCE_FIFO_OVERFLOW cycle=%llu produced_words=%llu accepted_words=%llu high_water_words=%llu capacity_words=%llu clock_hz=%.0f\n",
                            (unsigned long long)cycles,(unsigned long long)produced,(unsigned long long)(bytes_accepted/4),
                            (unsigned long long)max_buffer,(unsigned long long)fifo_words,fixed_clock);
                        std::fflush(stdout);throw std::runtime_error("fixed-rate source FIFO overflow");
                    }
                }
            }
            if(output_stalled) {
                if(!dut->record_valid) throw std::runtime_error("record valid dropped during backpressure");
                for(unsigned w=0;w<8;++w) if(dut->record_data[w]!=stalled_payload[w])
                    throw std::runtime_error("record payload changed during backpressure");
            }
            output_stalled=dut->record_valid && !dut->record_ready;
            if(output_stalled) for(unsigned w=0;w<8;++w) stalled_payload[w]=dut->record_data[w];
            const bool take_input=dut->stream_valid && dut->stream_ready;
            const bool take_record=dut->record_valid && dut->record_ready;
            std::array<uint32_t,8> saved{};
            if(take_record) for(unsigned w=0;w<8;++w) saved[w]=dut->record_data[w];
            dut->clk=1;context->timeInc(1);dut->eval();++cycles;
            if(take_record) {
                if(end_seen) throw std::runtime_error("record after end");
                std::array<uint8_t,32> record{};
                for(unsigned w=0;w<8;++w) for(unsigned b=0;b<4;++b) record[w*4+b]=saved[w]>>(8*b);
                if(std::fwrite(record.data(),1,32,output)!=32) throw std::runtime_error("record write failed");
                // Output handshake availability, independent of payload source time.
                // Accepted input includes at most one buffered 16-sample word.
                std::fprintf(availability,"{\"sequence\":%llu,\"available_sample\":%llu,\"hardware_cycle\":%llu}\n",
                    static_cast<unsigned long long>(records),
                    static_cast<unsigned long long>((bytes_accepted+(take_input ? 4 : 0))*4),
                    static_cast<unsigned long long>(cycles));
                ++records;
                if((saved[0]&255)==5)
                    std::printf("FAST_RTL_ACQUISITION prn=%u channel=%u detected=%u cycles=%u\n",
                        (saved[0]>>8)&63,(saved[0]>>14)&15,(saved[0]>>18)&1,saved[7]);
                if((saved[0]&255)==2 && ((saved[4]>>24)&15)==1)
                    std::printf("FAST_RTL_NAV prn=%u word1_sample=%llu\n",(saved[0]>>8)&63,
                        static_cast<unsigned long long>(uint64_t(saved[1])|(uint64_t(saved[2])<<32)));
                if((saved[0]&255)==6) {
                    const uint64_t n=uint64_t(saved[1])|(uint64_t(saved[2])<<32);
                    if(n!=max_bytes*4 || ((saved[0]>>18)&3)!=0 || bytes_accepted!=max_bytes)
                        throw std::runtime_error("DUT end count/error flags mismatch");
                    end_seen=true;
                }
            }
            if(take_input) {
                bytes_accepted+=4;load_word();
                const uint64_t second=bytes_accepted*4/16368000;
                if(second!=last_second) {
                    last_second=second;
                    const double wall=std::chrono::duration<double>(std::chrono::steady_clock::now()-begun).count();
                    std::printf("FAST_RTL_INPUT_PROGRESS seconds=%llu cycles=%llu wall=%.3f records=%llu\n",
                        static_cast<unsigned long long>(second),static_cast<unsigned long long>(cycles),wall,
                        static_cast<unsigned long long>(records));std::fflush(stdout);
                }
            }
            // An EOF exactly at the 4ms capture boundary can leave a legal
            // cold search/refinement outstanding: 345M coarse + up to 32*25M
            // refine cycles, plus bounded control/record overhead. A 2B budget
            // covers that finite work; ordinary RUN EOF still drains promptly.
            if(bytes_accepted==max_bytes && !end_seen && ++end_wait>2000000000ULL)
                throw std::runtime_error("end timeout after final input handshake");
        };
        for(unsigned k=0;k<8;++k) tick();
        dut->reset_n=1;tick();dut->start=1;tick();dut->start=0;load_word();
        while(!end_seen) {
            tick();
            if(cycles>8000000000ULL || context->gotFinish()) throw std::runtime_error("DUT did not complete");
        }
        for(unsigned k=0;k<20;++k) tick();
        dut->final();std::fclose(input);std::fclose(output);std::fclose(availability);
        const double wall=std::chrono::duration<double>(std::chrono::steady_clock::now()-begun).count();
        std::fprintf(stats,"{\"cycles\":%llu,\"samples\":%llu,\"processed_samples\":%llu,\"wall_seconds\":%.6f,\"input_ready_cycles\":%llu,\"input_valid_cycles\":%llu,\"output_ready_cycles\":%llu,\"output_valid_cycles\":%llu,\"records\":%llu,\"max_input_block_cycles\":%llu,\"run_cycles\":%llu,\"run_samples\":%llu,\"max_run_no_sample_cycles\":%llu,\"fixed_clock_hz\":%.0f,\"fifo_capacity_words\":%llu,\"fifo_high_water_words\":%llu,\"state_cycles\":[",
            (unsigned long long)cycles,(unsigned long long)(bytes_accepted*4),(unsigned long long)accepted_samples,wall,
            (unsigned long long)ready_cycles,(unsigned long long)valid_cycles,(unsigned long long)record_ready_cycles,(unsigned long long)record_valid_cycles,
            (unsigned long long)records,(unsigned long long)max_block,(unsigned long long)run_cycles,(unsigned long long)run_samples,
            (unsigned long long)max_run_block,fixed_clock,(unsigned long long)fifo_words,(unsigned long long)max_buffer);
        for(unsigned k=0;k<16;++k)std::fprintf(stats,"%s%llu",k ? "," : "",(unsigned long long)state_cycles[k]);
        std::fprintf(stats,"],\"bg_cycles\":[");
        for(unsigned k=0;k<8;++k)std::fprintf(stats,"%s%llu",k ? "," : "",(unsigned long long)bg_cycles[k]);
        std::fprintf(stats,"],\"hypothetical_fixed_source_backlog_words\":[");
        for(unsigned k=0;k<4;++k)std::fprintf(stats,"%s{\"clock_hz\":%llu,\"words\":%llu}",k ? "," : "",(unsigned long long)clocks[k],(unsigned long long)backlog_max[k]);
        std::fprintf(stats,"]}\n");std::fclose(stats);std::fclose(events);
        std::printf("FAST_RTL_PASS samples=%llu records=%llu cycles=%llu wall_seconds=%.3f\n",
            static_cast<unsigned long long>(bytes_accepted*4),static_cast<unsigned long long>(records),
            static_cast<unsigned long long>(cycles),wall);
        return 0;
    } catch(const std::exception& error) {
        std::fprintf(stderr,"FAST_RTL_FAIL: %s\n",error.what());return 1;
    }
}
