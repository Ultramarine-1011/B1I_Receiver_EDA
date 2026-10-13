"""Validate portable skill metadata, active links, inventory and local dependencies."""
from pathlib import Path
import hashlib, json, re, sys, subprocess

ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'.agents'/'.validation-deps'))
import yaml

BASE=ROOT/'.agents'/'skills'
lock=json.loads((ROOT/'.agents'/'skills-lock.json').read_text(encoding='utf-8'))
errors=[]
entries=[]
for path in sorted(BASE.glob('*/SKILL.md')):
    text=path.read_text(encoding='utf-8')
    front=yaml.safe_load(text.split('---',2)[1])
    name=front.get('name')
    if name != path.parent.name or not re.fullmatch('[a-z0-9-]{1,64}',name or ''):
        errors.append(f'Invalid name: {path}')
    if not isinstance(front.get('description'),str) or not front['description'].strip():
        errors.append(f'Missing description: {name}')
    if set(front)-{'name','description','metadata','license','compatibility','allowed-tools'}:
        errors.append(f'Nonportable frontmatter: {name}')
    for link in re.findall(r'\]\(([^)]+)\)',text):
        if '://' not in link and not (path.parent/link.split('#')[0]).exists():
            errors.append(f'Broken link: {name}/{link}')
    if re.search(r'\{plugin_root\}|Task\(subagent_type|superpowers:|LLM_FILL',text):
        errors.append(f'Unresolved plugin dependency: {name}')
    entries.append({'name':name,'path':str(path),'description':front['description']})
for relative,expected in lock['files'].items():
    file=BASE/relative
    if not file.exists() or hashlib.sha256(file.read_bytes()).hexdigest()!=expected:
        errors.append(f'Inventory mismatch: {relative}')
if len(entries)!=8: errors.append(f'Expected eight skills, found {len(entries)}')
if len({e['name'] for e in entries}) != len(entries): errors.append('Duplicate names')

# Harmless model import probes, with bytecode disabled: no model scan/vector mutation.
import importlib.util
sys.dont_write_bytecode=True
models=[]
for file in ['model/b1i_prn_golden.py','model/code_nco_epl_model.py','model/carrier_model.py','model/tracking_reference.py']:
    try:
        sys.path.insert(0,str(ROOT/'model'))
        spec=importlib.util.spec_from_file_location(Path(file).stem,ROOT/file)
        module=importlib.util.module_from_spec(spec)
        sys.modules[spec.name]=module
        spec.loader.exec_module(module)
        models.append({'file':file,'import':'PASS'})
    except Exception as e:
        models.append({'file':file,'import':'FAIL','error':str(e)})
        errors.append(f'Model dependency: {file}: {e}')
result={'date':'2026-10-13','skills':entries,'count':len(entries),'errors':errors,'model_dependencies':models,'python':sys.executable}
out=ROOT/'reports'/'skills'
out.mkdir(parents=True,exist_ok=True)
(out/'validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'count':len(entries),'models':models,'errors':errors},ensure_ascii=False,indent=2))
raise SystemExit(bool(errors))
