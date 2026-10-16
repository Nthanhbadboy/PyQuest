import {normalizePreference,resolveLanguage,storageKey,translate} from './locale-core.mjs';
// A small adapter for the two HTML review prototypes, NOT the Flutter localization architecture.
let preference='system',saveMessage='';
try{preference=normalizePreference(localStorage.getItem(storageKey));}catch{}
const languages=()=>navigator.languages?.length?navigator.languages:[navigator.language];
let resolved=resolveLanguage(preference,languages());
const originals=new WeakMap(),attributes=new WeakMap();
const skip='script,style,code,pre,textarea,[data-no-translate]';
export const language=()=>resolved.language;
export const getPreference=()=>preference;
export function applyExternalPreference(value){if(!['system','vi','en'].includes(value)||value===preference)return;preference=value;saveMessage='';refresh();}
export const t=s=>translate(s,resolved.language);
export function localize(root=document.body){
 if(!root)return;
 const walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT);let node;
 while((node=walker.nextNode())){
  if(node.parentElement?.closest(skip)||!node.nodeValue.trim())continue;
  const prior=originals.get(node),raw=prior&&node.nodeValue===prior.written?prior.source:node.nodeValue;
  const trimmed=raw.trim(),mapped=t(trimmed),written=raw.replace(trimmed,()=>mapped);
  originals.set(node,{source:raw,written});if(node.nodeValue!==written)node.nodeValue=written;
 }
 for(const el of root.querySelectorAll('[aria-label],[alt],[title],[placeholder]')){
  if(el.closest('[data-no-translate]'))continue;
  let record=attributes.get(el);if(!record){record={};attributes.set(el,record);}
  for(const key of ['aria-label','alt','title','placeholder']){
   const value=el.getAttribute(key);if(value===null)continue;
   const prior=record[key],source=prior&&value===prior.written?prior.source:value,written=t(source);
   record[key]={source,written};if(value!==written)el.setAttribute(key,written);
  }
 }
}
const originalTitle=document.title;
const style=document.createElement('link');style.rel='stylesheet';style.href=new URL('./settings.css',import.meta.url).href;document.head.append(style);
const trigger=document.createElement('button');trigger.id='language-settings';trigger.type='button';trigger.className='language-settings';trigger.textContent='⚙';trigger.setAttribute('aria-label','Cài đặt');trigger.setAttribute('title','Ngôn ngữ');
(document.querySelector('.topbar,.site-header')||document.body).append(trigger);
const dialog=document.createElement('dialog');dialog.id='language-dialog';dialog.setAttribute('aria-labelledby','language-title');dialog.innerHTML=`<div class="language-header"><h2 id="language-title">Cài đặt</h2><button type="button" id="language-close" aria-label="Đóng cài đặt">×</button></div><label for="language-choice">Ngôn ngữ</label><select id="language-choice"><option value="system">Theo hệ thống</option><option value="vi" lang="vi" data-no-translate>Tiếng Việt</option><option value="en" lang="en" data-no-translate>English</option></select><p id="language-effective"></p><p id="language-system"></p><p>Giao diện, lời Tutor và bảng giảng cùng dùng lựa chọn này.</p><p>Áp dụng ngay, giữ nguyên bài đang làm.</p><small>Chỉ có Tiếng Việt và English trong mẫu này. Nội dung mới phải có gói dịch được kiểm tra.</small><p id="language-save" role="status"></p>`;document.body.append(dialog);
function refresh(){
 resolved=resolveLanguage(preference,languages());document.documentElement.lang=resolved.language;document.documentElement.dir='ltr';document.title=t(originalTitle);
 document.querySelector('#language-choice').value=preference;
 document.querySelector('#language-effective').textContent='Đang dùng: '+(resolved.language==='vi'?'Tiếng Việt':'English');
 document.querySelector('#language-system').textContent=resolved.fallback?'Ngôn ngữ hệ thống chưa được hỗ trợ; dùng English.':resolved.matched?'Ngôn ngữ hệ thống đang dùng: '+resolved.matched:'';
 document.querySelector('#language-save').textContent=saveMessage;
 localize();window.dispatchEvent(new CustomEvent('pyquest:languagechange',{detail:{...resolved}}));
}
export function setPreference(value){preference=normalizePreference(value);try{localStorage.setItem(storageKey,preference);saveMessage='Đã lưu lựa chọn ngôn ngữ trên trình duyệt này.';}catch{saveMessage='Không thể lưu ở trình duyệt này; lựa chọn chỉ áp dụng trong phiên.';}refresh();}
trigger.onclick=()=>{refresh();dialog.showModal();document.querySelector('#language-choice').focus();};
document.querySelector('#language-close').onclick=()=>dialog.close();dialog.addEventListener('close',()=>trigger.focus({preventScroll:true}));
document.querySelector('#language-choice').onchange=e=>setPreference(e.target.value);
window.addEventListener('languagechange',refresh);
window.addEventListener('storage',e=>{if(e.key===storageKey||e.key===null){preference=normalizePreference(e.newValue);saveMessage='';refresh();}});
// Runs after prototype click handlers; render/timer code also calls localize explicitly.
document.addEventListener('click',()=>localize());
refresh();
