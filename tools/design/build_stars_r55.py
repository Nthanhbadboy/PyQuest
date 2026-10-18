"""Build study cutouts and pin source. No app/runtime writes. Requires Pillow."""
from collections import deque
from pathlib import Path
import hashlib, json, subprocess
from PIL import Image, ImageFilter
ROOT=Path(__file__).resolve().parents[2]
P=ROOT/'docs/design/catch-stars-r55'; A=P/'assets'
PIN='6dc8ca8feeed54cc0fa6a82109e3a59d24a16153'

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
cutouts={name:cutout(name) for name in ['jar','star','meteor']}
Image.open(A/'observatory-sky.png').save(A/'observatory-sky.webp',quality=88,method=6)
paths=['app/lib/modules/catch_stars/stars_game.dart','app/lib/modules/catch_stars/catch_stars_module.dart','app/assets/config/game_config.json','app/lib/core/config/game_config.dart','app/lib/modules/energy/energy_widgets.dart','app/lib/data/repositories/progress_repository.dart','app/lib/core/events.dart','app/lib/shared/widgets/result_screen.dart']
source={'code_pin':PIN,'files':[{'path':x,'sha256':hashlib.sha256(subprocess.check_output(['git','show',PIN+':'+x],cwd=ROOT)).hexdigest()} for x in paths]}
(P/'source-manifest.json').write_text(json.dumps(source,indent=2)+'\n')
config=json.loads(subprocess.check_output(['git','show',PIN+':app/assets/config/game_config.json'],cwd=ROOT))
(P/'rules.json').write_text(json.dumps({'catch_stars':config['catch_stars'],'run_cost':config['energy_costs']['arcade_run']},indent=2)+'\n')
import re
text=subprocess.check_output(['git','show',PIN+':'+paths[0]],cwd=ROOT).decode()
pattern=r"Constellation\('([^']+)', '([^']+)', (\d+),\s*\[(.*?)\],\s*\[(.*?)\], '([^']+)'\)"
items=[]
for id,name,n,pts,lines,story in re.findall(pattern,text,re.S):
    items.append({'id':id,'name':{'vi':name},'threshold':int(n),'points':[[float(a),float(b)] for a,b in re.findall(r'Offset\(([^,]+), ([^)]+)\)',pts)],'lines':[[int(a),int(b)] for a,b in re.findall(r'\((\d+), (\d+)\)',lines)],'story':{'vi':story}})
english=[('Robo','The first Robo is said to have been built beneath this constellation.'),('Pip the Dragon','A little dragon spreads its wings and flies toward the moon.'),('Bitsy the Cat','Pointed ears and a long tail — Bitsy keeps watch for bugs.'),('Py the Snake','Winding like a long line of code, this constellation belongs to the wise teacher.'),('Treasure Chest','Those who find this constellation are said to have good luck opening chests.'),('Rocket','A guide for inventors who want to fly to the stars.'),('Whale','A gentle whale swims in the sea of stars, sending little stars into the sky.'),('Snail','Slow and steady — a constellation for the island’s most patient explorers.')]
assert len(items)==8
for item,(name,story) in zip(items,english): item['name']['en']=name; item['story']['en']=story
(P/'catalog.json').write_text(json.dumps({'source':PIN,'en':'Design translation; Vietnamese names, stories, geometry and thresholds extracted verbatim from source. Fictional character atlas, not astronomy.','constellations':items},ensure_ascii=False,indent=2)+'\n')
refs=['docs/design/art-refresh-r33/concepts/w01-village.jpg','docs/design/art-review-r40/code-snapshot/a04-w05-catch-stars/concept.png','docs/design/dragon-run-r54/assets/basalt-source.png','docs/design/maze-play-r50/assets/robo-token.png']
manifest={'revision':55,'runtime_ready':False,'origin':'Four separate Arena AI-generated study assets. Background + three edge-matted object studies; golden/rainbow/comet use procedural overlays. No native translucent glass or animation claim. Jar generated taller than requested; rendered as a shallow 92x62 study proxy, needs production redraw.','references':[{'path':x,'sha256':hashlib.sha256((ROOT/x).read_bytes()).hexdigest()} for x in refs],'cutouts':cutouts,'files':[]}
for file in sorted(A.iterdir()):
    if file.suffix not in ('.png','.webp'): continue
    with Image.open(file) as im: size=list(im.size)
    manifest['files'].append({'path':str(file.relative_to(P)),'size':size,'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
(A/'provenance.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Exported',len(manifest['files']),'art files; pinned',len(paths),'source files; extracted',len(items),'constellations.')
