(() => {
'use strict';
const $ = id => document.getElementById(id);
const scenes = window.SCENES;
let language = 'vi';
let current = scenes.find(s => s.id === location.hash.slice(1)) || scenes[0];
let activeState = current.states[0];
const t = value => value[language];
const strings = {
 shellBadge: pair('Bản thiết kế · Không phải APK', 'Design study · Not the APK'),
 catalogEyebrow: pair('10 CẢNH MỚI', '10 NEW SCENES'),
 catalogTitle: pair('Một thế giới. Nhiều cách lớn lên.', 'One world. Many ways to grow.'),
 catalogIntro: pair('Nhà để sáng tạo. Bạn để sẻ chia. Những cuộc chơi thuộc về bạn.', 'A home to create in. Friends to share with. Adventures of your own.'),
 scopeNote: pair('PQC-017: Tutor, Nhà Thành Tích và Arena do CODE phụ trách. Journal, Settings, Welcome chưa có ảnh riêng mới; Catch Stars / Bug Hunter còn thiếu. Không gọi bộ này là toàn app hoàn tất.', 'PQC-017: Tutor, Achievement House and Arena belong to CODE. Journal, Settings and Welcome have no new dedicated artwork; Catch Stars / Bug Hunter remain missing. This is not a completed whole-app redesign.'),
 sizeLabel: pair('Khung', 'Frame'), scaleLabel: pair('Chữ', 'Text'),
 fixtureStrip: pair('MẪU THIẾT KẾ · KHÔNG DỮ LIỆU THẬT', 'DESIGN FIXTURE · NO REAL USER DATA'),
 stageCaption: pair('Đổi màn, ngôn ngữ và trạng thái để xem bố cục. Nút chỉ chuyển giữa các mẫu; không lưu nhà, gửi quà, mua hàng hoặc chạy game.', 'Switch scenes, language and states to inspect layouts. Buttons only move between fixtures; no home saving, gifts, purchases or game execution.'),
 reviewEyebrow: pair('BẢNG KIỂM THIẾT KẾ', 'DESIGN REVIEW'), reviewTitle: pair('Không chỉ một ảnh đẹp.', 'More than a pretty scene.'),
 stateLabel: pair('Trạng thái đang xem', 'Current state'), intentLabel: pair('Hành vi & ranh giới', 'Behavior & boundaries'),
 sourceLabel: pair('Nguồn dữ liệu', 'Data ownership'), gapLabel: pair('Chưa đủ để production', 'Production gaps'),
 fullArt: pair('Xem ảnh gốc ↗', 'Open original art ↗'),
 receiptText: pair('Concept + HTML study, chưa phải Flutter. Ảnh opaque, chưa tách layer/actor. Quyền, giao dịch, AI và trạng thái game đều chưa chạy trong gallery.', 'Concept + HTML study, not Flutter. Opaque art without separate layers/actors. Permissions, transactions, AI and game state do not run in this gallery.')
};
function nav() {
 const parent = $('screenNav'); parent.replaceChildren(); let group = '';
 for (const s of scenes) {
   if (t(s.group) !== group) {group = t(s.group); const heading = document.createElement('p'); heading.className = 'nav-group'; heading.textContent = group; parent.append(heading);}
   const button = document.createElement('button'); button.type = 'button'; button.className = 'nav-item'; button.dataset.screen = s.id;
   if (s.id === current.id) button.setAttribute('aria-current', 'page');
   const image = document.createElement('img'); image.src = `concepts/${s.id}.jpg`; image.alt = ''; image.loading = 'lazy';
   const label = document.createElement('span'); const small = document.createElement('small'); small.textContent = s.id.toUpperCase().split('-').slice(0,1).join('');
   label.append(small, document.createTextNode(t(s.title))); button.append(image, label);
   button.addEventListener('click', () => selectScene(s.id)); parent.append(button);
 }
}
function render(preserveScroll = false) {
 const scroll = $('phoneScroll').scrollTop;
 document.documentElement.lang = language;
 for (const [id, value] of Object.entries(strings)) $(id).textContent = t(value);
 $('langVi').setAttribute('aria-pressed', String(language === 'vi'));
 $('langEn').setAttribute('aria-pressed', String(language === 'en'));
 $('screenNav').setAttribute('aria-label', language === 'vi' ? 'Chọn màn thiết kế' : 'Choose a screen');
 $('phoneScroll').setAttribute('aria-label', language === 'vi' ? 'Nội dung màn có thể cuộn' : 'Scrollable screen content');
 $('phoneTitle').textContent = t(current.title); $('phoneSubtitle').textContent = t(current.subtitle);
 $('stateName').textContent = t(activeState.name); $('stateTitle').textContent = t(activeState.title);
 $('stateBody').textContent = t(activeState.body); $('primaryAction').textContent = t(activeState.action);
 $('stateReview').textContent = t(activeState.review); $('dataSource').textContent = current.source; $('artNote').textContent = t(current.note);
 $('fullArt').href = `concepts/${current.id}.jpg`;
 const select = $('stateSelect'); select.replaceChildren();
 for (const s of current.states) {const option = document.createElement('option'); option.value = s.id; option.textContent = t(s.name); select.append(option);}
 select.value = activeState.id;
 const rows = $('stateRows'); rows.replaceChildren();
 for (const r of activeState.rows) {const d = document.createElement('div'); const dt = document.createElement('dt'); const dd = document.createElement('dd'); dt.textContent = t(r.label); dd.textContent = t(r.value); d.append(dt,dd); rows.append(d);}
 const figure = $('scene'); figure.replaceChildren();
 const restricted = current.id === 'w09-visit' && ['revoked','offline'].includes(activeState.id);
 figure.classList.toggle('restricted', restricted);
 if (restricted) {
   figure.style.removeProperty('--scene-img'); const notice = document.createElement('div'); notice.className = 'privacy-sign';
   notice.textContent = language === 'vi' ? 'Cảnh nhà đã được ẩn' : 'Home scene hidden'; figure.append(notice);
 } else {
   figure.style.setProperty('--scene-img', `url("concepts/${current.id}.jpg")`);
   const image = document.createElement('img'); image.src = `concepts/${current.id}.jpg`; image.alt = t(current.alt); figure.append(image);
   const caption = document.createElement('figcaption'); caption.textContent = language === 'vi' ? 'Cảnh minh họa · chưa phải thế giới đang chạy' : 'Illustrative scene · not a running world'; figure.append(caption);
 }
 const missingStateArt = (current.id === 'w03-project' && activeState.id === 'built') || (current.id === 'w10-pet' && activeState.id === 'rest');
 $('artStateNotice').textContent = missingStateArt ? (language === 'vi' ? 'Chưa có hình riêng cho trạng thái này. Cảnh trên vẫn là concept ban đầu.' : 'Dedicated artwork for this state is missing. The scene above is still the original concept.') : '';
 nav(); $('phoneScroll').scrollTop = preserveScroll ? scroll : 0;
 $('phone').dataset.screen = current.id; $('phone').dataset.state = activeState.id;
}
function selectScene(id) {const next = scenes.find(s => s.id === id); if (!next) return; current = next; activeState = current.states[0]; history.replaceState(null,'',`#${id}`); $('transitionNotice').textContent = ''; render();}
function selectState(id) {const next = current.states.find(s => s.id === id); if (!next) return; activeState = next; render();}
$('stateSelect').addEventListener('change', e => selectState(e.target.value));
$('langVi').addEventListener('click', () => {language = 'vi'; render(true);});
$('langEn').addEventListener('click', () => {language = 'en'; render(true);});
$('size').addEventListener('change', e => {const small = e.target.value === '360'; document.documentElement.style.setProperty('--phone-w', small ? '360px' : '390px'); document.documentElement.style.setProperty('--phone-h', small ? '640px' : '844px');});
$('scale').addEventListener('change', e => document.documentElement.style.setProperty('--scale', e.target.value));
$('primaryAction').addEventListener('click', () => {const next = activeState.next; if (next.startsWith('@')) selectScene(next.slice(1)); else selectState(next); $('transitionNotice').textContent = language === 'vi' ? 'Đã đổi mẫu thiết kế. Không có giao dịch hoặc thay đổi dữ liệu thật.' : 'Design fixture changed. No transaction or real data change occurred.';});
window.addEventListener('hashchange', () => selectScene(location.hash.slice(1)));
// Explicit small API for deterministic design QA, not an application API.
window.gallery = {selectScene, selectState, get current() {return current.id;}, get state() {return activeState.id;}};
render();
})();
