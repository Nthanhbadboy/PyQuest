import * as M from './model.mjs';
import {copy,labels} from './copy.mjs';
const catalog=await (await fetch('catalog.json')).json();
const $=id=>document.getElementById(id),params=new URLSearchParams(location.search);
let lang=['vi','en'].includes(params.get('lang'))?params.get('lang'):(navigator.language.startsWith('vi')?'vi':'en');
let scale=[1,1.3,2].includes(+params.get('scale'))?+params.get('scale'):1;
let scenario=M.fixtures.includes(params.get('state'))?params.get('state'):'welcome_1';
let state=M.fixture(scenario,catalog),toolsOpen=false,hostOffset=0,returnFocus=state.selected?'place-'+state.selected:'place-main_quest';
const portraits={robo:'../maze-play-r50/assets/robo-token.png',pip:'../dragon-run-r54/assets/pip-token.png',py:'assets/py-token.png',bitsy:'assets/bitsy-token.png'};
const hosts={vi:{robo:'Robo',pip:'Pip',py:'Thầy Py',bitsy:'Bitsy'},en:{robo:'Robo',pip:'Pip',py:'Teacher Py',bitsy:'Bitsy'}};
await Promise.all([...Object.values(portraits),'assets/arrival.webp',...catalog.activities.map(a=>a.study_scene)].map(src=>new Promise((resolve,reject)=>{const image=new Image();image.onload=resolve;image.onerror=()=>reject(new Error(src));image.src=src;})));
const t=k=>copy[lang][k],activity=id=>catalog.activities.find(a=>a.id===id),lesson=id=>catalog.lessons.find(l=>l.id===id);
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const button=(id,text,cls='quiet',disabled=false)=>`<button id="${id}" class="${cls}" ${disabled?'disabled':''}>${text}</button>`;
function controls(prefix){return `<label>${t('language')}<select id="${prefix}-lang"><option value="vi">Tiếng Việt</option><option value="en">English</option></select></label><label>${t('scale')}<select id="${prefix}-scale"><option value="1">100%</option><option value="1.3">130%</option><option value="2">200%</option></select></label><label>${t('fixture')}<select id="${prefix}-fixture">${M.fixtures.map((s,i)=>`<option value="${s}">${labels[lang][i]}</option>`).join('')}</select></label>`;}
function simulation(prefix){return `<div class="simulation">${button(prefix+'-ack',t('confirmed'))}${button(prefix+'-unknown',t('unknown'))}${button(prefix+'-loaded',t('loaded'))}${button(prefix+'-error',t('error'))}</div>`;}
function bindControls(prefix){
 if(!$(prefix+'-lang'))return;
 $(prefix+'-lang').value=lang;$(prefix+'-scale').value=scale;$(prefix+'-fixture').value=scenario;
 $(prefix+'-lang').onchange=e=>{lang=e.target.value;render({preserve:true});$(prefix+'-lang')?.focus({preventScroll:true});};
 $(prefix+'-scale').onchange=e=>{scale=+e.target.value;render({preserve:true});$(prefix+'-scale')?.focus({preventScroll:true});};
 $(prefix+'-fixture').onchange=e=>setFixture(e.target.value);
 for(const key of ['ack','unknown','loaded','error'])if($(prefix+'-'+key))$(prefix+'-'+key).onclick=()=>simulate(key);
 const intro=state.modal==='welcome',sheet=state.modal==='sheet';
 if($(prefix+'-ack')){
 $(prefix+'-ack').disabled=!intro||!['saving','unknown','loading'].includes(state.introPhase);
 $(prefix+'-unknown').disabled=!intro||!['saving','unknown'].includes(state.introPhase);
 $(prefix+'-loaded').disabled=!(intro&&state.introPhase==='loading')&&!(sheet&&state.status.phase==='loading');
 $(prefix+'-error').disabled=!(intro&&state.introPhase==='loading')&&!(sheet&&state.status.phase==='loading');}
}
function bench(){
 for(const [id,key]of Object.entries({edition:'edition',headline:'benchTitle',intro:'benchBody',boundary:'boundary'}))$(id).textContent=t(key);
 $('desk-controls').innerHTML=controls('d');$('simulation').innerHTML=simulation('d');$('audit').textContent=`${t('source')} · ${state.events.length} RAM activityOpened`;
 bindControls('d');
}
function hostHTML(){return `<header class="host-header"><div><h2>PyQuest</h2><span>${t('island')}</span></div>${button('host-tools','☷')}</header><div class="study-label">${t('study')}</div><div id="host-scroll" class="host-scroll">${toolsOpen&&!state.modal?`<div class="review-panel">${controls('p')}${simulation('p')}</div>`:''}<div class="village-hero"><img src="${portraits.robo}" alt="Robo"><p>${t('choose')}</p></div><div class="host-body">${state.sessionOnly?`<p class="note">${t('sessionNote')}</p>`:''}<h3>${t('places')}</h3><div class="place-list">${catalog.activities.map(a=>`<button id="place-${a.id}" data-place="${a.id}"><img src="${a.study_scene}" alt=""><span><strong>${a.name[lang]}</strong><small>${a.tagline[lang]}</small></span></button>`).join('')}</div><p class="note">${t('islandNote')}</p>${button('welcome-again',t('welcomeAgain'))}<p class="caption">${t('sourceOnly')}</p></div></div>`;}
function scene(src,host,{welcome=false,seal=''}={}){return `<div class="scene ${welcome?'welcome-scene '+host:''}" style="background-image:url('${src}')">${seal?`<span class="scene-seal">${seal}</span>`:''}<img class="guide" src="${portraits[host]}" alt="${hosts[lang][host]}"></div>`;}
function heading(text){return `<h2 id="dialog-heading" tabindex="-1">${text}</h2>`;}
function welcomeBody(){
 const phase=state.introPhase,p=state.introPage;
 if(phase!=='ready'){
 const key={loading:'introLoading',error:'introError',saving:'saving',unknown:'saveUnknown'}[phase]??'saving';
 return `<div class="panel-copy welcome-copy"><img class="notice-art" src="${portraits.robo}" alt="Robo">${heading(t(key))}<p>${t(key+'Body')}</p><div class="notice-actions">${['error','unknown'].includes(phase)?button('read-intro',t(phase==='error'?'retry':'readBack'),'primary'):''}${['saving','unknown','error'].includes(phase)?button('session',t('session')):''}</div></div>`;
 }
 const host=['robo','py','pip'][p],background=['assets/arrival.webp','assets/main_quest.webp','assets/arrival.webp'][p];
 const art=scene(background,host,{welcome:true});const content=`<div class="panel-copy welcome-copy"><p class="step-caption">${t('page')} ${p+1} / 3 · ${t('stepNames')[p]}</p><div class="steps" aria-hidden="true">${[0,1,2].map(i=>`<span class="${i<=p?'active':''}"></span>`).join('')}</div>${heading(t('greeting'+(p+1)))}<p>${t('body'+(p+1))}</p>${p===2?`<p class="note">${t('regen')} <strong>${catalog.config.energy.regen_minutes_per_unit} ${t('minutes')}</strong>.</p>`:''}</div>`;return scale>=1.5?content+art:art+content;
}
function metric([key,n,total]){return `<div class="metric"><span>${copy[lang].metrics[key]}</span><strong>${n}${total!=null?' / '+total:''}</strong></div>`;}
function lessonCard(id){const l=lesson(id);return `<div class="lesson-card"><small>${t('lesson')} ${l?.number??'—'} · ${esc(id)}</small><strong>${l?l.title[lang]:t('missing')}</strong></div>`;}
function statusBody(){const s=state.status;
 if(s.phase==='loading'||s.phase==='error'){const key=s.phase==='loading'?'loading':'loadError';return `<section class="status-box ${s.phase==='error'?'error':''}" aria-busy="${s.phase==='loading'}"><h3>${t(key)}</h3><p>${t(s.phase==='loading'?'loadingBody':'errorBody')}</p></section>`;}
 if(s.locked)return `<section class="status-box locked"><h3>${t('locked')}</h3><p>${t(s.unlockLessonId?'lockBody':'missing')}</p>${s.unlockLessonId?lessonCard(s.unlockLessonId)+`<p class="caption">${t('notAuto')}</p>`:''}</section>`;
 if(s.legacy)return `<section class="status-box legacy"><h3>${t('legacy')}</h3><div lang="vi"><p>${esc(s.legacy.progressLabel)}</p>${s.legacy.detailLines.map(x=>`<p>${esc(x)}</p>`).join('')}</div><p class="caption">${t('legacyNote')}</p></section>`;
 let record='';if('record'in s)record=`<div class="metric"><span>${s.record==null?t(s.unplayed?'unplayed':'noRecord'):t('record')}</span><strong>${s.record??'—'}</strong></div>`;
 return `<section class="status-box"><h3>${t('progress')}</h3>${record}${s.metrics.map(metric).join('')}${s.stars!=null&&['dragon_jump','catch_stars','bug_hunter'].includes(state.selected)?metric(['stars',s.stars]):''}${state.selected==='main_quest'?`<p class="caption">${t(s.next?'nextLesson':'allLessons')}</p>${s.next?lessonCard(s.next):''}`:''}</section>`;
}
function sheetBody(){
 const a=activity(state.selected),art=scene(a.study_scene,a.host,{seal:t('host')+' · '+hosts[lang][a.host]});
 const info=`<div class="panel-copy">${heading(a.name[lang])}<p class="tagline">${a.tagline[lang]}</p><div class="tags"><span class="tag">${t(a.needsPython?'learn':'noPython')}</span>${a.hasCreatorMode?`<span class="tag creator">${t('creator')}</span>`:''}</div>${statusBody()}</div>`;
 const details=`<div class="panel-copy"><div class="guide-copy"><strong>${hosts[lang][a.host]}</strong><p>${a.description[lang]}</p></div><p class="caption">${t('costLater')}</p></div>`;
 return scale>=1.5?info+art+details:art+info+details;
}
function routeBody(){const r=state.route,a=activity(r.activity);return `${scene(a.study_scene,a.host)}<div class="panel-copy">${heading(t('route'))}<p>${t('routeBody')}</p><div class="status-box"><h3>${a.name[lang]}</h3><p>${t(r.highlightLesson?'lessonList':'moduleHome')}</p>${r.highlightLesson?lessonCard(r.highlightLesson)+`<p class="caption">${t('notAuto')}</p>`:''}<div class="route-code">${esc(r.activity)}${r.highlightLesson?' · openLessonId='+esc(r.highlightLesson):''}</div></div><p class="note">${t('simVisit')}</p><p class="caption">${t('energy')}: ${state.energy} → ${state.energy}</p></div>`;}
function footer(){
 if(state.modal==='welcome'){if(state.introPhase!=='ready')return '';return `<footer class="footer"><div class="footer-row">${state.introPage>0?button('previous','←','previous'):''}${button('next',t(state.introPage===2?'finish':'next'),'primary gold next')}</div></footer>`;}
 if(state.modal==='route')return `<footer class="footer">${button('return',t('backVillage'),'primary')}</footer>`;
 const s=state.status,d=M.destination(state);
 return `<footer class="footer"><p>${t(s.locked?'lessonFree':'entryFree')}</p>${s.phase==='error'?button('retry',t('retry'),'primary'):d?button('enter',t(s.locked?'goLesson':'open'),'primary'):button('blocked',s.phase==='loading'?t('loading'):t('statusBusy'),'quiet',true)}</footer>`;
}
function panelHTML(){if(!state.modal)return '';const title=state.modal==='welcome'?t('welcome'):state.modal==='sheet'?t('places'):t('route');return `<div class="shade"><section class="panel ${state.modal==='welcome'?'welcome':''}" role="dialog" aria-modal="false" aria-labelledby="dialog-heading"><header class="panel-bar"><span class="bar-title">${title}<br>${t('studyShort')}</span><div class="bar-actions">${button('panel-tools','☷')}${state.modal!=='welcome'?button('close','×'):''}</div></header><div id="body-scroll" class="body-scroll" tabindex="0">${toolsOpen?`<div class="review-panel">${controls('p')}${simulation('p')}</div>`:''}${state.modal==='welcome'?welcomeBody():state.modal==='sheet'?sheetBody():routeBody()}</div>${footer()}</section></div>`;}
function on(id,fn){if($(id))$(id).onclick=fn;}
function announce(text){$('live').textContent=text;}
function focusHeading(){requestAnimationFrame(()=>$('dialog-heading')?.focus({preventScroll:true}));}
function render({preserve=false,focus=false}={}){
 const oldHost=$('host-scroll')?.scrollTop??hostOffset,oldBody=$('body-scroll')?.scrollTop??0;
 document.documentElement.lang=lang;document.querySelector('.phone').style.setProperty('--s',scale);document.querySelector('.phone').classList.toggle('large',scale>=1.5);
 $('host').innerHTML=hostHTML();$('host').inert=!!state.modal;$('host-scroll').scrollTop=oldHost;
 $('modal-layer').innerHTML=panelHTML();if(preserve&&$('body-scroll'))$('body-scroll').scrollTop=oldBody;
 document.querySelectorAll('[data-place]').forEach(b=>b.onclick=()=>open(b.dataset.place));
 on('host-tools',toggleTools);on('panel-tools',toggleTools);for(const id of ['host-tools','panel-tools'])if($(id))$(id).ariaLabel=t('tools');
 on('welcome-again',()=>{captureReturn('welcome-again');M.welcome(state);toolsOpen=false;render({focus:true});});
 on('close',close);if($('close'))$('close').ariaLabel=t('close');
 on('previous',()=>{M.introBack(state);render({focus:true});});if($('previous'))$('previous').ariaLabel=t('previous');
 on('next',()=>{M.introNext(state);render({focus:true});});
 on('read-intro',()=>{M.introRead(state);render({focus:true});});
 on('session',()=>{M.exploreSession(state);render();restoreReturn();});
 on('retry',()=>{M.retryStatus(state);render({focus:true});});
 on('enter',()=>{if(M.activate(state)){toolsOpen=false;render({focus:true});announce(t('route'));}});
 on('return',close);bench();bindControls('p');if(focus)focusHeading();
}
function captureReturn(id){hostOffset=$('host-scroll')?.scrollTop??0;returnFocus=id;}
function restoreReturn(){requestAnimationFrame(()=>{const scroll=$('host-scroll');if(scroll)scroll.scrollTop=hostOffset;const node=$(returnFocus);node?.focus({preventScroll:true});if(node&&scroll){const n=node.getBoundingClientRect(),r=scroll.getBoundingClientRect();if(n.top<r.top||n.bottom>r.bottom)node.scrollIntoView({block:'nearest'});}});}
function open(id){if(state.modal)return;captureReturn('place-'+id);if(M.openSheet(state,id,catalog)){toolsOpen=false;render({focus:true});}}
function close(){const ok=state.modal==='route'?M.returnRoute(state):M.dismiss(state);if(ok){toolsOpen=false;render();restoreReturn();}}
function toggleTools(){toolsOpen=!toolsOpen;render({preserve:true});if(toolsOpen){const scroll=$('body-scroll')??$('host-scroll');scroll.scrollTop=0;requestAnimationFrame(()=>$('p-lang')?.focus());}else $('panel-tools')?.focus();}
function simulate(key){
 let changed=false;
 if(state.modal==='welcome'){
 if(state.introPhase==='loading')changed=M.introReadAck(state,state.introToken,key==='error'?null:key==='ack');
 else if(key==='ack'||key==='unknown')changed=M.introAck(state,state.introToken,key==='ack'?'confirmed':'unknown');
 }else if(state.modal==='sheet'&&state.status.phase==='loading')changed=M.resolveStatus(state,state.statusToken,state.selected,key==='error'?{...state.status,phase:'error'}:M.statusFor(state.selected,state.facts,catalog));
 if(changed){toolsOpen=false;render({focus:!!state.modal});if(!state.modal)restoreReturn();}
}
function setFixture(key){if(!M.fixtures.includes(key))return;scenario=key;state=M.fixture(key,catalog);toolsOpen=false;hostOffset=0;returnFocus=state.selected?'place-'+state.selected:'place-main_quest';render({focus:!!state.modal});}
// The dialog is local to the phone study, not a global modal over reviewer tools.
window.addEventListener('keydown',e=>{
 if(!state.modal||!e.target.closest('.phone'))return;
 if(e.key==='Escape'){e.preventDefault();if(toolsOpen){toolsOpen=false;render({preserve:true});$('panel-tools')?.focus();}else if(state.modal==='welcome'){if(M.introBack(state))render({focus:true});}else close();return;}
 if(e.key==='Tab'){
 const controls=[...document.querySelectorAll('.panel button:not(:disabled),.panel select,.panel a[href],.panel [tabindex="0"]')].filter(el=>el.getClientRects().length);
 const index=controls.indexOf(document.activeElement);
 if(e.shiftKey&&(index<=0)){e.preventDefault();controls.at(-1)?.focus();}else if(!e.shiftKey&&(index===controls.length-1)){e.preventDefault();controls[0]?.focus();}
 }
});
render({focus:!!state.modal});window.entranceStudy={get state(){return state;},catalog,setFixture,open,close,simulate,resolve:(token,id,status)=>{const changed=M.resolveStatus(state,token,id,status);if(changed)render({preserve:true});return changed;},introAck:(token,outcome)=>{const changed=M.introAck(state,token,outcome);if(changed)render({focus:!!state.modal});return changed;}};window.studyReady=true;
