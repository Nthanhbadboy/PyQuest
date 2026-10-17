'use strict';
(function(root){
const C=typeof module!=='undefined'?require('./catalog.js'):root.ChapterCatalog;
const fixtures=['new','returning','midway','challenge','chapter_done','locked','energy_empty','review_free','loading','load_error','energy_unknown','deep_link','next_chapter','departure'];
function fixture(id='returning'){
 if(!fixtures.includes(id))throw Error('Unknown fixture');
 const n={new:0,midway:6,challenge:11,chapter_done:12,next_chapter:12}[id]??1;
 const s={fixture:id,done:C.lessons.slice(0,n).map(l=>l.id),capacity:n===12?Math.min(C.energyConfig.max_cap,C.energyConfig.max_initial+C.energyConfig.milestone_bonus['chapter:code_apprentice']):C.energyConfig.max_initial,energy:id==='new'?16:11,status:'ready',selected:Math.min(n,11),group:Math.floor(Math.min(n,11)/4),modal:null,route:null};
 if(['energy_empty','review_free','chapter_done','next_chapter'].includes(id))s.energy=0;
 if(id==='challenge')s.energy=3;
 if(id==='midway')s.energy=9;
 if(id==='locked'){s.selected=3;s.group=0;s.modal='lessons'}
 if(id==='review_free'){s.selected=0;s.group=0;s.modal='lessons'}
 if(['energy_empty','energy_unknown'].includes(id))s.modal='lessons';
 if(id==='energy_unknown')s.energy=null;
 if(['loading','load_error'].includes(id)){s.status=id==='loading'?'loading':'error';s.done=null;s.energy=null;s.capacity=null}
 if(id==='deep_link'){s.selected=8;s.group=2;s.modal='lessons'}
 if(id==='next_chapter')s.modal='chapters';
 if(id==='departure'){s.modal='departure';s.route='lesson'}
 return s;
}
function unlocked(s,i){return s.status==='ready'&&i>=0&&i<C.lessons.length&&(i===0||s.done.includes(C.lessons[i-1].id))}
function done(s,i){return !!s.done?.includes(C.lessons[i]?.id)}
function cost(s,i){return done(s,i)?C.costs.main_quest_review:C.lessons[i].challenge?C.costs.chapter_challenge_first:C.costs.main_quest_lesson_first}
function gate(s,i){if(s.status!=='ready')return 'unknown';if(!unlocked(s,i))return 'locked';if(cost(s,i)===0)return 'ready';if(s.energy===null)return 'energy_unknown';return s.energy<cost(s,i)?'energy_empty':'ready'}
function current(s){if(s.status!=='ready')return null;return C.lessons.findIndex((l,i)=>unlocked(s,i)&&!done(s,i))}
function dispatch(s,e){
 const n=structuredClone(s);
 switch(e.type){
  case 'group':if(s.status!=='ready'||!Number.isInteger(e.group)||e.group<0||e.group>2)return n;n.group=e.group;n.selected=s.selected>=e.group*4&&s.selected<e.group*4+4?s.selected:e.group*4;n.modal='lessons';break;
  case 'select':if(s.status!=='ready'||!Number.isInteger(e.index)||e.index<0||e.index>=12)return n;n.selected=e.index;n.group=Math.floor(e.index/4);n.modal='lessons';break;
  case 'continue':if(current(s)===null)return n;n.selected=current(s)<0?0:current(s);n.group=Math.floor(n.selected/4);n.modal='lessons';break;
  case 'chapters':n.modal='chapters';break;
  case 'enter':if(gate(s,s.selected)!=='ready')return n;n.modal='departure';n.route='lesson';break;
  case 'practice':n.modal='departure';n.route='practice';break;
  case 'village':n.modal='departure';n.route='village';break;
  case 'recap':if(s.done?.length!==12)return n;n.modal='departure';n.route='recap';break;
  case 'close':n.modal=null;n.route=null;break;
  case 'retry':if(s.status!=='error')return n;n.status='loading';break;
  default:return n;
 }
 return n;
}
const api={fixtures,fixture,unlocked,done,cost,gate,current,dispatch};
if(typeof module!=='undefined')module.exports=api;root.ChapterModel=api;
})(globalThis);
