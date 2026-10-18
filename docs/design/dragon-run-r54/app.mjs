import {Study,makeFixture,fixtureNames,starsFor,thresholds,items,cameraGround} from './model.mjs';
import {copy} from './copy.mjs';
const $=s=>document.querySelector(s),params=new URLSearchParams(location.search);
let lang=params.get('lang')==='en'?'en':'vi',scale=[1,1.3,2].includes(+params.get('scale'))?+params.get('scale'):1;
let fixture=fixtureNames.includes(params.get('state'))?params.get('state'):'home';
let study=makeFixture(fixture),frozen=params.get('freeze')==='1',calm=matchMedia('(prefers-reduced-motion: reduce)').matches,last=performance.now(),hitUntil=0,lastTrigger;
const assets={};
for(const [name,path] of Object.entries({bg:'assets/volcano-trail.webp',pip:'assets/pip-token.png',rock:'assets/basalt-token.png',beetle:'assets/beetle-token.png',bush:'../maze-play-r50/assets/hedge-token.png'})){
 const image=new Image();image.src=path;await image.decode();assets[name]=image;
}
const c=()=>copy[lang];
function button(id,label,classes=''){return `<button id="${id}" class="${classes}">${label}</button>`;}
function stat(label,value){return `<div class="stat"><small>${label}</small><strong>${value}</strong></div>`;}
function bind(id,fn){const b=$('#'+id);if(b)b.onclick=fn;}
function modal(title,body,trigger){lastTrigger=trigger||document.activeElement;$('#dialog-title').textContent=title;$('#dialog-body').innerHTML=body;$('#dialog-close').textContent=c().close;$('#dialog').showModal();}
$('#dialog-close').onclick=()=>$('#dialog').close();$('#dialog').addEventListener('close',()=>lastTrigger?.isConnected&&lastTrigger.focus({preventScroll:true}));
function noEnergy(){modal(study.energy===null?c().energyUnknown:c().empty,`<p>${study.energy===null?c().unknownEnergyHelp:c().emptyHelp}</p>`);}
function enter(){if(!study.enter()){if(['pending','unknown'].includes(study.receipt)){study.route='result';render();return;}noEnergy();return;}last=performance.now();render();$('#jump').focus({preventScroll:true});}
function acknowledge(outcome){if(study.resolve(study.attempt,outcome))render();}
function finish(){if(!study.finish())return;render();
 const target=study,id=study.attempt;
 if(!frozen)setTimeout(()=>{if(study===target&&study.resolve(id,'confirmed'))render();},950);
}
function jump(){if(study.route!=='play'||study.game.paused||$('#dialog').open)return;const wasReady=study.game.phase==='ready';study.game.jump();if(wasReady){render();$('#jump')?.focus({preventScroll:true});}else{updateHud();draw();}}
function pause(){if(study.route!=='play'||study.game.phase!=='running')return;study.game.pause();render();$('#resume')?.focus({preventScroll:true});}
function resume(){study.game.resume();last=performance.now();render();$('#jump')?.focus({preventScroll:true});}
function home(){if(study.route==='play'&&study.game.phase==='ready'){study.route='home';render();return;}
 if(study.home())render();}
function showLoadout(){modal(c().loadout,`<p>${c().shopNote}</p>`+items.map(([id,price])=>`<div class="loadout-row"><div><strong>${c()[id]}</strong><small>${study.owned.includes(id)?c().owned:c().notOwned}</small></div><span>${price} ◉</span></div>`).join(''));}
function showRules(){modal(c().rules,`<p>${c().tap}</p><p>${c().formula}</p><p>${c().gemNote}</p><p>${c().cost}</p><p>${c().controlHelp}</p>`);}
function resultTitle(){const g=study.game;if(starsFor(g.score)===0)return c().zero;
 if(study.receipt!=='confirmed')return c().ended;
 if(study.previous===null)return c().first;if(g.score>study.previous)return c().newBest;if(g.score===study.previous)return c().tie;return c().lower;}
function render(){
 document.documentElement.lang=lang;$('.phone').style.setProperty('--s',scale);$('#dialog').style.setProperty('--s',scale);$('.phone').classList.toggle('playing',study.route==='play');$('.phone').classList.toggle('paused',study.route==='play'&&study.game.paused);
 $('#title').textContent=c().title;$('#mode').textContent=c().mode;$('#study-label').textContent=c().sample;
 $('#lang').value=lang;$('#scale').value=String(scale);$('#fixture').value=fixture;$('#freeze').checked=frozen;$('#calm').checked=calm;
 const surface=$('#surface');
 if(study.route==='home'){
  $('#top-action').textContent=c().rules;$('#top-action').onclick=showRules;
  surface.innerHTML=`<div class="scroll"><div class="home-hero"><span class="hero-kicker">${c().mode}</span><img class="pip" src="assets/pip-token.png" alt="Pip"></div><div class="home-copy"><h3>${c().ready}</h3><p>${c().homeLine}</p><div class="stats">${stat(c().best,study.record??c().noRecord)}${stat(c().wallet,study.wallet)}</div><p>${c().energy}: <strong>${study.energy??'—'}</strong> / 20</p>${['pending','unknown'].includes(study.receipt)?`<div class="receipt"><strong>${c()[study.receipt]}</strong>${button('view-receipt',c().check)}</div>`:''}<div class="home-actions">${button('start',c().start+' · 2 ϟ','primary')}${button('loadout',c().loadout)}</div><div class="formula">${c().formula}<br>${c().cost}</div><p class="small">${c().sample}</p></div></div>`;
  bind('start',enter);bind('loadout',showLoadout);bind('view-receipt',()=>{study.route='result';render();});$('#start').disabled=['pending','unknown'].includes(study.receipt);
 }else if(study.route==='play'){
  const g=study.game;$('#top-action').textContent=g.phase==='ready'?c().back:g.paused?c().resume:c().pause;
  $('#top-action').onclick=g.phase==='ready'?home:g.paused?resume:pause;
  surface.innerHTML=`<div class="hud"><div><small>${c().hearts}</small><strong class="heart-value" id="hearts"></strong></div><div><small>${c().score}</small><strong id="score"></strong></div><div><small>${c().coins}</small><strong id="coins"></strong></div></div><div class="stage-wrap"><div class="stage" role="button" tabindex="${g.paused?-1:0}" aria-hidden="${g.paused}" aria-label="${c().tap}"><canvas width="800" height="960" aria-hidden="true"></canvas>${g.phase==='ready'?`<div class="ready-caption"><strong>${c().ready}</strong>${c().tap}</div>`:''}</div>${g.paused?`<section class="paused-cover"><div class="pause-panel"><h3>${c().pause}</h3>${button('resume',c().resume,'secondary')}${button('finish',c().finish)}<p>${c().pauseLine}</p><p class="small">${c().finishHelp}</p></div></section>`:''}</div><footer class="jump-dock"><p class="jump-count" id="jump-count"></p>${button('jump',c().jump,'primary')}</footer>`;
  $('.stage').onpointerdown=e=>{e.preventDefault();jump();};bind('jump',jump);bind('resume',resume);bind('finish',finish);
  $('#jump').disabled=g.paused;resizeStage();updateHud();draw();
 }else{
  const g=study.game,n=starsFor(g.score),state=study.receipt;
  $('#top-action').textContent=c().back;$('#top-action').onclick=home;$('#top-action').disabled=false;
  surface.innerHTML=`<div class="scroll"><section class="result-hero"><img class="pip" src="assets/pip-token.png" alt="Pip"><div class="stars" aria-label="${n}/3">${[1,2,3].map(i=>`<span class="${i>n?'dim':''}" aria-hidden="true">${i>n?'☆':'★'}</span>`).join('')}</div><h3>${resultTitle()}</h3></section><div class="result-body"><div class="big-score"><span>${c().score}</span><strong>${g.score}</strong></div><div class="stats">${stat(c().distance,Math.floor(g.distance/50)+' m')}${stat(c().coins,g.coins)}${stat(c().gems,g.gems)}${stat(c().wallet,study.wallet)}</div><p class="small">${c().gemNote}</p><div class="record"><span>${c().best}</span><strong>${study.record??c().noRecord}</strong></div>${n===0?`<p>${c().noSave}</p>`:''}<ul class="milestones">${thresholds.map((t,i)=>`<li><span>${i+1} ★ · ${t} ${c().target}</span><span aria-label="${g.score>=t?'✓':'—'}">${g.score>=t?'✓':'—'}</span></li>`).join('')}</ul><div class="receipt ${state}"><strong>${c()[state]}</strong><span>${state==='confirmed'?c().savingHint:state==='pending'?c().pendingHelp:c().unknownHelp}</span>${state==='unknown'?button('reconcile',c().check):''}</div><p class="skill">${c().skill}</p><div class="result-actions">${button('replay',c().replay,'primary')}${button('home',c().back)}${button('village',c().village,'quiet')}</div><div class="formula">${c().formula}</div></div></div>`;
  bind('replay',enter);bind('home',home);bind('village',()=>{home();$('#audit').textContent='Navigation sample: main_map (no app route)';});
  for(const id of ['replay','village'])$('#'+id).disabled=state!=='confirmed';
  bind('reconcile',()=>{study.receipt='pending';render();const target=study,id=study.attempt;if(!frozen)setTimeout(()=>{if(study===target&&study.resolve(id,'confirmed'))render();},950);});
 }
 if(study.route!=='result')$('#top-action').disabled=false;
 $('#audit').textContent=`RAM · attempt ${study.attempt} · energy ${study.energy??'?'} · wallet ${study.wallet} · record ${study.record??'none'}`;
}
function resizeStage(){const wrap=$('.stage-wrap'),stage=$('.stage');if(!wrap||!stage)return;const w=wrap.clientWidth,h=wrap.clientHeight;stage.style.width=w+'px';stage.style.height=h+'px';const canvas=$('canvas'),pixels=Math.round(h/w*800);if(canvas&&canvas.height!==pixels)canvas.height=pixels;}
const observer=new ResizeObserver(()=>{resizeStage();draw();});observer.observe($('.phone'));
function updateHud(){if(study.route!=='play')return;const g=study.game;
 $('#hearts').textContent=`${g.hearts}/${g.maxHearts}`;$('#score').textContent=g.score;$('#coins').textContent=g.coins;
 $('#jump-count').textContent=g.invulnerable>0?(performance.now()<hitUntil||fixture==='hit'?c().hit:c().shield):`${c().jumps}: ${g.jumps}/${g.maxJumps}`;
 $('#jump').textContent=g.onGround?c().jump:c().flap;
 if(g.phase==='running')$('.ready-caption')?.remove();
}
function draw(){resizeStage();const canvas=$('canvas');if(!canvas)return;const ctx=canvas.getContext('2d');ctx.setTransform(2,0,0,2,0,0);ctx.clearRect(0,0,400,canvas.height/2);
 const g=study.game,H=canvas.height/2,ground=cameraGround(H,g.y),x=96;
 const imageAspect=assets.bg.width/assets.bg.height,bh=Math.max(H,400/imageAspect),bw=bh*imageAspect,bx=(400-bw)/2,by=ground-bh*.75;
 if(by>0)ctx.drawImage(assets.bg,0,0,assets.bg.width,1,bx,0,bw,by+1);ctx.drawImage(assets.bg,bx,by,bw,bh);
 for(const p of g.pickups){if(p.taken)continue;const cx=x+p.x,cy=ground-p.y;if(cx<-30||cx>430)continue;ctx.save();ctx.translate(cx,cy);
  if(p.gem){ctx.fillStyle='#287f89';ctx.beginPath();ctx.moveTo(0,-12);ctx.lineTo(11,0);ctx.lineTo(0,13);ctx.lineTo(-11,0);ctx.closePath();ctx.fill();ctx.strokeStyle='#a4ece9';ctx.lineWidth=3;ctx.stroke();}
  else{const grad=ctx.createRadialGradient(-3,-4,1,0,0,12);grad.addColorStop(0,'#fff0a6');grad.addColorStop(.55,'#f1bc4c');grad.addColorStop(1,'#ad6c23');ctx.fillStyle=grad;ctx.beginPath();ctx.ellipse(0,0,10,12,0,0,Math.PI*2);ctx.fill();ctx.strokeStyle='#9c621d';ctx.lineWidth=1.5;ctx.stroke();ctx.fillStyle='#b17828';ctx.fillRect(-1,-6,2,12);}ctx.restore();
 }
 for(const o of g.obstacles){const ox=x+o.x,oy=ground-o.lift-o.h;if(ox>430||ox+o.w<-30)continue;
  if(o.kind==='pillar'){ctx.drawImage(assets.rock,ox,oy,36,44);ctx.drawImage(assets.rock,ox,oy+40,36,44);}
  else ctx.drawImage(assets[o.kind==='rock'?'rock':o.kind==='bush'?'bush':'beetle'],ox,oy,o.w,o.h);
 }
 ctx.fillStyle='#234b4933';ctx.beginPath();ctx.ellipse(x,ground+3,24,5,0,0,2*Math.PI);ctx.fill();
 const h=66,w=h*assets.pip.width/assets.pip.height;
 const bob=!calm&&g.phase==='running'&&!g.paused&&g.onGround?Math.sin(g.time*14)*2:0;
 ctx.save();ctx.translate(x,ground-g.y+bob);if(g.invulnerable>0){ctx.strokeStyle='#fff7c8';ctx.lineWidth=3;ctx.beginPath();ctx.ellipse(0,-32,36,39,0,0,2*Math.PI);ctx.stroke();}ctx.drawImage(assets.pip,-w*.5,-h,w,h);ctx.restore();
}
function tick(now){const dt=Math.min(.25,(now-last)/1000);last=now;
 if(!frozen&&study.route==='play'&&!$('#dialog').open){const g=study.game;g.update(dt);if(g.events.includes('hit'))hitUntil=now+1200;g.events=[];if(g.phase==='over'){finish();}else{updateHud();draw();}}
 requestAnimationFrame(tick);
}
window.addEventListener('keydown',e=>{
 if($('#dialog').open||['SELECT','INPUT','TEXTAREA'].includes(e.target.tagName))return;
 if(study.route==='play'&&(e.code==='Space'||e.code==='ArrowUp'||e.code==='Enter'&&e.target.classList.contains('stage'))){e.preventDefault();if(!e.repeat)jump();}
 if(study.route==='play'&&e.code==='Escape'){e.preventDefault();if(!study.game.paused)pause();}
});
document.addEventListener('visibilitychange',()=>{if(document.hidden&&study.route==='play'&&study.game.phase==='running'&&!study.game.paused){pause();$('#audit').textContent=c().hidden;}});
$('#fixture').innerHTML=fixtureNames.map(x=>`<option value="${x}">${x}</option>`).join('');
$('#fixture').onchange=e=>{fixture=e.target.value;study=makeFixture(fixture);hitUntil=0;render();};
$('#lang').onchange=e=>{lang=e.target.value;render();};$('#scale').onchange=e=>{scale=+e.target.value;render();};
$('#freeze').onchange=e=>{frozen=e.target.checked;last=performance.now();};$('#calm').onchange=e=>{calm=e.target.checked;draw();};
$('#sample-hit').onclick=()=>{if(study.route==='play'){study.game.hit();if(study.game.phase==='over')finish();else{updateHud();draw();}}};
$('#receipt-ok').onclick=()=>acknowledge('confirmed');$('#receipt-unknown').onclick=()=>acknowledge('unknown');
window.dragonStudy={get state(){return study;},setFixture(name){fixture=name;study=makeFixture(name);render();},step(dt){study.game.update(dt);if(study.game.phase==='over'&&study.route==='play')finish();else{updateHud();draw();}},acknowledge,draw};
render();window.studyReady=true;requestAnimationFrame(tick);
