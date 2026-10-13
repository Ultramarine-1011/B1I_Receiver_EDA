"""Final PVT physical sanity and artifact fingerprint; no receiver-position truth."""
from pathlib import Path
import sys,json,math,statistics,hashlib
def main():
    directory=Path(sys.argv[1]);binary=Path(sys.argv[2])
    positions=[json.loads(s) for s in (directory/'position.jsonl').read_text().splitlines()]
    assert positions and len({p['common_epoch_id'] for p in positions})==len(positions)
    for p in positions:
        xyz=list(p['ecef_m'].values());assert all(math.isfinite(v) for v in xyz)
        norm=math.sqrt(sum(v*v for v in xyz));assert 6_000_000<norm<7_000_000
        assert p['satellite_count']>=4 and -90<=p['geodetic']['latitude_deg']<=90 and -180<=p['geodetic']['longitude_deg']<=180
    result=dict(status='DELIVERY_POSITION_SANITY_PASS',position_epochs=len(positions),
                first_epoch=positions[0]['common_epoch_id'],last_epoch=positions[-1]['common_epoch_id'],
                median_geodetic={k:statistics.median(p['geodetic'][k] for p in positions) for k in ('latitude_deg','longitude_deg','height_m')},
                binary_path=str(binary.resolve()),binary_bytes=binary.stat().st_size,
                binary_sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
                limitation='No hidden position truth. Four-satellite equation residual is not position accuracy.')
    (directory/'delivery_summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))
if __name__=='__main__':main()
