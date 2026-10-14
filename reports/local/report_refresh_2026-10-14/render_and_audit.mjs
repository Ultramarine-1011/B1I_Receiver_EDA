import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {marked} from 'file:///C:/Users/26255/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/marked/lib/marked.esm.js';
const root=process.cwd();
const output=path.join(root,'work/report_preview');
fs.mkdirSync(path.join(output,'assets'),{recursive:true});
const names=['ACQUISITION_REPORT','TRACKING_REPORT','NH_D1_REPORT'];
const reports=[];const failures=[];
const htmlEscape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
for(const name of names){
  const file=path.join(root,'docs',name+'.md');const raw=fs.readFileSync(file,'utf8');
  const tokens=marked.lexer(raw);const links=[];const images=[];const tables=[];
  marked.walkTokens(tokens,token=>{
    if(token.type==='link'||token.type==='image'){
      if(!/^(https?:|#)/.test(token.href)){
        const dest=path.resolve(path.dirname(file),decodeURIComponent(token.href.split('#')[0]));
        const exists=fs.existsSync(dest);links.push({target:token.href,exists});if(!exists)failures.push(`${name}: missing ${token.href}`);
        if(token.type==='image'){images.push(token.href);if(exists)fs.copyFileSync(dest,path.join(output,'assets',path.basename(dest)));}
      }
    }
    if(token.type==='table')tables.push({columns:token.header.length,rows:token.rows.length});
  });
  const mermaid=(raw.match(/```mermaid\n[\s\S]*?\n```/g)||[]).length;
  const displays=(raw.match(/^\$\$$/gm)||[]).length;
  if(displays%2)failures.push(name+': unmatched display math');
  const sections=tokens.filter(t=>t.type==='heading'&&t.depth===2).map(t=>t.text);
  if(sections.length!==5)failures.push(name+': expected 5 main sections');
  if(mermaid!==1)failures.push(name+': expected one architecture diagram');
  let source=raw.replace(/\$\$([\s\S]*?)\$\$/g,(all,body)=>'<div class="math">\\['+htmlEscape(body)+'\\]</div>');
  const inlineMath=[];
  source=source.replace(/(?<!\$)\$([^$\n]+)\$(?!\$)/g,(all,body)=>{const i=inlineMath.length;inlineMath.push('<span class="math">\\('+htmlEscape(body)+'\\)</span>');return 'EDAINLINEMATHPLACEHOLDER'+i+'TOKEN';});
  let body=marked.parse(source);
  body=body.replace(/EDAINLINEMATHPLACEHOLDER(\d+)TOKEN/g,(all,i)=>inlineMath[Number(i)]);
  body=body.replace(/<pre><code class="language-mermaid">([\s\S]*?)<\/code><\/pre>/g,'<div class="mermaid">$1</div>');
  body=body.replace(/src="([^"]+)"/g,(all,src)=>`src="assets/${path.basename(src)}"`);
  const html=`<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>${name}</title><style>
body{font-family:'Microsoft YaHei','Segoe UI',sans-serif;max-width:1120px;margin:28px auto;padding:0 22px;color:#182536;line-height:1.8;font-size:16px}h1{font-size:29px}h2{margin-top:36px;border-bottom:1px solid #ccd7e2;padding-bottom:8px}h3{margin-top:26px}img{display:block;width:100%;height:auto;margin:18px 0}table{border-collapse:collapse;width:100%;font-size:14px;line-height:1.65;margin:16px 0}th,td{border:1px solid #cfdae4;padding:8px 10px;vertical-align:top}th{background:#eef4f8;text-align:left}code{font-family:Consolas,monospace;font-size:.92em}.math{overflow-x:auto;text-align:center}.mermaid{background:#f9fbfd;padding:12px;margin:16px 0}a{color:#175b9c}#render-state{font-size:13px;color:#667}</style>
<div id="render-state">Temporary verification preview</div>${body}
<script>window.previewStatus={mermaid:'pending',math:'pending'}; window.MathJax={tex:{inlineMath:[['\\\\(','\\\\)']],displayMath:[['\\\\[','\\\\]']]},startup:{ready(){MathJax.startup.defaultReady();MathJax.startup.promise.then(()=>window.previewStatus.math='pass').catch(e=>window.previewStatus.math=String(e));}}};</script>
<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3.2.2/es5/tex-chtml.js" onerror="window.previewStatus.math='load_error'"></script>
<script type="module">try{const {default:mermaid}=await import('https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs');mermaid.initialize({startOnLoad:false,securityLevel:'strict',theme:'neutral'});await mermaid.run({querySelector:'.mermaid'});window.previewStatus.mermaid='pass';}catch(e){window.previewStatus.mermaid=String(e);}</script></html>`;
  fs.writeFileSync(path.join(output,name+'.html'),html);
  reports.push({name,sha256:crypto.createHash('sha256').update(raw).digest('hex'),sections,links:links.length,images,tables,mermaid,display_equations:displays/2,inline_equations:inlineMath.length});
}
const result={status:failures.length?'FAIL':'PASS',reports,failures,preview:'work/report_preview',note:'Preview uses installed Marked17.0.5 plus pinned Mermaid11.4.1 and MathJax3.2.2; source reports and assets are the final artifacts.'};
fs.writeFileSync(path.join(root,'reports/local/report_refresh_2026-10-14/document_audit.json'),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({status:result.status,reports:reports.map(r=>({name:r.name,links:r.links,images:r.images.length,tables:r.tables.length,mermaid:r.mermaid,display_equations:r.display_equations})),failures}));
if(failures.length)process.exitCode=1;
