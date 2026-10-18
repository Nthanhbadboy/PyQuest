/* Interaction model only. Authored transcript lookup, NEVER a Python interpreter. */
(function(root){'use strict';
const generated='for i in range(5):\n    right()\nfor i in range(5):\n    down()';
const samples={
 syntax:{code:'for i in range(5)\n    right()',kind:'syntax',line:1,raw:"SyntaxError: expected ':'",output:'',goal:false},
 runtime:{code:'rigth()',kind:'runtime',line:1,raw:"NameError: name 'rigth' is not defined",output:'',goal:false},
 unsupported:{code:'import turtle',kind:'unsupported',line:1,raw:'Unsupported example: import',output:'',goal:false},
 limit:{code:'while True:\n    pass',kind:'limit',line:null,raw:'Sample step-budget stop',output:'',goal:false},
 output:{code:'print("Sẵn sàng, Robo!")\nright()',kind:'none',line:null,raw:'',output:'Sẵn sàng, Robo!\n',goal:false},
 won:{code:generated,kind:'halted',line:null,raw:'HostHalt: win (authored example)',output:'',goal:true}
};
const clone=x=>JSON.parse(JSON.stringify(x));
function initial(token=0){return {code:generated,start:0,end:0,revision:0,token,scope:'sample-workshop-01/revision-1',mode:'python',dirty:false,history:[],future:[],pending:null,response:null,phase:'draft',notice:null};}
function select(s,start,end=start){start=Math.max(0,Math.min(s.code.length,start));end=Math.max(start,Math.min(s.code.length,end));return {...s,start,end};}
function edit(s,code,start,end=start){if(code.length>5000||code.split('\n').length>200)return {...s,notice:'length'};if(code===s.code)return select(s,start,end);const old={code:s.code,start:s.start,end:s.end};return {...select(s,start,end),code,start:Math.min(start,code.length),end:Math.min(end,code.length),revision:s.revision+1,dirty:true,history:[...s.history.slice(-39),old],future:[],phase:s.pending?'pending':s.response?'edited':'draft',notice:null};}
function insert(s,text,back=0){const code=s.code.slice(0,s.start)+text+s.code.slice(s.end),caret=s.start+text.length-back;return edit(s,code,caret);}
function newline(s){const prefix=s.code.slice(0,s.start),line=prefix.slice(prefix.lastIndexOf('\n')+1),indent=/^ */.exec(line)[0].length+(line.trimEnd().endsWith(':')?4:0);return insert(s,'\n'+' '.repeat(indent));}
function indent(s,out=false){if(s.start===s.end&&!out)return insert(s,'    ');const begin=s.start===0?0:s.code.lastIndexOf('\n',s.start-1)+1;let end=s.end>s.start&&s.code[s.end-1]==='\n'?s.end-1:s.code.indexOf('\n',s.end);if(end<0)end=s.code.length;const old=s.code.slice(begin,end),lines=old.split('\n'),changed=lines.map(l=>out?l.slice(Math.min(4,/^ */.exec(l)[0].length)):'    '+l).join('\n');if(s.start===s.end){const removed=old.length-changed.length;return edit(s,s.code.slice(0,begin)+changed+s.code.slice(end),Math.max(begin,s.start-removed));}return edit(s,s.code.slice(0,begin)+changed+s.code.slice(end),begin,begin+changed.length);}
function undo(s,redo=false){const from=redo?s.future:s.history;if(!from.length)return s;const snap=from.at(-1),here={code:s.code,start:s.start,end:s.end};return {...s,...snap,revision:s.revision+1,dirty:true,history:redo?[...s.history,here]:s.history.slice(0,-1),future:redo?s.future.slice(0,-1):[...s.future,here],phase:s.pending?'pending':s.response?'edited':'draft',notice:null};}
function begin(s){if(s.pending||!s.code.trim()||s.mode!=='python')return s;const token=s.token+1;return {...s,token,pending:{token,code:s.code,revision:s.revision,scope:s.scope},response:null,phase:'pending',notice:null};}
function transcript(code){const pair=Object.entries(samples).find(([,v])=>v.code===code);return pair?{...clone(pair[1]),sampleId:pair[0]}:{kind:'unavailable',line:null,raw:'',output:'',goal:false,sampleId:null};}
function deliver(s,token){if(!s.pending||s.pending.token!==token||s.token!==token)return s;const p=s.pending;if(s.revision!==p.revision||s.scope!==p.scope)return {...s,pending:null,response:null,phase:'outdated'};return {...s,pending:null,response:{...transcript(p.code),revision:p.revision,scope:p.scope},phase:'response'};}
function cancel(s){if(!s.pending)return s;return {...s,pending:null,response:null,token:s.token+1,phase:'cancelled'};}
function mode(s,next){if(s.pending||!['python','blocks'].includes(next))return s;return {...s,mode:next};}
function replaceFromBlocks(s){if(s.pending)return s;return {...edit(s,generated,generated.length),mode:'python'};}
function current(s){return !!s.response&&s.response.revision===s.revision&&s.response.scope===s.scope;}
function lineRange(code,line){if(!Number.isInteger(line)||line<1||line>code.split('\n').length)return null;const lines=code.split('\n');const start=lines.slice(0,line-1).reduce((n,l)=>n+l.length+1,0);return {start,end:start+lines[line-1].length};}
function commandLines(code){return code.split('\n').filter(l=>l.trim()&&!l.trim().startsWith('#')).length;}
const fixtures=['draft','syntax','runtime','unsupported','limit','output','won','pending','cancelled','outdated','edited','unavailable','blocks','long'];
function fixture(id,token=0){let s=initial(token);if(samples[id]){s=edit(s,samples[id].code,0);s=begin(s);return deliver(s,s.token)}if(id==='blocks')return {...s,mode:'blocks'};if(id==='long')return edit(s,Array.from({length:60},(_,i)=>'# '+(i+1)+' · Robo 🐾').join('\n'),0);if(['pending','cancelled','outdated'].includes(id)){s=begin(s);if(id==='pending')return s;if(id==='cancelled')return cancel(s);s=insert(s,'# edited\n');return deliver(s,s.token)}if(id==='edited'){s=fixture('syntax',token);return insert(s,'# changed\n')}if(id==='unavailable'){s=edit(s,'print(42)',0);s=begin(s);return deliver(s,s.token)}return s;}
const api={generated,samples,initial,select,edit,insert,newline,indent,undo,begin,transcript,deliver,cancel,mode,replaceFromBlocks,current,lineRange,commandLines,fixtures,fixture,clone};root.PythonStudyModel=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
