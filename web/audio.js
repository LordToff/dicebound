'use strict';
const Sound = (()=>{
let ctx=null,on=false,timer=null,step=0;let volume;
function init(){try{if(!ctx){ctx=new (window.AudioContext||window.webkitAudioContext)();volume=ctx.createGain();volume.gain.value=.12;volume.connect(ctx.destination);}ctx.resume();}catch(_){return false;}return true;}
function note(hz,start,duration,type='triangle',gain=.2){if(!ctx)return;const osc=ctx.createOscillator(),env=ctx.createGain();osc.type=type;osc.frequency.value=hz;env.gain.setValueAtTime(0,start);env.gain.linearRampToValueAtTime(gain,start+.015);env.gain.exponentialRampToValueAtTime(.001,start+duration);osc.connect(env);env.connect(volume);osc.start(start);osc.stop(start+duration+.02);}
const melody=[69,72,76,74,72,69,67,64,65,69,72,76,74,72,69,67,64,67,71,74,72,71,67,64,65,69,72,74,71,67,64,67];
const hz=n=>440*2**((n-69)/12);
function beat(){if(!on||!ctx)return;const t=ctx.currentTime+.025;note(hz(melody[step%32]),t,.36,'triangle',.25);if(step%2===0)note(hz([45,41,48,43][Math.floor(step/8)%4]),t,.65,'triangle',.32);if(step%4===0){note(hz(melody[(step+4)%32]-12),t,.9,'sine',.08);}step++;}
function toggle(){if(!init())return false;on=!on;if(on){beat();timer=setInterval(beat,310);}else{clearInterval(timer);timer=null;}return on;}
function fx(kind){if(!on||!ctx)return;const t=ctx.currentTime;const seq={hit:[240,150],move:[350,440],heal:[440,660,880],roll:[180,250,330,440],win:[440,554,660,880],hurt:[140,90],event:[330,440,554],click:[440]}[kind]||[440];seq.forEach((f,i)=>note(f,t+i*.06,.11,kind==='hurt'?'sawtooth':'square',.1));}
return{toggle,fx};})();
