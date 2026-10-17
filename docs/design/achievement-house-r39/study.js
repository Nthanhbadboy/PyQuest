'use strict';
const $=s=>document.querySelector(s),M=HouseModel,q=new URLSearchParams(location.search);
let lang=['vi','en'].includes(q.get('lang'))?q.get('lang'):(navigator.language.toLowerCase().startsWith('vi')?'vi':'en'),scale=['1','1.3','2'].includes(q.get('scale'))?q.get('scale'):'1',calm=matchMedia('(prefers-reduced-motion: reduce)').matches;
let state=M.create(M.fixtures.includes(q.get('state'))?q.get('state'):'room_populated'),lastFocus=null,note='';
const labels={vi:['Phòng có huy hiệu mẫu','Tủ · tất cả','Lọc đã đạt','Lọc chưa đạt','Lọc bí mật','Chi tiết đã đạt','Chi tiết chưa đạt','Bí mật chưa mở','Bí mật đã đạt · mẫu','Phòng trống thật','Đang tải','Lỗi tải','Tiến độ chưa có','Không tìm thấy'],en:['Room with sample badges','Cabinet · all','Earned filter','Not-yet filter','Secret filter','Earned detail','Not-yet detail','Hidden secret','Earned secret · sample','Truly empty room','Loading','Load error','Progress unavailable','No search results']};
const c=()=>HouseCopy[lang];
function medal(b){const n=document.createElement('span');n.className='medal'+(!b.earned?(b.secret?' secret':' locked'):'');n.textContent=b.icon;n.setAttribute('aria-hidden','true');return n}
function apply(event){const old=state;state=M.step(state,event);note=event.type==='resolve'&&old===state?'Old response ignored':'';render()}
function open(key,from){lastFocus=from;apply({type:'open',key,scroll:$('#screen').scrollTop});$('#screen').scrollTop=0;$('#detail-title').focus({preventScroll:true})}
function back(){const wasDetail=!!state.selected;const scroll=state.listScroll;apply({type:'back'});if(wasDetail){state.view='cabinet';render();$('#screen').scrollTop=scroll;const target=[...document.querySelectorAll('.badge-row')].find(b=>b.dataset.key===lastFocus);if(target)target.focus({preventScroll:true})}else $('#screen').scrollTop=0}
function render(){const t=c(),ready=state.status==='ready';document.documentElement.lang=lang;document.documentElement.style.fontSize=(16*Number(scale))+'px';document.body.classList.toggle('calm',calm);document.body.classList.toggle('large-type',Number(scale)>=2);document.title='PyQuest · '+t.title;
 document.querySelectorAll('[data-copy]').forEach(n=>n.textContent=t[n.dataset.copy]);$('#language').value=lang;$('#scale').value=scale;$('#calm').checked=calm;$('#back').setAttribute('aria-label',t.back);$('#back').disabled=ready&&state.view==='room'&&!state.selected;
 $('.view-tabs').setAttribute('aria-label',t.room+' / '+t.cabinet);$('.filter-tabs').setAttribute('aria-label',t.badgeLabel);
 const fs=$('#fixture');fs.replaceChildren();M.fixtures.forEach((id,i)=>{const o=document.createElement('option');o.value=id;o.textContent=labels[lang][i];fs.append(o)});fs.value=state.fixture;
 $('#phone-link').href=`?phone=1&lang=${lang}&scale=${scale}&state=${state.fixture}`;
 $('#owned-count').textContent=ready?`${state.earned.length} / 15 ${t.owned}`:'— / 15';
 document.querySelectorAll('[data-view]').forEach(b=>{b.setAttribute('aria-pressed',String(state.view===b.dataset.view&&!state.selected));b.disabled=!ready});
 $('#room').hidden=!ready||state.view!=='room'||!!state.selected;$('#cabinet').hidden=!ready||state.view!=='cabinet'||!!state.selected;$('#detail').hidden=!ready||!state.selected;$('#load-state').hidden=ready;
 $('#room-title').textContent=state.earned.length?t.roomTitle:t.emptyTitle;$('#room-body').textContent=state.earned.length?t.roomBody:t.emptyBody;
 $('.room-art').alt=lang==='vi'?'Phòng 2,5D với tủ huy hiệu và ba bục trống; huy hiệu được hiển thị bằng lớp UI riêng.':'A 2.5D room with a badge cabinet and three empty plinths; sample badges are separate UI overlays.';
 const plinths=$('#plinth-badges');plinths.replaceChildren();if(ready)for(const key of state.earned.slice(0,3)){const b=M.badge(state,key,lang),button=document.createElement('button');button.type='button';button.className='scene-badge';button.setAttribute('aria-label',t.inspect+': '+b.title+' · '+t.sample);button.append(medal(b));button.addEventListener('click',()=>open(key,key));plinths.append(button)}
 document.querySelectorAll('[data-filter]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.filter===state.filter)));
 if($('#search').value!==state.query)$('#search').value=state.query;$('#search').placeholder=t.search;$('#search').setAttribute('aria-label',t.search);$('#clear-search').setAttribute('aria-label',t.clear);
 const items=M.list(state,lang),list=$('#badge-list');list.replaceChildren();$('#result-count').textContent=`${items.length} ${t.results}`;$('#no-results').hidden=items.length!==0;
 for(const b of items){const button=document.createElement('button');button.type='button';button.className='badge-row';button.dataset.key=b.key;const words=document.createElement('span');words.className='words';const name=document.createElement('strong'),status=document.createElement('small');name.textContent=b.title;status.textContent=b.earned?t.earned:b.secret?t.secret:t.locked;words.append(name,status);button.append(medal(b),words);button.addEventListener('click',()=>open(b.key,b.key));list.append(button)}
 // Remove prior detail text from the DOM as well as hiding the panel on back/error.
 for(const id of ['detail-title','detail-description','how-text','detail-note','detail-state','progress-label'])$('#'+id).textContent='';$('#detail-medal').replaceChildren();$('#how-to').hidden=true;$('#progress-box').hidden=true;
 if(ready&&state.selected){const b=M.badge(state,state.selected,lang);$('#detail-medal').append(medal(b));$('#detail-state').textContent=b.earned?(b.secret?t.reveal:t.recorded):b.secret?t.secret:t.locked;$('#detail-title').textContent=b.title;$('#detail-description').textContent=b.description;
 if(b.howTo){$('#how-to').hidden=false;$('#how-text').textContent=b.howTo}
 if(!b.earned&&b.goal!==null){$('#progress-box').hidden=false;$('#progress').hidden=b.progress===null;$('#progress').max=b.goal;$('#progress').value=b.progress||0;$('#progress-label').textContent=b.progress===null?t.unknownProgress:`${t.progress} · ${b.progress} / ${b.goal}`;}
 $('#detail-note').textContent=b.secret&&!b.earned?t.secretNote:b.earned?t.recordedNote+' '+t.noDate:t.sample;
 }
 $('#load-title').textContent=state.status==='loading'?t.loadingTitle:t.errorTitle;$('#load-body').textContent=state.status==='loading'?t.loadingBody:t.errorBody;$('#retry').hidden=state.status!=='error';
 $('#resolve').disabled=$('#fail').disabled=state.status!=='loading';$('#trace').textContent=`fixture: ${state.fixture}\nview: ${state.view}\nstatus: ${state.status}\nrequest: ${state.request??'—'}\nearned(sample): ${state.earned.length}\nawards/claims/writes: 0${note?'\n'+note:''}`;
 $('#announce').textContent=ready?(state.selected?M.badge(state,state.selected,lang).title:state.view==='cabinet'?items.length+' '+t.results:$('#room-title').textContent):$('#load-title').textContent;
}
$('#language').addEventListener('change',e=>{lang=e.target.value;render()});$('#scale').addEventListener('change',e=>{scale=e.target.value;render()});$('#calm').addEventListener('change',e=>{calm=e.target.checked;render()});$('#fixture').addEventListener('change',e=>{state=M.create(e.target.value);note='';render();$('#screen').scrollTop=0});
for(const b of document.querySelectorAll('[data-view]'))b.addEventListener('click',()=>{apply({type:'view',view:b.dataset.view});$('#screen').scrollTop=0});
for(const b of document.querySelectorAll('[data-filter]'))b.addEventListener('click',()=>apply({type:'filter',filter:b.dataset.filter}));
for(const id of ['open-cabinet','cabinet-hotspot'])$('#'+id).addEventListener('click',()=>{apply({type:'view',view:'cabinet'});$('#screen').scrollTop=0;$('#search').focus({preventScroll:true})});
$('#search').addEventListener('input',e=>apply({type:'search',query:e.target.value}));for(const id of ['clear-search','reset-search'])$('#'+id).addEventListener('click',()=>{apply({type:'search',query:''});$('#search').focus()});
$('#back').addEventListener('click',back);$('#detail-back').addEventListener('click',back);document.addEventListener('keydown',e=>{if(e.key==='Escape'&&state.selected){e.preventDefault();back()}});
$('#retry').addEventListener('click',()=>apply({type:'retry'}));$('#resolve').addEventListener('click',()=>apply({type:'resolve',token:state.request,ok:true}));$('#fail').addEventListener('click',()=>apply({type:'resolve',token:state.request,ok:false}));$('#late').addEventListener('click',()=>apply({type:'resolve',token:state.generation-1,ok:true}));
window.W14Study={snapshot:()=>structuredClone(state),fixture:id=>{state=M.create(id);render()},dispatch:apply,preferences:p=>{if(p.lang)lang=p.lang;if(p.scale)scale=String(p.scale);if(typeof p.calm==='boolean')calm=p.calm;render()},publicRows:()=>M.list(state,lang)};render();
