// Source-derived rules; JS seeded RNG and 400x600 study camera are NOT Dart parity.
let attemptSerial=0; // Session-local identity, never a durable transaction key.
export const clamp=(x,a,b)=>Math.min(b,Math.max(a,x));
export const thresholds=[60,150,300],cost=2;
export const rating=score=>thresholds.filter(x=>score>=x).length;
export function createGame(seed=55){return {seed,started:false,over:false,paused:false,time:0,height:600,basketX:200,targetX:200,hearts:3,score:0,caught:0,combo:0,bestCombo:0,rainbow:0,hurt:0,spawn:.6,fallers:[],events:[]};}
function random(g){g.seed=(Math.imul(g.seed,1664525)+1013904223)>>>0;return g.seed/4294967296;}
export const multiplier=g=>Math.min(3,1+Math.floor(g.combo/5))*(g.rainbow>0?2:1);
export function moveTo(g,x){if(g.over||g.paused)return;g.targetX=clamp(x,45,355);g.started=true;}
export function nudge(g,dx){moveTo(g,g.targetX+dx);}
export function catchOne(g,kind){
 if(kind==='meteor'){g.hearts--;g.combo=0;g.hurt=1;g.events.push('hit');return;}
 g.caught++;g.combo++;g.bestCombo=Math.max(g.combo,g.bestCombo);
 if(kind==='rainbow'){g.rainbow=6;g.events.push('rainbow');}
 const points=({star:1,golden:5,comet:3,rainbow:2})[kind]*multiplier(g);
 g.score+=points;g.events.push(kind==='star'?'catch':'bonus');
}
export function spawnOne(g,p){
 const r=random(g);let kind=r<.14+.12*p?'meteor':r<.22+.12*p?'comet':r<.28+.12*p?'golden':r<.30+.12*p?'rainbow':'star';
 const speed={star:[150,70],golden:[120,40],comet:[330,80],meteor:[190,90]};
 const vy=kind==='rainbow'?140:speed[kind][0]+random(g)*speed[kind][1];
 g.fallers.push({kind,x:40+random(g)*320,y:-30,vy,sway:kind==='comet'?0:random(g)*2});
}
export function update(g,dt){
 if(g.paused)return;
 let remaining=clamp(dt,0,.25);
 while(remaining>1e-6){const d=Math.min(remaining,1/60);remaining-=d;
  if(!g.started||g.over)continue;
  g.time+=d;g.rainbow=Math.max(0,g.rainbow-d);g.hurt=Math.max(0,g.hurt-2*d);
  g.basketX+=(g.targetX-g.basketX)*Math.min(1,14*d);
  const p=clamp(g.time/45,0,1);g.spawn-=d;
  if(g.spawn<=0){spawnOne(g,p);g.spawn=(.85-.45*p)*(.7+random(g)*.6);}
  for(const f of g.fallers){
   f.y+=f.vy*d*(1+.35*p);f.x+=Math.sin(g.time*2+f.sway)*f.sway*d*20;
   if(!f.done&&Math.abs(f.y-g.height*.84)<26&&Math.abs(f.x-g.basketX)<52){f.done=true;catchOne(g,f.kind);}
   if(!f.done&&f.y>g.height+30){f.done=true;if(f.kind!=='meteor'&&g.combo>0){g.combo=0;g.events.push('miss');}}
  }
  g.fallers=g.fallers.filter(f=>!f.done);
  if(g.time>=45||g.hearts<=0){g.over=true;g.events.push('over');}
 }
}
export function recordOutcome(score,previous){if(rating(score)===0)return 'no_record';return previous==null?'first':score>previous?'better':score===previous?'tie':'lower';}
export const unlocked=(catalog,before,after)=>catalog.filter(c=>before<c.threshold&&after>=c.threshold).map(c=>c.id);
export function createState(){return {route:'home',energy:12,atlas:72,best:null,bestCaught:24,game:null,receipt:null,result:null,attempt:0,selected:'pip',lastEvent:'',eventTime:0};}
export function enter(s){if(s.receipt&&s.receipt!=='confirmed')return 'unresolved';if(s.energy==null)return 'unknown';if(s.energy<cost)return 'empty';s.energy-=cost;s.attempt=++attemptSerial;s.game=createGame(55+s.attempt);s.result=null;s.receipt=null;s.route='play';s.lastEvent='';return 'ok';}
export function finish(s,catalog){if(s.result)return false;const g=s.game;if(!g?.over)return false;s.result={score:g.score,caught:g.caught,combo:g.bestCombo,stars:rating(g.score),before:s.atlas,after:s.atlas+g.caught,previous:s.best,outcome:recordOutcome(g.score,s.best),newIds:unlocked(catalog,s.atlas,s.atlas+g.caught),attempt:s.attempt};s.receipt='pending';s.route='result';return true;}
// Proposed acknowledgement UI in RAM, NOT a transaction/exactly-once persistence layer.
export function acknowledge(s,attempt,status){if(!s.result||s.result.attempt!==attempt||s.receipt==='confirmed')return false;if(!['confirmed','unknown'].includes(status))return false;s.receipt=status;if(status==='confirmed'){s.atlas=s.result.after;s.bestCaught=Math.max(s.bestCaught,s.result.caught);if(s.result.stars>0)s.best=Math.max(s.best??0,s.result.score);}return true;}
export const fixtures=['home','ready','running','combo','rainbow','hit','miss','paused','zero_star','first','two_star','better','tie','lower','saving','save_unknown','atlas','atlas_all','energy_empty','energy_unknown'];
export function fixture(name,catalog){const s=createState();if(name==='energy_empty')s.energy=1;if(name==='energy_unknown')s.energy=null;
 if(name==='atlas'||name==='atlas_all'){s.route='atlas';if(name==='atlas_all'){s.atlas=1200;s.selected='snail';}return s;}
 if(['home','energy_empty','energy_unknown'].includes(name))return s;
 enter(s);const g=s.game;
 if(name==='ready')return s;
 g.started=true;g.time=14;g.spawn=.6;
 for(let i=0;i<8;i++)catchOne(g,'star');
 g.fallers=[{kind:'star',x:95,y:110,vy:180,sway:.3},{kind:'golden',x:210,y:260,vy:135,sway:.7},{kind:'meteor',x:320,y:370,vy:210,sway:.4},{kind:'comet',x:130,y:340,vy:350,sway:0},{kind:'rainbow',x:290,y:70,vy:140,sway:.2}];g.events=[];
 if(name==='combo')catchOne(g,'golden');
 if(name==='rainbow')catchOne(g,'rainbow');
 if(name==='hit'){catchOne(g,'meteor');s.lastEvent='hit';}
 if(name==='miss'){g.combo=0;s.lastEvent='miss';}
 if(name==='paused')g.paused=true;
 if(['running','combo','rainbow','hit','miss','paused'].includes(name))return s;
 if(name!=='zero_star'){
  g.score=0;g.caught=0;g.combo=0;g.bestCombo=0;
  const n=['better','saving','save_unknown'].includes(name)?25:name==='two_star'?15:8;
  for(let i=0;i<n;i++)catchOne(g,'golden');
  if(['better','saving','save_unknown'].includes(name)){s.best=150;s.atlas=395;}
  if(name==='tie')s.best=60;
  if(name==='lower')s.best=150;
 }
 g.time=45;g.over=true;finish(s,catalog);
 if(name==='save_unknown')acknowledge(s,s.attempt,'unknown');else if(name!=='saving')acknowledge(s,s.attempt,'confirmed');return s;
}
