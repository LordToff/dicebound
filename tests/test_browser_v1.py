"""Exercise the rebuilt game in Chromium, including events and complete campaigns."""
import asyncio,json
from pathlib import Path
from playwright.async_api import async_playwright
ROOT=Path(__file__).resolve().parents[1]
async def main():
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox'])
  page=await browser.new_page(viewport={'width':1280,'height':800})
  errors=[];requests=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  async def route(r):
   if r.request.url=='https://dicebound.test/':await r.fulfill(content_type='text/html',body=(ROOT/'docs/index.html').read_text())
   else:requests.append(r.request.url);await r.abort()
  await page.route('**/*',route)
  # Accelerate only the boss animation. All damage, movement and dice use real rules.
  await page.add_init_script('''const nativeTimeout=window.setTimeout;window.setTimeout=(f,t,...a)=>nativeTimeout(f,t===650?0:t,...a);let seed=123;Math.random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};''')
  await page.goto('https://dicebound.test/')
  await page.get_by_role('button',name='New Adventure').click()
  assert await page.locator('#screen').get_attribute('data-view')=='event'
  assert await page.locator('#arena').count()==0
  # No fight without a resolved event, even through the game API.
  assert await page.evaluate('enterFight()') is False
  # Every event choice applies once, shows the exact result, and starts no fight.
  branches=await page.evaluate('''()=>{let checks=0;for(let id=0;id<6;id++)for(let choice=0;choice<2;choice++){startNew();state.eventOrder=[id,...[0,1,2,3,4,5].filter(i=>i!==id)];selected=2;const before=state.heroes[2].hp;render();if(!chooseEvent(choice))throw Error('choice blocked');if(view!=='receipt'||state.status!=='receipt'||state.boss!==null)throw Error('event skipped');const after=JSON.stringify(state);if(chooseEvent(choice)!==false||JSON.stringify(state)!==after)throw Error('paid twice');if(!state.receipts[0].changes.length)throw Error('missing receipt');if(!document.querySelector('.receipt'))throw Error('missing visible receipt');if(!enterFight()||state.status!=='battle')throw Error('cannot enter');if(state.boss.hp!==BOSSES[0].hp+state.bossBonus)throw Error('incorrect boss cost');checks++;}return checks;}''')
  # Paid events cannot be selected when the chosen hero cannot pay; no mutations.
  assert await page.evaluate('''()=>{startNew();state.eventOrder=[0,1,2,3,4,5];state.heroes[0].hp=1;render();const before=JSON.stringify(state);return chooseEvent(0)===false&&JSON.stringify(state)===before;}''')
  # Old Godot saves never route this version into a fight.
  await page.evaluate('''()=>{localStorage.setItem('dicebound.cfg','journey_stage=battle');startNew();}''')
  await page.reload()
  await page.get_by_role('button',name='Continue run').click()
  assert await page.locator('#screen').get_attribute('data-view')=='event'
  await page.locator('[data-action="choice"]').last.click()
  await page.reload()
  await page.get_by_role('button',name='Continue run').click()
  assert await page.locator('#screen').get_attribute('data-view')=='receipt'
  await page.get_by_role('button',name='Enter the fight').click()
  await page.evaluate('''()=>{state.heroes[0].dice=[{face:'blank',used:false},{face:'strike',used:true}];save();}''')
  await page.reload()
  await page.get_by_role('button',name='Continue run').click()
  assert await page.get_by_role('button',name='Resume saved fight').count()==1
  await page.get_by_role('button',name='Resume saved fight').click()
  assert await page.evaluate('state.heroes[0].dice[1].used')
  # Free movement, paid Blank step, reforge never touches spent dice, and shields.
  unit=await page.evaluate('''async()=>{let n=0;const check=(v,m)=>{if(!v)throw Error(m);n++;};startNew();state.eventOrder=[0,1,2,3,4,5];chooseEvent(1);enterFight();let h=state.heroes[0];const dest=[...reachable(0)].find(([key,d])=>d===1)[0].split(',').map(Number);check(moveTo(...dest),'move rejected');check(h.steps===1,'free movement cost');h.dice=[{face:'blank',used:false},{face:'strike',used:true}];const spent=JSON.stringify(h.dice[1]);check(reforge(),'reforge');check(JSON.stringify(h.dice[1])===spent,'spent die rerolled');check(!reforge(),'second reforge');h.dice=[{face:'blank',used:false},{face:'guard',used:false}];selected=0;blankMove=0;const target=[[1,0],[-1,0],[0,1],[0,-1]].map(([x,y])=>[h.x+x,h.y+y]).find(([x,y])=>x>=0&&x<9&&y>=0&&y<7&&!occupied(x,y,0));check(moveTo(...target),'blank step');check(h.dice[0].used&&h.blankUsed&&h.steps===1,'blank payment');useDie(1);check(h.shield===2,'guard power');const warning=JSON.stringify(state.plan);h.dice=[{face:'nova',used:false}];h.x=state.boss.x-1;h.y=state.boss.y;state.boss.hp=Math.ceil(state.boss.max/2)+1;useDie(0);check(state.boss.phase===2&&JSON.stringify(state.plan)===warning,'unannounced damage changed');return n;}''')
  # Play complete runs. The bot avoids danger and uses only real legal movement/cards.
  campaigns=await page.evaluate('''async()=>{const results=[];for(let run=0;run<20;run++){startNew();let rounds=0,events=0;while(!['complete','defeat'].includes(state.status)&&rounds<120){if(state.status==='event'){selected=state.heroes.reduce((best,h,i)=>h.hp<state.heroes[best].hp?i:best,0);const event=EVENTS[eventId()];const choice=event.choices.findIndex(o=>!o.need||state.heroes[selected].hp>=o.need);chooseEvent(choice);events++;}else if(state.status==='receipt'){enterFight();}else if(state.status==='reward'){selected=state.fight%3;const reward=state.reward.find(f=>['nova','venom','bloom'].includes(f))||state.reward[0];chooseReward(reward);}else if(state.status==='battle'){rounds++;reforge();for(let i=0;i<3&&state.status==='battle';i++){chooseHero(i);const h=state.heroes[i];if(h.hp<=0)continue;let best=[h.x,h.y],bestScore=-Infinity;for(const [key,cost]of reachable(i)){const [x,y]=key.split(',').map(Number);const d=distance({x,y}),danger=state.plan.cells.some(p=>p[0]===x&&p[1]===y);const ranges=h.dice.filter(d=>!d.used&&FACES[d.face].kind==='attack').map(d=>FACES[d.face].range);const wanted=ranges.length?Math.min(...ranges):2;const score=(danger?-100:0)+(d<=wanted?25:0)-Math.abs(d-Math.max(1,wanted-1))*3-cost*.1;if(score>bestScore){bestScore=score;best=[x,y];}}if(best[0]!==h.x||best[1]!==h.y)moveTo(...best);for(let j=0;j<2&&state.status==='battle';j++){useDie(j);if(healing!==null){const target=state.heroes.reduce((best,u,k)=>u.hp<state.heroes[best].hp?k:best,0);chooseHero(target);healing=null;}}}if(state.status==='battle'){endRound();while(busy)await new Promise(r=>setTimeout(r,1));}}}results.push({status:state.status,rounds,events});if(state.status==='complete'&&events!==3)throw Error('campaign skipped an event');if(rounds>=120)throw Error('campaign never terminates');}return results;}''')
  wins=sum(r['status']=='complete' for r in campaigns)
  assert wins>=10, campaigns
  # Loss and revival routes actually work, including a usable retry receipt.
  assert await page.evaluate('''async()=>{startNew();chooseEvent(1);enterFight();state.heroes[0].hp=0;state.heroes[1].hp=2;selected=1;state.heroes[1].dice=[{face:'heal',used:false}];useDie(0);chooseHero(0);if(state.heroes[0].hp!==2||state.heroes[0].dice.length!==2)throw Error('revive failed');state.heroes.forEach((h,i)=>{h.hp=1;h.shield=0;h.x=i;h.y=0;});state.plan.cells=[[0,0],[1,0],[2,0]];endRound();while(busy)await new Promise(r=>setTimeout(r,1));if(state.status!=='defeat')throw Error('defeat');retry();return view==='receipt'&&state.heroes.every(h=>h.hp===6);}''')
  assert await page.evaluate("""()=>{startNew();chooseEvent(1);enterFight();const patterns=[];for(let id=0;id<3;id++){state.boss.id=id;state.boss.phase=2;state.round=1;makePlan();patterns.push(JSON.stringify(state.plan.cells));if(state.plan.cells.some(([x,y])=>x<0||x>=9||y<0||y>=7||footprint(x,y)))return false;}return new Set(patterns).size===3;}""")
  # Real mouse-based movement and action use, not just direct engine calls.
  await page.evaluate('startNew()')
  await page.locator('[data-action="choice"]').last.click()
  await page.get_by_role('button',name='Enter the fight').click()
  dest=await page.evaluate('''()=>[...reachable(0)].find(([key,c])=>c===1)[0].split(',').map(Number)''')
  arena=await page.locator('#arena').bounding_box()
  await page.mouse.click(arena['x']+(dest[0]+.5)*arena['width']/9,arena['y']+(dest[1]+.5)*arena['height']/7)
  assert await page.evaluate('state.heroes[0].steps')==1
  await page.evaluate('''()=>{state.heroes[0].dice=[{face:'guard',used:false},{face:'guard',used:false}];render();}''')
  await page.locator('[data-action="die"]').first.click()
  assert await page.evaluate('state.heroes[0].dice[0].used')
  await page.locator('#blank-setting').uncheck()
  await page.reload()
  await page.get_by_role('button',name='Continue run').click()
  await page.get_by_role('button',name='Resume saved fight').click()
  assert not await page.locator('#blank-setting').is_checked()
  await page.get_by_role('button',name='Inspect six faces').click()
  assert await page.locator('#loadout .pool-face').count()==6
  await page.get_by_role('button',name='Close ×').click()
  await page.get_by_role('button',name='How to play').click()
  assert await page.locator('#guide').evaluate('(e)=>e.open')
  await page.get_by_role('button',name='Close ×').click()
  await page.get_by_role('button',name='Music: off').click()
  assert await page.get_by_role('button',name='Music: on').count()==1
  await page.get_by_role('button',name='Music: on').click()
  await page.get_by_role('button',name='Full screen').click()
  assert await page.evaluate('!!document.fullscreenElement')
  await page.evaluate('document.exitFullscreen()')
  await page.wait_for_timeout(100)
  await page.screenshot(path='/workspace/dicebound-v1-tested-battle.png',full_page=True)
  # Test a narrow touch-sized viewport: no horizontal scrolling, usable controls.
  await page.set_viewport_size({'width':390,'height':844})
  assert await page.evaluate('document.documentElement.scrollWidth<=innerWidth'), 'mobile overflow'
  await page.screenshot(path='/workspace/dicebound-v1-mobile.png',full_page=True)
  assert not errors,errors
  assert not requests,requests
  print(json.dumps({'event_choices':branches,'mechanic_checks':unit,'campaigns':len(campaigns),'wins':wins,'rounds':[r['rounds'] for r in campaigns],'browser_errors':errors,'external_requests':requests,'result':'PASS'},indent=2))
  await browser.close()
if __name__ == '__main__':
 asyncio.run(main())
