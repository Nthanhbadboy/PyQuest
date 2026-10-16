import {Session,scenarios,frames,level} from './model.mjs';
import {copy} from './copy.mjs';
import {normalizePreference,resolveLanguage,storageKey} from '../shared-l10n/locale-core.mjs';
const $=s=>document.querySelector(s);
let session=new Session(), preference='system', language='vi', calm=false, preferenceMessage='';
try{preference=normalizePreference(localStorage.getItem(storageKey));}catch{}
const motion=matchMedia('(prefers-reduced-motion: reduce)');
const c=(key,args)=>copy(language,key,args);
const esc=value=>String(value).replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
const art='../tutor-board-prototype/art/';
const paths={
 star:'m12 2 3 6.5 7 1-5 5 1.2 7L12 18l-6.2 3.5L7 14.5l-5-5 7-1z',
 arrow:'M4 12h15m-6-6 6 6-6 6',check:'m5 12 4 4 10-10',home:'m3 11 9-8 9 8M5 10v11h14V10M10 21v-7h4v7',
 badge:'M12 3a7 7 0 1 0 0 14 7 7 0 0 0 0-14zm-5 13-2 6 7-3 7 3-2-6',leaf:'M5 20C1 6 13 2 21 3c-1 10-4 18-16 17zm0 0 10-10',
 lock:'M7 10V7a5 5 0 0 1 10 0v3M5 10h14v11H5zm7 4v3',code:'m8 6-6 6 6 6m8-12 6 6-6 6m-3-15-2 18',
 question:'M9 8a3 3 0 1 1 4 3c-1 1-1 2-1 3m0 4h.01',chest:'M3 10h18v10H3zM3 10V7q0-4 4-4h10q4 0 4 4v3M10 10v5h4v-5',
 retry:'M4 10a8 8 0 1 1 0 7M4 4v6h6',minus:'M6 12h12',book:'M3 4h7l2 2 2-2h7v16h-7l-2 1-2-1H3zm9 2v15',
};
function icon(name,cls=''){return `<svg class="${cls}" viewBox="0 0 24 24" aria-hidden="true"><path d="${paths[name]||paths.star}"/></svg>`;}
function arrow(command){return `<svg viewBox="0 0 24 24" aria-hidden="true" style="transform:rotate(${{R:0,D:90,L:180,U:270}[command]}deg)"><path d="${paths.arrow}"/></svg>`;}
const btn=(label,view,cls='secondary',ic='')=>`<button class="${cls}" data-view="${view}">${ic?icon(ic):''}${esc(c(label))}</button>`;
function scene(){return `<div class="scene" aria-hidden="true"><img class="island" src="art/arrival-island.svg" alt=""><img class="robo" src="${art}robo.svg" alt=""></div>`;}
function intro(eyebrow,title,line,extra=''){return `<header class="section-intro"><p class="eyebrow">${c(eyebrow)}</p><h1 tabindex="-1">${c(title)}</h1><p>${c(line)}</p>${extra}</header>`;}
function status(){const key={saved:'saved',pending:'pending',error:'saveError',attempt:'attemptOnly'}[session.status];return `<p class="save-status ${session.status==='error'?'error':''}" data-save-status="${session.status}">${icon(session.status==='saved'?'check':'minus')}${c(key)}</p>`;}
function pendingBox(){if(!['pending','error'].includes(session.status))return '';return `<div class="pending-box"><p class="small">${c(session.status==='pending'?'pendingHelp':'failedSaveHelp')}</p>${session.status==='error'?`<button data-action="ack">${c('retrySave')}</button>`:`<button data-action="workbench">${c('review')}</button>`}</div>`;}
function awards(){const notices=session.visibleNotices;
 if(!notices.length)return `<div class="award-neutral">${c(session.status!=='saved'?'notSaved':session.owned.has('first_steps')?'badgeAlready':'noAward')}</div>`;
 return `<section class="reward-box" aria-label="${c('multi')}">${notices.map(n=>n.kind==='badge'?`<div class="reward-row" data-notice="${n.id}"><img src="art/first-steps.svg" alt=""><div><p class="eyebrow">${c('newBadge')}</p><h3>${c('firstSteps')}</h3>${btn('viewBadge','badge','text-button','arrow')}</div></div>`:`<div class="quest-notice" data-notice="${n.id}">${icon('check')}<div><p><strong>${c('questTitle')}</strong>${c('questDescription')}</p><p class="small">${c('questNote')}</p></div></div>`).join('')}</section>`;
}
function result(){const o=session.outcome;
 const best=o.newHighScore&&session.scenario==='r03';
 const title=!o.success?'retryTitle':best?'bestTitle':'successTitle';
 const line=!o.success?'retryLine':best?'bestLine':'successLine';
 return `<div class="breadcrumb"><span class="pill">${icon('leaf')}${c('maze')}</span><span>${c('level')}</span></div><div class="result-layout"><section class="hero"><p class="eyebrow">${c('adventure')}</p><h1 tabindex="-1">${c(title)}</h1><p class="lead">${c(line)}</p><div class="stars" role="img" aria-label="${c('stars',{count:o.stars})}">${[0,1,2].map(i=>icon('star',i<o.stars?'':'unearned')).join('')}</div>${scene()}<div class="companion-note"><span>${icon('book')}</span><p>${c('skill')}</p></div></section><section class="result-card"><div class="card-body"><div class="card-heading"><h2>${c('resultHeading')}</h2><span class="pill gold">${o.stars} / 3 ${icon('star')}</span></div><div class="stats"><div class="stat"><strong>${o.score}</strong><span>${c('score')}</span></div><div class="stat"><strong>${session.bestScore||'—'}</strong><span>${c('best')}</span></div><div class="stat"><strong>${o.used}</strong><span>${c('commands')}</span></div></div><h3>${c('goals')}</h3><ul class="goal-list">${['goalReach','goalGems','goalLimit'].map((key,i)=>`<li><span class="goal-check ${o.goals[i]?'':'no'}">${icon(o.goals[i]?'check':'minus')}<span class="sr-only">${c(o.goals[i]?'goalDone':'goalNotYet')}: </span></span><div>${c(key)}${i===2?`<small>${c('goalCount',{count:o.used})}</small>`:''}</div></li>`).join('')}</ul>${status()}${pendingBox()}</div>${o.success?awards():''}<div class="action-bar">${btn(o.success?'chooseNext':'retry',o.success?'next':'play','primary','arrow')}<div class="secondary-row">${btn('home','home','text-button','home')}${btn(o.success?'practice':'backResult',o.success?'play':'result','text-button','retry')}</div></div></section></div>`;
}
function badge(){const has=session.owned.has('first_steps');
 return `<div class="badge-layout"><div class="badge-display"><img src="art/first-steps.svg" alt=""></div><section class="badge-copy"><p class="eyebrow">${c('badgeType')}</p><h1 tabindex="-1">${c('firstSteps')}</h1><span class="pill ${has?'gold':''}">${icon(has?'check':'lock')}${c(has?'earned':'locked')}</span><p>${c(has?'badgeReason':'badgeNotEarned')}</p><p class="small">${c('badgeHow')}</p>${has?`<p class="small">${c('saved')}</p>`:''}<div class="actions">${btn('viewCollection','hall','primary','badge')}${btn('backResult','result','text-button','arrow')}</div></section></div>`;
}
function reward(){return `${intro('adventure',session.visibleNotices.length?'multi':'resultHeading',session.visibleNotices.length?'newMilestone':session.status==='saved'?'noAward':'notSaved')}<div class="single-scene">${session.visibleNotices.some(n=>n.kind==='badge')?'<img src="art/first-steps.svg" alt="">':''}${status()}${pendingBox()}${awards()}<div class="actions">${btn('viewCollection','hall','primary','badge')}${btn('chooseNext','next')}</div></div>`;}
function hall(){const has=session.owned.has('first_steps');return `${intro('collectionEyebrow','collectionTitle','collectionLine',`<span class="pill">${icon('lock')}${c('private')}</span>`)}<section class="shelf"><div class="shelf-top"><h2>${c('earnedCount',{count:session.owned.size})}</h2><span class="small">${c('prototype')}</span></div>${!has?`<p class="quiet-box">${c('emptyCollection')}</p>`:''}<div class="badge-grid"><article class="collection-item" data-earned="${has}">${has?'<img class="medal" src="art/first-steps.svg" alt="">':`<div class="locked-medal">${icon('badge')}</div>`}<h3>${c('firstSteps')}</h3><p>${c('badgeHow')}</p>${has?btn('viewBadge','badge','text-button','arrow'):`<span class="pill">${c('locked')}</span>`}</article><article class="collection-item"><div class="locked-medal">${icon('code')}</div><h3>${c('firstLine')}</h3><p>${c('firstLineHow')}</p><span class="pill">${icon('lock')}${c('locked')}</span></article><article class="collection-item"><div class="locked-medal">${icon('question')}</div><h3>${c('secret')}</h3><p>${c('secretHint')}</p><span class="pill">${icon('lock')}${c('locked')}</span></article></div></section><div class="center-actions">${btn(has?'chooseNext':'emptyAction',has?'next':'play','primary','arrow')}${has?btn('showcase','share'):''}${btn('home','home','text-button','home')}</div>`;}
function next(){const blocked=session.energy<session.nextCost||session.noNext;return `${intro('nextEyebrow','nextTitle','nextLine')}<div class="journey-grid"><article class="journey-card"><img class="thumb" src="../village-kit/exports/robo_maze_512.webp" alt=""><div class="card-body"><p class="eyebrow">${c('maze')}</p><h2>${c('nextLevel')}</h2><p>${c('nextLevelLine')}</p><p class="cost">${c('cost',{cost:session.nextCost})}</p><p class="small">${c('sampleBalance',{amount:session.energy})}</p>${blocked?`<p class="error-note">${c(session.noNext?'endRoute':'noEnergy')}</p>`:''}<button class="primary" data-view="challenge" ${blocked?'disabled':''}>${c('previewNext')}${icon('arrow')}</button></div></article><article class="journey-card"><img class="thumb" src="art/arrival-island.svg" alt=""><div class="card-body"><p class="eyebrow">${c('notCompetition')}</p><h2>${c('practiceTitle')}</h2><p>${c('practiceLine')}</p><p class="cost">${c(session.owned.has('first_steps')?'practiceCost':'practiceNew')}</p>${btn('practice','play','secondary','retry')}</div></article><article class="journey-card calm-card"><div class="rest-picture"><img src="${art}robo.svg" alt=""></div><div class="card-body"><p class="eyebrow">${c('nextEyebrow')}</p><h2>${c('restTitle')}</h2><p>${c('restLine')}</p>${btn('rest','rest','secondary','leaf')}</div></article></div>`;}
function share(){const has=session.owned.has('first_steps');return `${intro('shareEyebrow','shareTitle','shareLine')}<div class="share-layout"><article class="share-card"><p class="eyebrow">PyQuest · ${c('badgeType')}</p>${has?'<img src="art/first-steps.svg" alt="">':`<div class="locked-medal">${icon('lock')}</div>`}<h2>${c('firstSteps')}</h2><p>${c(has?'badgeReason':'badgeNotEarned')}</p><p class="pill">${icon('lock')}${c('private')}</p></article><section class="share-controls"><label for="social-state">${c('shareView')}</label><select id="social-state">${['unconnected','offline','restricted'].map(key=>`<option value="${key}" ${key===session.social?'selected':''}>${c(key)}</option>`).join('')}</select><p data-social-message>${c(session.social==='offline'?'shareOffline':session.social==='restricted'?'shareRestricted':'shareNoSend')}</p><button disabled>${icon('lock')}${c('shareDisabled')}</button>${btn('viewCollection','hall','primary','badge')}${btn('chooseNext','next','text-button','arrow')}</section></div>`;}
function challenge(){return `${intro('challengeEyebrow','challengeTitle','challengeLine')}<div class="badge-layout"><img src="../village-kit/exports/robo_maze_512.webp" alt=""><section class="badge-copy"><span class="pill">${c('notCompetition')}</span><h2>${c('challengeSolo')}</h2><p>${c('challengeSoloLine')}</p><div class="actions">${btn('practice','play','primary','retry')}${btn('chooseNext','next','text-button','arrow')}</div></section></div>`;}
function finish(){return `${intro('adventure',session.outcome.success?'finishTitle':'retryTitle',session.outcome.success?'finishLine':'retryLine')}<div class="single-scene">${scene()}${status()}${pendingBox()}<div class="actions">${btn('toResult','result','primary','arrow')}${btn('home','home','text-button','home')}</div></div>`;}
function home(){return `${intro('nextEyebrow','homeTitle','homeLine')}<div class="single-scene"><img class="village-image" src="${art}village.webp" alt=""><div class="actions">${btn('chooseNext','next','primary','arrow')}${btn('viewCollection','hall')}${btn('rest','rest','text-button','leaf')}</div></div>`;}
function rest(){return `${intro('nextEyebrow','restHeading','restBody')}<div class="single-scene"><img class="rest-robo" src="${art}robo.svg" alt=""><p class="quiet-box">${c('restBoundary')}</p><div class="actions">${btn('home','home','primary','home')}${btn('backResult','result','text-button','arrow')}</div></div>`;}
function play(){return `${intro('maze','playTitle','playLine')}<div class="play-layout"><section><div class="maze-grid" role="img" aria-label="${c('boardLabel')}">${level.rows.flatMap((row,y)=>[...row].map((tile,x)=>`<span class="tile ${tile==='#'?'wall':''}">${x===0&&y===1?`<img src="${art}robo.svg" alt="">`:tile==='C'?icon('chest'):''}</span>`)).join('')}</div><p class="quiet-box">${c('playNote')}</p></section><section class="result-card"><div class="card-body"><h2>${c('program')}</h2><div class="program" aria-label="${c('program')}">${session.program.length?session.program.map(cmd=>`<span aria-label="${c({R:'right',L:'left',U:'up',D:'down'}[cmd])}">${arrow(cmd)}</span>`).join(''):`<span class="small">${c('emptyProgram')}</span>`}</div><div class="direction-buttons">${['L','U','D','R'].map(cmd=>`<button data-command="${cmd}" aria-label="${c({R:'right',L:'left',U:'up',D:'down'}[cmd])}">${arrow(cmd)}</button>`).join('')}</div><div class="program-tools"><button data-action="undo" ${session.program.length?'':'disabled'}>${c('undo')}</button><button data-action="clear" ${session.program.length?'':'disabled'}>${c('clear')}</button></div><div class="actions vertical"><button class="primary" data-action="run" ${session.program.length?'':'disabled'}>${c('run')}${icon('arrow')}</button>${btn('backResult','result','text-button','arrow')}</div></div></section></div>`;}
const views={result,badge,reward,hall,next,share,challenge,finish,home,rest,play};
const frameLabels=['frameFinish','frameResult','frameReward','frameBadge','frameHall','frameNext','frameShare','frameChallenge'];
function cancelMotion(){document.getAnimations().forEach(a=>a.cancel());}
function syncChrome(){
 document.documentElement.lang=language;document.title=`PyQuest · ${c('adventure')}`;
 for(const el of document.querySelectorAll('[data-copy]'))el.textContent=c(el.dataset.copy);
 $('#main-nav').setAttribute('aria-label',c('next'));
 $('#settings-open').setAttribute('aria-label',c('settings'));$('#settings-close').setAttribute('aria-label',c('close'));
 $('#main-nav').innerHTML=['result','hall','next'].map((view,i)=>`<button data-view="${view}" ${session.view===view?'aria-current="page"':''}>${icon(['star','badge','leaf'][i])}<span>${c(view)}</span></button>`).join('');
 $('#scenario').innerHTML=scenarios.map(id=>`<option value="${id}" ${id===session.scenario?'selected':''}>${c(id)}</option>`).join('');
 $('#frames').innerHTML=frames.map((view,i)=>`<button data-view="${view}" ${view===session.view?'aria-current="step"':''}>${c(frameLabels[i])}</button>`).join('');
 $('#language').value=preference;
 const resolved=resolveLanguage(preference,navigator.languages||[navigator.language]);
 $('#language-status').textContent=resolved.fallback?c('langFallback'):c('langEffective',{language:language==='vi'?'Tiếng Việt':'English'});
 $('#preference-status').textContent=preferenceMessage?c(preferenceMessage):'';
 $('#mock-success').disabled=!['pending','error'].includes(session.status);
 $('#mock-error').disabled=session.status!=='pending';
}
function render({focus=false,restoreFocus=null}={}){
 cancelMotion();document.body.dataset.calm=String(calm||motion.matches);
 $('#content').innerHTML=views[session.view]();syncChrome();
 const animate=session.consumeCelebration(calm||motion.matches);
 if(animate){const robo=$('.scene .robo');robo?.animate([{transform:'translateY(0) rotate(0)'},{transform:'translateY(-12px) rotate(-5deg)',offset:.4},{transform:'translateY(0) rotate(0)'}],{duration:650,iterations:1});}
 $('#debug').textContent=c('debug',{writes:session.writes,badges:session.owned.size,celebrations:session.celebrations});
 if(focus){$('#content h1')?.focus({preventScroll:true});window.scrollTo({top:0,behavior:'instant'});$('#announcement').textContent=$('#content h1')?.textContent||'';}
 if(restoreFocus)$(restoreFocus)?.focus({preventScroll:true});
}
function changeLanguage(){language=resolveLanguage(preference,navigator.languages||[navigator.language]).language;render();}
function workbench(){const panel=$('#review-panel');panel.hidden=false;$('#review-open').setAttribute('aria-expanded','true');$('#scenario').focus();}
document.addEventListener('click',e=>{
 const view=e.target.closest('[data-view]')?.dataset.view;
 if(view){session.navigate(view);render({focus:true});return;}
 const command=e.target.closest('[data-command]')?.dataset.command;
 if(command){session.addCommand(command);render({restoreFocus:`[data-command="${command}"]`});return;}
 const action=e.target.closest('[data-action]')?.dataset.action;
 if(action==='workbench'){workbench();return;}
 if(action==='ack'){session.ack();render({focus:true});}
 if(action==='run'){session.run();render({focus:true});}
 if(action==='undo'||action==='clear'){
  if(action==='undo')session.program.pop();else session.program=[];
  render({restoreFocus:session.program.length?`[data-action="${action}"]`:'[data-command="R"]'});
 }
});
$('.brand').onclick=e=>{e.preventDefault();session.navigate('result');render({focus:true});};
$('#review-open').onclick=()=>{const hidden=!$('#review-panel').hidden;$('#review-panel').hidden=hidden;$('#review-open').setAttribute('aria-expanded',String(!hidden));if(!hidden)$('#scenario').focus();};
$('#scenario').onchange=e=>{session=new Session(e.target.value);render();$('#scenario').focus({preventScroll:true});};
$('#mock-success').onclick=()=>{session.ack();render({focus:true});};
$('#mock-error').onclick=()=>{session.failSave();render({focus:true});};
$('#restore').onclick=()=>{session.restore();render({focus:true});};
document.addEventListener('change',e=>{if(e.target.id==='social-state'){session.social=e.target.value;render({restoreFocus:'#social-state'});}});
$('#settings-open').onclick=()=>{$('#settings').showModal();$('#language').focus();};
$('#settings-close').onclick=()=>$('#settings').close();
$('#settings').addEventListener('close',()=>{
 // Native dialog close may dispatch after a subsequent navigation. Do not steal
 // focus back from a new page heading (e.g. fast Escape then Space on a badge).
 const active=document.activeElement;
 if(active===document.body||active===$('#settings')||$('#settings').contains(active))$('#settings-open').focus({preventScroll:true});
});
$('#language').onchange=e=>{preference=normalizePreference(e.target.value);try{localStorage.setItem(storageKey,preference);preferenceMessage='langSaved';}catch{preferenceMessage='langFailed';}changeLanguage();};
$('#calm').onchange=e=>{calm=e.target.checked;render();};
$('#text-scale').onchange=e=>{const scale=Number(e.target.value);document.documentElement.style.setProperty('--scale',scale);document.body.classList.toggle('large-text',scale>1.3);render();};
motion.addEventListener('change',()=>render());
window.addEventListener('languagechange',changeLanguage);
window.addEventListener('storage',e=>{if(e.key===storageKey||e.key===null){preference=normalizePreference(e.newValue);preferenceMessage='';changeLanguage();}});
document.addEventListener('visibilitychange',()=>{if(document.hidden)cancelMotion();});
window.addEventListener('pagehide',cancelMotion);
// Read-only diagnostic snapshot; no test-only action bypasses the UI.
Object.defineProperty(window,'__p05',{get:()=>Object.freeze({...session.snapshot(),language,preference,calm:calm||motion.matches})});
changeLanguage();
