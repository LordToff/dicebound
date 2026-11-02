# 1.0 — The Ember Road: a new browser game

Rebuilt the browser release from scratch in plain JavaScript, HTML and Canvas. This replaces the Godot browser export. The old Godot project remains historical source; its old saves and native downloads are separate.

## The event skip is removed
- The old journey button could resume an already committed battle without showing its event. That resume path and save format are not used in this game.
- New Adventure always begins with an event, never a fight. Every subsequent new encounter gets its own event.
- Event choices show exact costs, the receiving hero and the face being replaced. Costs apply once and cannot be paid again on reload.
- A result receipt explains what changed. Enter the Fight is a separate, explicit button.
- Continue from a saved battle shows its previous event receipt before Resume Saved Fight. A retry also returns through that receipt.

## Original pixel graphics
- Removed all old illustrated scenes and image assets from the shipped browser game.
- Heroes, bosses, NPCs, ability icons, scenery and terrain are drawn from original indexed pixel patterns and simple pixel geometry.
- Crisp nearest-neighbor display, integer sprite scales, a restrained console-style palette, idle animation and distinct boss palettes.
- Added sword arcs, ranged projectiles, floating numbers, shield feedback and impact shake. Reduced-motion preferences stop shake and idle motion.
- A new original synthesized chiptune has melody, bass and harmony, with short action sounds. Music starts only when enabled.

## Simpler, quicker combat
- Control three heroes in any order. There is no initiative queue or manual boss resolution.
- Each hero rolls two dice from one six-face pool. Each visible card is one action and costs only that die.
- Free two-step movement per hero, split around actions. No movement-die requirement.
- Attacks automatically hit the boss when in range. Guard applies immediately. Heal by choosing a party portrait or tile.
- A free, party-wide Blank reforge once per round guarantees installed abilities for unused Blanks; spent dice are preserved.
- Blanks can always throw a 1-damage Pebble at range 3. The saved Blank Step toggle also lets each hero trade a Blank for one step per round.
- An all-Blank shared roll retains one installed non-Blank ability where possible.
- Six-HP heroes, simple shield, healing that revives, party recovery after victory and a full-health retry option.
- Face upgrades equip immediately and their replacement is shown. The complicated old manual editor, confirmation flow, Souls and permanent curse system are absent from this new ruleset.

## A complete short adventure
- Three encounters: Briar Guardian (22 HP), The Drowned Bell (28 HP), and The Cinder Crown (34 HP).
- Different attack patterns: root sweeps, cross blasts and thorn rings; separated tidal rows; crossing crownfire diagonals and falling embers.
- Bosses enrage at half health and deal stronger damage from the next announced plan. Warnings stay fixed through your decisions.
- Red tiles show every damaging area. There is no hidden attack outside those tiles. Boss movement happens between warnings.
- Six rewritten events with two transparent bargains each. Three distinct events are drawn per adventure.
- Win a fight, recover, choose one of three upgrades for a hero, then visit the next event. Defeat the final boss to reach an ending with your event history.

## Browser and validation
- The entire game is a roughly 60 KB self-contained HTML file, replacing the roughly 20 MB engine bundle. No external fonts, images or audio requests.
- Responsive layout, real HTML buttons, keyboard shortcuts, visible focus, full-screen controls, guide and automatic local saves.
- Tested all 12 event choices, save/resume, real mouse movement, action payments, phase warning stability, revival, defeat/retry, music, preferences and mobile width.
- Twenty seeded full-adventure simulations completed successfully. These are regression checks; human difficulty and enjoyment still need player feedback.

---

# 0.6 — Adventure overhaul

This is a new, deliberately redesigned ruleset. The title-screen ruleset button retains the original Classic prototype for comparison. Existing inventories, curses, events and unlocked Souls are kept.

## A faster run
- An event comes before every new fight. The main flow is preparation → event → boss.
- Matching event rewards immediately upgrade a starter face before this fight. Lantern Cut replaces Basic Strike, Iron Ward replaces Basic Defense, Pilgrim Step replaces Basic Movement, and extra First Aid can replace Focus. Unmatched rewards remain owned in inventory. Locked faces are never replaced.
- Each hero gets a free Move 2 every turn, independent of dice. Press M or use the button. Cancel before choosing a destination without paying.
- Each hero can Reforge unused Blanks once per turn. Press R; it never rerolls spent results or stored reactions.
- Shared rolls cannot leave an otherwise functional hero with three dead Blanks: one installed ability is retained when all three results would be Blank. No abilities are invented on an all-Blank build.
- Blank-step movement defaults on for fresh players; existing saved preferences are respected.
- Heroes act first in roster order, then the boss. No surprise initiative loss before the first decision.

## Actions worth taking
- Basic Strike: 2 damage. Lantern Cut: 3 damage.
- Flanking opposite sides of the boss adds 1 damage.
- Basic Defense: 2 Block. Iron Ward: 3 Block.
- First Aid: heal 2, including revival.
- Heroes gain 1 protective Block at the start of their turn.
- Start closer to the fight instead of spending opening turns walking across an empty board.

## The Bell Tyrant
- 24 HP and two phases. At 12 HP it enrages; new patterns begin next round.
- Phase one alternates Advance / Ruin / Rest and Skirmish / Strike / Rest.
- Phase two alternates Advance / Ruin / Sweep and Skirmish / Strike / Ruin.
- Ruin marks a cross on the arena at the shared roll. Its location stays fixed, so move out before the boss acts. It deals 2 damage in phase one and 3 in phase two, using Block. This ground blast is avoided by positioning rather than a late Reaction prompt.
- Phase-two Strike deals 3 and Sweep deals 2. Rest is a genuine breathing beat, not hidden defense or healing.
- The boss now uses a detailed sprite. Harmless steps, route choices and attack resolution proceed automatically at a readable pace. Eligible Reactions still pause for the player.
- Boss movement uses its permitted approach distance instead of choosing the first, shortest-looking one-square option.

## Less clicking
- Click an Attack while adjacent to the boss to strike immediately; otherwise choose a target normally.
- Block faces resolve immediately. No confirmation dialog for gaining your own protection.
- End turn is one click in Adventure. Classic keeps its original confirmation.
- M: free move; R: reforge; 1/2/3: abilities; E: end turn; Escape/right-click: cancel an uncommitted choice.
- Hero sprites in Adventure combat now match the story artwork.

## Validation and limits
- Legacy behavior is tested explicitly in Classic, rather than silently redefining those rules.
- A separate Adventure benchmark runs 50 deterministic complete fights, checks termination, and verifies that the starter builds can win. It is a regression check, not a substitute for player balance feedback.
- This release still has one boss and six events. It is not a complete multi-boss campaign. Inventory trading and the full extended catalogue remain future work.
