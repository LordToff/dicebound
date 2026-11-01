"""Generate an original layered, seamless 16-bar fantasy chip score."""
from pathlib import Path
import math,wave
import numpy as np
rate=22050; bpm=108; beat=60/bpm; length=64*beat; n=int(length*rate)
left=np.zeros(n);right=np.zeros(n)
def note(midi,start,duration,volume,voice='bell',pan=0):
 start=int(start*rate); count=min(int(duration*rate),n-start)
 if count<=0:return
 t=np.arange(count)/rate;f=440*2**((midi-69)/12)
 env=np.minimum(t/.014,1)*np.minimum((duration-t)/.09,1)
 if voice=='pad': y=(np.sin(2*np.pi*f*t)+.22*np.sin(2*np.pi*f*2.003*t))*env*.6
 elif voice=='bass': y=np.arcsin(np.sin(2*np.pi*f*t))*env*.8
 else:y=(np.sin(2*np.pi*f*t)+.3*np.sin(2*np.pi*f*2*t)+.12*np.sin(2*np.pi*f*3*t))*np.exp(-t*4)*env
 left[start:start+count]+=y*volume*(1-pan*.4);right[start:start+count]+=y*volume*(1+pan*.4)
chords=[[50,57,65],[46,53,62],[48,55,64],[45,52,61]]
melody=[74,0,77,76,74,69,72,0,70,0,74,72,70,65,69,0,72,0,76,74,72,67,70,0,69,0,73,76,74,73,69,0]
for bar in range(16):
 chord=chords[bar%4]
 for pitch in chord:note(pitch,bar*4*beat,4*beat,.055,'pad', (pitch%3-1)*.6)
 for step in range(8):note(chord[step%3]+12, (bar*4+step*.5)*beat,.7*beat,.045,'bell',(-1 if step%2 else 1)*.8)
 for b in range(4):note(chord[0]-12,(bar*4+b)*beat,.7*beat,.11,'bass')
 for b in range(4):
  t0=(bar*4+b)*beat;count=int(.16*rate);t=np.arange(count)/rate;start=int(t0*rate)
  kick=np.sin(2*np.pi*(68*t-110*t*t))*np.exp(-t*28)*.13
  if b%2: kick+=np.random.default_rng(bar*4+b).normal(0,.025,count)*np.exp(-t*35)
  end=min(n,start+count);left[start:end]+=kick[:end-start];right[start:end]+=kick[:end-start]
 for b in range(4):
  m=melody[(bar%8)*4+b]
  if m:note(m,(bar*4+b)*beat,1.7*beat,.10,'bell',.25)
# The score naturally returns to D minor; a short boundary fade prevents clicks.
a=np.stack([left,right],axis=1);a=np.tanh(a*1.3)*.72
fade=int(.018*rate);a[:fade]*=np.linspace(0,1,fade)[:,None];a[-fade:]*=np.linspace(1,0,fade)[:,None]
p=Path(__file__).resolve().parents[1]/'assets'/'tribunal.wav'
with wave.open(str(p),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(rate);w.writeframes((a*32767).astype('<i2').tobytes())
print('Original score:',round(length,2),'seconds, stereo,',p)

import subprocess
subprocess.run(["ffmpeg","-loglevel","error","-y","-i",str(p),"-c:a","libvorbis","-q:a","4",str(p.with_suffix(".ogg"))],check=True)
