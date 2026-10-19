// P03: deterministic storyboard and a deliberately tiny print sandbox, NOT Python.
const kinds = new Set(['code', 'focus', 'caption', 'output', 'tokens', 'arrow']);
const boundedText = value => typeof value === 'string' && value.length <= 600;
export function validatePlan(plan) {
  if (!plan || plan.version !== 1 || !Array.isArray(plan.beats) || plan.beats.length < 1 || plan.beats.length > 12) throw new Error('Invalid board plan');
  for (const beat of plan.beats) {
    if (!boundedText(beat.title) || !boundedText(beat.say) || !Array.isArray(beat.ops) || beat.ops.length > 8) throw new Error('Invalid beat');
    for (const op of beat.ops) {
      if (!op || !kinds.has(op.type)) throw new Error('Unsupported board operation');
      if (['code', 'caption', 'output'].includes(op.type) && !boundedText(op.text)) throw new Error('Invalid text');
      if (op.type === 'focus' && (!Number.isInteger(op.line) || op.line < 0 || op.line > 3 || !boundedText(op.token))) throw new Error('Invalid focus');
      if (op.type === 'tokens' && (!Number.isInteger(op.left) || !Number.isInteger(op.right) || op.left < 0 || op.right < 0 || op.left + op.right > 12 || typeof op.merged !== 'boolean')) throw new Error('Invalid tokens');
      if (op.type === 'arrow' && typeof op.visible !== 'boolean') throw new Error('Invalid arrow');
      const fields = {code:['text'], caption:['text'], output:['text'], focus:['line','token'], tokens:['left','right','merged'], arrow:['visible']}[op.type];
      if (Object.keys(op).some(k => k !== 'type' && !fields.includes(k))) throw new Error('Unknown operation field');
    }
  }
  return plan;
}
export function boardAt(plan, index) {
  validatePlan(plan);
  if (!Number.isInteger(index) || index < 0 || index >= plan.beats.length) throw new Error('Invalid beat index');
  const board = {code:'',caption:'',output:null,focus:null,tokens:null,arrow:false};
  for (const beat of plan.beats.slice(0,index+1)) for (const op of beat.ops) {
    if (['code','caption','output'].includes(op.type)) board[op.type] = op.text;
    if (op.type === 'focus') board.focus = {line:op.line,token:op.token};
    if (op.type === 'tokens') board.tokens = {left:op.left,right:op.right,merged:op.merged};
    if (op.type === 'arrow') board.arrow = op.visible;
  }
  return board;
}
export function tryPrint(source) {
  if (typeof source !== 'string' || source.length > 140) return {ok:false,message:'Mẫu chỉ nhận một dòng ngắn, tối đa 140 ký tự.'};
  const match = source.trim().match(/^print\(\s*(.*?)\s*\)$/);
  if (!match) return {ok:false,message:'Thử đặt nội dung trong ngoặc tròn của print(...). Mẫu chỉ hỗ trợ một lệnh print.'};
  const body = match[1];
  const literal = body.match(/^("([^"\\\r\n]*)"|'([^'\\\r\n]*)')$/);
  if (literal) return {ok:true,output:literal[2] ?? literal[3],kind:'text'};
  const sum = body.match(/^(\d{1,2})\s*\+\s*(\d{1,2})$/);
  if (sum) return {ok:true,output:String(Number(sum[1])+Number(sum[2])),kind:'sum'};
  return {ok:false,message:'Nếu muốn in chữ, thêm dấu ngoặc kép quanh chữ. Bản mẫu chỉ hiểu print với chuỗi đơn giản hoặc hai số 0–99 cộng nhau; đây không phải Python đầy đủ.'};
}
