"""Bundle a Godot single-threaded web export into an offline-playable HTML file."""
from pathlib import Path
import base64,gzip,re,json,argparse
parser=argparse.ArgumentParser();parser.add_argument('web',type=Path);parser.add_argument('output',type=Path);args=parser.parse_args()
web=args.web
assets={}
for name,mime in [('index.wasm','application/wasm'),('index.pck','application/octet-stream')]:
 assets[name]={'data':base64.b64encode(gzip.compress((web/name).read_bytes(),compresslevel=9,mtime=0)).decode(),'mime':mime}
bootstrap='''
// All game resources stay inside this document. No external requests are required.
const packedAssets = ASSETS;
const originalFetch = window.fetch.bind(window);
const unpackedAssets = new Map();
async function unpackAsset(name) {
 if (!unpackedAssets.has(name)) {
  unpackedAssets.set(name, (async () => {
   const entry = packedAssets[name];
   const compressed = Uint8Array.from(atob(entry.data), c => c.charCodeAt(0));
   const stream = new Blob([compressed]).stream().pipeThrough(new DecompressionStream('gzip'));
   return new Uint8Array(await new Response(stream).arrayBuffer());
  })());
 }
 return unpackedAssets.get(name);
}
window.fetch = async function(input, options) {
 const raw = typeof input === 'string' ? input : input.url;
 const name = new URL(raw, document.baseURI).pathname.split('/').pop();
 if (Object.hasOwn(packedAssets, name)) {
  return new Response(await unpackAsset(name), {status: 200, headers: {'Content-Type': packedAssets[name].mime}});
 }
 return originalFetch(input, options);
};
'''.replace('ASSETS',json.dumps(assets,separators=(',',':')))
for suffix,key in [('audio.worklet.js','__diceboundAudio'),('audio.position.worklet.js','__diceboundAudioPosition')]:
 code=(web/('index.'+suffix)).read_text()
 bootstrap+='\nwindow.'+key+' = URL.createObjectURL(new Blob(['+json.dumps(code)+'], {type:"application/javascript"}));\n'
engine=(web/'index.js').read_text()
engine=engine.replace('return `${loadPath}.audio.worklet.js`;', 'return window.__diceboundAudio;').replace('return `${loadPath}.audio.position.worklet.js`;', 'return window.__diceboundAudioPosition;')
html=(web/'index.html').read_text()
version_match = re.search(r'config/version="([^\"]+)"', (Path(__file__).resolve().parents[1]/'project.godot').read_text())
version = version_match.group(1) if version_match else "0.1.0"
html=html.replace('<head>', '<head>\n<meta name="application-version" content="'+version+'">')
html=html.replace('<script src="index.js"></script>', '<script>'+bootstrap.replace('</script','<\\/script')+'\n'+engine.replace('</script','<\\/script')+'</script>')
assert '<script src="index.js">' not in html
for name in ['index.png','index.icon.png','index.apple-touch-icon.png']:
 data='data:image/png;base64,'+base64.b64encode((web/name).read_bytes()).decode()
 html=html.replace('"'+name+'"','"'+data+'"')
html=html.replace('<title>DICEBOUND · The Hollow Tribunal</title>','<title>Play DICEBOUND</title>')
html=html.replace('<head>', '<head>\n<meta name="description" content="DICEBOUND: an offline-playable tactical pixel-art dice battler.">')
# A self-contained branded loading screen, with the real engine progress bar.
html=re.sub(r'^[\t ]*<img id="status-splash"[^>]*>[\t ]*\n?', '', html, flags=re.MULTILINE)
icon='data:image/png;base64,'+base64.b64encode((web/'index.icon.png').read_bytes()).decode()
loading='<div id="loading-shell"><img src="'+icon+'" width="72" height="72" alt=""><h1>DICEBOUND</h1><p>THE HOLLOW TRIBUNAL</p><small>Preparing your journey…</small></div>'
html=html.replace('<div id="status">','<div id="status">'+loading)
html=html.replace('</head>', '<style>#status{position:fixed;inset:0;display:flex;flex-direction:column;justify-content:center;align-items:center;background:radial-gradient(ellipse at center,#242334 0%,#101321 70%)}#loading-shell{text-align:center;font-family:monospace;color:#e7b86a}#loading-shell img{image-rendering:pixelated;display:block;margin:0 auto 22px}#loading-shell h1{font-size:42px;letter-spacing:8px;margin:0 0 10px;color:#e6dfcb}#loading-shell p{font-size:12px;letter-spacing:4px;color:#e7b86a}#loading-shell small{display:block;margin-top:22px;font-size:13px;color:#9398ab}#status-progress{width:300px;height:7px;margin-top:26px;accent-color:#e7b86a}#status-notice{max-width:580px;font:14px monospace;color:#e66d78;padding:20px}</style></head>')
html=html.replace('background-color: black;', 'background-color: #101321;')
notices = '\n'.join((web/name).read_text() for name in ['GODOT_LICENSE.txt','GODOT_COPYRIGHT.txt','FONT_LICENSE.txt'])
html += '\n<!-- Third-party notices\n'+notices.replace('--','—')+'\n-->\n'
args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(html)
print(args.output,round(args.output.stat().st_size/1024/1024,2),'MiB')
