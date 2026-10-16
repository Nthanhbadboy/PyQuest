import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {boardAt,validatePlan,tryPrint} from '../../docs/design/tutor-board-prototype/engine.mjs';
const fixture=JSON.parse(await readFile(new URL('../../docs/design/tutor-board-prototype/lessons.json',import.meta.url)));
const plans=fixture.plans;
test('two examples remain pinned to the real lesson dataset',async()=>{
 const raw=await readFile(new URL('../../app/assets/data/main_quest_ch1.json',import.meta.url));
 assert.equal(createHash('sha256').update(raw).digest('hex'),fixture.source_sha256);
 const lessons=JSON.parse(raw).lessons;
 for(const p of plans)assert.equal(p.beats[0].ops.find(o=>o.type==='code').text,lessons.find(l=>l.id===p.lesson_id).steps.find(s=>s.id===p.source_step).code);
});
test('authored board plans validate and replay deterministically',()=>{for(const p of plans){validatePlan(p);assert.deepEqual(boardAt(p,0),boardAt(p,0));}});
test('highlight then connect code to an output without quotes',()=>{assert.equal(boardAt(plans[0],0).focus.token,'print');assert.equal(boardAt(plans[0],1).focus.token,'"Xin chào!"');assert.equal(boardAt(plans[0],2).output,'Xin chào!');assert.equal(boardAt(plans[0],0).output,null);});
test('number diagram has three plus four objects; quoted code stays text',()=>{const b=boardAt(plans[1],2);assert.equal(b.tokens.left+b.tokens.right,7);assert.equal(b.tokens.merged,true);assert.equal(b.output,'7\n3 + 4');assert.equal(b.focus.line,1);});
test('replaying backwards neither mutates the plan nor keeps future output',()=>{const before=structuredClone(plans[1]);boardAt(plans[1],3);assert.equal(boardAt(plans[1],0).output,null);assert.deepEqual(plans[1],before);});
test('reject arbitrary executable or remote drawing operations',()=>{for(const type of ['eval','html','svg','fetch','clearStudentInk']){const p=structuredClone(plans[0]);p.beats[0].ops.push({type,text:'anything'});assert.throws(()=>validatePlan(p));}});
test('reject unknown operation fields and oversized payloads',()=>{const p=structuredClone(plans[0]);p.beats[0].ops[0].url='https://untrusted.invalid';assert.throws(()=>validatePlan(p));const q=structuredClone(plans[0]);q.beats[0].say='x'.repeat(601);assert.throws(()=>validatePlan(q));});
test('reject invalid token counts, focus positions and beats',()=>{const p=structuredClone(plans[1]);p.beats[0].ops.find(o=>o.type==='tokens').left=50;assert.throws(()=>validatePlan(p));assert.throws(()=>boardAt(plans[0],-1));assert.throws(()=>boardAt(plans[0],4));});
test('limited evaluator distinguishes text from addition',()=>{assert.equal(tryPrint('print(3 + 4)').output,'7');assert.equal(tryPrint('print("3 + 4")').output,'3 + 4');assert.equal(tryPrint('print("Robo thông minh")').output,'Robo thông minh');assert.equal(tryPrint("print('')").output,'');});
test('unsupported Python and malformed code are not executed or judged as lesson failure',()=>{for(const s of ['print(Robo)','print["x"]','print(100 + 1)','print(2 * 3)','while True: pass','print("x");globalThis.pwned=1', 'print("a\\nb")'])assert.equal(tryPrint(s).ok,false,s);assert.equal(globalThis.pwned,undefined);});

test('authored outputs agree with the supported deterministic example evaluator',()=>{for(const p of plans){const b=boardAt(p,p.beats.length-1);const outputs=b.code.split('\n').map(line=>{const r=tryPrint(line);assert(r.ok);return r.output;});assert.equal(b.output,outputs.join('\n'));}});
