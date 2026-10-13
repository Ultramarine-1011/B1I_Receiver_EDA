// Direct Verilator clock driver. All receiver computation stays in the RTL.
// Public IF2 pair order and record LE packing are cross-checked against the
// unchanged teacher player/writer in the timing-TB regression.
#include "Vstudent_receiver_core.h"
#include "verilated.h"
#include <array>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <stdexcept>
#include <string>

int main(int argc,char** argv) {
    try {
        if(argc<4 || argc>6) throw std::runtime_error("usage: receiver_fast INPUT OUTPUT MAX_BYTES [--stall-output] [--stall-input]");
        bool stall_output=false,stall_input=false;
        for(int k=4;k<argc;++k) {
            if(std::string(argv[k])=="--stall-output") stall_output=true;
            else if(std::string(argv[k])=="--stall-input") stall_input=true;
            else throw std::runtime_error("unknown option");
        }
        const uint64_t max_bytes=std::stoull(argv[3]);
        if(!max_bytes || max_bytes%4) throw std::runtime_error("MAX_BYTES must be positive /4");
        FILE* input=std::fopen(argv[1],"rb");FILE* output=std::fopen(argv[2],"wb");
        FILE* availability=std::fopen((std::string(argv[2])+".availability.jsonl").c_str(),"wb");
        if(!input || !output || !availability) throw std::runtime_error("file open failed");
        std::array<uint8_t,256> pairs{};
        for(unsigned b=0;b<256;++b) for(unsigned k=0;k<4;++k)
            pairs[b]|=((b>>(6-2*k))&3)<<(2*k);
        auto context=std::make_unique<VerilatedContext>();
        context->commandArgs(argc,argv);
        auto dut=std::make_unique<Vstudent_receiver_core>(context.get());
        dut->clk=0;dut->reset_n=0;dut->start=0;dut->stream_valid=0;dut->stream_last=0;
        dut->stream_data=0;dut->sample_index=0;dut->record_ready=1;
        uint64_t bytes_loaded=0,bytes_accepted=0,cycles=0,records=0,last_second=0,end_wait=0;
        bool end_seen=false,input_available=false,input_offered=false;
        bool output_stalled=false;
        std::array<uint32_t,8> stalled_payload{};
        const auto begun=std::chrono::steady_clock::now();
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
            context->timeInc(1);dut->eval();
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
        std::printf("FAST_RTL_PASS samples=%llu records=%llu cycles=%llu wall_seconds=%.3f\n",
            static_cast<unsigned long long>(bytes_accepted*4),static_cast<unsigned long long>(records),
            static_cast<unsigned long long>(cycles),wall);
        return 0;
    } catch(const std::exception& error) {
        std::fprintf(stderr,"FAST_RTL_FAIL: %s\n",error.what());return 1;
    }
}
