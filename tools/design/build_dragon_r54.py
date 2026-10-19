"""Build study cutouts and pin source. No app/runtime writes. Requires Pillow."""
from collections import deque
from pathlib import Path
import hashlib, json, subprocess
from PIL import Image, ImageFilter
ROOT=Path(__file__).resolve().parents[2]
P=ROOT/'docs/design/dragon-run-r54'; A=P/'assets'
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
cutouts={name:cutout(name) for name in ['pip','basalt','beetle']}
Image.open(A/'volcano-trail.png').save(A/'volcano-trail.webp',quality=88,method=6)
paths=['app/lib/modules/dragon_jump/dragon_game.dart','app/lib/modules/dragon_jump/dragon_jump_module.dart','app/assets/config/game_config.json','app/lib/core/config/game_config.dart','app/lib/modules/energy/energy_widgets.dart','app/lib/data/repositories/progress_repository.dart','app/lib/core/events.dart','app/lib/shared/widgets/result_screen.dart','app/lib/shared/characters/cast.dart','app/lib/shared/characters/characters.dart']
source={'code_pin':PIN,'files':[{'path':x,'sha256':hashlib.sha256(subprocess.check_output(['git','show',PIN+':'+x],cwd=ROOT)).hexdigest()} for x in paths]}
(P/'source-manifest.json').write_text(json.dumps(source,indent=2)+'\n')
config=json.loads(subprocess.check_output(['git','show',PIN+':app/assets/config/game_config.json'],cwd=ROOT))
(P/'rules.json').write_text(json.dumps({'dragon_jump':config['dragon_jump'],'run_cost':config['energy_costs']['arcade_run'],'physics':{'gravity':2700,'first_jump':900,'air_jump':800,'default_jumps':2,'wings_jumps':3,'invulnerable_seconds':1.5,'meter_units':50,'coin_score':3,'gem_coin_value':5}},indent=2)+'\n')
refs=['docs/design/art-refresh-r33/concepts/w01-village.jpg','docs/design/art-refresh-r34/concepts/w05-dragon.jpg','docs/design/maze-play-r50/assets/hedge-token.png']
manifest={'revision':54,'runtime_ready':False,'origin':'Four separate Arena AI-generated illustrations guided by project references; no stock/exclusivity claim. Derivatives are study-only cutouts, not animation atlases.','references':[{'path':x,'sha256':hashlib.sha256((ROOT/x).read_bytes()).hexdigest()} for x in refs], 'cutouts':cutouts,'background_alignment':{'authored_track_y_fraction':.75,'logical_ground_y_fraction':.8,'logical_width':400,'logical_height':'responsive scene height / width * 400','camera_lift':'max(0, pipY+80 - logicalHeight*0.8)','note':'Aspect-preserved backdrop cover, track aligned at75percent source to80percent viewport; top-row sky extension if needed; camera tracks high jumps, collision stays in world coordinates'},'files':[]}
for file in sorted(A.iterdir()):
    if file.suffix not in ('.png','.webp'): continue
    with Image.open(file) as im: size=list(im.size)
    manifest['files'].append({'path':str(file.relative_to(P)),'size':size,'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
(A/'provenance.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Exported',len(manifest['files']),'art files; pinned',len(paths),'source files.')
