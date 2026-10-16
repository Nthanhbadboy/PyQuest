import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {simulate} from '../../docs/design/first-play-prototype/engine.mjs';
const fixture=JSON.parse(await readFile(new URL('../../docs/design/first-play-prototype/levels.json',import.meta.url)));
const [first,second]=fixture.levels;
test('fixtures are the first two source levels, not a new gameplay design',async()=>{
 const bytes=await readFile(new URL('../../app/assets/data/robot_maze_levels.json',import.meta.url));
 assert.equal(createHash('sha256').update(bytes).digest('hex'),fixture.source_sha256);
 assert.deepEqual(fixture.levels,JSON.parse(bytes).levels.slice(0,2).map(({solution,...rest})=>rest));
});
test('four right steps reach the chest',()=>{const r=simulate(first,['R','R','R','R']);assert.equal(r.outcome,'success');assert.equal(r.frames.length,4);assert.deepEqual(r.position,{x:4,y:1});});
test('wrong direction identifies the exact failed command',()=>{const r=simulate(first,['R','U']);assert.equal(r.outcome,'collision');assert.equal(r.step,1);assert.deepEqual(r.position,{x:1,y:1});});
test('leaving grid is a collision',()=>{assert.equal(simulate(first,['L']).outcome,'collision');});
test('short program does not invent a win',()=>{assert.equal(simulate(first,['R']).outcome,'incomplete');assert.equal(simulate(first,[]).outcome,'incomplete');});
test('second level collects the real gem before reaching chest',()=>{const r=simulate(second,['R','R','R','D','D','D']);assert.equal(r.outcome,'success');assert.deepEqual(r.collected,['2,0']);assert.equal(r.step,5);});
test('each run starts fresh and inputs stay unchanged',()=>{const before=JSON.stringify(second);const cmds=['R','R'];simulate(second,cmds);assert.equal(simulate(second,[]).collected.length,0);assert.equal(JSON.stringify(second),before);assert.deepEqual(cmds,['R','R']);});
test('unknown command fails instead of fabricating a step',()=>{assert.throws(()=>simulate(first,['X']),/Unknown command/);});
