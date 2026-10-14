#include "Vg_bank_service.h"
#include "verilated.h"
#include <cstdint>
#include <cstdio>
#include <memory>
#include <stdexcept>
#include <string>
#include <algorithm>
#include <chrono>
int main(int argc,char** argv){try{
    if(argc!=4)throw std::runtime_error("g_bank INPUT SAMPLES OUTPUT_JSON");
    FILE* f=std::fopen(argv[1],"rb");if(!f)throw std::runtime_error("input open");
    const uint64_t total=std::stoull(argv[2]);
    auto context=std::make_unique<VerilatedContext>();auto dut=std::make_unique<Vg_bank_service>(context.get());
    uint64_t cycles=0,samples=0,processed=0,records=0,ready=0,block=0,maxblock=0,nosample=0,maxnosample=0;
    uint64_t warmcycles=0,warmprocessed=0,highwater[4]{},clocks[]={20000000,25000000,50000000,100000000};
    const auto begun=std::chrono::steady_clock::now();
    dut->clk=0;dut->reset_n=0;dut->start=0;dut->stream_valid=0;dut->stream_last=0;dut->sample_index=0;dut->stream_data=0;dut->record_ready=1;
    auto tick=[&](){dut->clk=0;context->timeInc(1);dut->eval();
        bool take=dut->stream_valid&&dut->stream_ready;
        if(dut->reset_n){ready+=dut->stream_ready;processed+=dut->sample_accept;records+=dut->record_valid&&dut->record_ready;
            if(dut->stream_valid&&!dut->stream_ready){++block;maxblock=std::max(maxblock,block);}else block=0;
            if(!dut->sample_accept){++nosample;maxnosample=std::max(maxnosample,nosample);}else nosample=0;
            if(processed>=16368){++warmcycles;warmprocessed+=dut->sample_accept;}
            for(unsigned k=0;k<4;++k){uint64_t produced=std::min(total,uint64_t(cycles*16368000.0/clocks[k]));highwater[k]=std::max(highwater[k],produced>samples?produced-samples:0);}
            if(dut->overflow)throw std::runtime_error("slot overflow");}
        dut->clk=1;context->timeInc(1);dut->eval();++cycles;if(take)samples+=16;
        if(cycles>total*3+10000)throw std::runtime_error("service timeout");return take;};
    for(int k=0;k<4;++k)tick();dut->reset_n=1;tick();dut->start=1;tick();dut->start=0;
    bool offered=false;
    while(samples<total){if(!offered){unsigned word=0;
        for(unsigned b=0;b<4;++b){int x=std::fgetc(f);if(x==EOF)throw std::runtime_error("early EOF");
            for(unsigned k=0;k<4;++k)word|=((unsigned(x)>>(6-2*k))&3)<<(8*b+2*k);}
        dut->stream_data=word;dut->sample_index=samples;dut->stream_last=samples+16==total;dut->stream_valid=1;offered=true;}
        if(tick())offered=false;}
    dut->stream_valid=0;while(!dut->drained)tick();for(int k=0;k<10;++k)tick();
    if(processed!=total)throw std::runtime_error("sample service count");dut->final();std::fclose(f);
    double wall=std::chrono::duration<double>(std::chrono::steady_clock::now()-begun).count();
    FILE* out=std::fopen(argv[3],"wb");if(!out)throw std::runtime_error("output open");
    std::fprintf(out,"{\"status\":\"SELF_GENERATED_PASS\",\"scope\":\"all active digital slots, no twelve-D1 qualification\",\"samples\":%llu,\"cycles\":%llu,\"ready_cycles\":%llu,\"records\":%llu,\"max_input_block_cycles\":%llu,\"max_no_sample_cycles\":%llu,\"warm_cycles\":%llu,\"warm_samples\":%llu,\"minimum_average_clock_hz\":%.6f,\"warm_minimum_clock_hz\":%.6f,\"wall_seconds\":%.6f,\"backlog_samples\":[",
        (unsigned long long)samples,(unsigned long long)cycles,(unsigned long long)ready,(unsigned long long)records,
        (unsigned long long)maxblock,(unsigned long long)maxnosample,(unsigned long long)warmcycles,(unsigned long long)warmprocessed,
        cycles*16368000.0/samples,warmcycles*16368000.0/warmprocessed,wall);
    for(unsigned k=0;k<4;++k)std::fprintf(out,"%s{\"clock_hz\":%llu,\"samples\":%llu}",k?",":"",(unsigned long long)clocks[k],(unsigned long long)highwater[k]);
    std::fprintf(out,"]}\n");std::fclose(out);
    std::printf("G_BANK_SERVICE_PASS samples=%llu cycles=%llu records=%llu max_block=%llu wall=%.3f\n",(unsigned long long)samples,(unsigned long long)cycles,(unsigned long long)records,(unsigned long long)maxblock,wall);return 0;
}catch(const std::exception& e){std::fprintf(stderr,"G_BANK_SERVICE_FAIL %s\n",e.what());return 1;}}
