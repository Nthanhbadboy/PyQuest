// Source-derived DESIGN analogue. Not Dart engine parity or durable storage.
export const thresholds=[150,300,500];
export const items=[['heart',120],['magnet',150],['wings',200],['party',60],['scarf',80],['goggles',100],['wizard',150],['crown',250]];
export const dimensions={rock:[48,44],bush:[74,38],pillar:[36,84],beetle:[46,32]};
export const starsFor=score=>thresholds.filter(t=>score>=t).length;
export const scoreFor=(distance,coins)=>Math.floor(distance/50)+coins*3;
export function recordAfter(previous,score){return starsFor(score)>0?Math.max(previous??0,score):previous;}
export function cameraGround(height,y){return height*.8+Math.max(0,y+80-height*.8);}
export class Dragon {
 constructor({owned=[],seed=54}={}){
  this.maxHearts=owned.includes('heart')?4:3;this.hearts=this.maxHearts;
  this.maxJumps=owned.includes('wings')?3:2;this.magnet=owned.includes('magnet');
  this.phase='ready';this.paused=false;this.distance=0;this.speed=0;this.y=0;this.vy=0;this.jumps=0;
  this.coins=0;this.gems=0;this.invulnerable=0;this.time=0;this.next=380;this.obstacles=[];this.pickups=[];this.events=[];this.seed=seed>>>0;
 }
 random(){this.seed=(Math.imul(this.seed,1664525)+1013904223)>>>0;return this.seed/4294967296;}
 get onGround(){return this.y<=.001&&this.vy<=0;}
 get score(){return scoreFor(this.distance,this.coins);}
 jump(){
  if(this.paused||this.phase==='over')return false;
  if(this.phase==='ready'){this.phase='running';this.speed=250;}
  if(this.onGround)this.jumps=0;
  if(this.jumps>=this.maxJumps)return false;
  this.vy=this.jumps===0?900:800;this.jumps++;this.events.push(this.jumps===1?'jump':'flap');return true;
 }
 pause(){if(this.phase==='running')this.paused=true;}
 resume(){this.paused=false;}
 finish(){if(this.phase==='running'){this.hearts=0;this.phase='over';this.paused=false;return true;}return false;}
 hit(){if(this.invulnerable>0||this.phase!=='running'||this.paused)return false;
  this.hearts--;this.events.push('hit');if(this.hearts<=0){this.phase='over';this.events.push('over');}else{this.invulnerable=1.5;this.vy=Math.max(this.vy,450);}return true;
 }
 obstacle(kind,x,lift=0){const [w,h]=dimensions[kind];this.obstacles.push({kind,x,lift,w,h});}
 line(x,n,height){for(let i=0;i<n;i++)this.pickups.push({x:x+i*34,y:22+height,gem:false});}
 arc(x,n,peak){for(let i=0;i<n;i++)this.pickups.push({x:x+i*30,y:40+Math.sin((n===1?.5:i/(n-1))*Math.PI)*(peak-40),gem:false});}
 spawn(){
  const difficulty=Math.max(0,Math.min(1,(this.speed-250)/(540-250))),roll=this.random(),x=460;
  if(roll<.28){this.obstacle('rock',x);this.arc(x-30,7,150);}
  else if(roll<.46){this.obstacle('bush',x);this.line(x+110,4,0);}
  else if(roll<.6&&difficulty>.15){this.obstacle('pillar',x);this.arc(x-40,5,230);}
  else if(roll<.76){this.obstacle('beetle',x,70+this.random()*30);this.line(x-30,4,18);}
  else if(roll<.88&&difficulty>.3){this.obstacle('rock',x);this.obstacle('rock',x+210+60*(1-difficulty));}
  else{this.arc(x,8,120);if(this.random()<.25)this.pickups.push({x:x+120,y:210,gem:true});}
  this.next=(330+this.random()*220-difficulty*120)*Math.min(1.6,Math.max(1,this.speed/250));
 }
 update(dt){if(this.paused||this.phase!=='running'||!Number.isFinite(dt))return;
  let remaining=Math.max(0,Math.min(.25,dt));while(remaining>1e-6&&this.phase==='running'){const step=Math.min(remaining,1/60);this.step(step);remaining-=step;}
 }
 step(dt){
  this.time+=dt;this.speed=Math.min(540,this.speed+5*dt);const dx=this.speed*dt;this.distance+=dx;this.invulnerable=Math.max(0,this.invulnerable-dt);
  this.vy-=2700*dt;this.y+=this.vy*dt;if(this.y<=0){this.y=0;this.vy=0;this.jumps=0;}
  this.obstacles.forEach(o=>o.x-=dx);this.pickups.forEach(p=>p.x-=dx);
  this.obstacles=this.obstacles.filter(o=>o.x+o.w>=-140);this.pickups=this.pickups.filter(p=>p.x>=-140&&!p.taken);
  this.next-=dx;if(this.next<=0)this.spawn();this.collide(dt);
 }
 collide(dt){
  for(const p of this.pickups){
   if(p.taken)continue;
   const py=this.y+30;let d=Math.hypot(p.x,p.y-py);
   if(this.magnet&&d<130&&d>1&&p.x>-20){const step=Math.min(d,420*dt);p.x-=p.x/d*step;p.y+=(py-p.y)/d*step;}
   if(Math.hypot(p.x,p.y-py)<34){p.taken=true;if(p.gem){this.gems++;this.coins+=5;this.events.push('gem');}else{this.coins++;this.events.push('coin');}}
  }
  if(this.invulnerable>0)return;
  for(const o of this.obstacles){const overlapX=o.x+o.w*.88>-20&&o.x+o.w*.12<20;
   const overlapY=o.lift+o.h*.86>this.y+8&&o.lift+o.h*.04<this.y+52;
   if(overlapX&&overlapY){this.hit();return;}
  }
 }
}
export class Study {
 constructor({energy=12,wallet=80,record=300,owned=[]}={}){this.energy=energy;this.wallet=wallet;this.record=record;this.owned=owned;this.runs=0;this.attempt=0;this.route='home';this.receipt='none';this.game=new Dragon({owned});this.applied=new Set();}
 enter(){if(!['home','result'].includes(this.route)||['pending','unknown'].includes(this.receipt))return false;
  if(this.energy===null||this.energy<2)return false;
  this.energy-=2;this.attempt++;this.route='play';this.receipt='none';this.game=new Dragon({owned:this.owned});return true;
 }
 finish(){if(this.route!=='play')return false;this.game.finish();this.game.phase='over';this.route='result';this.receipt='pending';this.previous=this.record;return true;}
 resolve(id,outcome){if(id!==this.attempt||this.game.phase!=='over'||!['home','result'].includes(this.route)||this.applied.has(id))return false;
  if(outcome==='unknown'){this.receipt='unknown';return true;}
  if(outcome!=='confirmed')return false;
  this.applied.add(id);this.wallet+=this.game.coins;this.runs++;this.record=recordAfter(this.record,this.game.score);this.receipt='confirmed';return true;
 }
 home(){if(this.route==='play'&&this.game.phase!=='ready')return false;this.route='home';return true;}
}
export const fixtureNames=['home','ready','running','jump','hit','paused','upgraded','zero_star','first','best','tie','lower','saving','save_error','energy_empty','energy_unknown'];
export function makeFixture(name){
 const s=new Study({record:['first','zero_star'].includes(name)?null:300,energy:name==='energy_empty'?0:name==='energy_unknown'?null:12,owned:name==='upgraded'?['heart','wings','magnet']:[]});
 if(['home','energy_empty','energy_unknown'].includes(name))return s;
 s.enter();if(name==='ready')return s;
 const g=s.game;g.phase='running';g.speed=320;g.distance=4200;g.coins=7;
 g.obstacle('rock',170);g.obstacle('beetle',315,85);g.arc(110,6,130);
 if(name==='upgraded')return s;
 if(name==='jump'){g.y=110;g.vy=100;g.jumps=1;return s;}
 if(name==='hit'){g.hit();return s;}
 if(name==='paused'){g.pause();return s;}
 if(name==='running')return s;
 const results={zero_star:[41,4,0],first:[123,11,1],best:[350,60,4],tie:[240,20,2],lower:[123,11,1],saving:[123,11,1],save_error:[123,11,1]};
 const [m,c,gems]=results[name];g.distance=m*50;g.coins=c;g.gems=gems;s.finish();
 if(name==='saving')return s;
 s.resolve(s.attempt,name==='save_error'?'unknown':'confirmed');return s;
}
