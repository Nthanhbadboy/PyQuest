/* Pure UI proposal: receipt fixtures only. No events, database, Python or rewards. */
(function(root){'use strict';
const clone=x=>JSON.parse(JSON.stringify(x));
const notices=[{kind:'badge',id:'first_steps',title:['Bước Chân Đầu Tiên','First Steps'],description:['Vượt qua màn chơi đầu tiên trên đảo.','Complete your first island game level.']},{kind:'quest',id:'sample-daily',title:['Nhiệm vụ hôm nay hoàn thành!','Daily quest completed!'],description:['Đến bảng nhiệm vụ để nhận tem; xem thông báo không nhận tem.','Visit daily quests to claim a stamp; viewing this notice does not claim it.']},{kind:'energy',id:'sample-milestone',title:['Thông báo năng lượng mẫu','Sample energy notice'],description:['Chỉ hiển thị biên nhận mẫu, không cộng vào số dư.','Displays a sample receipt only; no balance is changed.']},{kind:'unlock',id:'sample-unlock',title:['Một cánh cửa mới','A new door'],description:['Mẫu thông báo mở khóa, không mở thêm phòng trong app.','Sample unlock notice; no app room is unlocked.']},{kind:'item',id:'sample-item',title:['Kỷ vật cho chuyến đi','A keepsake for the journey'],description:['Mẫu vật phẩm, không thêm vào túi đồ thật.','Sample item; nothing is added to a real inventory.']}];
const key=n=>n.kind+':'+n.id;
function unique(items){const seen=new Set();return items.filter(n=>{const k=key(n);if(seen.has(k))return false;seen.add(k);return true})}
function initial(serial=0){return {serial,scope:'robot_maze:rm_02',revision:1,runRevision:1,mode:'regular',phase:'pending',request:null,token:serial,attempt:{won:true,allGems:true,withinLimit:true,score:100,stars:3,commands:6,limit:6,gems:1,totalGems:1,runs:2},previous:{score:70,stars:2,plays:1},record:null,proof:null,wasVerified:false,notices:[],seen:[],inboxOpen:true,noticeStatus:'unknown',last:false,noGems:false};}
function begin(s){if(s.request||!s.attempt.won||s.phase==='stale'||s.phase==='saved')return s;const token=s.token+1;return {...s,token,phase:'checking',request:{token,scope:s.scope,revision:s.revision}}}
function valid(s){return !!s.request&&s.request.scope===s.scope&&s.request.revision===s.revision}
function settle(s,token,result='complete',items=[]){if(!['complete','partial','error'].includes(result))return s;if(!s.request||s.request.token!==token||s.token!==token)return s;if(!valid(s))return {...s,phase:'stale',request:null};if(result==='error')return {...s,phase:s.record||s.proof?'partial':'error',request:null};
 let record=s.record,proof=s.proof;if(s.mode==='regular'&&!record)record={score:Math.max(s.previous?.score||0,s.attempt.score),stars:Math.max(s.previous?.stars||0,s.attempt.stars),plays:(s.previous?.plays||0)+1};if(s.mode==='custom')proof={scope:s.scope,revision:s.revision};
 return {...s,record,proof,request:null,phase:result==='partial'?'partial':'saved',noticeStatus:result==='partial'?'unknown':'ready',notices:result==='partial'?s.notices:unique(clone(items))};}
function cancel(s){return s.request?{...s,request:null,token:s.token+1,phase:s.record||s.proof?'partial':'pending'}:s}
function editCustom(s){if(s.mode!=='custom')return s;return {...s,revision:s.revision+1,phase:'stale',proof:null,notices:[],seen:[],noticeStatus:'unknown'};}
function verified(s){return s.mode==='custom'&&!!s.proof&&s.proof.scope===s.scope&&s.proof.revision===s.revision}
function newBest(s){return s.mode==='regular'&&!!s.record&&!!s.previous&&s.record.score>s.previous.score}
function available(s){return s.phase==='saved'&&(s.mode==='regular'?!!s.record:verified(s))}
function mark(s,k){if(s.noticeStatus!=='ready'||!s.notices.some(n=>key(n)===k)||s.seen.includes(k))return s;return {...s,seen:[...s.seen,k]}}
function inbox(s,open){return {...s,inboxOpen:open}}
function fixture(id,serial=0){let s=initial(serial);let result='complete',items=[];
 if(id==='first'||id==='no-gems'){s.previous=null;items=notices.slice(0,2)}
 if(id==='tie'){s.previous={score:100,stars:3,plays:3}}
 if(id==='lower'){s.previous={score:100,stars:3,plays:3};s.attempt={...s.attempt,allGems:false,withinLimit:false,score:40,stars:1,commands:9,gems:0}}
 if(['first','no-gems','rewards'].includes(id)){s.noGems=true;s.scope='robot_maze:rm_01';s.attempt={...s.attempt,commands:4,limit:4,gems:0,totalGems:0,runs:1}}
 if(id==='no-gems'){s.previous={score:100,stars:3,plays:2};items=[]}
 if(id==='final'){s.last=true;s.scope='robot_maze:rm_10'}
 if(id==='rewards'){s.previous=null;items=notices;}
 if(id==='pending')return s;
 if(id==='waiting')return begin(s);
 if(id==='save-error')result='error';
 if(id==='partial')result='partial';
 if(id.startsWith('custom')){s.mode='custom';s.scope='custom:sample-07';s.previous=null;s.attempt={...s.attempt,allGems:false,stars:2,score:70,commands:4,limit:10,gems:0,totalGems:1};s.wasVerified=id==='custom-repeat';if(id==='custom-pending')return s;if(id==='custom-save-error')result='error';if(id==='custom-partial')result='partial'}
 if(id==='not-won'){s.mode='custom';s.scope='custom:sample-07';s.attempt={...s.attempt,won:false,stars:0,score:0};return {...s,phase:'not-won'}}
 s=begin(s);s=settle(s,s.token,result,items);if(id==='custom-edited')s=editCustom(s);return s;}
const fixtures=['first','better','tie','lower','no-gems','final','pending','waiting','save-error','partial','rewards','empty','custom-pending','custom-save-error','custom-saved','custom-repeat','custom-partial','custom-edited','not-won'];
const api={clone,notices,key,unique,initial,begin,settle,cancel,editCustom,verified,newBest,available,mark,inbox,fixture,fixtures};root.MazeReceiptModel=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
