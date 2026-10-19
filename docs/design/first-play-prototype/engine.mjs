// Deterministic interaction model for the DESIGN PROTOTYPE only.
// Does not replace Flutter MazePlayback, persistence, scoring or energy rules.
export const directions = {L: [-1, 0], U: [0, -1], D: [0, 1], R: [1, 0]};
export function simulate(level, commands) {
  const rows = level.rows;
  let start;
  rows.forEach((row, y) => [...row].forEach((cell, x) => { if (cell === 'S') start = {x, y}; }));
  if (!start) throw new Error('Fixture has no start');
  let position = {...start};
  const collected = new Set(), frames = [];
  for (let i = 0; i < commands.length; i++) {
    const delta = directions[commands[i]];
    if (!delta) throw new Error('Unknown command');
    const next = {x: position.x + delta[0], y: position.y + delta[1]};
    const tile = rows[next.y]?.[next.x];
    if (tile === undefined || tile === '#' || tile === '~') {
      frames.push({position: {...position}, collected: [...collected], step: i, collision: next});
      return {outcome: 'collision', frames, position, collected: [...collected], step: i};
    }
    position = next;
    if (tile === '*') collected.add(`${next.x},${next.y}`);
    frames.push({position: {...position}, collected: [...collected], step: i});
    if (tile === 'C') return {outcome: 'success', frames, position, collected: [...collected], step: i};
  }
  return {outcome: 'incomplete', frames, position, collected: [...collected], step: commands.length - 1};
}
