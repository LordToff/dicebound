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
