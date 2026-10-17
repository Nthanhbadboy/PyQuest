/* r50 design-only JS analogue. No Flutter/Python, database, events or real economy. */
(function(root){
'use strict';
const catalog=typeof module!=='undefined'?require('../maze-trail-r45/catalog.js'):root.MazeCatalog;
const copy=x=>JSON.parse(JSON.stringify(x)),directions={U:[0,-1],D:[0,1],L:[-1,0],R:[1,0]};
const count=p=>p.reduce((n,b)=>n+(typeof b==='string'?1:1+b.body.length),0);
function expand(program,loops){
 const refs=[];let commands=0;
 for(let i=0;i<program.length;i++){
  const b=program[i];
  if(typeof b==='string'&&directions[b]){refs.push({dir:b,block:i,inner:null});commands++;}
  else if(b&&loops&&Number.isInteger(b.times)&&b.times>=2&&b.times<=9&&Array.isArray(b.body)&&b.body.length>0&&b.body.length<=6&&b.body.every(d=>directions[d])){
   commands+=1+b.body.length;for(let t=0;t<b.times;t++)b.body.forEach((dir,inner)=>refs.push({dir,block:i,inner,iteration:t+1}));
  }else return {valid:false,refs:[],commands:0};
 }
 return {valid:refs.length>0&&commands<=30,refs,commands};
}
function run(level,program){
 const width=level.rows[0].length,flat=level.rows.join(''),start=flat.indexOf('S'),expanded=expand(program,level.allowLoops);
 let pos=start,outcome=null;const gems=new Set(),frames=[{pos,gems:[],ref:null}];
 if(!expanded.valid)return {outcome:'invalid',frames,commands:count(program),stars:0,score:0};
 for(let i=0;i<expanded.refs.length;i++){
  const ref=expanded.refs[i];if(i>=200){outcome='tooLong';break;}
  const [dx,dy]=directions[ref.dir],x=pos%width+dx,y=Math.floor(pos/width)+dy;
  if(x<0||x>=width||y<0||y>=level.rows.length)outcome='edge';
  else {const next=y*width+x,c=flat[next];if(c==='#')outcome='wall';else{pos=next;if(c==='~')outcome='water';if(c==='*')gems.add(pos);if(c==='C')outcome='win';}}
  frames.push({pos,gems:[...gems],ref,blocked:outcome&&outcome!=='win'?outcome:null});if(outcome)break;
 }
 outcome=outcome||'notThere';const reached=outcome==='win',allGems=reached&&gems.size===level.gems,withinLimit=reached&&expanded.commands<=level.commandLimit;
 return {outcome,frames,commands:expanded.commands,stars:reached?1+Number(allGems)+Number(withinLimit):0,score:reached?40+30*Number(allGems)+30*Number(withinLimit):0,reached,allGems,withinLimit};
}
function initial(index=2,token=0){return {index,program:[],history:[],openLoop:null,phase:'editing',frame:0,result:null,attempts:0,token,record:'idle',pending:null,records:{rm_01:3,rm_02:2},energy:4,notice:null};}
const level=s=>catalog.levels[s.index];
function edit(s,fn){if(['running','paused'].includes(s.phase)||s.pending)return s;const n=copy(s);n.history.push({program:copy(s.program),openLoop:s.openLoop});if(n.history.length>40)n.history.shift();fn(n);if(count(n.program)>30)return s;n.phase='editing';n.frame=0;n.result=null;n.record='idle';n.notice=null;n.token++;return n;}
function add(s,dir){if(!directions[dir])return s;if(s.openLoop!==null&&s.program[s.openLoop].body.length>=6)return s;return edit(s,n=>{if(n.openLoop===null)n.program.push(dir);else n.program[n.openLoop].body.push(dir);});}
function loop(s){if(!level(s).allowLoops||s.openLoop!==null)return s;return edit(s,n=>{n.openLoop=n.program.length;n.program.push({times:2,body:[]});});}
function closeLoop(s){if(s.openLoop===null)return s;return edit(s,n=>{if(!n.program[n.openLoop].body.length)n.program.splice(n.openLoop,1);n.openLoop=null;});}
function times(s,v){if(s.openLoop===null||!Number.isInteger(v)||v<2||v>9)return s;return edit(s,n=>{n.program[n.openLoop].times=v;});}
function undo(s){if(!s.history.length||['running','paused'].includes(s.phase)||s.pending)return s;const n=copy(s),h=n.history.pop();n.program=h.program;n.openLoop=h.openLoop;n.phase='editing';n.result=null;n.frame=0;n.record='idle';n.token++;return n;}
function clear(s){return edit(s,n=>{n.program=[];n.openLoop=null;});}
function reopen(s,index){if(s.openLoop!==null||!s.program[index]||typeof s.program[index]==='string')return s;return edit(s,n=>{n.openLoop=index;});}
function popInner(s){if(s.openLoop===null||!s.program[s.openLoop].body.length)return s;return edit(s,n=>n.program[n.openLoop].body.pop());}
function remove(s,index){if(s.openLoop!==null||!Number.isInteger(index)||index<0||index>=s.program.length)return s;return edit(s,n=>n.program.splice(index,1));}
function shift(s,index,delta){if(s.openLoop!==null||!Number.isInteger(index)||![-1,1].includes(delta)||index<0||index>=s.program.length||index+delta<0||index+delta>=s.program.length)return s;return edit(s,n=>{const b=n.program.splice(index,1)[0];n.program.splice(index+delta,0,b);});}
function start(s){if(s.openLoop!==null||!['editing','result'].includes(s.phase)||s.pending)return s;const r=run(level(s),s.program);if(r.outcome==='invalid')return {...s,notice:'empty'};return {...s,phase:'running',frame:0,result:r,token:s.token+1,attempts:s.attempts+1,record:'idle',notice:null};}
function tick(s,token){if(token!==s.token||!['running','paused'].includes(s.phase))return s;const frame=Math.min(s.frame+1,s.result.frames.length-1);if(frame===s.result.frames.length-1)return {...s,frame,phase:'result',record:s.result.reached?'pending':'idle',pending:s.result.reached?{token,level:level(s).id,stars:s.result.stars}:null};return {...s,frame};}
function pause(s){return s.phase==='running'?{...s,phase:'paused'}:s;}
function resume(s){return s.phase==='paused'?{...s,phase:'running'}:s;}
function stop(s){return {...s,phase:'editing',result:null,frame:0,pending:null,record:'idle',token:s.token+1};}
function acknowledge(s,token,ok){if(!s.pending||s.pending.token!==token||s.token!==token||s.phase!=='result')return s;if(!ok)return {...s,record:'error'};const p=s.pending;return {...s,record:'saved',pending:null,records:{...s.records,[p.level]:Math.max(s.records[p.level]||0,p.stars)}};}
function retryRecord(s){return s.record==='error'?{...s,record:'pending'}:s;}
function nextInfo(s){const next=catalog.levels[s.index+1];if(!next)return {kind:'last',cost:0};const cost=s.records[next.id]?0:catalog.costs.new;if(s.record!=='saved')return {kind:'unconfirmed',cost};if(cost&&s.energy===null)return {kind:'unknown',cost};if(cost&&s.energy<cost)return {kind:'empty',cost};return {kind:'ready',cost};}
function next(s){const info=nextInfo(s);if(info.kind!=='ready')return s;return {...initial(s.index+1,s.token+1),records:copy(s.records),energy:s.energy===null?null:s.energy-info.cost};}
function python(program){return program.map(b=>typeof b==='string'?`${{U:'up',D:'down',L:'left',R:'right'}[b]}()`: `for i in range(${b.times}):\n${b.body.length?b.body.map(d=>'    '+({U:'up',D:'down',L:'left',R:'right'}[d])+'()').join('\n'):'    pass'}`).join('\n');}
const fixtures=['ready','assembled','running','paused','wall','water','edge','short','win_one','win_two','win_three','pending','save_error','energy_empty','energy_unknown','last','final_win','loop','open_loop'];
function fixture(id,token=0){let s=initial(2,token);if(id==='ready')return s;
 if(['assembled','running','paused'].includes(id)){s.program=['R','D','D','D','R','R','U','R'];if(id==='assembled')return s;s=tick(start(s),s.token+1);return id==='paused'?pause(s):s;}
 if(id==='loop'||id==='open_loop'){s.index=5;s=loop(s);s=times(s,3);s=add(s,'R');return id==='loop'?closeLoop(s):s;}
 if(id==='final_win'){s.index=9;s.program=[{times:5,body:['R']},{times:2,body:['D']},{times:5,body:['L']},{times:2,body:['D']},{times:5,body:['R']},'D'];}
 else if(id==='water'){s.index=3;s.program=['R','R','R'];}
 else if(id==='wall')s.program=['R','R'];else if(id==='edge')s.program=['U'];else if(id==='short')s.program=['R'];
 else if(id==='win_one')s.program=['D','U','D','D','R','D','R','R','U','R'];
 else if(id==='win_two')s.program=['D','D','R','D','R','R','U','R'];
 else if(id==='last'){s.index=9;s.program=['R','R','R','R','R','D','D','D','D','D'];} // Not a win fixture: final-level entry.
 else {s.index=0;s.program=['R','R','R','R'];}
 if(id==='last'){s.program=[];return s;}
 s=start(s);while(s.phase==='running')s=tick(s,s.token);
 if(s.pending){if(id==='save_error')s=acknowledge(s,s.token,false);else if(id!=='pending')s=acknowledge(s,s.token,true);}
 if(id==='energy_empty'){s.records={rm_01:3};s.energy=0;}
 if(id==='energy_unknown'){s.records={rm_01:3};s.energy=null;}
 return s;
}
const api={catalog,copy,count,expand,run,initial,level,add,loop,closeLoop,times,undo,clear,reopen,popInner,remove,shift,start,tick,pause,resume,stop,acknowledge,retryRecord,nextInfo,next,python,fixture,fixtures};root.MazePlayModel=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
