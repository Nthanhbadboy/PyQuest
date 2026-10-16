import {en} from './en.mjs';
export const preferences=['system','vi','en'];
export const storageKey='pyquest.prototype.language.v1';
export function normalizePreference(value){return preferences.includes(value)?value:'system';}
export function resolveLanguage(preference='system',languages=[]){
 const pref=normalizePreference(preference);
 if(pref!=='system')return {language:pref,preference:pref,matched:null,fallback:false};
 for(const candidate of Array.isArray(languages)?languages:[]){
  if(typeof candidate!=='string')continue;
  try{const tag=Intl.getCanonicalLocales(candidate)[0],base=tag.split('-')[0];if(base==='vi'||base==='en')return {language:base,preference:'system',matched:tag,fallback:false};}catch{}
 }
 return {language:'en',preference:'system',matched:null,fallback:true};
}
const escapeRegex=s=>s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
const templates=Object.entries(en).filter(([k])=>/\{\d+\}/.test(k)).map(([key,value])=>{
 const ids=[...key.matchAll(/\{(\d+)\}/g)].map(m=>m[1]);
 const pattern=key.split(/\{\d+\}/).map(escapeRegex).join('(.+?)');
 return {regex:new RegExp('^'+pattern+'$','u'),value,ids};
});
export function translate(source,language='vi'){
 if(language!=='en'||typeof source!=='string')return source;
 if(Object.hasOwn(en,source))return en[source];
 for(const entry of templates){const match=source.match(entry.regex);if(!match)continue;const values=Object.fromEntries(entry.ids.map((id,i)=>[id,translate(match[i+1],language)]));return entry.value.replace(/\{(\d+)\}/g,(_,id)=>values[id]);}
 return source;
}
