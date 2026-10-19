// P06 design simulation ONLY. No identities, server permissions, moderation service or delivery.
export const people = Object.freeze({
 may: Object.freeze({name:'Mây',avatar:'fox',interest:'mazeInterest',work:'mayMaze'}),
 bo: Object.freeze({name:'Bo',avatar:'owl',interest:'artInterest',work:'boGarden'}),
 la: Object.freeze({name:'Lá',avatar:'rabbit',interest:'craftInterest',work:'laCard'}),
});
export const fixtures = ['default','empty','incoming','outgoing','offline','limited','private','moderation','pending','failed','blocked','declined'];
export const papers=['cream','mint','peach'];
export const stamps=['flower','star','leaf','sun'];
export const wishes=['thanks','keepGoing','playTogether'];
export const compliments=['clever','beautiful','inspiring'];
export const reasons=['content','unwanted','other'];
export const items=['maze','art','badge'];
const clone=x=>JSON.parse(JSON.stringify(x));
export class SocialSession {
 constructor(fixture='default') {
  if(!fixtures.includes(fixture))throw new Error('Unknown fixture');
  this.fixture=fixture;this.view='home';this.person='may';this.mode='ready';this.friends=new Set(['may','bo']);
  this.blocked=new Set();this.privateProfiles=new Set();this.heldWorks=new Set();this.requests={};this.reactions={};this.mail=[];this.reports=[];
  this.audience='private';this.displayed=new Set(['maze','badge']);this.previewAsFriend=false;
  this.draft={paper:'cream',wish:'thanks',slots:['flower',null,'star',null,'leaf',null],revision:0};this.history=[];this.selectedStamp='flower';this.recipient='may';this.activeMail=null;
  if(fixture==='empty'){this.friends.clear();this.recipient='';}
  if(fixture==='incoming')this.requests.la='incoming';
  if(fixture==='outgoing')this.requests.la='pending';
  if(fixture==='offline')this.mode='offline';
  if(fixture==='limited')this.mode='limited';
  if(fixture==='private'){this.privateProfiles.add('may');this.view='visit';}
  if(fixture==='moderation'){this.heldWorks.add('mayMaze');this.view='work';}
  if(['pending','failed','declined'].includes(fixture)){this.sendGift();this.view='mail';if(fixture!=='pending')this.resolveMail(this.activeMail,fixture);}
  if(fixture==='blocked'){this.block('may');this.view='home';}
 }
 navigate(view,person=this.person){if(!['home','visit','work','mine','craft','review','mail'].includes(view))throw new Error('Unknown view');if(!people[person])throw new Error('Unknown person');this.view=view;this.person=person;}
 reason(id){if(!people[id])return 'unknown';if(this.blocked.has(id))return 'blocked';if(this.mode==='offline')return 'offline';if(this.mode==='limited')return 'limited';if(!this.friends.has(id))return 'notFriend';if(this.privateProfiles.has(id))return 'private';return null;}
 canView(id){return !!people[id]&&this.friends.has(id)&&!this.blocked.has(id)&&!this.privateProfiles.has(id)&&this.mode!=='limited';}
 canReact(id){return !this.reason(id)&&!this.heldWorks.has(people[id].work);}
 lookup(code){return code.trim().toUpperCase()==='LA006'?'la':null;}
 inviteFriend(id){if(!people[id])return 'unknown';if(this.blocked.has(id))return 'blocked';if(this.mode!=='ready')return this.mode;if(this.friends.has(id))return 'alreadyFriend';if(['incoming','pending'].includes(this.requests[id]))return 'alreadyPending';this.requests[id]='pending';return 'pending';}
 answerRequest(id,accept){if(this.requests[id]!=='incoming')return false;if(this.mode!=='ready'||this.blocked.has(id))return false;this.requests[id]=accept?'accepted':'declined';if(accept)this.friends.add(id);return true;}
 resolveFriend(id,accept){if(this.requests[id]!=='pending'||this.mode!=='ready'||this.blocked.has(id))return false;this.requests[id]=accept?'accepted':'declined';if(accept)this.friends.add(id);return true;}
 cancelRequest(id){if(this.requests[id]!=='pending')return false;this.requests[id]='canceled';return true;}
 react(id,kind){if(!compliments.includes(kind)||!this.canReact(id))return false;this.reactions[people[id].work]=kind;return true;}
 setAudience(value){if(!['private','friends'].includes(value))return false;if(value==='friends'&&this.mode==='limited')return false;this.audience=value;return true;}
 toggleItem(id){if(!items.includes(id))return false;if(this.displayed.has(id))this.displayed.delete(id);else this.displayed.add(id);return true;}
 visibleOwnItems(asFriend=this.previewAsFriend){return asFriend?(this.audience==='friends'?[...this.displayed]:[]):[...items];}
 editDraft(change){this.history.push(clone(this.draft));if(this.history.length>30)this.history.shift();this.draft={...this.draft,...change,revision:this.draft.revision+1};}
 setPaper(value){if(!papers.includes(value)||value===this.draft.paper)return false;this.editDraft({paper:value});return true;}
 setWish(value){if(!wishes.includes(value)||value===this.draft.wish)return false;this.editDraft({wish:value});return true;}
 place(slot){if(!Number.isInteger(slot)||slot<0||slot>=6||!stamps.includes(this.selectedStamp))return false;const slots=[...this.draft.slots];slots[slot]=slots[slot]===this.selectedStamp?null:this.selectedStamp;this.editDraft({slots});return true;}
 undo(){if(!this.history.length)return false;const before=this.history.pop();this.draft={...before,revision:this.draft.revision+1};return true;}
 clear(){if(this.draft.slots.every(x=>x===null))return false;this.editDraft({slots:Array(6).fill(null)});return true;}
 sendGift(){const error=this.reason(this.recipient);if(error)return {ok:false,reason:error};const id=`gift-${this.recipient}-${this.draft.revision}`;let mail=this.mail.find(x=>x.id===id);if(!mail){mail={id,kind:'gift',recipient:this.recipient,status:'pending',draft:clone(this.draft)};this.mail.push(mail);}this.activeMail=id;return {ok:true,id};}
 invitePlay(id){const error=this.reason(id);if(error)return {ok:false,reason:error};if(this.heldWorks.has(people[id].work))return {ok:false,reason:'moderation'};const key=`play-${id}`;if(!this.mail.some(x=>x.id===key))this.mail.push({id:key,kind:'play',recipient:id,status:'pending'});this.activeMail=key;return {ok:true,id:key};}
 resolveMail(id,status){const mail=this.mail.find(x=>x.id===id);if(!mail||!['delivered','failed','declined'].includes(status)||!['pending','failed'].includes(mail.status))return false;if(this.reason(mail.recipient))return false;mail.status=status;return true;}
 retryMail(id){const mail=this.mail.find(x=>x.id===id);if(!mail||mail.status!=='failed'||this.reason(mail.recipient))return false;mail.status='pending';return true;}
 block(id){if(!people[id])return false;this.blocked.add(id);this.friends.delete(id);if(this.requests[id])this.requests[id]='canceled';for(const mail of this.mail)if(mail.recipient===id&&['pending','failed'].includes(mail.status))mail.status='canceled';return true;}
 unblock(id){return this.blocked.delete(id);}
 report(id,reason){if(!people[id]||!reasons.includes(reason))return false;if(!this.reports.some(x=>x.person===id&&x.reason===reason))this.reports.push({person:id,reason,status:'local-only'});return true;}
 snapshot(){return clone({fixture:this.fixture,view:this.view,person:this.person,mode:this.mode,friends:[...this.friends],blocked:[...this.blocked],requests:this.requests,reactions:this.reactions,mail:this.mail,reports:this.reports,audience:this.audience,displayed:[...this.displayed],draft:this.draft,activeMail:this.activeMail,recipient:this.recipient});}
}
