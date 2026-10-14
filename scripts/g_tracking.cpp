#include "Vg_tracking_probe.h"
#include "verilated.h"
#include <cstdio>
#include <cstdint>
#include <memory>
#include <string>
#include <stdexcept>
#include <chrono>

int main(int argc,char** argv) {
    try {
        if(argc!=5)throw std::runtime_error("g_tracking INPUT OUTPUT SAMPLES INITIAL_DOPPLER_HZ");
        FILE* input=std::fopen(argv[1],"rb");FILE* output=std::fopen(argv[2],"wb");
        if(!input||!output)throw std::runtime_error("file open");
        const uint64_t total=std::stoull(argv[3]);const double initial_hz=std::stod(argv[4]);
        auto context=std::make_unique<VerilatedContext>();auto dut=std::make_unique<Vg_tracking_probe>(context.get());
        uint64_t cycles=0,samples=0,windows=0;const auto before=std::chrono::steady_clock::now();
        dut->clk=0;dut->reset_n=0;dut->init_valid=0;dut->sample_valid=0;dut->sample_ref=0;dut->sample_data=0;
        dut->init_doppler_word=int32_t(initial_hz*4294967296.0/16368000);
        std::fprintf(output,"window_ref,end_code_phase_q,end_code_period_count,carrier_step_word,locked,usable,prompt_i,prompt_q,hardware_cycle\n");
        auto tick=[&]() {
            dut->clk=0;context->timeInc(1);dut->eval();const bool take=dut->sample_valid&&dut->sample_ready;
            if(dut->window_done) {
                std::fprintf(output,"%llu,%llu,%u,%u,%u,%u,%d,%d,%llu\n",(unsigned long long)dut->window_ref,
                    (unsigned long long)dut->window_end_code_phase_q,dut->window_end_code_period_count,dut->carrier_step_word,
                    dut->locked,dut->usable,int32_t(dut->ip<<4)>>4,int32_t(dut->qp<<4)>>4,(unsigned long long)(cycles+1));++windows;
            }
            dut->clk=1;context->timeInc(1);dut->eval();++cycles;if(take)++samples;
            if(cycles>total*3+10000)throw std::runtime_error("tracking timeout");
            return take;
        };
        for(int k=0;k<4;k++)tick();dut->reset_n=1;tick();dut->init_valid=1;tick();dut->init_valid=0;
        while(!dut->sample_ready)tick();
        unsigned byte=0,shift=0;
        while(samples<total) {
            if(shift==0) {const int b=std::fgetc(input);if(b==EOF)throw std::runtime_error("early EOF");byte=unsigned(b);shift=8;}
            dut->sample_data=(int((byte>>(shift-2))&3)*2-3)&7;dut->sample_ref=samples;dut->sample_valid=1;
            if(tick())shift-=2;
        }
        dut->sample_valid=0;for(int k=0;k<30;k++)tick();dut->final();std::fclose(output);std::fclose(input);
        const double wall=std::chrono::duration<double>(std::chrono::steady_clock::now()-before).count();
        if(windows<total/16368-2)throw std::runtime_error("missing window outputs");
        std::printf("G_TRACKING_TRACE_PASS samples=%llu windows=%llu cycles=%llu wall_seconds=%.3f\n",
            (unsigned long long)samples,(unsigned long long)windows,(unsigned long long)cycles,wall);return 0;
    }catch(const std::exception& e){std::fprintf(stderr,"G_TRACKING_TRACE_FAIL %s\n",e.what());return 1;}
}
