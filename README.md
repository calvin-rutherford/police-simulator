# Sunset Sheriff

A cute first-person Western town-defense game made with Godot 4.5. Explore a pastel desert town, meet your neighbors, prepare in daylight, then protect yourself and the town bell at night. All art and sound are original procedural primitives; no proprietary assets or gore.

## Play

Install **Godot 4.5** (Compatibility renderer), then open `project.godot` and press **F6** on `main.tscn`, or run:

```sh
godot --editor --path .
# launch directly
godot --path .
```

Choose **New Game** or **Load Game**. The title shows your saved day, coins, defenders, weapons, and foes stopped. Load is disabled without a valid checkpoint; replacing an existing game requires confirmation.

| Control | Action |
| --- | --- |
| WASD / mouse | Move / aim |
| Left click | Fire (first uncaptured click captures the mouse) |
| R | Reload |
| 1 / 2 / 3 | Revolver / shotgun / purchased Confetti Cannon |
| Q | Cycle weapons |
| Space | Jump |
| E | Shop, greet a neighbor, or ring the town bell |
| N | Start night when ready |
| Escape | Pause / release mouse / close shop |

Keyboard and mouse are required. The HUD shows health, armor, coins, day/wave, ammunition, remaining foes, bell health, controls, and nearby interactions. The map marks the sheriff in white, the bell in gold, defenders in mint, and foes in coral.

## Your first frontier

- Start with **$220**, including the first day's $120 wage, a revolver, and a double-barrel shotgun. Preparation has no time limit. Signed shops work from their porches or inside.
- **Gunsmith:** $35 ammo boxes (+36 rounds / +12 shells), $850 Confetti Cannon with 20 shots, $65 party cartridges (+15).
- **General Store:** $90 padded vest (75 armor), $30 healing lemonade, $220 permanent speed boots.
- **Sheriff Office:** $180 deputies (up to six), $350 automatic popper turrets (up to **four**).
- Press **N** or interact with the bell to start a wave. Foes attack the sheriff, defenders, and bell. Neighbors are safe, never fight, and cannot be hurt; there is no friendly fire.
- Clear the wave for bounties and the next day's wage: $120 + $25 per day after day one, capped at $420. Dawn restores health, bell, and defenders, and supplies at least 24 rounds / 8 shells. Armor is not automatically replenished.
- Waves start at four foes and grow by two, capped at 36. Sleepwalker zombies join on night four; marshmallow monsters on night seven.
- If the sheriff or bell runs out of health, retry your sunset checkpoint. Purchased defenders rest when defeated and return at dawn or retry.

## Saves

One local slot, `user://sunset_sheriff_v1.json`, with a validated backup. Daytime progress autosaves every ten seconds, after purchases, before night, at dawn, and on **Save & title**. It includes progression, coins, purchases, health/armor, weapons/ammo, and player pose. No cloud service is used.

**Nights are checkpoint-based, not mid-wave saves.** Leaving or losing a night returns to the pre-wave preparation state on Load; night bounties become durable when you win. Loading never awards another wage. Storage errors are surfaced in-game, and a failed purchase save cancels the purchase. Browser persistence depends on browser/site storage; private mode or clearing site data can remove saves.

## Validation and web export

```sh
npm test
npm run export:web
python3 -m http.server 4173 --directory public
```

`tests/smoke_test.gd` covers save round trips and corruption recovery, purchases and limits, ammunition/armor, progression, title buttons, movement, shops, real raycast combat, defender attacks, victory, defeat, and checkpoint retries. Tests use `.cache/test_checkpoint.json`, not the player's slot. `npm test` imports the project before running the headless suite.

If a sandboxed Snap launcher cannot access a hidden worktree, invoke the installed executable directly for validation:

```sh
GODOT=/snap/godot4/current/Godot_v4.5-stable_linux.x86_64
"$GODOT" --headless --editor --path "$PWD" --quit
"$GODOT" --headless --path "$PWD" --script res://tests/smoke_test.gd
```

`export_presets.cfg` defines single-threaded **Web** output for current desktop browsers; serve it over HTTP, not `file://`. Local exports need the matching Godot 4.5 export templates. On Linux x86_64 without Godot, `scripts/export-web.sh` downloads pinned official 4.5 tools and templates into ignored `.tools/`. Generated caches, saves, and exports are not committed.

For Vercel, import this repository, select framework **Other**, and retain `vercel.json`: build `npm run export:web`, output `public`. No backend or environment variable is required.

This is a first playable slice: one town, one save slot, three weapons, simple AI and procedural sound effects; no multiplayer or mobile controls.
