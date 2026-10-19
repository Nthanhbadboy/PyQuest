"""Build study cutouts and pin source. No app/runtime writes. Requires Pillow."""
from collections import deque
from pathlib import Path
import hashlib, json, subprocess
from PIL import Image, ImageFilter
ROOT=Path(__file__).resolve().parents[2]
P=ROOT/'docs/design/arrival-entrance-r56'; A=P/'assets'
PIN='5c97577c32c27d36f33c09bf3af2fa01ad0111f5'

def cutout(name):
    im=Image.open(A/f'{name}-source.png').convert('RGBA'); w,h=im.size
    rgb=im.load(); alpha=Image.new('L',(w,h),255); mask=alpha.load(); seen=bytearray(w*h)
    q=deque([(x,0) for x in range(w)]+[(x,h-1) for x in range(w)]+[(0,y) for y in range(h)]+[(w-1,y) for y in range(h)])
    while q:
        x,y=q.popleft(); n=y*w+x
        if seen[n]: continue
        seen[n]=1; r,g,b,_=rgb[x,y]
        if min(r,g,b)<232 or max(r,g,b)-min(r,g,b)>26: continue
        mask[x,y]=0
        for a,b in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=a<w and 0<=b<h and not seen[b*w+a]: q.append((a,b))
    alpha=alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.35))
    im.putalpha(alpha); box=im.getbbox(); im=im.crop(box); im.thumbnail((512,512),Image.Resampling.LANCZOS)
    im.save(A/f'{name}-token.png'); return {'crop':list(box),'size':list(im.size),'method':'edge-connected white flood fill, minRGB232/chroma26; 1px erode +0.35 blur; study matte, not native alpha'}
cutouts={name:cutout(name) for name in ['py','bitsy']}
refs=['docs/screenshots/13_lesson_story.jpg','docs/design/maze-play-r50/assets/robo-token.png','docs/design/dragon-run-r54/assets/pip-token.png']
scenes={'arrival':'docs/design/art-review-r40/code-snapshot/a03-shared-welcome/concept.png','main_quest':'docs/design/chapter-journey-r43/assets/tower-garden.png','robot_maze':'docs/design/maze-play-r50/assets/garden-stage.png','dragon_jump':'docs/design/dragon-run-r54/assets/volcano-trail.png','catch_stars':'docs/design/catch-stars-r55/assets/observatory-sky.png','bug_hunter':'docs/design/art-review-r40/code-snapshot/a05-w05-bug-hunter/concept.png','achievement_house':'docs/design/art-sync-r35/corrections/w14-achievements.jpg'}
for name,path in scenes.items():
    im=Image.open(ROOT/path).convert('RGB');im.thumbnail((720,1000),Image.Resampling.LANCZOS);im.save(A/f'{name}.webp',quality=87,method=6);refs.append(path)
refs+=['docs/design/r1-village-r53/assets/village-r53.webp','docs/design/chapter-journey-r43/catalog.js']
modules=['main_quest/main_quest','robot_maze/robot_maze','dragon_jump/dragon_jump','catch_stars/catch_stars','bug_hunter/bug_hunter','achievements/achievement_house']
paths=['app/lib/app/activity.dart','app/lib/app/activity_registry.dart','app/lib/modules/main_map/activity_sheet.dart','app/lib/modules/main_map/main_map_screen.dart','app/lib/core/settings_service.dart','app/lib/core/localization/locale_preference.dart','app/assets/config/game_config.json','app/assets/data/main_quest_ch1.json','app/assets/data/robot_maze_levels.json','app/assets/data/bug_hunter_puzzles.json','app/lib/modules/bug_hunter/bug_models.dart','app/lib/modules/achievements/achievement_catalog.dart','app/lib/modules/catch_stars/stars_game.dart','app/lib/shared/characters/characters.dart','app/lib/shared/characters/cast.dart']+['app/lib/modules/'+x+'_module.dart' for x in modules]
def raw(path):return subprocess.check_output(['git','show',PIN+':'+path],cwd=ROOT)
(P/'source-manifest.json').write_text(json.dumps({'code_pin':PIN,'code_acceptance':'PQC020 NOT_ACCEPTED; source pin only','files':[{'path':x,'sha256':hashlib.sha256(raw(x)).hexdigest()} for x in paths]},indent=2)+'\n')
import re
ids=['main_quest','robot_maze','dragon_jump','catch_stars','bug_hunter','achievement_house']
en=[('Python Tower','Learn real Python','Write real code with Teacher Py, one short lesson at a time, with runnable examples and playful exercises.'),('Robo Maze','Arrange commands to find the way','Robo is lost in the hedge garden! Arrange arrows into a program that guides Robo to the treasure chest.'),('Pip’s Volcano','Jump with a little dragon','Pip loves collecting coins! Tap to leap over rocks and thorny bushes, then tap again to fly higher.'),('Observatory','Catch falling stars','Stars are falling tonight! Move the jar to catch them, and remember to dodge the meteors.'),('Bitsy’s Workshop','Find and fix code bugs','Bitsy is a code detective. Read a program, try it, find the buggy line and choose the right fix.'),('Achievement House','Keep your badges and memories','A place to look back on your journey: badges, milestones, collections and creations.')]
entries=[]
for id,module,english in zip(ids,modules,en):
    src=raw('app/lib/modules/'+module+'_module.dart').decode();block=src.split('final ActivityDef def = const ActivityDef(')[1].split('\n  );')[0]
    def field(key):return re.search(key+r": '([^']*)'",block).group(1)
    entries.append({'id':id,'name':{'vi':field('name'),'en':english[0]},'tagline':{'vi':field('tagline'),'en':english[1]},'description':{'vi':field('description'),'en':english[2]},'host':re.search(r'host: CharacterId\.(\w+)',block).group(1),'needsPython':'needsPython: true' in block,'hasCreatorMode':'hasCreatorMode: true' in block,'source_thumbnail':field('thumbnail'),'study_scene':'assets/'+id+'.webp'})
quest=json.loads(raw('app/assets/data/main_quest_ch1.json'));maze=json.loads(raw('app/assets/data/robot_maze_levels.json'));bug=json.loads(raw('app/assets/data/bug_hunter_puzzles.json'));config=json.loads(raw('app/assets/config/game_config.json'))
old=json.JSONDecoder().raw_decode((ROOT/'docs/design/chapter-journey-r43/catalog.js').read_text().split('const c=')[1])[0]
lessons=[]
for lesson in quest['lessons']:
    prior=next(x for x in old['lessons'] if x['id']==lesson['id']);assert prior['title']['vi']==lesson['title'];lessons.append({'id':lesson['id'],'number':lesson['number'],'title':prior['title']})
ach=raw('app/lib/modules/achievements/achievement_catalog.dart').decode().split('final List<AchievementDef> achievementCatalog = [')[1]
welcome=re.findall(r"CharacterId\.(\w+),\s*'([^']+)',\s*'([^']+)',",raw('app/lib/modules/main_map/main_map_screen.dart').decode().split('static const _pages = [')[1].split('];')[0]);assert len(welcome)==3
catalog={'source_pin':PIN,'en_provenance':'DESIGN translations; lesson EN reused from r43. No substring translation of ActivityStatus strings.','activities':entries,'lessons':lessons,'chapter':quest['chapter'],'totals':{'lessons':len(lessons),'maze':len(maze['levels']),'puzzles':len(bug['puzzles']),'bugs':sum(len(x['bugs']) for x in bug['puzzles']),'badges':len(re.findall(r"AchievementDef\(",ach)),'secretBadges':ach.count('secret: true')},'unlockLessonId':bug['packs'][0]['requires_lesson'],'constellations':[{'id':x,'threshold':int(n)} for x,n in re.findall(r"Constellation\('([^']+)', '[^']+', (\d+)",raw('app/lib/modules/catch_stars/stars_game.dart').decode())],'config':{'energy':config['energy'],'costs':config['energy_costs']},'welcome_source':[{'host':h,'title':t,'body':b} for h,t,b in welcome]}
(P/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
manifest={'revision':56,'runtime_ready':False,'origin':'Two Arena AI-generated character studies, edge-matted; seven WebP exports of existing study scenes, no new scene generation. Reuse r50 Robo and r54 Pip. Not animation or native-alpha production pack.','cutouts':cutouts,'references':[{'path':x,'sha256':hashlib.sha256((ROOT/x).read_bytes()).hexdigest()} for x in refs],'exports':scenes,'files':[]}
for file in sorted(A.iterdir()):
    if file.suffix not in ('.png','.webp'):continue
    with Image.open(file) as im:size=list(im.size)
    manifest['files'].append({'path':str(file.relative_to(P)),'size':size,'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
(A/'provenance.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Pinned',len(paths),'source files; art',len(manifest['files']),'catalog',catalog['totals'])
