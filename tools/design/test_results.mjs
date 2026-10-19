import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {Session,scenarios,frames,level,evaluate} from '../../docs/design/result-adventure-prototype/model.mjs';
import {messages,copy} from '../../docs/design/result-adventure-prototype/copy.mjs';
const root=new URL('../../',import.meta.url);
test('rm_01 fixture and cost mirror source; four commands is a goal not an input cap',()=>{
 const source=JSON.parse(readFileSync(new URL('app/assets/data/robot_maze_levels.json',root))).levels[0];
 assert.equal(level.id,source.id);assert.deepEqual([...level.rows],source.rows);assert.equal(level.command_limit,source.command_limit);
 const config=JSON.parse(readFileSync(new URL('app/assets/config/game_config.json',root)));
 assert.equal(new Session().nextCost,config.energy_costs.mini_game_new_level);assert.equal(config.energy_costs.mini_game_replay_completed,0);
 assert.deepEqual(evaluate(['R','R','R','R']),{success:true,goals:[true,true,true],used:4,stars:3,score:100,position:{x:4,y:1}});
 const slow=evaluate(['R','L','R','R','R','R']);assert.equal(slow.score,70);assert.equal(slow.stars,2);
});
test('failure has no earned stars or award, and retains program for retry',()=>{
 const s=new Session('r04');assert.equal(s.outcome.success,false);assert.equal(s.outcome.stars,0);assert.equal(s.writes,0);assert.equal(s.owned.size,0);
 s.navigate('play');assert.deepEqual(s.program,['R','R']);s.addCommand('R');s.addCommand('R');s.run();assert.equal(s.outcome.success,true);assert.equal(s.owned.size,1);assert.equal(s.writes,1);
});
test('pending/error states never claim a reward or saved score before ack',()=>{
 for(const id of ['r06','r06error']){const s=new Session(id);assert.equal(s.owned.size,0);assert.equal(s.bestScore,0);assert.equal(s.writes,0);assert.deepEqual(s.visibleNotices,[]);s.restore();assert.equal(s.writes,0);s.ack();assert.equal(s.writes,1);assert.equal(s.owned.size,1);assert.equal(s.status,'saved');assert.equal(s.visibleNotices.length,1);}
});
test('retrying the same token is idempotent, even after navigating away',()=>{
 const s=new Session('r06');s.failSave();s.navigate('home');assert.equal(s.status,'error');s.ack();const before=s.snapshot();for(let i=0;i<10;i++)s.ack();assert.deepEqual(s.snapshot(),before);
});
test('replay never awards first_steps twice and never reduces best',()=>{
 const s=new Session();assert.equal(s.visibleNotices.length,1);s.program=['R','L','R','R','R','R'];s.run();assert.equal(s.outcome.score,70);assert.equal(s.bestScore,100);assert.equal(s.owned.size,1);assert.deepEqual(s.visibleNotices,[]);assert.equal(s.writes,2);
});
test('new best is distinct from new award',()=>{const s=new Session('r03');assert.equal(s.bestScore,100);assert(s.outcome.newHighScore);assert.deepEqual(s.visibleNotices,[]);});
test('navigation, repeated render and restored page do not replay celebrations',()=>{
 const s=new Session();assert(s.consumeCelebration());assert(!s.consumeCelebration());s.navigate('hall');s.navigate('result');assert(!s.consumeCelebration());s.restore();assert(!s.consumeCelebration());assert.equal(s.celebrations,1);assert.equal(s.writes,1);
});
test('calm consumes a presentation without animating; turning calm off cannot replay it',()=>{const s=new Session();assert(!s.consumeCelebration(true));assert(!s.consumeCelebration(false));assert.equal(s.celebrations,0);});
test('restore suppresses old new-award notices without deleting ownership',()=>{const s=new Session();s.restore();assert.equal(s.owned.size,1);assert.deepEqual(s.visibleNotices,[]);});
test('multiple notices retain kinds; quest notification does not mint another badge',()=>{const s=new Session('r09');assert.deepEqual(s.visibleNotices,[{kind:'badge',id:'first_steps'},{kind:'quest',id:'three_stars'}]);assert.equal(s.owned.size,1);});
test('all 14 fixtures and eight storyboard destinations exist and remain read-only on navigation',()=>{
 assert.equal(scenarios.length,14);assert.equal(frames.length,8);
 for(const id of scenarios){const s=new Session(id),before=s.snapshot();for(const frame of [...frames,'play','rest','home'])s.navigate(frame);assert.equal(s.writes,before.writes);assert.deepEqual([...s.owned],before.owned);}
 assert.throws(()=>new Session('unknown'));assert.throws(()=>new Session().navigate('unknown'));assert.throws(()=>new Session().addCommand('eval'));
});
test('snapshot cannot mutate program, notices or earned awards',()=>{const s=new Session();const snap=s.snapshot();snap.program.push('U');snap.owned.length=0;snap.visibleNotices[0].id='fake';assert.equal(s.program.length,4);assert(s.owned.has('first_steps'));assert.equal(s.visibleNotices[0].id,'first_steps');});
test('VI/EN cover every copy key with identical named placeholders',()=>{
 for(const [key,pair] of Object.entries(messages)){assert.equal(pair.length,2);assert(pair.every(x=>typeof x==='string'&&x.length));const slots=x=>[...x.matchAll(/\{(\w+)\}/g)].map(m=>m[1]).sort();assert.deepEqual(slots(pair[0]),slots(pair[1]),key);const args=Object.fromEntries(slots(pair[0]).map(k=>[k,'TEST']));for(const lang of ['vi','en'])assert(!copy(lang,key,args).includes('{'));}
 assert.throws(()=>copy('vi','madeUp'));assert.throws(()=>copy('en','stars'));
});
test('source and reused art manifest hashes are reproducible',()=>{
 const manifest=JSON.parse(readFileSync(new URL('docs/design/result-adventure-prototype/manifest.json',root)));
 for(const entry of [...manifest.sources,...manifest.assets]){const bytes=readFileSync(new URL(entry.path,root));assert.equal(createHash('sha256').update(bytes).digest('hex'),entry.sha256,entry.path);}
});
