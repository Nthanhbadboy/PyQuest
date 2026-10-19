/* In-memory interaction prototype only. Simulated responses never leave this page. */
'use strict';
const $=s=>document.querySelector(s),query=new URLSearchParams(location.search),M=window.TravelStudy;
let lang=query.get('lang')==='en'?'en':'vi',scale=['1','1.3','2'].includes(query.get('scale'))?query.get('scale'):'1';
let state=M.fixture(M.states.includes(query.get('state'))?query.get('state'):'overview'),view='map',timer=null,traceNote='';
let auto=query.get('auto')!=='0',calm=matchMedia('(prefers-reduced-motion: reduce)').matches;
const docks={village:[66.5,68.8],home:[55.4,110.6],forest:[87,55]};
const paths={home:'M66.5 68.8 C72 76 43 82 43 97 C43 106 47 110 55.4 110.6',forest:'M66.5 68.8 C83 80 98 73 87 55'};
function text(){return window.W08_COPY[lang]}
function commit(event,focus=false){const old=state;state=M.step(state,event);traceNote=old===state&&event.type==='response'?text().harness.lateIgnored:'';render();schedule();if(focus)$('#state-title').focus({preventScroll:true});}
function stopTimer(){if(timer!==null){clearTimeout(timer);timer=null}}
function schedule(){stopTimer();if(!auto||document.hidden||!state.request||!['loading','downloading'].includes(state.state))return;const token=state.request.id;timer=setTimeout(()=>{timer=null;commit({type:'response',token,ok:true,access:true})},1100)}
function loadFixture(id){stopTimer();state=M.fixture(id);traceNote='';render();schedule()}
function choose(destination){commit({type:'select',destination},true);$('#info').scrollIntoView({block:'nearest'})}
function action(event){if(event==='select-list'){setView('list');$('#destination-list button').focus();return}if(event==='back'){commit({type:[...M.busy,'confirm','return_confirm'].includes(state.state)?'cancel':'overview'},true);return}commit({type:event},true);$('#info').scrollIntoView({block:'nearest'})}
function setView(value){view=value;render();}
function setButton(id,label,event,disabled=false){const b=$(id);b.textContent=label||'';b.hidden=!label;b.disabled=disabled;b.dataset.action=event||''}
function render(){
 const c=text();document.documentElement.lang=lang;document.documentElement.style.fontSize=(16*Number(scale))+'px';document.body.classList.toggle('calm',calm);document.title='PyQuest · '+c.title+' / W08';
 document.querySelectorAll('[data-h]').forEach(n=>n.textContent=c.harness[n.dataset.h]);document.querySelectorAll('[data-ui]').forEach(n=>n.textContent=c[n.dataset.ui]);
 $('#lang').value=lang;$('#scale').value=scale;$('#auto').checked=auto;$('#calm').checked=calm;$('#back').setAttribute('aria-label',c.back);
 const fs=$('#fixture');fs.replaceChildren();for(const id of M.states){const option=document.createElement('option');option.value=id;option.textContent=c.states[id][0];fs.append(option)}fs.value=state.state;
 $('#standalone').href=`?phone=1&lang=${lang}&scale=${scale}&state=${state.state}&auto=0`;
 $('.view-tabs').setAttribute('aria-label',`${c.map} / ${c.list}`);
 $('#current-place').textContent=c.places[state.current].name;
 const selection=state.selected?c.places[state.selected]:null;const restricted=['eligibility_missing','permission_denied','permission_unknown','revoked'].includes(state.state);
 $('#place-kind').textContent=state.state==='overview'?c.selected:restricted?(selection?.kind||c.selected):(selection?.kind||c.selected);
 $('#state-title').textContent=c.states[state.state][0];$('#state-body').textContent=c.states[state.state][1];
 const showActivity=['public_ready','private_ready','content_preview'].includes(state.state);$('#activity').hidden=!showActivity;$('#activity').textContent=showActivity?selection.activity:'';
 const routeVisible=!!selection&&!['overview','content_preview','eligibility_missing','permission_unknown','permission_denied','revoked'].includes(state.state);
 $('#route-summary').hidden=!['confirm','loading','load_error','cancelled','sailing','arrived','return_confirm','offline'].includes(state.state)||!selection;
 const from=state.request?.from||state.departure;$('#route-from').textContent=c.places[from].name;$('#route-to').textContent=restricted?'—':(selection?.name||'—');
 const routeKey=state.selected==='village'?'home':state.selected;const route=routeVisible?paths[routeKey]||'':'';
 $('#route-path').setAttribute('d',route);$('#route-shadow').setAttribute('d',route);
 const departure=docks[from],arrival=docks[state.selected]||departure;
 for(const [id,point] of [['origin-dot',departure],['arrival-dot',arrival]]){const n=$('#'+id);n.style.display=route?'':'none';n.setAttribute('cx',point[0]);n.setAttribute('cy',point[1]);}
 $('#map-frame').classList.toggle('sailing',state.state==='sailing'&&!calm);$('#map-frame').hidden=view!=='map';$('#destination-list').hidden=view!=='list';
 $('.map-art').alt=lang==='vi'?'Hải đồ minh họa: làng công cộng bên trái, đảo riêng phía dưới và khu rừng phía trên; không phải bản đồ nhà của người dùng.':'Illustrative chart: public village left, personal island below, woodland above; not an actual user’s private layout.';
 document.querySelectorAll('[data-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.view===view)));
 document.querySelectorAll('.map-pin').forEach((b,i)=>{const p=c.places[b.dataset.destination];b.setAttribute('aria-label',`${i+1}. ${p.name}. ${p.kind}`);b.setAttribute('aria-pressed',String(state.selected===b.dataset.destination));b.disabled=M.busy.includes(state.state)});
 const list=$('#destination-list');list.replaceChildren();Object.entries(c.places).forEach(([id,p],i)=>{const b=document.createElement('button');b.type='button';b.className='destination-card';b.dataset.destination=id;b.disabled=M.busy.includes(state.state);b.setAttribute('aria-pressed',String(state.selected===id));const num=document.createElement('span');num.className='num';num.textContent=i+1;const wrap=document.createElement('span'),name=document.createElement('b'),kind=document.createElement('small');name.textContent=p.name;kind.textContent=p.kind;wrap.append(name,kind);b.append(num,wrap);b.addEventListener('click',()=>choose(id));list.append(b)});
 setButton('#primary',null,null);setButton('#secondary',null,null);
 switch(state.state){
 case 'overview':setButton('#primary',c.list,'select-list');break;
 case 'public_ready':case 'private_ready':setButton('#primary',state.selected===state.current?c.here:c.preview,'confirm',state.selected===state.current);setButton('#secondary',c.choose,'overview');break;
 case 'content_preview':setButton('#primary',c.packageDisabled,null,true);setButton('#secondary',c.choose,'overview');break;
 case 'eligibility_missing':case 'permission_unknown':case 'permission_denied':setButton('#primary',c.disabled,null,true);setButton('#secondary',c.choose,'overview');break;
 case 'pack_missing':case 'download_error':setButton('#primary',c.download,'download');setButton('#secondary',c.choose,'overview');break;
 case 'confirm':case 'return_confirm':setButton('#primary',c.depart,'begin');setButton('#secondary',c.cancel,'cancel');break;
 case 'loading':case 'downloading':setButton('#primary',c.wait,null,true);setButton('#secondary',c.cancel,'cancel');break;
 case 'sailing':setButton('#primary',c.skip,'arrive');setButton('#secondary',c.cancel,'cancel');break;
 case 'load_error':case 'cancelled':setButton('#primary',c.retry,'retry');setButton('#secondary',c.choose,'overview');break;
 case 'offline':setButton('#primary',c.disabled,null,true);setButton('#secondary',c.choose,'overview');break;
 case 'arrived':setButton('#primary',c.return,'return');break;
 case 'revoked':setButton('#primary',c.choose,'overview');break;
 }
 $('#loading-track').hidden=!['loading','downloading'].includes(state.state);
 const safe=['loading','load_error','cancelled','downloading','download_error'].includes(state.state);$('#safe-note').hidden=!safe&&state.state!=='arrived';$('#safe-note').textContent=safe?c.sourceSafe:c.noReward;
 $('#announce').textContent=c.states[state.state][0];
 $('#reconnect').disabled=state.online;
 $('#response-ok').disabled=$('#response-fail').disabled=!state.request||!['loading','downloading'].includes(state.state);
 $('#trace').textContent=`state: ${state.state}\nsource/current: ${state.current}\nrequest: ${state.request?state.request.id+' → '+state.request.to:c.harness.idle}\narrivals (fixture): ${state.arrivals}\nenergy Δ: ${state.energyDelta} | rewards Δ: ${state.rewardDelta}${traceNote?'\n'+traceNote:''}`;
}
$('#lang').addEventListener('change',e=>{lang=e.target.value;render()});$('#scale').addEventListener('change',e=>{scale=e.target.value;render()});$('#fixture').addEventListener('change',e=>loadFixture(e.target.value));
$('#auto').addEventListener('change',e=>{auto=e.target.checked;schedule()});$('#calm').addEventListener('change',e=>{calm=e.target.checked;render()});
for(const b of document.querySelectorAll('[data-view]'))b.addEventListener('click',()=>setView(b.dataset.view));
for(const b of document.querySelectorAll('.map-pin'))b.addEventListener('click',()=>choose(b.dataset.destination));
for(const id of ['back','primary','secondary'])$('#'+id).addEventListener('click',e=>{if(!e.currentTarget.disabled&&e.currentTarget.dataset.action)action(e.currentTarget.dataset.action)});
$('#reconnect').addEventListener('click',()=>commit({type:'online'}));
$('#response-ok').addEventListener('click',()=>commit({type:'response',token:state.request?.id,ok:true,access:true}));$('#response-fail').addEventListener('click',()=>commit({type:'response',token:state.request?.id,ok:false,access:true}));$('#revoke').addEventListener('click',()=>commit({type:'revoke'}));$('#stale').addEventListener('click',()=>commit({type:'response',token:Math.max(0,state.generation-1),ok:true,access:true}));
document.addEventListener('visibilitychange',()=>{if(document.hidden)stopTimer();/* Resume never commits an arrival or replays a transition. */});
window.W08Study={getSnapshot:()=>structuredClone(state),fixture:loadFixture,dispatch:commit,setView,setPreferences:p=>{if(p.lang)lang=p.lang;if(p.scale)scale=String(p.scale);if(typeof p.auto==='boolean')auto=p.auto;if(typeof p.calm==='boolean')calm=p.calm;render();schedule()},getPreferences:()=>({lang,scale,auto,calm,view})};
render();schedule();
