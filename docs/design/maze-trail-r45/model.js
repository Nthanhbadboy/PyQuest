'use strict';
(function(root){
const C=typeof module!=='undefined'?require('./catalog.js'):root.MazeCatalog;
const fixtures=['new','returning','loop_ready','replay','perfect','locked','energy_empty','energy_unknown','loading','load_error','deep_link','unknown_link','all_partial','detail','one_star_unlock'];
function fixture(id='returning'){
 if(!fixtures.includes(id))throw Error('Unknown fixture');
 const count={new:0,loop_ready:5,perfect:10,all_partial:10,one_star_unlock:3}[id]??2;
 const records=Object.fromEntries(C.levels.slice(0,count).map((l,i)=>[l.id,{stars:id==='perfect'?3:2}]));
 const s={fixture:id,records,energy:id==='new'?20:11,status:'ready',selected:Math.min(count,9),page:Math.floor(Math.min(count,9)/5),modal:null,route:null};
 if(id==='replay'){s.selected=0;s.page=0;s.energy=0;s.modal='detail'}
 if(id==='locked'){s.selected=7;s.page=1;s.modal='detail'}
 if(id==='energy_empty'){s.energy=0;s.modal='detail'}
 if(id==='energy_unknown'){s.energy=null;s.modal='detail'}
 if(id==='deep_link'){s.selected=8;s.page=1;s.modal='detail'}
 if(id==='unknown_link'){s.selected=null;s.modal='not_found'}
 if(id==='detail')s.modal='detail';
 if(id==='one_star_unlock')s.records.rm_03.stars=1;
 if(id==='perfect'||id==='all_partial')s.energy=0;
 if(id==='loading'||id==='load_error'){s.status=id==='loading'?'loading':'error';s.records=null;s.energy=null}
 return s;
}
function done(s,i){return !!s.records&&Object.hasOwn(s.records,C.levels[i]?.id)}
function unlocked(s,i){return s.status==='ready'&&Number.isInteger(i)&&i>=0&&i<10&&(i===0||done(s,i-1))}
function cost(s,i){return done(s,i)?C.costs.replay:C.costs.new}
function gate(s,i){if(!Number.isInteger(i)||!C.levels[i])return 'not_found';if(s.status!=='ready')return 'unknown';if(!unlocked(s,i))return 'locked';if(cost(s,i)===0)return 'ready';if(s.energy===null)return 'energy_unknown';return s.energy<cost(s,i)?'energy_empty':'ready'}
function current(s){return s.records===null?null:C.levels.findIndex((_,i)=>unlocked(s,i)&&!done(s,i))}
function totalStars(s){return s.records===null?null:Object.values(s.records).reduce((n,r)=>n+r.stars,0)}
function dispatch(s,e){const n=structuredClone(s);switch(e.type){
 case 'page':if(![0,1].includes(e.page))return n;n.page=e.page;break;
 case 'select':if(!Number.isInteger(e.index)||!C.levels[e.index]){n.modal='not_found';n.selected=null;break}if(s.status!=='ready')return n;n.selected=e.index;n.page=Math.floor(e.index/5);n.modal='detail';break;
 case 'deep_link':{const i=C.levels.findIndex(l=>l.id===e.id);return dispatch(s,{type:'select',index:i})}
 case 'continue':{const i=current(s);if(i===null)return n;return dispatch(s,{type:'select',index:i<0?0:i})}
 case 'enter':if(gate(s,s.selected)!=='ready')return n;n.modal='departure';n.route='level';break;
 case 'workshop':case 'village':n.modal='departure';n.route=e.type;break;
 case 'rules':n.modal='rules';break;
 case 'journal':n.modal='journal';break;
 case 'close':n.modal=null;n.route=null;break;
 case 'retry':if(s.status!=='error')return n;n.status='loading';break;
 default:return n;
}return n}
const api={fixtures,fixture,done,unlocked,cost,gate,current,totalStars,dispatch};if(typeof module!=='undefined')module.exports=api;root.MazeModel=api;
})(globalThis);
