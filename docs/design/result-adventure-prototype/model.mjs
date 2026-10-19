// Memory-only DESIGN simulation. No app events, persistence, social APIs or currency writes.
import {simulate} from '../first-play-prototype/engine.mjs';
export const level = Object.freeze({id:'rm_01',rows:Object.freeze(['#####','S...C','#####']),command_limit:4});
export const scenarios = ['r01','r02','r03','r04','r05','r06','r06error','r07','r07end','r08','r09','r10','r11','r12'];
export const frames = ['finish','result','reward','badge','hall','next','share','challenge'];
export function evaluate(commands) {
 const run=simulate(level,commands);
 const success=run.outcome==='success';
 const used=success?run.step+1:commands.length;
 // rm_01 has no gems. Match MazeStars: allGems = true on success, even with no gems.
 const goals=[success,success,success&&used<=level.command_limit];
 return {success,goals,used,stars:success?goals.filter(Boolean).length:0,score:success?40+30+(goals[2]?30:0):0,position:run.position};
}
export class Session {
 constructor(scenario='r01') {
  if(!scenarios.includes(scenario))throw new Error('Unknown scenario');
  this.scenario=scenario; this.view='result'; this.program=['R','R','R','R'];
  this.owned=new Set(); this.receipts=new Set(); this.celebrated=new Set();
  this.writes=0; this.celebrations=0; this.runNumber=1; this.bestScore=0;
  this.energy=scenario==='r07'?0:8; this.nextCost=2; this.noNext=scenario==='r07end';
  this.social='unconnected'; this.reopened=false;
  if(['r02','r03','r05','r07','r07end','r08','r12'].includes(scenario)) {
   this.owned.add('first_steps'); this.bestScore=scenario==='r03'?70:100;
  }
  if(['r04','r11'].includes(scenario))this.program=['R','R'];
  if(scenario==='r05')this.program=['R','L','R','R','R','R'];
  this.prepare();
  if(scenario==='r06error')this.status='error';
  else if(scenario!=='r06')this.ack();
  if(scenario==='r08')this.restore();
  if(scenario==='r11')this.view='hall';
  if(scenario==='r12')this.view='share';
 }
 prepare() {
  this.token=`sample-run-${this.runNumber}`;
  this.outcome={...evaluate(this.program),notices:[],newHighScore:false};
  this.status=this.outcome.success?'pending':'attempt'; this.reopened=false;
 }
 ack() {
  if(!this.outcome.success||this.receipts.has(this.token))return false;
  this.receipts.add(this.token); this.writes++; this.reopened=false;
  this.outcome.newHighScore=this.outcome.score>this.bestScore;
  this.bestScore=Math.max(this.bestScore,this.outcome.score);
  if(!this.owned.has('first_steps')) {
   this.owned.add('first_steps'); this.outcome.notices.push({kind:'badge',id:'first_steps'});
  }
  // Authored fixture: three_stars is assumed to be an active, previously incomplete daily quest.
  if(this.scenario==='r09'&&this.runNumber===1)this.outcome.notices.push({kind:'quest',id:'three_stars'});
  this.status='saved'; return true;
 }
 failSave() {if(this.status==='pending')this.status='error';}
 restore() {this.reopened=true;this.view='result';}
 navigate(view) {
  if(![...frames,'play','home','rest'].includes(view))throw new Error('Unknown view');
  this.view=view;
 }
 run() {this.runNumber++;this.prepare();this.ack();this.view='result';}
 addCommand(command) {if(!['L','R','U','D'].includes(command))throw new Error('Unknown command');this.program.push(command);}
 consumeCelebration(calm=false) {
  if(this.view!=='result'||this.status!=='saved'||this.reopened||this.celebrated.has(this.token))return false;
  this.celebrated.add(this.token);
  if(calm)return false;
  this.celebrations++;return true;
 }
 get visibleNotices() {return this.status==='saved'&&!this.reopened?this.outcome.notices:[];}
 snapshot() {return {scenario:this.scenario,view:this.view,status:this.status,token:this.token,program:[...this.program],bestScore:this.bestScore,owned:[...this.owned],writes:this.writes,celebrations:this.celebrations,visibleNotices:this.visibleNotices.map(n=>({...n})),score:this.outcome.score,stars:this.outcome.stars,energy:this.energy};}
}
