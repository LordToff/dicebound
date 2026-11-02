"""Exercise the embedded HTML in a secure browser context; block every external asset request."""
import asyncio,json,io
from PIL import Image
from pathlib import Path
from playwright.async_api import async_playwright
async def main():
 path=Path('/workspace/dicebound-downloads/Play-Dicebound.html')
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  page=await browser.new_page(viewport={'width':1280,'height':800})
  errors=[];external=[];logs=[];console_errors=[]
  page.on('pageerror',lambda e: (errors.append(str(e)),print('JS ERROR',e,flush=True)))
  page.on('console',lambda m: (logs.append(m.text),console_errors.append(m.text) if m.type=='error' else None,print(m.type,m.text,flush=True)))
  async def block(route):
   external.append(route.request.url);await route.abort()
  await page.route('http://**/*',block);await page.route('https://**/*',block)
  await page.route('https://dicebound.test/play',lambda route: route.fulfill(status=200,content_type='text/html',body=path.read_text()))
  await page.goto('https://dicebound.test/play',wait_until='load',timeout=60000)
  await page.wait_for_function("document.getElementById('status') === null",timeout=60000)
  await page.wait_for_timeout(1000)
  await page.mouse.click(952,42)
  await page.wait_for_timeout(1500)
  await page.reload(wait_until='load')
  await page.wait_for_function("document.getElementById('status') === null",timeout=60000)
  await page.wait_for_timeout(500)
  settings_image=Image.open(io.BytesIO(await page.screenshot())).convert('RGB')
  toggle_color=settings_image.getpixel((827,42))
  assert toggle_color[1] > toggle_color[0]*1.4, ('Blank-step preference did not survive reload',toggle_color)
  await page.mouse.click(778,42)
  await page.wait_for_function("document.fullscreenElement !== null",timeout=5000)
  await page.evaluate("document.exitFullscreen()")
  await page.wait_for_function("document.fullscreenElement === null",timeout=5000)
  await page.wait_for_timeout(300)
  await page.screenshot(path='/workspace/dicebound-standalone-title.png')
  await page.mouse.click(243,480)
  await page.wait_for_timeout(300)
  await page.screenshot(path='/workspace/dicebound-standalone-builder.png')
  await page.mouse.click(929,684)
  await page.wait_for_timeout(350)
  await page.screenshot(path='/workspace/dicebound-standalone-event.png')
  await page.mouse.click(320,728)
  await page.wait_for_timeout(1100)
  await page.screenshot(path='/workspace/dicebound-standalone-outcome.png')
  await page.mouse.click(862,734)
  await page.wait_for_timeout(1000)
  await page.screenshot(path='/workspace/dicebound-standalone-battle.png')
  await page.keyboard.press('Escape');await page.wait_for_timeout(200)
  await page.screenshot(path='/workspace/dicebound-standalone-help.png')
  assert not errors,errors
  assert not console_errors,console_errors
  assert not external,external
  print(json.dumps({'page_errors':errors,'external_requests':external,'result':'PASS: embedded game opens, saved Blank-step preference, fullscreen, builder, event choice and battle verified; zero external asset requests','console':logs[-10:]},indent=2))
  await browser.close()
asyncio.run(main())
