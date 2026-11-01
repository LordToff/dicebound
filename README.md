# DICEBOUND — The Hollow Tribunal

A playable, 16-bit-style tactical dice-building boss battler made in Godot 4.7, based on the supplied **Master Rules v14 (31 October 2026)** and **Face Catalogue v2 (31 October 2026)**. This prototype now includes the tutorial boss, a persistent journey loop, and six original test events. It does not implement the full extended catalogue or a multi-boss campaign.

## Play

**Simplest browser version:** open `Play-Dicebound.html` in a current Chrome or Edge browser. The single HTML file embeds the engine, game, artwork and audio. No installation, extraction, network access or local server is needed. Godot requires a secure browser context; ordinary local HTML files are treated as trustworthy by these browsers.

- **Windows:** extract the Windows download and run `Dicebound.exe`. No Godot installation required.
- **Linux x86-64:** extract the Linux download, make `Dicebound.x86_64` executable if necessary, and run it. No Godot installation required.
- **Browser:** extract the Web download and serve the entire folder using any static HTTP server, for example `python3 -m http.server 8000` from that folder. Open the server in a current browser. Opening the HTML directly as a local file does not work. WebGL 2 is required; no cross-origin isolation headers are needed for this single-threaded export. The same folder can be uploaded as an HTML game to itch.io, with `index.html` as its entry point.
- **Edit:** import `project.godot` into Godot **4.7 stable**. The project has no external addons, package manager dependencies, or required credentials.

Click **Carve Your Dice** to build, or **New Journey** to use the legal starter loadouts. Select a face from the pool and paint a die side. Every die needs at least three Blanks with the Original starting Soul, or two with the selectable Alternative. Every owned copy and the separate Broken Body category caps are checked.

### Controls

- Mouse: choose dice, targets, movement destinations, boss routes, Fracture losses, and push directions.
- `1`, `2`, `3`: select a hero's rolled die.
- `E`: finish the active hero's turn, declining remaining beneficial results.
- `Esc` or right-click: cancel an uncommitted selection for free. With no selection, `Esc` opens/closes the field guide.
- SFX button: mute/unmute both music and effects.

Ordinary actions wait for their owner's initiative activation. Roll results, boss intentions, and stored Reactions are public. The boss does **not** act after each hero. Click **Resolve Die** during its activation and follow the prompts. Tactical Defense is offered at attack declaration, before damage. Gold push-direction buttons also allow selecting off-board collision directions.

Builds, the unlocked Bound Soul, owned reward faces, permanent curses, event-pool numbers and committed event outcomes are saved locally. An encounter itself is not saved; restarting a committed encounter retains its event injuries. Browser saves are specific to that site's origin. Victory unlocks the 6-HP, three-Blank reward Soul: once each turn, spend one Action Blank to Move 1. An Alternative-Soul build must be refitted before using that reward. Defeat supports a clean restart without campaign penalties.

### Presentation

Original procedurally drawn pixel heroes, a twisted humanoid boss, a ruined cathedral title scene, eclipse, limited dark-fantasy palette, crisp rune UI, animated rolling, embers, slash streaks, block/healing bursts, floating combat text, screen shake, procedural chip effects and an original 35.6-second looping stereo score with melody, chord pads, arpeggios, bass, and percussion. Art and audio are self-contained.

## Development and tests

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/test_game.gd
godot --path .
```

Use a Godot 4.7 binary for `godot` in these examples. On the prepared cloud machine it is `/workspace/.godot-dev/tools/4.7/Godot_v4.7-stable_linux.x86_64`. Writable XDG cache/config/data directories are already prepared under `/workspace/.godot-dev`.

Tests cover construction, ownership, fixed initiative, footprint range, occupied-square movement, exact starter effects, protection and recovery, stored Reactions, Fracture, shortest boss routes, collisions, Soul use, and encounter completion. A controlled legal-roll fixture checks a full winning fight; 20 deterministic random fights exercise termination and losing outcomes. These tests establish behavior, not balance. The simple benchmark player loses frequently; the prototype's original numbers remain unchanged for designer playtesting.

`tests/test_events.gd` exercises every event choice, all risk-die branches, ownership and locks, serialized save/resume, event injury carryover, pool exhaustion and the reward faces in combat. Run it with the same `godot --headless --path . --script res://tests/test_events.gd` pattern.

`tests/capture.gd` captures the rendered title, builder, and battle using a graphical display. `tests/balance.gd` is an exploratory benchmark, not a passing/failing balance requirement. `export_presets.cfg` contains release presets for Web, Linux, and Windows. Install the corresponding official 4.7 export templates before exporting.

See [RULES_MAPPING.md](RULES_MAPPING.md) for scope, exact implementation choices, and deferred content. Godot and DejaVu license notices are included in `assets/` and in the binary downloads.

To regenerate the single-file browser build after a Web export:

```sh
python3 tools/build_standalone.py ../dicebound-builds/web ../dicebound-downloads/Play-Dicebound.html
```

## GitHub Pages publication

The prebuilt browser game is in `docs/index.html`. It embeds every runtime asset and works on a standard HTTPS static site. `docs/.nojekyll` keeps GitHub Pages from processing it as a Jekyll project.

Publish this repository as `dicebound`. In GitHub **Settings → Pages**, choose **Deploy from a branch**, branch **main**, folder **/docs**. The deployment does not require an Actions build, Godot installation, or external asset hosting. After GitHub reports a successful deployment, use the HTTPS URL shown by Pages.

To update the site, re-export the Web build and run `tools/build_standalone.py`, with `docs/index.html` as the output. Commit that file and push the main branch.

## v0.2 — clarity and presentation

Combat uses large ability cards with full names, exact effects, ready/spent/Reaction states and explicit rolled-die costs. Hovering previews legal reach. Selecting Block or Focus does not spend it until confirmation; cancelling selection is free. Direct target buttons show the actual HP change after Block or the healing cap. Ending a turn with unused results requires confirmation.

The builder is now side-first: choose a die side, then an ability. Balanced, Assault and Support presets are legal under either starting Soul. Invalid placements are refused; unique owned faces can swap between sides without duplication. Probabilities show each die's non-Blank roll chance.

The presentation adds a newly composed stereo chip score, distinct hit/heal/Block/step/carve sounds, attack streaks, layered impact rings, movement trails, hit flashes, breathing sprites, and torchlight. The music source generator is `tools/compose_score.py` (NumPy and FFmpeg are needed only to regenerate audio, not to play or edit the game).

## v0.3 — The Roads Between

Choose **Camp / Test Six Events** on the title screen to test any remaining numbered event directly. Or finish your dice preparation and click **Venture Out** to roll the d6 normally. Event titles and stories are revealed only after selection. The six original stories take high-level inspiration from consequential dark-fantasy road encounters; no names, text, artwork or event designs from Kingdom Death: Monster or Gloomhaven were copied.

The flow is recovery → voluntary preparation → one event → minimum necessary face repairs → boss encounter. Changing the selected hero before choosing determines who receives the face and pays the cost. Every possible outcome is printed before committing. The Event Pool removes a resolved event at its original d6 number, rerolls unmapped results, and returns to base without a roll when empty.

- **The Bell Below Stone:** trade two HP for Lantern Cut, or walk away.
- **The Iron Stitcher:** gain Iron Ward with a permanent Cursed Blank, or pay two HP instead.
- **The Moth Causeway:** risk a d6 for Pilgrim Step, or pay one HP per hero for certainty.
- **The Orchard of Blades:** permanently exchange an owned Basic Strike for Lantern Cut, or accept a curse for an extra First Aid.
- **The Ashen Hospice:** cleanse a permanent curse (gain Basic Defense if none), or buy a First Aid with one HP.
- **The Hollow Procession:** accept a curse for Pilgrim Step, or risk face loss, wounds, or Lantern Cut.

New, explicitly original test reward faces: **Lantern Cut** (Attack: 2 damage to an adjacent unit), **Iron Ward** (Defense: gain 2 Block), and **Pilgrim Step** (Movement: Move up to 2, allowing turns). Each costs one rolled result, follows normal targeting and construction, and is permanently owned. They are not free starting faces or replacements for similarly named catalogue entries.

Rewards enter inventory; equip them in the builder's **Found Faces** tab during the NEXT preparation. Event wounds carry into the immediate fight. Cursed Blanks count toward Soul Blank minima but cannot be overwritten, cleared, preset away or removed by Fracture. Only explicit cleansing unlocks them. All six event choices remove the triggering entry from this test pool.

A deliberately marked **New Test Expedition** button refills an exhausted pool for repeated testing; it keeps owned faces and permanent curses. This is a manual prototype test control, not an automatic full-pool reset or finalized campaign progression. The same tutorial boss is repeated between events.
