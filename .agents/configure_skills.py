"""One-time project adaptation; touches only newly installed skill packages."""
from pathlib import Path
import hashlib, json, urllib.request, time

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / '.agents' / 'skills'
SOURCES = {
 'systemverilog': ('babyworm/rtl-agent-team','56c02875d77bd7b6d44fe9c5acd27d7d03f34b12','skills/systemverilog'),
 'tb-best-practices': ('codejunkie99/Gateflow-Plugin','bf7e94c002eab8ce8ea76365a7490daaaba3b102','plugins/gateflow/skills/tb-best-practices'),
 'systematic-debugging': ('openai/plugins','0722921d5542fc593105c27bd52630babd8b8c2a','plugins/superpowers/skills/systematic-debugging'),
 'nature-writing': ('Mubuky/nature-skills','f792de121632744e32f8ebcf858fc57e52b4678a','skills/nature-writing'),
}

def fetch(url):
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=30) as r: return r.read()
        except Exception:
            if attempt == 2: raise
            time.sleep(1)

def write(name, desc, body):
    folder = BASE / name
    folder.mkdir(parents=True, exist_ok=True)
    (folder/'SKILL.md').write_text('---\nname: '+name+'\ndescription: '+json.dumps(desc,ensure_ascii=False)+'\n---\n\n'+body.strip()+'\n',encoding='utf-8')

manifest = {'date':'2026-10-13','sources':{},'adaptation':'Project entrypoints adapted; upstream materials are reference-only.'}
for name,(repo,rev,source) in SOURCES.items():
    folder=BASE/name
    original=folder/'SKILL.md'
    if not original.exists(): raise RuntimeError(f'Install {name} first')
    ref=folder/'references'
    ref.mkdir(exist_ok=True)
    upstream=ref/'upstream.txt'
    if not upstream.exists(): upstream.write_bytes(original.read_bytes())
    license_path='plugins/superpowers/LICENSE' if repo=='openai/plugins' else 'LICENSE'
    license_data=fetch(f'https://raw.githubusercontent.com/{repo}/{rev}/{license_path}')
    (folder/'LICENSE').write_bytes(license_data)
    if name=='nature-writing':
        (folder/'NOTICE').write_bytes(fetch(f'https://raw.githubusercontent.com/{repo}/{rev}/NOTICE'))
    # No Claude metadata is required for the portable entrypoint.
    manifest['sources'][name]={'repository':repo,'revision':rev,'path':source,'upstream_sha256':hashlib.sha256(upstream.read_bytes()).hexdigest(),'license_path':license_path}

write('systemverilog','编写或审查本工程 SystemVerilog RTL，检查位宽、signed 运算、组合完整性和 VCS/DC 兼容性。', '''
# SystemVerilog for this EDA project

Adapted from babyworm/rtl-agent-team; original text is [upstream.txt](references/upstream.txt), reference only. Existing repository interfaces and AGENTS.md override upstream style choices.

- Inspect the nearest module and its design document before editing. Preserve existing ports, reset polarity, naming and pipeline behavior; do not introduce mandatory i_/o_ prefixes or rename localparams merely for style.
- Prefer explicit logic, always_ff and always_comb where compatible with adjacent code. Sequential assignments are nonblocking; combinational blocks assign every output on every path. Review case defaults, accidental latches and multiple drivers.
- Size constants and intermediate arithmetic explicitly. Check signed casts before multiply/shift/compare, extension before addition, part-select signedness, negative limits, rounding, saturation and phase wrap.
- Preserve accepted-sample semantics: calculate using the current NCO state, then advance; idle sample_valid holds state. Check reset/init collisions and align I/Q, code, valid and sample indices through pipelines.
- VCS I-2014.03 and DC K-2015.06 are the historical tool baselines. Avoid assuming modern SV features or simulator-specific behavior; compile the actual change through the Linux VCS target.
- In TB, a variable assigned by initial/task and an edge process must not also use always_ff. Prefer a single owner or ordinary always in the TB. This does not authorize multiple RTL drivers.
- SRAM macros, memory latency and target clock are external TBDs. Do not import upstream size thresholds or blackbox unresolved storage to claim synthesis closure.
- Use rtl-vcs-verification for actual verification; source code review alone is not a PASS.
''')

write('tb-best-practices','设计本工程自检 SystemVerilog testbench、事件 scoreboard、边界激励和超时判据。', '''
# Self-checking testbench patterns

Adapted from Gateflow tb-best-practices; [upstream.txt](references/upstream.txt) is background, not an executable recipe. Gateflow CLI, cocotb, Verilator and UVM are not dependencies.

Use the smallest TB architecture that separates stimulus, passive observation and expected results. Existing task-based TBs do not need a class/UVM rewrite.

1. Read the module contract and current Makefile target. Define events, latency, reset behavior, tolerances and acceptance counts before stimulation.
2. Drive outside the sampling race and check after NBA updates or the documented observation edge. Do not copy upstream posedge drive/check examples without fixing race and output-latency assumptions.
3. Use independent vectors or an independent model. Match by sample/window/update event, not only by final value. Expected truth never enters feedback inputs.
4. Check missing, duplicate and reordered events, X/Z, idle holds, first/last window sample, wrap, signed extrema, mid-run reset/init and feedback delay. Seed randomness and bound every wait.
5. A mismatch or timeout uses $fatal(1, ...); if collecting $error counts, end with fatal when count is nonzero. Emit the unique final PASS marker only after all expected events and pipeline draining complete. $finish alone is insufficient.
6. Coverage goals are defined by the project acceptance matrix, not upstream percentage examples. Record unreachable bins only with evidence.
7. Use rtl-vcs-verification to run VCS over SSH and retain exit status plus logs. Document reproduced failures before fixing.
''')

write('systematic-debugging','定位本 EDA 工程模型、RTL、testbench、VCS/DC 日志或 SSH 执行失败的根因。', '''
# Evidence-led EDA debugging

Adapted from OpenAI superpowers systematic-debugging. [upstream.txt](references/upstream.txt) and [root-cause-tracing.md](root-cause-tracing.md) supply background. No superpowers plugin runtime or companion skill is required.

Read the first substantive error and the command exit status. Distinguish transport/runtime/tool/license failure from DUT or checker failure. Inspect recent source and vector changes, and compare current hashes with the tested mirror.

Reproduce with the smallest meaningful existing case. Trace backward from the first divergent sample/window through valid, latency, reset/init, signed arithmetic and feedback. Form one specific hypothesis and test a minimal correction; do not stack speculative fixes.

For RTL bugs, preserve a failing stimulus and run the affected VCS target after fixing; for documentation or reversible setup changes use proportionate checks. Never reveal environment values or credential contents in diagnostics. Use only availability booleans for sensitive configuration.

After repeated unsuccessful fixes, reconsider assumptions and interfaces; continue reasonable diagnosis within GOAL.md. Stop only at repository stop conditions, not an arbitrary upstream three-attempt approval gate. Record root cause, attempts, affected scope, current test evidence and executable next step. No automatic branch/worktree creation or agent delegation is implied.
''')

write('nature-writing','撰写、忠实润色或排版本工程 GNSS/EDA 技术报告，核对单位、实验条件、证据与引用。', '''
# Evidence-preserving technical reports

Modified derivative of Mubuky/nature-skills nature-writing for engineering reports rather than journal submission. Preserve LICENSE and NOTICE. [upstream.txt](references/upstream.txt) is provenance, not a router to execute.

Read the requested source, current design docs and report template. Preserve undamaged original text during structural cleanup; distinguish implementation, historical verification, current verification and missing evidence. Never rewrite frozen plan.md without explicit authorization.

For faithful editing read [polishing-workflow.md](references/polishing-workflow.md). For experimental sections read [experiments.md](references/experiments.md), applying engineering metrics and acceptance conditions rather than journal claims. For LaTeX placement read [latex-layout.md](references/latex-layout.md).

Include mathematical definitions, units, fixed-point formats, rounding/overflow behavior, sample timing, feedback activation, parameter provenance, test seeds/conditions/tolerances, failure cases and limitations. Use actual RTL ports and current evidence; do not manufacture citations, PPA numbers or convergence results.

Follow the actual course/template formatting; Nature journal word counts, title pages and submission declarations are irrelevant unless separately requested. Sources may include the course guide, B1I ICD and authoritative technical literature without a Nature-only restriction.

Deliver editable local artifacts. If PDF/Word is requested, compile/render and inspect pages, references, glyphs, tables and diagrams using available document/PDF tools. Pure Markdown changes require consistency and link checks, not EDA reruns. No publishing is implied.
''')

write('rtl-vcs-verification','在 Windows 编辑源与 Linux SSH VCS 环境中执行本工程 RTL 自检回归、同步文件并回收可追溯证据。', '''
# RTL / VCS verification

Read AGENTS.md, GOAL.md, docs/NEXT_STEPS.md and the affected module contract. Windows owns source edits; Linux ~/eda_project is the execution mirror. Read [environment.md](../eda-autonomous-workflow/references/environment.md) for runtime and SSH handling.

1. Identify changed RTL, dependent modules, TB, includes, model configuration and vectors. Regenerate changed golden vectors with Windows Python. Select actual Makefile targets: prn-regression, code-nco-epl-regression, carrier-regression, frontend-regression as applicable; inspect the Makefile for future targets.
2. Synchronize only required source/config/vector files using scp/sftp and compare SHA-256. Never test a stale remote mirror or overwrite unrelated user files. Create a new evidence directory for this run; preserve historical logs.
3. Run bash -lc with source ~/eda_env.sh, cd ~/eda_project and the selected make targets via SSH. Existing Makefile uses pipefail. Inspect compilation and simulator exit status as well as final self-check marker; reject fatal/error/mismatch/timeout and incomplete event counts even when the outer command exits zero.
4. Markers: B1I_PRN_REGRESSION_PASS; CODE_NCO_EPL_REGRESSION_PASS with RELOAD_COLLISION_PASS; CARRIER_REGRESSION_PASS; FRONTEND_REGRESSION_PASS. Markers must come from this run with matched source hashes. Verify expected counts from the current TB/vector manifest rather than historical constants.
5. Copy logs back using known absolute remote file paths one at a time if legacy SCP rejects multi-source copies. Do not disable host-key/file-name verification.
6. Record command, date, tool version, hashes, seeds/config, exit codes, events and logs. Fix failures and rerun affected targets; rerun dependencies when shared RTL changes. Update NEXT_STEPS and relevant design docs after substantive development.

Never run VCS/DC directly on Windows, call a Python model a VCS PASS, or equate module PASS to full tracking-loop acceptance. Skills installation itself does not authorize development or broad regression.
''')

write('gnss-b1i-design','设计与审查当前北斗 B1I 单通道码/载波跟踪算法、reference/golden 模型和逐样本 RTL 时间语义。', '''
# B1I single-channel design

Read GOAL.md, frozen plan.md, docs/ARCHITECTURE.md, docs/TBD.md, docs/NEXT_STEPS.md and affected module docs. The live goal controls scope; no automatic acquisition, 12-channel integration or back-end implementation.

Course V1.7 signal constants: Fs=16.368 MHz, real IF=4.092 MHz, Rc=2.046 Mcps, 2046 chips, nominal 16368 accepted samples per primary-code period. Fs is not logic clk. Two-bit input 00/01/10/11 maps to -3/-1/+1/+3 and needs signed 3-bit reconstruction. Verify PRN taps against the available ICD and current PRN doc; do not infer supported PRNs or NH/D1 parameters from memory.

For new algorithms first build an independent full-precision reference and signal generator. Scan meaningful candidates, retain failed cases and choose an engineering baseline with evidence. Then specify bit-exact golden arithmetic before RTL. Label every parameter course/ICD/derived/scanned; no guessed clock, SRAM or official dataset.

Define frequency/phase I/Q signs, Hz/radian/chip units, phase wrap, word formats, rounding/saturation, integration and loop update periods, pipeline delay, init reference sample and feedback effective sample. The current sample uses current NCO state; advance afterward. sample_valid gaps preserve state; init/reset priority and first/last integration sample are explicit contracts.

Score DLL and FLL/Costas PLL transients, steady errors, acquisition-to-tracking initial offsets, noise seeds, bounded dynamics, low energy, mode transitions, lock hysteresis and reset/init/gaps against a predeclared acceptance matrix. Truth is restricted to signal generation and scoring, never loop feedback. Separate synthetic evidence from unavailable course-data validation.

Consult live module documents for existing width/bandwidth baselines; this skill intentionally does not freeze new numerical choices. Use rtl-vcs-verification for implementation and nature-writing for design reports. Complete only the current GOAL acceptance criteria.
''')

write('synopsys-asic-flow','在既有 Linux SSH 环境中准备或审查 VCS、Design Compiler、ICC 和 PrimeTime 流程与报告；正式后端执行需在用户范围内。', '''
# Synopsys ASIC flow

Read GOAL.md, EDA_ENV_STATUS.md including newest appendices, docs/TBD.md, docs/NEXT_STEPS.md, Makefile and the requested Tcl/SDC files. Read [environment.md](../eda-autonomous-workflow/references/environment.md). A skill invocation is not authorization to expand the milestone.

Historical evidence: VCS I-2014.03 module regressions and DC K-2015.06 counter smoke have run; ICC/PT complete flows are not verified. icc2_shell was not found. Check requested commands only when actual execution is in scope; do not rescan licenses/PDKs/network or install modern substitutes.

VCS: use existing -sverilog targets and self-checking TBs. DC: inspect scripts/dc_smoke.tcl and constraints/counter.sdc as a smoke example, not GNSS timing requirements. Explicitly set design, sources/includes, target/link libraries, clocks and IO constraints based on supplied specifications; check analyze/elaborate/link/check_design and unmapped cells before area/timing reporting.

ICC is the legacy icc_shell flow, not ICC2. Physical implementation needs actual technology/Milkyway libraries, reference libraries, floorplan, power and RC/PVT inputs. PrimeTime needs matched netlist, libraries, SDC, corners and parasitics. Prepare parameterized scripts or document missing dependencies; do not claim closure using invented defaults or smoke constraints.

Retain tool exit codes, Tcl errors, check reports, netlist/SDC and source/config hashes under reports/. Distinguish smoke availability, functional correctness, synthesis mapping and timing/PPA signoff. Missing course clk/SRAM/PVT remain explicit TBDs. Current M1 excludes formal synthesis/PPA and ICC/PT unless the user changes scope.

Do not modify /home/IC/.bashrc, license files/daemons, system network or EDA installations.
''')

write('eda-autonomous-workflow','用户要求继续当前 EDA milestone 时，按工程基线自主执行模型、RTL、SSH 回归与文档交接；整理或安装请求仅处理授权范围。', '''
# EDA project execution and handoff

Read in order: GOAL.md; plan.md; EDA_ENV_STATUS.md including appended records; docs/ARCHITECTURE.md; docs/TBD.md; docs/NEXT_STEPS.md; involved module docs/code/Makefile/current logs. Read [environment.md](references/environment.md) before remote commands.

Current user request controls work. Merely opening the project, installing Skills, reviewing or organizing docs does not authorize implementation. For an explicit continue request, choose an unblocked task within live GOAL, establish full-precision model/scan evidence, specify golden arithmetic and RTL, run automated relevant VCS tests, fix failures and update docs; continue until goal completion or the repository's actual stop conditions.

Keep frozen plan.md unchanged; use design docs and NEXT_STEPS for implementation refinement. Preserve unrelated local edits and historical evidence. Unknown course configurations stay parameterized and in TBD with their real blocking scope.

Use gnss-b1i-design for algorithms, systemverilog for coding, tb-best-practices for checker design, rtl-vcs-verification for execution, systematic-debugging for faults, nature-writing for reports and synopsys-asic-flow only for explicitly scoped tool work. No companion plugin, custom agent type, Gateflow executable or global config change is needed.

After each substantive phase record current-source verification, failures/limitations, sync status and a directly executable next task in NEXT_STEPS, TBD and affected design docs. On completion check every GOAL criterion, record evidence and stop. Stop immediately on explicit pause. A tool limit or inaccessible VM is not completion; leave an accurate handoff.
''')

env=BASE/'eda-autonomous-workflow'/'references'/'environment.md'
env.parent.mkdir(exist_ok=True)
env.write_text('''# Windows / Linux execution boundary

Windows is the editing and Python-model host. Obtain bundled Python via the Codex workspace-dependency tool or an already verified local runtime; WindowsApps/python.exe may be only a store alias. Never depend on the historical C:\\Users\\IC runtime path without checking it.

Linux target: 7901_15@192.168.159.128; environment ~/eda_env.sh; project ~/eda_project. SSH options: BatchMode=yes, ConnectTimeout=15, IPQoS=none. Read docs/NEXT_STEPS.md for the established command and existing key path. The historical C:\\Users\\IC\\.ssh\\id_rsa_eda_codex may be absent on this account. Accept a caller-supplied -KeyPath, or a verified existing agent/config identity; never create/copy credentials or disable host-key verification automatically.

PowerShell example (set $edaKey to an existing key path only):

```powershell
$edaArgs = @('-o','BatchMode=yes','-o','ConnectTimeout=15','-o','IPQoS=none')
if ($edaKey) { $edaArgs += @('-i', $edaKey) }
& ssh @edaArgs '7901_15@192.168.159.128' "bash -lc 'source ~/eda_env.sh && cd ~/eda_project && make carrier-regression'"
if ($LASTEXITCODE -ne 0) { throw 'VCS remote command failed' }
```

This example is an execution recipe, not a transport check: synchronize and verify requested sources first. For connectivity validation use only command -v and readable-file checks. If unreachable, document timeout separately from tool failure; do not change VM/network configuration. Do not run EDA regressions solely for Skill installation when no RTL changed.
''',encoding='utf-8')

# Retain only resources reachable from adapted entrypoints, plus legal provenance.
# These packages were created by this installation; never prune an existing user package.
keep={
 'systemverilog':{'SKILL.md','LICENSE','references/upstream.txt'},
 'tb-best-practices':{'SKILL.md','LICENSE','references/upstream.txt'},
 'systematic-debugging':{'SKILL.md','LICENSE','references/upstream.txt','root-cause-tracing.md'},
 'nature-writing':{'SKILL.md','LICENSE','NOTICE','references/upstream.txt','references/polishing-workflow.md','references/experiments.md','references/latex-layout.md','references/terminology-ledger.md','references/ethics.md'},
}
for name,allowed in keep.items():
    folder=(BASE/name).resolve()
    if BASE.resolve() not in folder.parents: raise RuntimeError('Invalid prune boundary')
    for file in folder.rglob('*'):
        if file.is_file() and file.relative_to(folder).as_posix() not in allowed:
            file.unlink()
    for directory in sorted((p for p in folder.rglob('*') if p.is_dir()),key=lambda p:len(p.parts),reverse=True):
        if not any(directory.iterdir()): directory.rmdir()

# Immutable install/adaptation inventory for maintenance and validation.
manifest['files']={str(p.relative_to(BASE)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in BASE.rglob('*') if p.is_file()}
(ROOT/'.agents'/'skills-lock.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Adapted 4 upstream skills and created 4 project skills.')
