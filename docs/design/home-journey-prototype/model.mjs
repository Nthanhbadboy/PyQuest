// P06C design-only local ledger. No app economy, events, payments or persistence.
import {simulate} from '../first-play-prototype/engine.mjs';
export const maze={id:'rm_01',rows:['#####','S...C','#####'],command_limit:4};
export const jobs={maze:{wood:2,cloth:0},bridge:{wood:1,cloth:2}};
export const cost={wood:3,cloth:2};
export const fixtures=['start','partial','ready','pending','failed','built','offline'];
const clone=x=>JSON.parse(JSON.stringify(x));
export class Journey {
 constructor(fixture='start'){
  if(!fixtures.includes(fixture))throw Error('Unknown fixture');
  this.fixture=fixture;this.view='home';this.bag={wood:0,cloth:0};this.badges=new Set();this.claims=new Set();this.pendingRuns={};this.log=[];
  this.commands=[];this.planks=[1,0,1];this.result=null;this.run=0;this.build='idle';this.room=false;this.online=fixture!=='offline';this.pet='rest';
  if(['partial','ready','pending','failed','built'].includes(fixture))this.seed('maze');
  if(['ready','pending','failed','built'].includes(fixture))this.seed('bridge');
  if(['pending','failed','built'].includes(fixture)){this.beginBuild();if(fixture==='failed')this.settleBuild(false);if(fixture==='built')this.settleBuild(true);}
  if(fixture!=='start')this.view=fixture==='built'?'room':'project';
 }
 seed(job){this.playFixture(job);this.claim();}
 playFixture(job){if(job==='maze')this.commands=['R','R','R','R'];else this.planks=[0,0,0];this.play(job);}
 navigate(view){if(!['home','project','quests','maze','bridge','result','room'].includes(view))throw Error('Unknown view');if(view==='room'&&!this.room)return false;this.view=view;return true;}
 add(dir){if(!['L','R','U','D'].includes(dir)||this.commands.length>=16)return false;this.commands.push(dir);return true;}
 undo(){return this.commands.pop()||null;}
 clear(){this.commands=[];}
 rotate(i){if(!Number.isInteger(i)||i<0||i>2)return false;this.planks[i]=1-this.planks[i];return true;}
 play(job){if(!Object.hasOwn(jobs,job))throw Error('Unknown job');const outcome=job==='maze'?simulate(maze,this.commands):{outcome:this.planks.every(p=>p===0)?'success':'incomplete'};this.run++;
  this.result={id:`run-${this.run}`,job,success:outcome.outcome==='success',outcome:outcome.outcome,position:outcome.position||null,claimed:false};if(this.result.success&&!this.pendingRuns[job])this.pendingRuns[job]=clone(this.result);this.view='result';return clone(this.result);
 }
 showReward(job){if(!this.pendingRuns[job])return false;this.result={...clone(this.pendingRuns[job]),claimed:this.claims.has(job)};this.view='result';return true;}
 claim(){const r=this.result;if(!r?.success||!this.pendingRuns[r.job]||r.claimed||!this.online||this.claims.has(r.job))return false;
  this.claims.add(r.job);r.claimed=true;for(const kind of ['wood','cloth'])this.bag[kind]+=jobs[r.job][kind];
  const first=!this.badges.has('first_steps');this.badges.add('first_steps');this.log.push({type:'reward',id:`project-reward-${r.job}`,source:r.job,items:clone(jobs[r.job]),badge:first?'first_steps':null});return true;
 }
 get needs(){return {badge:!this.badges.has('first_steps'),wood:Math.max(0,cost.wood-this.bag.wood),cloth:Math.max(0,cost.cloth-this.bag.cloth)};}
 get ready(){const n=this.needs;return !this.room&&!n.badge&&!n.wood&&!n.cloth;}
 get nextJob(){return !this.claims.has('maze')?'maze':!this.claims.has('bridge')?'bridge':null;}
 get next(){return this.room?'room':this.ready?'project':this.nextJob||'project';}
 beginBuild(){if(!this.online||!this.ready||this.build==='pending')return false;this.build='pending';return true;}
 settleBuild(ok){if(this.build!=='pending'||!this.online)return false;if(!ok){this.build='failed';return false;}
  // Recheck at acknowledgement; atomic debit and one room entitlement in this local simulation.
  if(!this.ready){this.build='failed';return false;}for(const kind of ['wood','cloth'])this.bag[kind]-=cost[kind];this.room=true;this.build='built';this.log.push({type:'build',id:'study-room-v1',spent:clone(cost)});return true;
 }
 get progress(){return this.room?3:this.claims.size;}
 snapshot(){return clone({fixture:this.fixture,view:this.view,bag:this.bag,badges:[...this.badges],claims:[...this.claims],earned:Object.keys(this.pendingRuns),log:this.log,commands:this.commands,planks:this.planks,result:this.result,build:this.build,room:this.room,online:this.online,pet:this.pet,ready:this.ready,needs:this.needs,next:this.next,progress:this.progress});}
}
