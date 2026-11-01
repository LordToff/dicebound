# Rules mapping and implementation choices

The uploaded documents are game-design reference material. Their editorial instructions, historical approval language, and undecided concepts were not treated as instructions to operate this workspace.

## Implemented first encounter

- Three heroes, each 6 HP, three mixed customizable d6 Action Dice; empty Memory; Broken Body with separate Movement/Defense/Skill caps of three.
- Original starting Soul by default (three Blanks per die); approved Alternative test Soul selectable (two). Optional abilities need not all be equipped.
- Per-hero starter ownership exactly: four Basic Strikes, two Basic Movements, one Tactical Movement, two Basic Defenses, one Tactical Defense, one Focus, one First Aid, one Shove.
- Basic Strike deals a printed **1**, not Numeric. Basic Defense grants **1** Block. First Aid heals **1**. Basic Movement is **1**; Tactical Movement is **up to 3 in one straight line**. Focus rerolls another unresolved die. Shove moves an adjacent unit directly away by one, including the full boss footprint, without collision penalty.
- An open 9×9 board, no terrain or hazards, orthogonal distance and movement, rigid 2×2 boss footprint, 18 boss HP, one phase.
- Separate initiative d6 once per encounter, high first, boss wins ties. All Action Dice are shared-rolled at round start. Each unit completes its activation before initiative proceeds.
- Exact boss mixed dice: I = Advance/Advance/Strike/Strike/Brace/Drive Back; II = Advance/Skirmish/Strike/Sweep/Brace/Distort; III = Advance/Skirmish/Strike/Sweep/Drive Back/Fracture.
- Boss movement destinations lie on shortest legal routes around occupied squares. Players choose legal destinations. Single-target priorities use orthogonal footprint distance; Strike uses lowest Block before random ties. Ordinary target selection excludes Downed heroes.
- Advance up to 2; Skirmish moves up to 1 then attacks for 1 without extra fallback after failed attack; Strike 2; Sweep 1 to each adjacent hero once, including Downed heroes; Brace 2 Block; Distort Weakness 1 through boss's next turn start; Drive Back damage 1 then Push 1 even through Block or Downing; Fracture player-selectable temporary non-Blank removal with eligible-target fallback.
- Tutorial fallback moves closer up to 1, or gains 1 Block when unable. Failed original effects are not resumed after fallback.
- Tactical Defense is automatically stored and considered resolved; it grants 1 Block and optional orthogonal Step 1 at its trigger. Targets are rechecked and new targets receive their own Reaction windows. Reactions expire at the next shared roll.
- Pooled Block is consumed by absorbed damage and expires at the protected unit's turn start. No encounter face in this scope inflicts Burn or grants Persistent Block.
- Downed clears Block, Weakness, Stunned, unused results and Reactions. Initial protection lasts through the acting unit's full turn. Healing revives with Broken and queues a fresh-roll full recovery turn after the current unit. It replaces a remaining regular activation. Broken's next zero HP is death; dead pieces leave the grid.
- Forced-movement collision is 1 unavoidable damage plus Stunned. Stunned has no deferred die loss when no unresolved die remains. Reapplication adds damage instead of stacking. Shove has its explicit no-collision exception.
- Immediate victory at zero boss HP; immediate defeat if all heroes are Downed/dead. Rewards stop combat. Clean encounter restarts reconstruct recorded builds.
- Each hero receives the Bound Soul after victory, with the once-per-turn Blank-to-Move-1 effect and three-Blank minimum. No unapproved two-Blank reward Soul is provided.

## Explicit digital adaptation choices

- One local user may control all three heroes; this is a convenience adaptation of the physical three-player rule. There is no network multiplayer.
- Hero initiative ties use roster order, recorded visibly. The physical rule lets tied heroes choose.
- The unnamed tutorial boss is presented as **The Hollow One**. Names, pixel art, music, and cathedral fiction are original presentation, not claims about approved canon.
- Deployment is fixed for this prototype: zero-based boss anchor `(3,2)` and heroes `(2,6)`, `(4,6)`, `(6,6)`. The master leaves deployment undecided.
- Boss movement prompts choose a destination on a shortest route. Intermediate squares are checked by pathfinding rather than individually clicked. The convenience button chooses the first legal route; players may instead select any highlighted option.
- The default equipped loadout uses nine of the thirteen owned faces. Per-hero editing is implemented; trading copies between heroes is not exposed in this prototype.
- Every displayed starter face has its exact catalogue value. No difficulty bonus, free reroll, automatic Blank movement before Soul unlock, damage boost, or hidden stat scaling was added.
- Victory immediately equips the unlocked Soul for rematches after legal refitting. There is no between-encounter Event implementation in this milestone.

## Deferred rather than invented

The extended hero catalogue, Channel/Constant abilities, Numeric manipulation, copying/Echo, Poison/Burn/Doom and other out-of-scope statuses, acquired Memories and Bodies, transferable inventory, three-face reward pool, events, shops, base activities, later bosses, campaign progression, permanent curse rules, and online multiplayer are not included. The undefined Bonecraft/Bone entries remain unused. Starter and tutorial boss effects do not require a Numeric roll, so no unrelated Numeric UI was added.

## Validation limits

The native Linux executable and browser export were run. Windows was exported from the same validated project but could not be executed on this Linux machine. Automated battle tests exercise wins, losses, and recovery but are not a human balance study. Original prototype values are deliberately preserved.
