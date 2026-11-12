"""Stage the current navigation/control candidate and the real PCPS simulation."""
from pathlib import Path
import shutil
import re

root = Path(__file__).resolve().parents[1]
course = root.parent.parent / "B1I_Receiver_EDA"
backend = root.parent / "Backend_20261111"
names = ["receiver_contract_pkg", "b1i_prn_gen", "code_nco", "carrier_nco_mixer", "epl_correlator",
         "tracking_frontend", "tracking_frontend_spaced", "tracking_channel_minimal", "nh20_sync",
         "d1_word_sync", "navigation_d1", "tracking_record_framer", "receiver_channel", "acquisition_refine",
         "fft4096_serial", "acquisition_pcps", "b1i_period_reduce", "bds_bb_6ch_engine", "bds_bb_6ch_core"]
for name in names:
    destination = root / "rtl" / (name + ".sv")
    if name in ["nh20_sync", "navigation_d1", "receiver_channel", "b1i_period_reduce"]:
        shutil.copyfile(backend / "rtl" / (name + ".sv"), destination)
    elif not destination.exists():
        shutil.copyfile(course / "student_release/student_release/rtl" / (name + ".sv"), destination)
shutil.copyfile(course / "student_release/student_release/rtl/fft_twiddle_rom.svh", root / "rtl/fft_twiddle_rom.svh")
(root / "rtl/receiver.f").write_text("\n".join("../rtl/" + name + ".sv" for name in names) + "\n", encoding="utf-8")
for path in (course / "tb/fixtures/six_channel").iterdir():
    if path.suffix in [".mem", ".if2"]:
        shutil.copyfile(path, root / "tb" / path.name)
wrapper = (root / "rtl/bds_bb_6ch_core.sv").read_text()
fixed = re.sub(r"bds_bb_6ch_engine #\([\s\S]*?\) engine\(", "bds_bb_6ch_engine engine(", wrapper)
(root / "rtl/mapped_core_wrapper.sv").write_text(fixed, encoding="utf-8", newline="\n")
print("CORE_FUNCTIONAL_INPUTS_READY")
