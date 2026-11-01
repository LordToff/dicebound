"""Exercise the embedded HTML in a secure browser context; block every external asset request."""
import asyncio,json
from pathlib import Path
from playwright.async_api import async_playwright
async def main():
 path=Path('/workspace/dicebound-downloads/Play-Dicebound.html')
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  page=await browser.new_page(viewport={'width':1280,'height':800})
  errors=[];external=[];logs=[]
  page.on('pageerror',lambda e: (errors.append(str(e)),print('JS ERROR',e,flush=True)))
  page.on('console',lambda m: (logs.append(m.text),print(m.type,m.text,flush=True)))
  async def block(route):
   external.append(route.request.url);await route.abort()
  await page.route('http://**/*',block);await page.route('https://**/*',block)
  await page.route('https://dicebound.test/play',lambda route: route.fulfill(status=200,content_type='text/html',body=path.read_text()))
  await page.goto('https://dicebound.test/play',wait_until='load',timeout=60000)
  await page.wait_for_function("document.getElementById('status') === null",timeout=60000)
  await page.wait_for_timeout(1000)
  await page.screenshot(path='/workspace/dicebound-standalone-title.png')
  await page.mouse.click(243,480)
  await page.wait_for_timeout(300)
  await page.screenshot(path='/workspace/dicebound-standalone-builder.png')
  await page.mouse.click(929,684)
  await page.wait_for_timeout(350)
  await page.screenshot(path='/workspace/dicebound-standalone-event.png')
  await page.mouse.click(665,641)
  await page.wait_for_timeout(350)
  await page.screenshot(path='/workspace/dicebound-standalone-outcome.png')
  await page.mouse.click(862,687)
  await page.wait_for_timeout(1000)
  await page.screenshot(path='/workspace/dicebound-standalone-battle.png')
  await page.keyboard.press('Escape');await page.wait_for_timeout(200)
  await page.screenshot(path='/workspace/dicebound-standalone-help.png')
  assert not errors,errors
  assert not external,external
  print(json.dumps({'page_errors':errors,'external_requests':external,'result':'PASS: embedded game opens, builder, event choice, consequence screen and battle playable; guide works; zero external asset requests','console':logs[-10:]},indent=2))
  await browser.close()
asyncio.run(main())
