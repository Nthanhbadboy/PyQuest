import {ids,names,copy,fixtures,suggestion,destination} from './model.mjs';
const manifest = await (await fetch('manifest.json')).json();
const $ = s => document.querySelector(s);
const params = new URLSearchParams(location.search);
let lang = params.get('lang') === 'en' ? 'en' : 'vi';
let scale = [1,1.3,2].includes(Number(params.get('scale'))) ? Number(params.get('scale')) : 1;
let fixture = ['fresh','returning','complete','loading','error'].includes(params.get('state')) ? params.get('state') : 'fresh';
let entries = fixtures(fixture);
let mode = scale >= 1.5 ? 'list' : 'map';
let lastTrigger, openedId, openingScroll = 0, routeCalls = 0;
const title = id => names[lang][ids.indexOf(id)];
const stateLabel = id => {const e=entries[id],c=copy[lang];return e.phase==='loading'?c.loading:e.phase==='error'?c.retry:e.locked?c.locked:c.ready;};
function open(id,trigger){
  if ($('#sheet').open) return;
  const entry=entries[id];
  if (entry?.phase==='error') { entries[id]={...entry,phase:'ready'}; renderContent(); document.querySelector(`[data-id="${id}"]`)?.focus({preventScroll:true}); return; }
  if (entry?.phase!=='ready') return;
  openedId=id; lastTrigger=trigger; openingScroll=$('#hub-scroll').scrollTop;
  $('#sheet-title').textContent=title(id); $('#sheet-copy').textContent=copy[lang].sample;
  $('#route-value').textContent=copy[lang].route+': '+destination(id,entries);
  $('#route-action').hidden=false; $('#route-action').disabled=!destination(id,entries);
  $('#route-action').textContent=entry.locked?copy[lang].lesson:copy[lang].open;
  $('#sheet-close').textContent=copy[lang].close;
  $('#sheet').showModal();
}
function restore(){ $('#hub-scroll').scrollTop=openingScroll;lastTrigger?.focus({preventScroll:true});openedId=null; }
$('#sheet').addEventListener('close',restore);
$('#sheet-close').onclick=()=>$('#sheet').close();
$('#route-action').onclick=()=>{
  if (!openedId) return;
  const route=destination(openedId,entries); if(!route)return;
  routeCalls++; window.routeCalls=routeCalls; window.lastRoute=route;
  $('#event').textContent=`SIMULATION ${routeCalls}: ${route}`;
  $('#sheet').close();
};
function renderContent(){
  const c=copy[lang];
  $('.device').classList.toggle('map-mode',mode==='map');
  $('#map-view').setAttribute('aria-pressed',String(mode==='map'));$('#list-view').setAttribute('aria-pressed',String(mode==='list'));
  $('#hint').textContent=scale>=1.5?c.large:mode==='map'?c.scroll:c.directory;
  const rec=suggestion(entries);const box=$('#recommendation');box.hidden=!rec;box.replaceChildren();
  if(rec){const l=document.createElement('span');l.className='eyebrow';l.textContent=c.suggestion;const b=document.createElement('button');b.textContent=c.visit+title(rec);b.id='suggestion';b.onclick=()=>open(rec,b);box.append(l,b);}
  const content=$('#content');content.replaceChildren();
  const container=document.createElement('div');container.className=mode==='map'?'scene':'directory';
  if(mode==='map'){const img=document.createElement('img');img.src=manifest.asset.path;img.alt='';img.width=853;img.height=1844;container.append(img);}
  for(const [i,id] of ids.entries()){
    const button=document.createElement('button');button.dataset.id=id;button.id=`place-${id}`;
    button.className=(mode==='map'?'marker':'place-row')+(entries[id].locked?' locked':'');
    button.disabled=entries[id].phase==='loading';button.setAttribute('aria-label',`${title(id)}. ${stateLabel(id)}`);
    if(mode==='map'){const {anchor}=manifest.layout.markers.find(m=>m.id===id);button.style.left=`${anchor[0]*100}%`;button.style.top=`${anchor[1]*100}%`;}
    else{const ordinal=document.createElement('span');ordinal.className='ordinal';ordinal.textContent=String(i+1);ordinal.setAttribute('aria-hidden','true');button.append(ordinal);}
    const text=document.createElement('span');text.className='name';text.textContent=title(id);const small=document.createElement('small');small.textContent=stateLabel(id);text.append(small);button.append(text);
    button.onclick=()=>open(id,button);container.append(button);
  }
  content.append(container);
}
function render(){
  document.documentElement.lang=lang;$('.device').style.setProperty('--text',scale);$('#sheet').style.setProperty('--text',scale);$('.device').classList.toggle('large',scale>=1.5);
  const c=copy[lang];$('#island').textContent=c.island;$('#subtitle').textContent=c.subtitle;$('#daily').textContent=c.daily;$('#settings').textContent=c.settings;
  $('.energy').setAttribute('aria-label',c.energy+': 12 / 20, fixture');$('#map-view').textContent=c.map;$('#list-view').textContent=c.list;$('#footer-note').textContent=c.saved;
  $('#lang').value=lang;$('#scale').value=String(scale);$('#fixture').value=fixture;renderContent();
}
$('#lang').onchange=e=>{lang=e.target.value;render();};
$('#scale').onchange=e=>{scale=Number(e.target.value);mode=scale>=1.5?'list':'map';render();};
$('#fixture').onchange=e=>{fixture=e.target.value;entries=fixtures(fixture);render();};
$('#map-view').onclick=()=>{if(scale>=1.5)return;mode='map';renderContent();};
$('#list-view').onclick=()=>{mode='list';renderContent();};
for(const id of ['daily','settings','energy'])$('#'+id).onclick=e=>{
  openedId=null;lastTrigger=e.currentTarget;openingScroll=$('#hub-scroll').scrollTop;
  $('#sheet-title').textContent=copy[lang][id];$('#sheet-copy').textContent=copy[lang].sample;$('#route-value').textContent='';$('#route-action').hidden=true;$('#sheet-close').textContent=copy[lang].close;$('#sheet').showModal();
};
render();window.studyReady=true;
