import assert from 'node:assert/strict';
import fs from 'node:fs';
import {ids,fixtures,suggestion,destination,ReadGeneration,names} from '../../docs/design/r1-village-r53/model.mjs';
let checks=0;const check=(name,fn)=>{fn();checks++;console.log('PASS',name)};
check('six real route identities',()=>assert.equal(new Set(ids).size,6));
check('VI and EN names complete',()=>{for(const lang of ['vi','en'])assert.equal(names[lang].length,6)});
check('fresh suggestion is actual Python module',()=>assert.equal(suggestion(fixtures('fresh')),'main_quest'));
check('returning suggestion follows ready recommendation',()=>assert.equal(suggestion(fixtures('returning')),'robot_maze'));
check('completed fixture does not invent a next lesson',()=>assert.equal(destination(suggestion(fixtures('complete')),fixtures('complete')),'activity:main_quest'));
check('loading has no suggestion or available routes',()=>{const x=fixtures('loading');assert.equal(suggestion(x),null);for(const id of ids)assert.equal(destination(id,x),null)});
check('one error does not turn another route into unavailable',()=>{const x=fixtures('error');assert.equal(destination('robot_maze',x),null);assert.equal(destination('main_quest',x),'activity:main_quest')});
check('locked fixture routes to prerequisite, never to locked game',()=>assert.equal(destination('bug_hunter',fixtures('fresh')),'lesson:mq1_03'));
check('missing prerequisite has no fabricated route',()=>{const x=fixtures('fresh');x.bug_hunter.unlockLessonId=null;assert.equal(destination('bug_hunter',x),null)});
check('no home/dock/arena route',()=>{for(const id of ['private_home','dock','arena','travel'])assert.equal(destination(id,fixtures('fresh')),null)});
check('unlocked route identities stable',()=>{for(const id of ids)assert.equal(destination(id,fixtures('returning')),`activity:${id}`)});
check('stale read is discarded',()=>{const g=new ReadGeneration();const a=g.begin(),b=g.begin();assert.equal(g.accept(b,{ok:true}),true);assert.equal(g.accept(a,{ok:false}),false);assert.equal(g.entries.ok,true)});
check('disposed read is discarded',()=>{const g=new ReadGeneration();const a=g.begin();g.dispose();assert.equal(g.accept(a,{ok:true}),false)});
const manifest=JSON.parse(fs.readFileSync('docs/design/r1-village-r53/manifest.json'));
check('all markers reference exactly the source route set',()=>assert.deepEqual(manifest.layout.markers.map(m=>m.id),ids));
check('marker rectangles in bounds and non-overlapping at normal and 1.3 scale',()=>{
 for(const width of [360,390])for(const scale of [1,1.3]){
   const height=width*1844/853;
   const rects=manifest.layout.markers.map(m=>({x:m.anchor[0]*width-manifest.layout.marker_width_fraction*width/2,y:m.anchor[1]*height-35,w:manifest.layout.marker_width_fraction*width,h:70}));
   for(const r of rects){assert.ok(r.w>=48&&r.h>=48);assert.ok(r.x>=0&&r.x+r.w<=width&&r.y>=0&&r.y+r.h<=height)}
   for(let i=0;i<rects.length;i++)for(let j=i+1;j<rects.length;j++){const a=rects[i],b=rects[j];assert.ok(a.x+a.w<=b.x||b.x+b.w<=a.x||a.y+a.h<=b.y||b.y+b.h<=a.y)}
 }
});
const receipt={scope:'JS design model, not Flutter or persistent state',checks,failures:0};
fs.writeFileSync('docs/design/r1-village-r53/evidence/model-checks.json',JSON.stringify(receipt,null,2)+'\n');
