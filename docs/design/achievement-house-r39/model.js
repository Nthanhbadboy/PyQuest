/* Read-only DESIGN simulator: no achievement checks, unlocks, claims or persistence. */
(function(g){'use strict';
const catalog=typeof module!=='undefined'?require('./catalog.js'):g.BadgeCatalog;
const fixtures=['room_populated','cabinet_all','earned_filter','locked_filter','secret_filter','earned_detail','locked_detail','secret_locked','secret_earned','empty_room','loading','load_error','progress_unknown','search_empty'];
function create(id='room_populated'){
 if(!fixtures.includes(id))throw Error('Unknown fixture');
 const s={fixture:id,view:id==='room_populated'||id==='empty_room'?'room':'cabinet',filter:'all',query:'',selected:null,earned:['first_steps','first_line'],progress:{maze_explorer:4},status:'ready',generation:0,request:null,listScroll:0};
 if(id==='earned_filter')s.filter='earned';if(id==='locked_filter')s.filter='locked';if(id==='secret_filter')s.filter='secret';
 if(id==='earned_detail')s.selected='first_line';if(id==='locked_detail'||id==='progress_unknown')s.selected='maze_explorer';
 if(id==='secret_locked')s.selected='mystery_2';if(id==='secret_earned'){s.earned.push('mystery_2');s.selected='mystery_2';}
 if(id==='empty_room')s.earned=[];if(id==='progress_unknown')s.progress={};if(id==='search_empty')s.query='zzzz';
 if(id==='loading'){s.status='loading';s.request=++s.generation;}if(id==='load_error')s.status='error';return s;
}
function badge(s,key,lang='vi'){
 const source=catalog.badges.find(b=>b.key===key);if(!source)return null;
 const earned=s.earned.includes(key);const secret=source.secret;
 if(secret&&(!earned||key!==catalog.earnedSecretFixture.key))return {key,secret:true,earned,title:lang==='vi'?'Huy hiệu bí mật':'Secret badge',description:lang==='vi'?'Một điều bất ngờ đang chờ bạn khám phá.':'A surprise is waiting to be discovered.',howTo:null,icon:'?',goal:null,progress:null};
 const b=secret?catalog.earnedSecretFixture:source;
 const progress=key==='maze_explorer'&&typeof s.progress[key]==='number'?Math.max(0,Math.min(b.goal,s.progress[key])):null;
 return {key,secret,earned,title:b.title[lang],description:b.description[lang],howTo:earned?null:b.howTo?.[lang]||null,icon:b.icon,goal:key==='maze_explorer'?b.goal:null,progress};
}
function list(s,lang='vi'){
 if(s.status!=='ready')return [];
 return catalog.badges.map(b=>badge(s,b.key,lang)).filter(b=>(s.filter==='all'||s.filter==='earned'&&b.earned||s.filter==='locked'&&!b.earned&&!b.secret||s.filter==='secret'&&b.secret)&&b.title.toLocaleLowerCase(lang).includes(s.query.toLocaleLowerCase(lang).trim()));
}
function step(old,e){const s={...old,earned:[...old.earned],progress:{...old.progress}};
 if(e.type==='retry'&&s.status==='error'){s.status='loading';s.request=++s.generation;return s;}
 if(e.type==='resolve'){if(s.status!=='loading'||e.token!==s.request)return old;s.status=e.ok?'ready':'error';s.request=null;return s;}
 if(e.type==='back'){if(s.status==='loading'){s.generation++;s.request=null;s.status='error';return s;}if(s.selected){s.selected=null;return s;}s.view='room';return s;}
 if(s.status!=='ready')return old;
 switch(e.type){
 case 'view':if(!['room','cabinet'].includes(e.view))return old;s.view=e.view;s.selected=null;break;
 case 'filter':if(!['all','earned','locked','secret'].includes(e.filter))return old;s.filter=e.filter;s.selected=null;break;
 case 'search':s.query=String(e.query).slice(0,100);s.selected=null;break;
 case 'open':if(!catalog.badges.some(b=>b.key===e.key))return old;s.selected=e.key;s.listScroll=e.scroll||0;break;
 default:return old;
 }return s;
}
const api={fixtures,create,badge,list,step};if(typeof module!=='undefined')module.exports=api;g.HouseModel=api;
})(typeof window!=='undefined'?window:globalThis);
