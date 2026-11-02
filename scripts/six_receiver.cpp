#include "Vsix_receiver_probe.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <array>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

int main(int argc,char** argv) {
    try {
        if(argc!=4) throw std::runtime_error("usage: six_receiver INPUT MODE OUTPUT_PREFIX");
        const bool recovery=std::string(argv[2])=="recovery";
        const bool permuted=std::string(argv[2])=="permuted";
        const bool paced=std::string(argv[2])=="paced";
        const uint64_t paced_samples=6547200; // 0.4 RF seconds at Fs=16.368 MHz
        std::array<int,6> source{};
        for(int c=0;c<6;c++) source[c]=permuted ? (c*5+1)%6 : c;
        const std::string prefix=argv[3];
        std::ifstream in(argv[1],std::ios::binary);
        if(!in) throw std::runtime_error("IF open failed");
        std::array<std::vector<int>,6> bits;
        for(int c=0;c<6;c++) {
            std::ifstream f("bits"+std::to_string(c)+".mem");int b;
            while(f>>b) bits[c].push_back(b);
            if(bits[c].size()!=400) throw std::runtime_error("missing independent bit truth");
        }
        auto context=std::make_unique<VerilatedContext>();context->commandArgs(argc,argv);context->traceEverOn(true);
        auto dut=std::make_unique<Vsix_receiver_probe>(context.get());
        auto trace=std::make_unique<VerilatedVcdC>();dut->trace(trace.get(),1);trace->open((prefix+".vcd").c_str());
        FILE* csv=std::fopen((prefix+".csv").c_str(),"w");
        if(!csv) throw std::runtime_error("CSV open failed");
        std::fprintf(csv,"sample,cycle,capture,locked,sync,nav_valid,nav_data\n");
        uint64_t n=0,cycles=0,stalls=0,max_stall=0,stall_run=0;
        std::array<int,6> counts{},last_index{},captures{},losses{},tail_locks{};
        last_index.fill(-1);
        unsigned old_capture=0,old_lock=0,old_sync=0,old_nav=0;
        bool observed_parallel=false,observed_loss=false,observed_recovery=false;
        dut->clk=0;dut->rst_n=0;dut->if_valid=0;dut->IF=0;dut->cfg_valid=0;
        dut->cfg_channel=0;dut->cfg_prn=6;dut->cfg_enable=1;
        auto tick=[&]() {
            dut->clk=0;dut->eval();
            const bool take=dut->if_valid && dut->if_ready;
            if(dut->rst_n) {
                if(dut->processed!=n) throw std::runtime_error("sample counter mismatch");
                if(dut->overflow) throw std::runtime_error("channel record overflow");
                if(dut->nav_valid & ~dut->bit_sync_ok) throw std::runtime_error("invalid serial output");
                if(dut->bit_sync_ok & ~dut->capture_ok) throw std::runtime_error("stale sync status");
                if(old_nav & dut->nav_valid) throw std::runtime_error("nav_valid is not a single clock pulse");
                if(recovery && n>8000000 && n<11457600 && !(dut->capture_ok&1)) observed_loss=true;
                if(recovery && n>18000000 && (dut->locked&1)) observed_recovery=true;
                if(dut->locked==63) observed_parallel=true;
                for(int c=0;c<6;c++) {
                    if((dut->capture_ok & (1u<<c)) && !(old_capture & (1u<<c))) captures[c]++;
                    if(!(dut->capture_ok & (1u<<c)) && (old_capture & (1u<<c))) losses[c]++;
                    if(n>(paced ? paced_samples-1636800 : 21000000) && (dut->locked & (1u<<c))) tail_locks[c]++;
                    if(dut->nav_valid & (1u<<c)) {
                        const int lag[6]={0,720,1600,2400,3200,4000};
                        int index=int(std::llround(double(n-lag[source[c]])/327360.0))-1;
                        int got=(dut->nav_data>>c)&1;
                        if(index<0 || index>=int(bits[source[c]].size()) || got!=bits[source[c]][index] ||
                           (last_index[c]>=0 && index!=last_index[c]+1)) {
                            std::fprintf(stderr,"BIT_MISMATCH ch=%d n=%llu index=%d got=%d expected=%d previous=%d\n",c,
                                (unsigned long long)n,index,got,index>=0 && index<int(bits[source[c]].size()) ? bits[source[c]][index] : -1,last_index[c]);
                            throw std::runtime_error("navigation bit mismatch/missing/duplicate/order");
                        }
                        last_index[c]=index;counts[c]++;
                    }
                }
            } else if(dut->capture_ok || dut->bit_sync_ok || dut->nav_valid) throw std::runtime_error("reset outputs not cleared");
            bool event=dut->capture_ok!=old_capture || dut->locked!=old_lock || dut->bit_sync_ok!=old_sync || dut->nav_valid;
            if(event) {
                std::fprintf(csv,"%llu,%llu,%u,%u,%u,%u,%u\n",(unsigned long long)n,(unsigned long long)cycles,
                    dut->capture_ok,dut->locked,dut->bit_sync_ok,dut->nav_valid,dut->nav_data);
                if(dut->capture_ok!=old_capture || dut->locked!=old_lock || dut->bit_sync_ok!=old_sync) {
                    std::printf("SIX_STATE sample=%llu cycle=%llu capture=%02x lock=%02x sync=%02x\n",
                        (unsigned long long)n,(unsigned long long)cycles,dut->capture_ok,dut->locked,dut->bit_sync_ok);std::fflush(stdout);
                }
            }
            const bool wave=cycles<200 || event || old_nav;
            old_capture=dut->capture_ok;old_lock=dut->locked;old_sync=dut->bit_sync_ok;old_nav=dut->nav_valid;
            const unsigned pre_data=dut->nav_data;
            // The model precision is 1 ps: 5000 ps per half-cycle = 100 MHz.
            context->timeInc(5000);if(wave) trace->dump(context->time());
            dut->clk=1;dut->eval();context->timeInc(5000);
            // Capture the asserting NBA edge as well as the next sampling edge;
            // otherwise a sparse trace shortens a one-clock pulse to half a clock.
            if(wave || dut->capture_ok!=old_capture || dut->locked!=old_lock ||
               dut->bit_sync_ok!=old_sync || dut->nav_valid!=old_nav || dut->nav_data!=pre_data)
                trace->dump(context->time());
            cycles++;if(take) n++;
            if(dut->if_valid && !take) {stalls++;stall_run++;if(stall_run>max_stall)max_stall=stall_run;} else stall_run=0;
            if(cycles>100000000) throw std::runtime_error("bounded cycle timeout");
        };
        for(int k=0;k<8;k++) tick();dut->rst_n=1;tick();
        // Independent staggered configuration; no code phase/carrier truth ports.
        for(int c=0;c<6;c++) {
            dut->cfg_valid=1;dut->cfg_channel=c;dut->cfg_prn=6+source[c];tick();
            dut->cfg_valid=0;for(int k=0;k<c+1;k++) tick();
        }
        unsigned byte=0,pair=4;bool held=false,eof=false;int cfg_step=0;uint64_t input_phase=0;
        while(!eof) {
            if(paced && n==paced_samples) break;
            if(!held) {
                if(pair==4) {char ch;if(!in.get(ch)) {eof=true;break;}byte=uint8_t(ch);pair=0;}
                dut->IF=(byte>>(6-2*pair))&3;pair++;held=true;
            }
            if(paced) {
                input_phase+=16368000;dut->if_valid=input_phase>=100000000;
                if(dut->if_valid) input_phase-=100000000;
                dut->clk=0;dut->eval();
                if(dut->if_valid && !dut->if_ready) throw std::runtime_error("fixed-rate IF overrun at 100 MHz");
            } else dut->if_valid=cycles%37!=0; // Idle clocks do not advance RF time.
            dut->cfg_valid=0;
            if(recovery && cfg_step==0 && n>=14731200) {
                dut->cfg_valid=1;dut->cfg_channel=2;dut->cfg_prn=8;dut->cfg_enable=0;cfg_step++;
            } else if(recovery && cfg_step==1 && n>=15058560) {
                dut->cfg_valid=1;dut->cfg_channel=2;dut->cfg_prn=8;dut->cfg_enable=1;cfg_step++;
            }
            uint64_t before=n;tick();if(n!=before) held=false;
        }
        dut->if_valid=0;dut->cfg_valid=0;for(int k=0;k<100;k++)tick();
        if(!observed_parallel) throw std::runtime_error("six simultaneous stable locks not observed");
        for(int c=0;c<6;c++) {
            if(!captures[c] || tail_locks[c]<1000 || (!recovery && losses[c]) || (!paced && counts[c]<35))
                throw std::runtime_error("channel coverage missing c="+std::to_string(c));
            if(recovery && c!=0 && c!=2 && (captures[c]!=1 || losses[c])) throw std::runtime_error("cross-channel state corruption");
            std::printf("SIX_CHANNEL ch=%d captures=%d losses=%d nav_bits=%d last_index=%d tail_locked_cycles=%d\n",
                c,captures[c],losses[c],counts[c],last_index[c],tail_locks[c]);
        }
        if(dut->locked!=63 || dut->capture_ok!=63) throw std::runtime_error("final six-channel lock missing");
        if(recovery && (!observed_loss || !observed_recovery || captures[0]!=2 || captures[2]!=2 || losses[0]!=1 || losses[2]!=1))
            throw std::runtime_error("RF loss/reacquisition or reconfiguration coverage missing");
        dut->rst_n=0;for(int k=0;k<4;k++)tick();
        dut->final();trace->close();std::fclose(csv);
        std::printf("SIX_RECEIVER_PASS mode=%s samples=%llu cycles=%llu stalled_cycles=%llu maximum_stall=%llu parallel=6\n",
            argv[2],(unsigned long long)n,(unsigned long long)cycles,(unsigned long long)stalls,(unsigned long long)max_stall);
        return 0;
    } catch(const std::exception& error) {std::fprintf(stderr,"SIX_RECEIVER_FAIL: %s\n",error.what());return 1;}
}
