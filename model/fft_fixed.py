"""Radix-2 /4096 FFT with Q30 twiddles and floor shifts, independent vectors.
Each butterfly scales by 1/2. All intermediate products are signed 64bit.
No IF, satellite identity or navigation truth in the twiddle constants.
"""
from pathlib import Path
import cmath, math, random, json
ROOT=Path(__file__).resolve().parents[1]
N=4096
COS=[round(math.cos(2*math.pi*k/N)*2**30) for k in range(N)]
SIN=[round(math.sin(2*math.pi*k/N)*2**30) for k in range(N)]
def reverse(n): return int(f'{n:012b}'[::-1],2)
def transform(values,inverse=False):
    a=[(0,0)]*N
    for k,z in enumerate(values): a[reverse(k)]=z
    span=2
    while span<=N:
        half=span//2;step=N//span
        for base in range(0,N,span):
            for j in range(half):
                ar,ai=a[base+j];br,bi=a[base+j+half]
                wr=COS[j*step];wi=SIN[j*step]*(1 if inverse else -1)
                tr=(br*wr-bi*wi)>>30;ti=(br*wi+bi*wr)>>30
                a[base+j]=((ar+tr)>>1,(ai+ti)>>1)
                a[base+j+half]=((ar-tr)>>1,(ai-ti)>>1)
        span*=2
    assert all(-2**31<=v<2**31 for z in a for v in z)
    return a
def float_transform(values,inverse=False):
    a=[0j]*N
    for k,z in enumerate(values): a[reverse(k)]=complex(*z)
    span=2
    while span<=N:
        half=span//2;step=N//span
        for base in range(0,N,span):
            for j in range(half):
                v=a[base+j+half]*cmath.exp((1 if inverse else -1)*2j*math.pi*j*step/N)
                u=a[base+j];a[base+j]=(u+v)/2;a[base+j+half]=(u-v)/2
        span*=2
    return a
def mem(path,values):path.write_text(''.join(f'{v & 0xffffffff:08x}\n' for v in values),encoding='ascii')
def main():
    rom=ROOT/'student_release/student_release/rom';rom.mkdir(exist_ok=True)
    mem(rom/'fft_cos_q30.mem',COS);mem(rom/'fft_sin_q30.mem',SIN)
    dest=ROOT/'work/fft';dest.mkdir(parents=True,exist_ok=True)
    rng=random.Random(1301)
    cases=[([(2**20,0)]+[(0,0)]*(N-1),False),
           ([(round(100000*math.cos(2*math.pi*317*k/N)),round(100000*math.sin(2*math.pi*317*k/N))) for k in range(N)],False),
           ([(rng.randint(-2**20,2**20),rng.randint(-2**20,2**20)) for k in range(N)],True)]
    report=[]
    for c,(values,inverse) in enumerate(cases):
        fixed=transform(values,inverse);floats=float_transform(values,inverse)
        error=max(abs(complex(*z)-f) for z,f in zip(fixed,floats))
        assert error<16,(c,error)
        for field,index in [('r',0),('i',1)]:
            mem(dest/f'in{c}_{field}.mem',[z[index] for z in values])
            mem(dest/f'out{c}_{field}.mem',[z[index] for z in fixed])
        report.append(dict(case=c,inverse=inverse,max_float_absolute_error=error,limit=16))
    (ROOT/'reports/e_stage/fft_model.json').write_text(json.dumps(report,indent=2)+'\n')
    print('FFT_FIXED_MODEL_PASS',report)
if __name__=='__main__':main()
