// DESIGN-only state machine. No services, persistence or awards.
let serial=0;
export const ids=['main_quest','robot_maze','dragon_jump','catch_stars','bug_hunter','achievement_house'];
export const fixtures=['welcome_1','welcome_2','welcome_3','intro_loading','intro_error','intro_saving','intro_unknown','returning','tower','maze','dragon','stars','bitsy_locked','bitsy_ready','house','sheet_loading','sheet_error','legacy_vi','energy_zero','locked_missing','route_preview'];
export function facts(c){return {lessons:['mq1_01','mq1_02'],mazeDone:3,mazeStars:7,creations:2,dragonBest:340,dragonStars:2,coins:86,runs:5,starsBest:150,starsRating:2,caught:162,bugsDone:2,bugsFixed:3,bugStars:5,badges:4,unseen:1};}
export function statusFor(id,f,c){
 const common={phase:'ready',locked:false,unlockLessonId:null,stars:null,metrics:[],legacy:null};
 if(!ids.includes(id))return null;
 if(id==='main_quest'){const done=c.lessons.filter(x=>f.lessons.includes(x.id));return {...common,metrics:[['lessons',done.length,c.totals.lessons]],next:c.lessons.find(x=>!f.lessons.includes(x.id))?.id??null};}
 if(id==='robot_maze')return {...common,stars:f.mazeStars,metrics:[['levels',f.mazeDone,c.totals.maze],['stars',f.mazeStars,c.totals.maze*3],...(f.creations?[['creations',f.creations]]:[])]};
 if(id==='dragon_jump')return {...common,stars:f.dragonStars,record:f.dragonBest,unplayed:f.runs===0,metrics:[['coins',f.coins],['runs',f.runs]]};
 if(id==='catch_stars')return {...common,stars:f.starsRating,record:f.starsBest,metrics:[['caught',f.caught],['constellations',c.constellations.filter(x=>f.caught>=x.threshold).length,c.constellations.length]]};
 if(id==='bug_hunter'){if(!f.lessons.includes(c.unlockLessonId))return {...common,locked:true,unlockLessonId:c.unlockLessonId};return {...common,stars:f.bugStars,metrics:[['puzzles',f.bugsDone,c.totals.puzzles],['bugs',f.bugsFixed,c.totals.bugs]]};}
 return {...common,metrics:[['badges',f.badges,c.totals.badges],...(f.unseen?[['unseen',f.unseen]]:[]),['secret',c.totals.secretBadges]]};
}
export function createState(c){const f=facts(c);return {session:++serial,revision:0,introSeen:false,introPhase:'ready',introPage:0,introToken:null,sessionOnly:false,energy:12,view:'village',modal:null,selected:null,status:null,statusToken:null,route:null,events:[],facts:f};}
export function welcome(s){s.modal='welcome';s.introPage=0;s.introPhase='ready';s.introToken=null;}
export function introNext(s){if(s.modal!=='welcome'||s.introPhase!=='ready')return false;if(s.introPage<2){s.introPage++;return true;}s.introPhase='saving';s.introToken=`${s.session}:intro:${++s.revision}`;return true;}
export function introBack(s){if(s.modal==='welcome'&&s.introPhase==='ready'&&s.introPage>0){s.introPage--;return true;}return false;}
export function introAck(s,token,outcome){if(s.modal!=='welcome'||s.introToken!==token||!['saving','unknown'].includes(s.introPhase))return false;if(outcome==='confirmed'){s.introSeen=true;s.sessionOnly=false;s.introPhase='confirmed';s.modal=null;s.introToken=null;return true;}if(outcome==='unknown'){s.introPhase='unknown';return true;}return false;}
export function introRead(s){s.modal='welcome';s.introPhase='loading';s.introToken=`${s.session}:read:${++s.revision}`;return s.introToken;}
export function introReadAck(s,token,seen){if(s.modal!=='welcome'||s.introPhase!=='loading'||token!==s.introToken)return false;if(seen===null){s.introPhase='error';return true;}s.introSeen=seen;s.introPhase=seen?'confirmed':'ready';s.introPage=0;s.introToken=null;if(seen){s.modal=null;s.sessionOnly=false;}return true;}
export function exploreSession(s){if(s.modal!=='welcome'||!['saving','unknown','error'].includes(s.introPhase))return false;s.sessionOnly=true;s.modal=null;s.introToken=null;return true;}
export function openSheet(s,id,c,{phase='ready',status=null}={}){if(s.modal||s.route||!ids.includes(id))return false;s.selected=id;s.modal='sheet';s.status=status??statusFor(id,s.facts,c);s.status={...s.status,phase};s.statusToken=`${s.session}:status:${++s.revision}`;return true;}
export function retryStatus(s){if(s.modal!=='sheet'||!['error','loading'].includes(s.status.phase))return null;s.status.phase='loading';s.statusToken=`${s.session}:status:${++s.revision}`;return s.statusToken;}
export function resolveStatus(s,token,id,status){if(s.modal!=='sheet'||s.statusToken!==token||s.selected!==id||!status)return false;s.status=structuredClone(status);return true;}
export function dismiss(s){if(s.modal!=='sheet')return false;s.modal=null;s.statusToken=null;s.status=null;return true;}
export function destination(s){if(s.modal!=='sheet'||s.status?.phase!=='ready')return null;if(s.status.locked)return s.status.unlockLessonId?{activity:'main_quest',highlightLesson:s.status.unlockLessonId,action:`lesson:${s.status.unlockLessonId}`} :null;return {activity:s.selected,highlightLesson:null,action:'open'};}
export function activate(s){const dest=destination(s);if(!dest)return false;s.route=dest;s.modal='route';s.statusToken=null;s.events.push({type:'activityOpened',sourceId:'main_map',activity:dest.activity,simulation:true});return true;}
export function returnRoute(s){if(s.modal!=='route')return false;s.route=null;s.modal=null;s.status=null;return true;}
export function fixture(key,c){const s=createState(c);s.introSeen=true;
 if(key.startsWith('welcome_')){s.introSeen=false;welcome(s);s.introPage=Number(key.slice(-1))-1;return s;}
 if(key.startsWith('intro_')){s.introSeen=false;welcome(s);if(key==='intro_loading'||key==='intro_error'){introRead(s);if(key==='intro_error')introReadAck(s,s.introToken,null);}else{s.introPage=2;introNext(s);if(key==='intro_unknown')introAck(s,s.introToken,'unknown');}return s;}
 const map={tower:'main_quest',maze:'robot_maze',dragon:'dragon_jump',stars:'catch_stars',bitsy_locked:'bug_hunter',bitsy_ready:'bug_hunter',house:'achievement_house',sheet_loading:'robot_maze',sheet_error:'robot_maze',legacy_vi:'robot_maze',energy_zero:'dragon_jump',locked_missing:'bug_hunter',route_preview:'bug_hunter'};
 if(key==='bitsy_ready')s.facts.lessons.push(c.unlockLessonId);if(key==='energy_zero')s.energy=0;
 if(map[key])openSheet(s,map[key],c,{phase:key==='sheet_loading'?'loading':key==='sheet_error'?'error':'ready'});
 if(key==='locked_missing')s.status.unlockLessonId=null;
 if(key==='legacy_vi'){s.status.legacy={progressLabel:'3/10 màn',detailLines:['Sao: 7/30','Mê cung tự tạo: 2'],language:'vi'};s.status.metrics=[];}
 if(key==='route_preview')activate(s);return s;
}
