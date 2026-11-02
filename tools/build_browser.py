"""Build the new browser game as one offline-capable HTML file (no dependencies)."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
web=root/'web'
html=(web/'index.html').read_text()
html=html.replace('<link rel="stylesheet" href="style.css">','<style>'+(web/'style.css').read_text()+'</style>')
for name in ['sprites.js','audio.js','game.js']:
    html=html.replace(f'<script src="{name}"></script>','<script>\n'+(web/name).read_text().replace('</script','<\\/script')+'\n</script>')
(root/'docs'/'index.html').write_text(html)
out=root.parent/'dicebound-downloads'
out.mkdir(exist_ok=True)
(out/'Play-Dicebound.html').write_text(html)
print(f'Built Dicebound 1.0: {len(html.encode()):,} bytes, no external assets.')
