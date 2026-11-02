# DICEBOUND — The Ember Road

[Play in your browser](https://lordtoff.github.io/dicebound/?v=1.0.0)

A new tactical dice adventure, rebuilt from scratch for the browser. Three heroes, three bosses, six possible story events, original low-resolution pixel sprites and an original chiptune soundtrack. No engine download, external assets, packages or network connection are needed after opening the page.

## Play

Start **New Adventure**. Choose a hero and an event bargain, read its result, then explicitly enter the fight. Every later boss is also preceded by a fresh event. The main loop is **event → choice receipt → fight → die upgrade → next event**. Continue shows the saved event receipt before resuming a battle.

- Each hero has 6 HP, a six-face pool, and two dice rolled from that pool per round. Each rolled card is one action; spending it is the entire cost.
- Pick a hero and click a highlighted square to move. Each hero gets two free steps per round; movement can be split around actions.
- Click attacks to hit the boss automatically when in range. Guard protects the caster. Mend asks you to choose a hero; Bloom heals the whole party. Healing revives fallen heroes.
- Reforge turns all unused Blanks into installed abilities, once per round. Spent dice stay spent. A Blank also works as a 1-damage Pebble at range 3.
- The Blank Step option trades one Blank for one extra step, once per hero per round. It defaults on and is saved separately.
- Marked red tiles show exactly where the boss will hit when you end the round. Move away or use shield. All unused shield expires after the boss attack. The boss may reposition between rounds, before revealing its next warning.
- At half HP, bosses enrage. Stronger damage is announced with the next warning; a phase change never secretly increases the current attack.
- Victory heals everyone for up to 2 HP and lets you equip one of three face upgrades. Each upgrade replaces a Blank first, otherwise a starter face. The exact replacement is shown before choosing.
- Fallen heroes remain on the board and can be revived. All three fallen ends the encounter. Recovery offers a full-health retry through the event receipt.

Keyboard: **1/2/3** select hero, **Q/W** use dice, **R** reforge, **E** end round, **Escape** cancel a pending heal or Blank step. Music is off until enabled. Full-screen and an in-game guide are available.

Progress saves automatically to this browser. The rebuilt game has a separate save slot from the old Godot prototype; it does not import old builds or restart old committed fights. It does not save halfway through the short boss animation: closing there resumes the last complete player decision state.

## Build and test

The source is in `web/`: `game.js` contains the rules and interface, `sprites.js` contains original indexed pixel drawings and scenery, and `audio.js` contains synthesis and composition. `style.css` handles responsive layout. There are no runtime dependencies.

```sh
python3 tools/build_browser.py
python3 -m http.server 8000 --directory docs
```

The in-game dice inspector shows every currently installed face.

The build writes `docs/index.html` for GitHub Pages and `../dicebound-downloads/Play-Dicebound.html` for offline play. The HTML embeds all code, styles, sprites and sound. You can also serve `web/` directly while editing.

With Python Playwright and Chromium installed:

```sh
python3 tests/test_browser_v1.py
```

The browser suite exercises all 12 event branches, atomic event payment, event receipts on reload, real mouse controls, free movement, reforge costs, shield, phase warnings, revival, defeat/retry, saved preferences, music, full screen and mobile overflow. It also plays 20 seeded complete adventures with a simple legal-move bot. This checks functionality; it is not a human balance or enjoyment study.

## Scope and history

This is a single-player, three-boss adventure. Dice building happens through immediate event and victory upgrades. It has no manual dice editor, old Soul/curse system, online multiplayer or extended campaign. The user authorized a free redesign for simpler, more accessible play; the new rules deliberately depart from the supplied design documents.

[CHANGELOG.md](CHANGELOG.md) describes the rebuild. The Godot prototype remains in the repository as historical source, with its original instructions in [LEGACY_GODOT.md](LEGACY_GODOT.md) and historical rules in [RULES_MAPPING.md](RULES_MAPPING.md). Godot/native exports and their older tests do not represent the current browser game. The browser build ships none of the old illustrated image assets.
