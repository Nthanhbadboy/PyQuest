/* DESIGN-only fixture reducer. Nothing reads/writes app progress or storage. */
(function(g){'use strict';
const C=typeof module!=='undefined'?require('./catalog.js'):g.DailyCatalog;
const fixtures=['daily_ready','daily_progress','daily_claimable','daily_claim_pending','daily_claim_error','daily_claimed','daily_loading','daily_error','daily_new_day','energy_partial','energy_empty','energy_full','energy_loading','energy_error','break_active','break_done'];let serial=0;
function create(id='daily_ready'){
 if(!fixtures.includes(id))throw Error('Unknown fixture');
 const s={fixture:id,view:id.startsWith('energy')?'energy':id.startsWith('break')?'break':'daily',day:'2026-10-18',dailyStatus:'ready',energyStatus:'ready',quests:['code_runs_3','arcade_star','robot_code'].map(id=>({id,progress:0,rewarded:false})),stamps:2,energy:11,max:20,next:405,claim:null,selected:null,remaining:20};
 if(id==='daily_progress')s.quests[0].progress=2;
 if(['daily_claimable','daily_claim_pending','daily_claim_error','daily_claimed'].includes(id))s.quests[0].progress=3;
 if(id==='daily_claim_pending')s.claim={id:s.quests[0].id,day:s.day,token:++serial,status:'pending'};
 if(id==='daily_claim_error')s.claim={id:s.quests[0].id,day:s.day,token:null,status:'error'};
 if(id==='daily_claimed'){s.quests[0].rewarded=true;s.stamps=3}
 if(id==='daily_new_day')s.day='2026-10-19';
 if(id==='daily_loading')s.dailyStatus='loading';if(id==='daily_error')s.dailyStatus='error';
 if(id==='energy_loading')s.energyStatus='loading';if(id==='energy_error')s.energyStatus='error';
 if(id==='energy_empty')s.energy=0;if(id==='energy_full'){s.energy=20;s.next=null}
 if(id==='break_done')s.remaining=0;return s;
}
function def(id){return C.quests.find(q=>q.id===id)}
function step(old,e){const s=structuredClone(old);
 switch(e.type){
 case 'view':if(!['daily','energy'].includes(e.view))return old;s.view=e.view;s.selected=null;return s;
 case 'open':if(s.dailyStatus!=='ready'||!s.quests.some(q=>q.id===e.id))return old;s.selected=e.id;return s;
 case 'back':if(s.selected)s.selected=null;else s.view='daily';return s;
 case 'claim':{const q=s.quests.find(q=>q.id===e.id);if(s.dailyStatus!=='ready'||s.claim?.status==='pending'||!q||q.rewarded||q.progress<def(q.id).target)return old;s.claim={id:q.id,day:s.day,token:++serial,status:'pending'};return s;}
 case 'reply':{const r=s.claim;if(!r||r.status!=='pending'||e.token!==r.token||e.day!==r.day||s.day!==r.day)return old;const q=s.quests.find(q=>q.id===r.id);if(!e.ok){r.status='error';r.token=null;return s;}if(!q||q.rewarded)return old;q.rewarded=true;s.stamps++;s.claim=null;return s;}
 case 'rollover':if(s.day==='2026-10-19')return old;s.day='2026-10-19';s.quests=s.quests.map(q=>({...q,progress:0,rewarded:false}));s.claim=null;s.selected=null;s.dailyStatus='ready';return s;
 case 'retry':if(s.view==='daily'&&s.dailyStatus==='error')s.dailyStatus='loading';else if(s.view==='energy'&&s.energyStatus==='error')s.energyStatus='loading';else return old;return s;
 case 'loaded':if(s.view==='daily'&&s.dailyStatus==='loading')s.dailyStatus=e.ok?'ready':'error';else if(s.view==='energy'&&s.energyStatus==='loading')s.energyStatus=e.ok?'ready':'error';else return old;return s;
 case 'rest':s.view='break';s.remaining=20;s.selected=null;return s;
 case 'tick':if(s.view!=='break'||s.remaining===0)return old;s.remaining=Math.max(0,s.remaining-1);return s;
 case 'endRest':if(s.view!=='break')return old;s.view='energy';return s;
 default:return old;
 }
}
const api={fixtures,create,step,def};if(typeof module!=='undefined')module.exports=api;g.DailyModel=api;
})(typeof window!=='undefined'?window:globalThis);
