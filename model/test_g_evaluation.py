"""Independent adversarial checks for G scoring/causal replay, not receiver PASS."""
import unittest,copy,sys
from pathlib import Path
from performance_metrics import acquisition_statistics,tracking_quality,causal_ttff,position_statistics,wilson
from online_navigation import OnlineNavigation
from decode_records import decode
from route_a_position import transmit_sow
ROOT=Path(__file__).resolve().parents[1]

class StatisticsTests(unittest.TestCase):
    def test_failed_and_censored_denominator(self):
        score=acquisition_statistics([{'id':'success','seed':1,'target_present':True,'verified_success':True,'observation_seconds':.004},
            {'id':'timeout','seed':2,'target_present':True,'verified_success':False,'observation_seconds':.004},
            {'id':'absent','seed':3,'target_present':False,'detected':True,'observation_seconds':.004}])
        self.assertEqual(score['detection']['rate'],.5);self.assertEqual(score['false_alarm']['rate'],1)
        self.assertEqual(score['trials'][1]['censored_lower_bound_seconds'],.004)
        self.assertFalse(score['working_point_observed'])
    def test_short_200_trials_cannot_qualify(self):
        rows=[{'id':str(i),'seed':i,'target_present':i<100,'verified_success':True,'detected':False,'observation_seconds':.004} for i in range(200)]
        self.assertFalse(acquisition_statistics(rows)['working_point_observed'])
    def test_zero_counts_and_wilson(self):
        self.assertIsNone(wilson(0,0)['rate']);self.assertAlmostEqual(wilson(0,100)['ci95'][1],.0369934982)
    def test_duplicate_tracking_cannot_fill_window(self):
        row={'sample_ref':0,'valid':True,'locked':True,'code_error_chip':0,'frequency_error_hz':0}
        with self.assertRaisesRegex(ValueError,'duplicate'):tracking_quality([row]*1000,duration_s=1)
    def test_wrong_grid_cannot_fill_60s(self):
        rows=[{'epoch_sample':2*i,'valid':True,'ecef_m':[0,0,0]} for i in range(1,61)]
        self.assertEqual(position_statistics(rows,[0,0,0],0,0,0,fs=1)['status'],'PARTIAL_WINDOW')
    def test_empty_truth_and_windows(self):
        self.assertIsNone(tracking_quality([],duration_s=1)['code_rms_chip'])
        self.assertEqual(position_statistics([],None,0,0,0)['status'],'BLOCKED_INPUT')

class CausalTests(unittest.TestCase):
    def fixture(self):
        ledger=[{'sequence':i,'kind':'nav','prn':i+6,'generation':1,'valid':True,'ephemeris_ready':True,'available_sample':1} for i in range(4)]
        sols=[]
        for t in (10,20,30):
            ids=[]
            for i in range(4):
                ids.append(len(ledger));ledger.append({'sequence':len(ledger),'kind':'obs','prn':i+6,'generation':1,'valid':True,'epoch_sample':t,'available_sample':t})
            sols.append({'valid':True,'epoch_sample':t,'available_sample':t+2,'used_nav':list(range(4)),'used_obs':ids})
        return ledger,sols
    def test_third_actual_output_defines_confirmation(self):
        l,s=self.fixture();self.assertEqual(causal_ttff(l,s,fs=10)['ttff_signal_seconds'],3.2)
    def test_short_window_lower_bound(self):
        l,s=self.fixture();r=causal_ttff(l,s,fs=10,window_s=2);self.assertEqual(r['status'],'CENSORED');self.assertEqual(r['lower_bound_seconds'],2)
    def test_later_nav_cannot_backfill_earlier_obs(self):
        l,s=self.fixture();l[0]['available_sample']=11;l.sort(key=lambda r:r['available_sample'])
        self.assertEqual(causal_ttff(l,s,fs=10)['rejected'][0]['reason'],'retrospective_ephemeris_backfill')
    def test_generation_isolation(self):
        l,s=self.fixture();l[0]['generation']=2;self.assertEqual(causal_ttff(l,s,fs=10)['status'],'CENSORED')
    def test_incomplete_ephemeris_rejected(self):
        l,s=self.fixture();l[0]['ephemeris_ready']=False;self.assertEqual(causal_ttff(l,s,fs=10)['status'],'CENSORED')
    def test_missing_second_breaks_run(self):
        l,s=self.fixture();self.assertEqual(causal_ttff(l,[s[0],s[2]],fs=10)['status'],'CENSORED')
    def test_code_epoch_and_week_wrap(self):
        anchor={'type':'navigation','prn':6,'generation':1,'bch_valid':True,'time_valid':True,'word_number':10,'sow':604793,
            'sample_index':0,'code_epoch':65535,'code_chip':0,'code_fraction':0}
        obs={'prn':6,'generation':1,'sample_index':32736,'code_epoch':1,'code_chip':0,'code_fraction':0}
        tx,_,_=transmit_sow(obs,[anchor]);self.assertAlmostEqual(tx,604799.002)

class AdapterTests(unittest.TestCase):
    def test_historical_nav_fixture_prefix_and_full_frames(self):
        # Availability below is a TEST fixture, not a measured E sidecar.
        # Nothing from this test is published as RTL TTFF/time evidence.
        path=ROOT/'reports/e_stage/final/receiver_records.bin'
        if not path.exists():self.skipTest('historical local BIN absent')
        o=OnlineNavigation();avail=0;prefix=None
        with path.open('rb') as f:
            i=0
            while raw:=f.read(32):
                r=decode(raw)
                if r['sample_index']>51*16368000:break
                avail=max(avail,r['sample_index']+1)
                o.consume(r,{'sequence':i,'available_sample':avail,'hardware_cycle':i+1});i+=1
                if prefix is None and avail>20*16368000:prefix=copy.deepcopy(o)
        self.assertEqual(len(prefix.eph),0);self.assertEqual(len(prefix.positions),0)
        self.assertEqual(len(o.eph),4)
        self.assertTrue(o.positions)
        for s in o.positions:
            self.assertTrue(all(n<s['output_sequence'] for n in s['used_raw_nav']))
        self.assertEqual(len(prefix.positions),0,'later ephemeris cannot mutate prefix state')
    def test_reordered_sidecar_rejected(self):
        o=OnlineNavigation();r={'type':'tracking','prn':6,'generation':1,'channel':0,'sample_index':0}
        with self.assertRaisesRegex(ValueError,'order'):o.consume(r,{'sequence':1,'available_sample':0,'hardware_cycle':1})
    def test_single_good_word_is_not_ephemeris(self):
        path=ROOT/'reports/f_stage/real20/receiver_records.bin'
        if not path.exists():self.skipTest('F20 local BIN absent')
        with path.open('rb') as f:
            while raw:=f.read(32):
                r=decode(raw)
                if r['type']=='navigation':break
        o=OnlineNavigation();o.consume(r,{'sequence':0,'available_sample':20*16368000,'hardware_cycle':1})
        self.assertFalse(o.eph)

if __name__=='__main__':unittest.main(verbosity=2)
