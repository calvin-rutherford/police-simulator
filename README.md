# Sunset Sheriff

A kid-friendly first-person Western town-defense game for **Godot 4.5**, Compatibility renderer, and desktop browsers. All characters, scenery, icons and synthesized audio are original repository-native assets. No gore, real-money purchases, account, or backend.

## Play

Open `project.godot` in Godot 4.5 and run, or serve a Web export over HTTP. Choose **New Game** or **Load Game**; replacing an existing town requires confirmation. Keyboard and mouse are required.

| Control | Action |
| --- | --- |
| WASD / mouse | Move / aim |
| Left click | Fire; first uncaptured click captures the pointer |
| R | Reload (also automatic on an empty click) |
| 1 / 2 / 3, Q | Select / cycle weapons |
| Space | Jump |
| E | Shop, greet, build at a striped site, or ring the bell |
| F | Eat one carried biscuit: +40 health |
| N | Start night when ready |
| M | Mute / unmute |
| Escape | Pause, release pointer, or close a shop |

The speaker button and volume slider work on menus too. Sound unlocks only after a pointer/key gesture; volume and mute preferences persist independently of the town save. The map marks you in white, the bell in gold, allies in mint and foes in coral.

## The complete loop

1. **Prepare without a timer.** Start with $220 (including the first $120 wage), a revolver and shotgun. Visit visible keepers, icon cards and physical merchandise displays.
2. **Build your defenses.** Four striped sites offer a **$150 guard post** (one victorious night) or **$280 tower** (two victorious nights). At most **two structures combined**, including unfinished construction. Frames, platforms and progress blocks show the work. Finished posts have a stationary guard (22 damage, 24-unit reach); towers give an elevated guard (32 damage, 38-unit reach). Construction advances only at victory/dawn, never on failure, reload, or merely entering night. Defeated guards return at dawn/retry and still occupy their site.
3. **Defend at night.** Press N or ring the town bell. Protect yourself and the bell; civilians are safe and there is no friendly fire. Damage, recoil and reload have visible reactions and synthesized effects.
4. **Collect rewards and prepare again.** Defeated bandits/sleepwalkers/brutes award $12/$18/$30. Dawn pays $120 + $25 per day after day one, capped at $420; restores health, bell and defenders; and supplies at least 24 rounds / 8 shells. Armor is not replenished. Waves grow from four foes by two per day, capped at 36; sleepwalkers arrive on night four and marshmallow brutes on night seven.
5. **Try again safely.** If you or the bell lose all health, retry your sunset checkpoint or return to title. The game continues across successive days; there is no final-wave cutoff.

### Shops and neighbors

- **Mabel, Gunsmith:** $35 ammo (+36 rounds / +12 shells), $850 Confetti Cannon with 20 shots, $65 party cartridges (+15; cannon required).
- **June, General Store:** $90 vest (75 armor), $30 healing lemonade (full health), $220 permanent speed boots.
- **Marshal Kit, Sheriff Office:** $180 deputies (up to six), plus directions to the building sites.
- **Sunny, Saloon:** $25 picnic (three carried biscuits). F eats one only when hurt. The saloon is over three times a standard interior's floor area, with a long bar, shelves, stools, tables, piano, eleven guests and its keeper.

Keepers have distinct colors, hats, faces, portraits and short dialogue. Other neighbors vary in build, hair, skin, hats and clothing. The stable and resting horse are scenery only. Bounties, inter-town travel, hideout missions and horse ownership remain future work.

## Local saves

One slot, `user://sunset_sheriff_v1.json`, with a validated backup. Daytime autosaves every ten seconds, after purchases/build orders/eating, before night, at dawn and on **Save & title**. Money, food, health/armor, purchases, ammunition, construction and player pose are saved. Failed purchase/build saves roll back the transaction.

**Nights use sunset checkpoints, not mid-wave saves.** Loading or retrying a night restores pre-night inventory and construction; rewards and consumed supplies become durable on victory. Load never grants another wage. Errors are surfaced instead of silently discarding the checkpoint. Schema 2 automatically migrates the first slice's instant turrets into up to two completed guard posts and refunds extra turrets at their original $350 price.

Browser saves use site-local IndexedDB. Private browsing, clearing site data, changing hostname/port, or a browser crash before storage sync may lose progress. No cloud synchronization is provided.

## Build and validate

```sh
npm test
npm run export:web
python3 -m http.server 4173 --directory public
# Visit http://localhost:4173, not file://
```

For Snap installations that cannot access hidden worktrees, set the actual binary:

```sh
export GODOT=/snap/godot4/current/Godot_v4.5-stable_linux.x86_64
npm test
npm run export:web
```

The Linux x86_64 export script downloads pinned official Godot **4.5 stable** and matching Web templates when needed. `GODOT` overrides the executable, not the required version. It imports before exporting, stores tooling/caches locally in ignored directories, and outputs only the static site to `public/`. The first template download is large; subsequent builds reuse it.

`export_presets.cfg` uses **single-threaded Web**, no extensions, no cross-origin isolation requirement and no service worker. The generated site is approximately 37 MiB before HTTP compression. Static primitives are batched by material; browser directional shadows are disabled to reduce frame cost. Native smoke coverage includes economy, food, migration, corruption recovery, atomic purchase failure, construction durations/limits, real raycasts, defenders, victory, failure and retry.

### Browser validation

`npm run export:web:test` creates a separate, **local-only** build with a test bridge. Serve `.cache/web-validation/public` on port 4174; never deploy it. In a fresh browser profile, press M twice to unlock/unmute sound, evaluate the function in `tests/browser-smoke.js` using `chrome-devtools-axi eval`, then evaluate `frontierSmoke.combat()` and `frontierSmoke.builder()` separately. The latter saves its expected checkpoint in localStorage; after reloading, call `frontierCommand(JSON.stringify({action: 'load'}))` and compare `frontier.state` against `JSON.parse(localStorage.frontierExpected)`. Also check production on port 4173 with actual keyboard/pointer controls and verify `typeof frontierCommand === 'undefined'`.

Focused validation: Godot import and **83 native checks passed**; HTTP-served Chrome checks covered New/Load, food/ammo/armor, insufficient funds, reload/raycast damage, victory wages, one-/two-night construction and the combined limit, bell failure/retry, and persistence after page reload. Generated screenshots and logs stay in ignored `.cache/`. Headless Chrome uses software WebGL here: functional validation is not a hardware-GPU frame-rate certification. Audio unlock/playback/mute state is checked, not subjective listening quality.

### Vercel import settings

- Framework preset: **Other**
- Root directory: repository root (`.`)
- Install command: `npm install` (no runtime dependencies)
- Build command: `npm run export:web`
- Output directory: `public`
- Environment variables: **none**
- Production branch: **main**, after this change is merged

`vercel.json` supplies the WASM content type and revalidating pack cache policy (filenames are not content-hashed). Do not deploy `.cache/web-validation/public`: it deliberately includes a test bridge. No credentials or deployment are created by the repository scripts.
