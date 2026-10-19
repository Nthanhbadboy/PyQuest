import {simulate} from './engine.mjs';
const $ = s => document.querySelector(s);
const app = $('#app');
const arrows = {L:'←',U:'↑',D:'↓',R:'→'};
const names = {L:'Trái',U:'Lên',D:'Xuống',R:'Phải'};
const escape = s => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const places = [
 {id:'python_academy',name:'Tháp Python',tag:'HỌC & SÁNG TẠO',desc:'Thử một dòng code, khám phá một ý tưởng.',x:50,y:30,icon:'⌘'},
 {id:'robo_maze',name:'Mê Cung Robo',tag:'MỘT THỬ THÁCH NHỎ',desc:'Xếp lệnh. Tìm đường. Mở kho báu.',x:28,y:44,icon:'↗'},
 {id:'pip_volcano',name:'Núi Lửa Pip',tag:'PHẢN XẠ & PHIÊU LƯU',desc:'Nhảy cùng Pip, khám phá đường đua.',x:80,y:34,icon:'△'},
 {id:'star_observatory',name:'Đài Thiên Văn',tag:'SƯU TẦM & KHÁM PHÁ',desc:'Hứng sao, thắp sáng bầu trời.',x:82,y:53,icon:'✧'},
 {id:'bitsy_workshop',name:'Xưởng Bitsy',tag:'TÒ MÒ & GIẢI ĐỐ',desc:'Cùng Bitsy tìm chỗ code cần sửa.',x:23,y:68,icon:'⚙'},
 {id:'achievement_house',name:'Nhà Thành Tích',tag:'NHỮNG ĐIỀU BẠN ĐÃ LÀM',desc:'Cất giữ những kỷ niệm của hành trình.',x:78,y:74,icon:'◇'}
];
let levels, screen='intro', selected=1, levelIndex=0, commands=[], frame=null, running=false,
    feedback='', problem=false, runToken=0, hintStep=0, lastResult=null;
const completed = new Set();
const calmInput=$('#calm');calmInput.checked=matchMedia('(prefers-reduced-motion: reduce)').matches;
const reduced=()=>calmInput.checked;
const thumb=p=>`art/${p.id}_512.webp`;
const robot='<img src="art/robo.svg" alt="Robo">';
const header=(title,subtitle,back='hub',right='hint')=>`<header class="app-header"><button class="icon-button" data-go="${back}" aria-label="Quay lại">←</button><div class="head-copy"><h2>${escape(title)}</h2><small>${escape(subtitle)}</small></div>${right==='hint'?'<button class="icon-button" data-hint aria-label="Mở gợi ý của Robo">?</button>':''}</header>`;
const ribbon='<div class="prototype-ribbon">BẢN MẪU · Không lưu vào tiến trình PyQuest</div>';
function initialPosition(){let pos;levels[levelIndex].rows.forEach((r,y)=>[...r].forEach((c,x)=>{if(c==='S')pos={x,y};}));return pos;}
function board(){
 const level=levels[levelIndex],pos=frame?.position||initialPosition(),collected=frame?.collected||[];
 return `<div class="board" role="img" aria-label="Bàn chơi ${escape(level.title)}. Robo ở cột ${pos.x+1}, hàng ${pos.y+1}." style="--cols:${level.rows[0].length}">${level.rows.map((row,y)=>[...row].map((c,x)=>{
  const here=pos.x===x&&pos.y===y,crash=frame?.collision?.x===x&&frame?.collision?.y===y;
  return `<div class="cell ${c==='#'?'wall':''} ${here?'trail':''} ${crash?'crash':''}" aria-hidden="true">${c==='#'?'<div class="tree"></div>':c==='C'?'<div class="chest"></div>':c==='*'&&!collected.includes(`${x},${y}`)?'<div class="gem"></div>':''}${here?'<img class="robot" src="art/robo.svg" alt="">':''}</div>`;
 }).join('')).join('')}</div>`;
}
const review={
 intro:['Một lời chào có mục đích.','Một người bạn, hai cách bắt đầu. Có thể bỏ qua; không bắt đăng nhập, bật micro hay đọc một đoạn dài.'],
 hub:['Nhìn thấy một thế giới.','Sáu địa điểm, một lựa chọn đang được tập trung. Nhãn chỉ xuất hiện khi chọn; card nằm ngoài cảnh thay vì che công trình.'],
 activity:['Hiểu trước khi bắt đầu.','Mục tiêu, cách thao tác và một nút vào chơi. Không xếp các bảng thống kê lên trước trải nghiệm.'],
 maze:['Thử một bước. Hiểu một điều.','Lệnh sáng cùng bước đi. Có thể dừng, sửa một lệnh hoặc xin gợi ý. Góc nhìn giữ lưới dễ hiểu, dùng độ dày và ánh sáng để tạo khối.'],
 result:['Ghi nhận điều đã làm.','Kết quả lấy từ mô phỏng của lượt vừa chạy. Khen hành động cụ thể, không cộng XP toàn cục hoặc phần thưởng giả.'],
 detail:['Nói rõ giới hạn của mẫu.','Địa điểm này có trong source app nhưng chưa được mô phỏng ở đây. Không biến một trang minh họa thành lời tuyên bố đã triển khai tính năng.']
};
function navigate(next){runToken++;running=false;screen=next;if(next==='maze'){frame=null;feedback='';problem=false;}render();app.scrollTop=0;}
function render(){
 if(!levels)return;
 const focused=document.activeElement;
 let restoreFocus=null;
 if(focused&&app.contains(focused)){
  if(focused.dataset.command)restoreFocus=`[data-command="${focused.dataset.command}"]`;
  else if(focused.dataset.place)restoreFocus=`[data-place="${focused.dataset.place}"]`;
  else if(focused.id)restoreFocus=`#${focused.id}`;
 }
 const [title,copy]=review[screen]||review.detail;$('#review-title').textContent=title;$('#review-copy').textContent=copy;
 document.querySelectorAll('[data-screen]').forEach(b=>{const active=b.dataset.screen===screen;b.classList.toggle('active',active);b.setAttribute('aria-current',active?'step':'false');});
 document.body.classList.toggle('calm',reduced());
 if(screen==='intro') app.innerHTML=`<section class="intro"><div class="intro-top"><span>◈ PyQuest</span><button data-go="hub">Để mình khám phá →</button></div><div class="intro-art"><div class="robo-halo">${robot}<span class="float-mark">✦</span></div></div><div class="intro-copy"><span class="tag">NGƯỜI BẠN ĐỒNG HÀNH</span><h1>Chào bạn,<br>mình là Robo!</h1><p>Hòn đảo này có rất nhiều điều để thử.<br>Bạn muốn khám phá, hay giúp mình<br>tìm một chiếc rương trước?</p></div><div class="bottom-actions"><button class="primary" data-go="hub">Khám phá hòn đảo <span class="arrow">→</span></button><button class="secondary" data-go="activity">Giúp Robo tìm kho báu</button><p class="micro">Bạn có thể chọn lại bất cứ lúc nào.</p></div>${ribbon}</section>`;
 else if(screen==='hub'){
 const p=places[selected];app.innerHTML=`<section class="hub"><header class="app-header hub-header"><div class="head-copy"><small>CHÀO MỪNG ĐẾN PYQUEST</small><h2>Đảo Khởi Đầu</h2></div><span class="energy" title="Số mẫu, chưa kết nối năng lượng thật"><b>ϟ</b> 20/20</span><button class="icon-button" data-calm aria-label="${reduced()?'Bật':'Giảm'} chuyển động">${reduced()?'☾':'☼'}</button></header><div class="map-region"><div class="map-canvas"><img src="art/village.webp" alt="Làng 2.5D có sáu địa điểm nối với nhau bằng đường và cầu">${places.map((p,i)=>`<button class="map-hotspot ${i===selected?'selected':''}" style="left:${p.x}%;top:${p.y}%" data-place="${i}" aria-label="Chọn ${escape(p.name)}" aria-pressed="${i===selected}">${p.icon}<span>${escape(p.name)}</span></button>`).join('')}</div></div><section class="selected-place" aria-live="polite"><div class="place-row"><img src="${thumb(p)}" alt=""><div><span class="tag">${completed.size&&selected===1?'ĐÃ THỬ '+completed.size+' MÀN MẪU':p.tag}</span><h3>${p.name}</h3><p>${p.desc}</p></div></div><button class="primary" id="enter-place">${selected===1?'Khám phá cùng Robo':'Xem địa điểm'} <span class="arrow">→</span></button></section><nav class="bottom-nav" aria-label="Điều hướng mẫu"><button class="current" data-go="hub"><b>⌂</b>Hòn đảo</button><button data-go="activity"><b>⌘</b>Thử thách</button><button data-go="intro"><b>◉</b>Gặp Robo</button></nav>${ribbon}</section>`;
 }
 else if(screen==='activity') app.innerHTML=`${header('Mê Cung Robo','CHƠI NGAY · KHÔNG CẦN PYTHON','hub','')}<div class="activity-hero"><img src="${thumb(places[1])}" alt="Khu vườn mê cung của Robo"><span class="tag">✧ LỆNH NHỎ · KHÁM PHÁ LỚN</span></div><div class="activity-copy"><span class="eyebrow">THỬ THÁCH ĐẦU TIÊN</span><h1>Một con đường.<br>Nhiều điều để thử.</h1><p>Đưa Robo tới rương bằng các mũi tên. Bạn thử, Robo làm theo.</p><div class="steps"><div><b>1</b>Xếp lệnh</div><div><b>2</b>Chạy thử</div><div><b>3</b>Tìm kho báu</div></div><div class="guide-line">${robot}<p>Đi nhầm cũng không sao.<br>Mình sửa một bước rồi thử lại nhé!</p></div></div><div class="bottom-actions"><button class="primary" id="start-maze">Thử màn đầu tiên <span class="arrow">→</span></button><p class="micro">Hai màn dữ liệu mẫu · Không tiêu hao năng lượng thật</p></div>`;
 else if(screen==='maze'){
 const l=levels[levelIndex];app.innerHTML=`<section class="maze-screen">${header(l.title,`MÊ CUNG ROBO · MÀN ${levelIndex+1} / 2`,'activity')}<div class="goal-strip"><span>◇ Tới chiếc rương</span><span>${l.rows.join('').includes('*')?'✧ Nhặt viên đá quý':'↗ Thử xếp '+l.command_limit+' lệnh'}</span></div><div class="board-wrap">${board()}</div><div class="maze-feedback ${problem?'error':''}" role="status" aria-live="polite">${robot}<p>${escape(feedback||l.story)}</p></div><section class="program-section"><div class="program-heading">Chương trình của bạn <span>${commands.length} lệnh · chạm để bỏ một lệnh</span></div><div class="program ${commands.length?'':'empty'}">${commands.length?commands.map((c,i)=>`<button class="command-chip ${frame?.step===i?'playing':''} ${problem&&frame?.step===i?'failed':''}" data-remove="${i}" aria-label="Bỏ lệnh ${i+1}: ${names[c]}" ${running?'disabled':''}><small>${i+1}</small>${arrows[c]}</button>`).join(''):'Chọn mũi tên bên dưới để bắt đầu'}</div></section><div class="direction-pad">${Object.keys(arrows).map(c=>`<button data-command="${c}" aria-label="Thêm lệnh ${names[c]}" ${running||commands.length>=12?'disabled':''}>${arrows[c]}<small>${names[c]}</small></button>`).join('')}</div><div class="run-row"><button class="icon-button" id="undo" aria-label="Bỏ lệnh cuối" ${running||!commands.length?'disabled':''}>↶</button><button class="icon-button" id="clear" aria-label="Xóa chương trình" ${running||!commands.length?'disabled':''}>↺</button><button class="primary" id="run" ${!commands.length?'disabled':''}>${running?'■ Dừng lại':'▶ Chạy thử'}</button></div><div class="maze-bottom">${running?'Robo đang làm theo từng lệnh.':'Chương trình chỉ chạy trong bản mẫu này.'}</div></section>`;
 }
 else if(screen==='result'&&lastResult){
 const gems=levels[levelIndex].rows.join('').split('*').length-1;app.innerHTML=`<section class="result">${header('Một khám phá mới','KẾT QUẢ LƯỢT CHẠY MẪU','hub','')}<div class="result-art"><div class="result-stars" aria-hidden="true">✦ ✦ ✦</div>${robot}</div><span class="eyebrow">BẠN VỪA LÀM ĐƯỢC</span><h1>Robo tìm thấy<br>kho báu rồi!</h1><p>Bạn đã xếp các bước theo đúng thứ tự.<br>Một chương trình nhỏ đã hoạt động!</p><div class="result-summary"><h3>Trong lượt thử này</h3><p>Đến chiếc rương <b>✓ Đã tới</b></p><p>Lệnh đã thực hiện <b>${lastResult.step+1}</b></p>${gems?`<p>Đá quý đã nhặt <b>${lastResult.collected.length}/${gems}</b></p>`:''}<p>Dữ liệu lưu <b>Chỉ trong phiên mẫu</b></p></div><div class="bottom-actions"><button class="primary" id="next-level">${levelIndex===0?'Thử một khúc rẽ mới':'Về đảo khám phá'} <span class="arrow">→</span></button><button class="secondary" id="replay">Thử lại theo cách của bạn</button><p class="micro">Không cộng XP, xu hoặc huy hiệu vào tài khoản thật.</p></div></section>`;
 }
 else if(screen==='detail'){
 const p=places[selected];app.innerHTML=`${header(p.name,'ĐỊA ĐIỂM TRONG THẾ GIỚI PYQUEST','hub','')}<section class="coming"><img src="${thumb(p)}" alt="${p.name}"><h1>${p.name}</h1><p>${p.desc}</p><p><strong>Chưa mô phỏng trong mẫu này.</strong> Hoạt động này có trong source app; bản thiết kế hiện chỉ chạy luồng Robo để kiểm chứng cách vào chơi và phản hồi.</p><button class="primary" data-go="hub">Về hòn đảo →</button><button class="secondary" data-go="activity">Thử luồng Robo</button></section>`;
 }
 bind();
 if(restoreFocus){const el=app.querySelector(restoreFocus);if(el&&!el.disabled)el.focus({preventScroll:true});}
}
function resetRun(){runToken++;running=false;frame=null;problem=false;feedback='';}
function bind(){
 app.querySelectorAll('[data-go]').forEach(b=>b.onclick=()=>navigate(b.dataset.go));
 app.querySelectorAll('[data-place]').forEach(b=>b.onclick=()=>{selected=Number(b.dataset.place);render();});
 app.querySelector('[data-calm]')?.addEventListener('click',()=>{calmInput.checked=!calmInput.checked;render();});
 app.querySelector('#enter-place')?.addEventListener('click',()=>navigate(selected===1?'activity':'detail'));
 app.querySelector('#start-maze')?.addEventListener('click',()=>{levelIndex=0;commands=[];navigate('maze');});
 app.querySelector('[data-hint]')?.addEventListener('click',showHint);
 app.querySelectorAll('[data-command]').forEach(b=>b.onclick=()=>{if(running||commands.length>=12)return;commands.push(b.dataset.command);resetRun();render();});
 app.querySelectorAll('[data-remove]').forEach(b=>b.onclick=()=>{if(running)return;commands.splice(Number(b.dataset.remove),1);resetRun();render();});
 app.querySelector('#undo')?.addEventListener('click',()=>{commands.pop();resetRun();render();});
 app.querySelector('#clear')?.addEventListener('click',()=>{commands=[];resetRun();render();});
 app.querySelector('#run')?.addEventListener('click',()=>{if(running){resetRun();feedback='Đã dừng. Bạn có thể sửa lệnh rồi chạy lại từ đầu.';render();}else run();});
 app.querySelector('#next-level')?.addEventListener('click',()=>{if(levelIndex===0){levelIndex=1;commands=[];hintStep=0;navigate('maze');}else navigate('hub');});
 app.querySelector('#replay')?.addEventListener('click',()=>{commands=[];navigate('maze');});
}
async function run(){
 if(running||!commands.length)return;
 const token=++runToken;running=true;problem=false;frame=null;feedback='Mình đi theo chương trình của bạn nhé!';
 const result=simulate(levels[levelIndex],commands);render();
 for(const f of result.frames){
  if(document.hidden){resetRun();feedback='Đã tạm dừng khi bạn rời trang. Chạy lại từ đầu khi sẵn sàng.';render();return;}
  await new Promise(r=>setTimeout(r,reduced()?100:460));
  if(token!==runToken)return;
  frame=f;feedback=`Đang thực hiện lệnh ${f.step+1}: đi ${names[commands[f.step]].toLowerCase()}.`;render();
 }
 if(token!==runToken)return;
 running=false;
 if(result.outcome==='success'){
  lastResult=result;completed.add(levels[levelIndex].id);
  await new Promise(r=>setTimeout(r,reduced()?0:400));if(token!==runToken)return;screen='result';render();app.scrollTop=0;
 }else{
  problem=true;feedback=result.outcome==='collision'?`Lệnh ${result.step+1} gặp tường. Chạm vào lệnh đó để bỏ hoặc sửa, rồi mình thử lại nhé!`:'Hết lệnh rồi, nhưng chưa tới rương. Bạn thử thêm một bước nhé!';render();
 }
}
function showHint(){hintStep=0;updateHint();$('#hint-dialog').showModal();}
function updateHint(){const l=levels[levelIndex];$('#hint-copy').textContent=hintStep===0?l.tip:levelIndex===0?'Robo và rương cùng một hàng. Có bốn ô đường ở bên phải Robo.':'Đi sang phải ba bước tới góc đường, rồi xuống ba bước. Bạn thử tự xếp lại nhé.';$('#hint-next').textContent=hintStep===0?'Gợi ý thêm':'Mình thử lại nhé';}
$('#hint-next').onclick=()=>{if(hintStep===0){hintStep=1;updateHint();}else $('#hint-dialog').close();};
$('#close-hint').onclick=()=>$('#hint-dialog').close();
document.querySelectorAll('[data-screen]').forEach(b=>b.onclick=()=>navigate(b.dataset.screen));
$('#sample-error').onclick=()=>{levelIndex=0;commands=['U'];navigate('maze');run();};
$('#sample-win').onclick=()=>{commands=levelIndex===0?['R','R','R','R']:['R','R','R','D','D','D'];navigate('maze');run();};
$('#reset-demo').onclick=()=>{completed.clear();commands=[];levelIndex=0;selected=1;navigate('intro');};
calmInput.onchange=()=>{document.body.classList.toggle('calm',reduced());};
document.addEventListener('visibilitychange',()=>{if(document.hidden&&running){resetRun();feedback='Đã tạm dừng khi bạn rời trang. Chạy lại từ đầu khi sẵn sàng.';render();}});
try{const response=await fetch('levels.json');if(!response.ok)throw new Error('Không tải được dữ liệu mẫu');levels=(await response.json()).levels;render();}catch(e){app.innerHTML='<div class="loading">Không mở được bản mẫu. Hãy chạy qua HTTP theo README.</div>';console.error(e);}
