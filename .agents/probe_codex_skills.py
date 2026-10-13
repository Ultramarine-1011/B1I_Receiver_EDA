"""Read-only app-server discovery probe, no thread creation or agent execution."""
from pathlib import Path
import json, subprocess, queue, threading, time

ROOT=Path(__file__).resolve().parent.parent
cli=Path.home()/'AppData/Roaming/npm/node_modules/@openai/codex/bin/codex.js'
node=Path.home()/'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
proc=subprocess.Popen([str(node),str(cli),'app-server'],cwd=ROOT,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True,encoding='utf-8')
messages=queue.Queue()
def reader():
    for line in proc.stdout:
        try: messages.put(json.loads(line))
        except ValueError: pass
threading.Thread(target=reader,daemon=True).start()
def send(payload):
    proc.stdin.write(json.dumps(payload)+'\n'); proc.stdin.flush()
def receive(identifier):
    end=time.monotonic()+30
    while time.monotonic()<end:
        try: item=messages.get(timeout=max(.1,end-time.monotonic()))
        except queue.Empty: break
        if item.get('id')==identifier: return item
    raise TimeoutError('App-server discovery response timed out')
try:
    send({'id':1,'method':'initialize','params':{'clientInfo':{'name':'eda-skills-check','version':'1.0'}}})
    first=receive(1)
    if 'error' in first: raise RuntimeError(str(first['error']))
    send({'method':'initialized','params':{}})
    send({'id':2,'method':'skills/list','params':{'cwds':[str(ROOT)],'forceReload':True}})
    result=receive(2)
    if 'error' in result: raise RuntimeError(str(result['error']))
    local=[]
    discovery_errors=[]
    for group in result['result'].get('data',[]):
        discovery_errors+=group.get('errors',[])
        for skill in group.get('skills',[]):
            if str(ROOT/'.agents'/'skills').lower() in skill.get('path','').replace('/','\\').lower():
                local.append({key:skill.get(key) for key in ('name','path','enabled','scope')})
    evidence={'date':'2026-10-13','method':'skills/list','project_skills':local,'discovery_errors':discovery_errors}
    (ROOT/'reports/skills/codex_discovery.json').write_text(json.dumps(evidence,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(json.dumps(evidence,indent=2,ensure_ascii=False))
    if len(local)!=8 or any(s.get('enabled') is False for s in local): raise RuntimeError('Eight enabled project skills were not discovered')
finally:
    proc.terminate()
    try: proc.wait(timeout=5)
    except subprocess.TimeoutExpired: proc.kill()
