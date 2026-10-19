/* Design-only state simulator. No app, persistence, entitlement or network authority. */
(function(root){
'use strict';
const states=['overview','public_ready','private_ready','content_preview','eligibility_missing','permission_unknown','permission_denied','pack_missing','downloading','download_error','confirm','loading','load_error','cancelled','sailing','arrived','revoked','offline','return_confirm'];
const busy=['loading','downloading','sailing'];
function fixture(state='overview'){
 if(!states.includes(state))throw Error('Unknown design fixture');
 const content=['content_preview','pack_missing','downloading','download_error'].includes(state);
 const s={state,current:'village',selected:content?'forest':'home',generation:0,request:null,access:true,packReady:true,loaded:false,arrivals:0,energyDelta:0,rewardDelta:0,privateDetails:null,homeEligible:state!=='eligibility_missing',online:state!=='offline',departure:'village',rights:{village:'granted',home:'granted',forest:content&&state!=='content_preview'?'granted':'unknown'},forestPackReady:false};
 if(state==='overview')s.selected=null;
 if(state==='public_ready'){s.selected='village';s.current='home';s.departure='home';}
 if(['permission_unknown','permission_denied','content_preview','revoked'].includes(state))s.access=false;
 if(state==='permission_unknown')s.rights.home='unknown';
 if(['permission_denied','revoked'].includes(state))s.rights.home='denied';
 if(['pack_missing','downloading','download_error'].includes(state))s.packReady=false;
 if(busy.includes(state)){s.generation=1;s.request={id:1,kind:state==='downloading'?'download':'travel',from:s.current,to:s.selected};s.loaded=state==='sailing';}
 if(state==='arrived'){s.current='home';s.arrivals=1;}
 if(state==='return_confirm'){s.current='home';s.selected='village';s.departure='home';}
 return s;
}
function step(previous,event){
 const s={...previous,rights:{...previous.rights},request:previous.request?{...previous.request}:null};
 const invalidate=()=>{s.generation++;s.request=null;s.loaded=false;};
 switch(event.type){
 case 'select':
  if(busy.includes(s.state)||!['village','home','forest'].includes(event.destination))return previous;
  invalidate();s.selected=event.destination;s.departure=s.current;s.access=s.rights[event.destination]==='granted';s.packReady=event.destination!=='forest'||s.forestPackReady;
  s.state=!s.online?'offline':event.destination==='home'&&!s.homeEligible?'eligibility_missing':s.rights[event.destination]==='denied'?'permission_denied':!s.access?(event.destination==='forest'?'content_preview':'permission_unknown'):!s.packReady?'pack_missing':({village:'public_ready',home:'private_ready',forest:'confirm'})[event.destination];break;
 case 'confirm':
  if(!['public_ready','private_ready'].includes(s.state)||s.selected===s.current||!s.access||!s.packReady||(s.selected==='home'&&!s.homeEligible))return previous;
  s.state='confirm';break;
 case 'begin':
  if(!s.online){s.state='offline';return s;}
  if(!['confirm','return_confirm'].includes(s.state)||!s.access||!s.packReady||!s.selected||s.selected===s.current||(s.selected==='home'&&!s.homeEligible))return previous;
  s.generation++;s.request={id:s.generation,kind:'travel',from:s.current,to:s.selected};s.loaded=false;s.state='loading';break;
 case 'download':
  if(!['pack_missing','download_error'].includes(s.state)||!s.access)return previous;
  s.generation++;s.request={id:s.generation,kind:'download',from:s.current,to:s.selected};s.state='downloading';break;
 case 'response':
  if(!s.request||s.request.id!==event.token||!['loading','downloading'].includes(s.state))return previous;
  if(!event.access){invalidate();s.access=false;s.rights[s.selected]='denied';s.state='permission_denied';s.privateDetails=null;break;}
  if(!event.ok){const downloading=s.state==='downloading';invalidate();s.state=downloading?'download_error':'load_error';break;}
  if(s.state==='downloading'){invalidate();s.packReady=true;if(s.selected==='forest')s.forestPackReady=true;s.state='confirm';}
  else{s.loaded=true;s.access=true;s.state='sailing';}
  break;
 case 'arrive':
  if(s.state!=='sailing'||!s.request||!s.loaded||!s.access||!s.packReady||(s.selected==='home'&&!s.homeEligible))return previous;
  s.current=s.request.to;s.request=null;s.arrivals++;s.state='arrived';break;
 case 'cancel':
  if(!['loading','downloading','sailing','confirm','return_confirm'].includes(s.state))return previous;
  invalidate();s.state='cancelled';break;
 case 'retry':
  if(!['load_error','cancelled','offline'].includes(s.state)||!s.selected)return previous;
  invalidate();s.state=!s.online?'offline':!s.access?'permission_unknown':!s.packReady?'pack_missing':'confirm';break;
 case 'return':
  if(s.current==='village'){invalidate();s.selected=null;s.state='overview';break;}
  invalidate();s.departure=s.current;s.selected='village';s.access=true;s.packReady=true;s.state='return_confirm';break;
 case 'overview': invalidate();s.selected=null;s.state='overview';break;
 case 'revoke':
  invalidate();s.current='village';s.selected='home';s.departure='village';s.access=false;s.rights.home='denied';s.privateDetails=null;s.state='revoked';break;
 case 'offline': invalidate();s.online=false;s.state='offline';break;
 case 'online': s.online=true;if(s.state==='offline')s.state=!s.selected?'overview':s.selected===s.current?'arrived':!s.access?'permission_unknown':!s.packReady?'pack_missing':'confirm';break;
 default:return previous;
 }
 return s;
}
const api={states,busy,fixture,step};if(typeof module!=='undefined')module.exports=api;root.TravelStudy=api;
})(typeof window!=='undefined'?window:globalThis);
