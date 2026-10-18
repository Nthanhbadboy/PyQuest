export const ids = ['main_quest', 'robot_maze', 'dragon_jump', 'catch_stars', 'bug_hunter', 'achievement_house'];
export const names = {
  vi: ['Tháp Python', 'Mê Cung Robo', 'Núi Lửa', 'Đài Thiên Văn', 'Xưởng Bitsy', 'Nhà Thành Tích'],
  en: ['Python Tower', 'Robo Maze', 'Volcano', 'Observatory', 'Bitsy’s Workshop', 'Achievement House'],
};
export const copy = {
  vi: {island:'Đảo Khởi Đầu',subtitle:'Một hòn đảo, nhiều cách khám phá',map:'Cảnh làng',list:'Địa điểm',settings:'Cài đặt',daily:'Nhiệm vụ',energy:'Năng lượng',suggestion:'GỢI Ý CHO BẠN',visit:'Ghé ',loading:'Đang tải',error:'Chưa tải được',retry:'Thử lại',locked:'Cần học trước',ready:'Khám phá',close:'Về làng',open:'Vào hoạt động',lesson:'Tới bài cần học',sample:'Mô phỏng điều hướng — không chạy trò chơi, không ghi tiến độ.',route:'Đích điều hướng',scroll:'Cuộn để khám phá sáu địa điểm',directory:'Chọn địa điểm — cùng sáu lối vào của làng',large:'Chữ lớn: dùng danh sách để đọc đủ tên địa điểm.',saved:'Khi quay lại, giữ vị trí cuộn và focus ở nơi vừa chọn.',noStatus:'Chưa có trạng thái, không mở hoạt động như thể đã được mở khóa.'},
  en: {island:'Starter Island',subtitle:'One island, many ways to explore',map:'Village',list:'Places',settings:'Settings',daily:'Quests',energy:'Energy',suggestion:'A PLACE TO EXPLORE',visit:'Visit ',loading:'Loading',error:'Could not load',retry:'Try again',locked:'Learn first',ready:'Explore',close:'Back to village',open:'Enter activity',lesson:'Go to required lesson',sample:'Navigation simulation — no game execution or progress writes.',route:'Route destination',scroll:'Scroll to discover six places',directory:'Choose a place — the same six village entrances',large:'Large text: use the directory to read every place name.',saved:'Returning restores your scroll position and focus to the selected place.',noStatus:'Status is unavailable; do not treat the activity as unlocked.'},
};
export function fixtures(kind) {
  return Object.fromEntries(ids.map((id, i) => [id, {
    phase: kind === 'loading' ? 'loading' : kind === 'error' && id === 'robot_maze' ? 'error' : 'ready',
    locked: id === 'bug_hunter' && kind !== 'returning' && kind !== 'complete',
    recommended: kind === 'fresh' && i === 0 || kind === 'returning' && i === 1,
    unlockLessonId: id === 'bug_hunter' ? 'mq1_03' : null,
  }]));
}
export function suggestion(entries) {
  return ids.find(id => entries[id]?.phase === 'ready' && !entries[id].locked && entries[id].recommended)
    ?? (entries.main_quest?.phase === 'ready' && !entries.main_quest.locked ? 'main_quest' : null);
}
export function destination(id, entries) {
  const entry = entries[id];
  if (!ids.includes(id) || entry?.phase !== 'ready') return null;
  return entry.locked ? (entry.unlockLessonId ? `lesson:${entry.unlockLessonId}` : null) : `activity:${id}`;
}
// A read-generation token, not a persistence/reward or permission authority.
export class ReadGeneration {
  generation = 0;
  entries = {};
  begin() { return ++this.generation; }
  accept(generation, entries) {
    if (generation !== this.generation) return false;
    this.entries = entries;
    return true;
  }
  dispose() { ++this.generation; }
}
