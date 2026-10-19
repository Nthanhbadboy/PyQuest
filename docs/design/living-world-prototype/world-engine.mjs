export const islands = [
  {id:'home',name:'Đảo Khởi Đầu',short:'Làng của mình',x:.26,y:.64,dock:[.40,.83],tone:'mint',icon:'⌂',description:'Những con đường quen, một vài người bạn mới. Tutor và bảng giảng bắt đầu ở đây.',status:'Làng tương tác + bảng mẫu'},
  {id:'forest',name:'Làng Tán Lá',short:'Một làng trong rừng',x:.50,y:.32,dock:[.54,.52],tone:'leaf',icon:'♧',description:'Ý tưởng mở rộng: nhà trên cây, xưởng sáng tạo và những chiếc cầu nối ý tưởng.',status:'Phác thảo điểm đến · chưa có game'},
  {id:'stars',name:'Đảo Sao Mai',short:'Một bầu trời khác',x:.82,y:.57,dock:[.67,.69],tone:'lavender',icon:'✧',description:'Ý tưởng mở rộng: đài quan sát, câu đố bầu trời và những chuyến khám phá cùng Tutor.',status:'Phác thảo điểm đến · chưa có game'}
];
export const greetings = {
  welcome:['Bạn thấy con đường nhỏ kia không? Mình cùng ghé Tháp Python nhé.','Mèo đang dạo qua quảng trường đấy. Còn mình có một điều muốn vẽ cho bạn xem!','Hôm nay mình muốn thử một lời chào bằng code. Bạn đi cùng mình chứ?'],
  home:['Mây vừa ghé vào xưởng. Mình cũng có thể chọn một nơi để khám phá.','Bạn thích ghé một ngôi nhà hay ra bến thuyền? Mình đi cùng bạn.','Không cần làm mọi thứ ngay đâu. Mình bắt đầu bằng điều bạn tò mò nhé.'],
  atlas:['Ngoài làng còn có những hòn đảo khác. Chọn một bến, mình cùng xem hải đồ nhé.','Mỗi làng sẽ có một câu chuyện riêng. Hai đảo mới ở đây vẫn là bản phác thảo.'],
  forest:['Những chiếc cầu trên cây có thể nối các xưởng sáng tạo. Mình đang phác thảo nơi này thôi nhé.','Nếu xây một ngôi nhà trên cây, bạn sẽ đặt chiếc cầu ở đâu? Câu chuyện này còn đang được thiết kế.'],
  stars:['Đài quan sát ở kia! Mình muốn biến những chấm sáng thành một bài học có thể nhìn thấy.','Đảo Sao Mai mới là ý tưởng. Bảng giảng ở làng chính thì đã có thể thử ngay.'],
  return:['Mình về làng rồi. Code và nét vẽ trên bảng vẫn còn trong phiên này.','Một chuyến đi nhỏ, thêm một ý tưởng mới. Bạn muốn thử viết nó lên bảng không?']
};
export function nextGreeting(context,counters={}) {
  if(!Object.hasOwn(greetings,context))throw new Error('Unknown greeting context');
  const n=counters[context]??0;
  if(!Number.isInteger(n)||n<0)throw new Error('Invalid greeting index');
  return {text:greetings[context][n%greetings[context].length],counters:{...counters,[context]:n+1}};
}
const routes={
  'home:forest':[[.40,.83],[.47,.84],[.48,.70],[.52,.60],[.54,.52]],
  'home:stars':[[.40,.83],[.47,.84],[.50,.73],[.59,.67],[.67,.69]],
  'forest:stars':[[.54,.52],[.57,.58],[.62,.65],[.67,.69]]
};
export function routeBetween(from,to){
  if(!islands.some(i=>i.id===from)||!islands.some(i=>i.id===to)||from===to)throw new Error('Invalid route');
  const route=routes[`${from}:${to}`]||routes[`${to}:${from}`]?.slice().reverse();
  return route.map(p=>[...p]);
}
export function pointOnRoute(route,t){
  if(!Number.isFinite(t)||!Array.isArray(route)||route.length<2||route.some(p=>p.length!==2||p.some(v=>!Number.isFinite(v)||v<0||v>1)))throw new Error('Invalid path');
  if(t<=0)return [...route[0]];
  if(t>=1)return [...route.at(-1)];
  const lengths=route.slice(1).map((p,i)=>Math.hypot(p[0]-route[i][0],p[1]-route[i][1]));
  let distance=Math.max(0,Math.min(1,t))*lengths.reduce((a,b)=>a+b,0);
  for(let i=0;i<lengths.length;i++){if(distance<=lengths[i]||i===lengths.length-1){const f=lengths[i]?distance/lengths[i]:0;return [route[i][0]+(route[i+1][0]-route[i][0])*f,route[i][1]+(route[i+1][1]-route[i][1])*f];}distance-=lengths[i];}
}
export function startVoyage(from,to){return {from,to,elapsed:0,duration:3600,route:routeBetween(from,to),done:false};}
export function advanceVoyage(v,ms){if(!Number.isFinite(ms)||ms<0)throw new Error('Invalid delta');const elapsed=Math.min(v.duration,v.elapsed+ms);return {...v,elapsed,done:elapsed===v.duration,position:pointOnRoute(v.route,elapsed/v.duration)};}
export const villagers=[
 {id:'may',name:'Mây',art:'child-may.svg',offset:0,duration:21000,route:[[.50,.76],[.45,.80],[.34,.80],[.21,.79],[.15,.775],[.20,.745]]},
 {id:'bo',name:'Bo',art:'child-bo.svg',offset:6800,duration:24500,route:[[.51,.74],[.52,.79],[.62,.83],[.72,.82],[.73,.795]]}
];
export function villagerAt(v,time){
 if(!Number.isFinite(time)||time<0)throw new Error('Invalid world time');
 const phase=((time+v.offset)%v.duration)/v.duration;
 // Short visit: approach door -> disappear inside -> return along the same safe path.
 if(phase>=.38&&phase<.56)return {position:v.route.at(-1),inside:true,phase:'inside'};
 if(phase<.38)return {position:pointOnRoute(v.route,phase/.38),inside:false,phase:'walking-in'};
 if(phase<.94)return {position:pointOnRoute(v.route,1-(phase-.56)/.38),inside:false,phase:'walking-out'};
 return {position:v.route[0],inside:false,phase:'resting'};
}
