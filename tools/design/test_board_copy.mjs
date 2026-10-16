import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const load=async path=>JSON.parse(await readFile(new URL(path,import.meta.url),'utf8'));
const source=await load('../../docs/design/tutor-board-prototype/lessons.json');
const copy=await load('../../docs/design/tutor-board-prototype/authored-copy.v1.json');
const dataset=await readFile(new URL('../../app/assets/data/main_quest_ch1.json',import.meta.url));
test('copy references the same pinned source dataset and two examples',()=>{
 assert.equal(copy.sourceDatasetSha256,createHash('sha256').update(dataset).digest('hex'));
 assert.deepEqual(copy.plans.map(p=>[p.id,p.lessonId,p.sourceStep]),source.plans.map(p=>[p.id,p.lesson_id,p.source_step]));
 assert.deepEqual(copy.languages,['vi','en']);
});
test('all eight beats have stable unique IDs and authored text alternatives in both languages',()=>{
 const ids=new Set();let count=0;
 for(const p of copy.plans){const original=source.plans.find(x=>x.id===p.id);assert.equal(p.beats.length,original.beats.length);
  for(const [i,b] of p.beats.entries()){assert.equal(b.beatId,`${p.sourceStep}.b${i+1}`);assert(!ids.has(b.beatId));ids.add(b.beatId);assert.equal(b.sourceBeatIndex,i);
   for(const lang of copy.languages){assert.deepEqual(Object.keys(b.copy[lang]).sort(),['altText','caption','say','title']);for(const value of Object.values(b.copy[lang])){assert(value.trim().length>0);assert([...value].length<=600);}}
   assert.notEqual(b.copy.vi.altText,b.copy.en.altText);count++;
  }
 }
 assert.equal(count,8);
});
test('overlay carries only translated content, never executable ops or grading fields',()=>{
 const forbidden=new Set(['ops','code','expectedOutput','expected_output','answer','answers','rules','challenge','py_line','prerequisite']);
 const walk=o=>{if(!o||typeof o!=='object')return;for(const [key,value] of Object.entries(o)){assert(!forbidden.has(key),key);walk(value);}};walk(copy);
 for(const p of copy.plans){const original=source.plans.find(x=>x.id===p.id);for(const [i,b] of p.beats.entries()){
  assert.equal(b.copy.vi.title,original.beats[i].title);assert.equal(b.copy.vi.say,original.beats[i].say);
  assert.equal(b.copy.vi.caption,original.beats[i].ops.find(op=>op.type==='caption').text);
 }}
});
test('learner turn is explicit on the last beat, not a timer or a reduced-motion skip',()=>{
 for(const p of copy.plans)for(const [i,b] of p.beats.entries())assert.equal(b.waitForLearner,i===p.beats.length-1);
 // This is a content assertion only; runtime scheduler and TalkBack remain untested here.
});
