# Street Beat: Keep It Safe

A tiny Godot 4 browser prototype for one player. You patrol one comic-book graybox street in first person. The goal is simple: keep civilians safe. Shooting near people makes them run; shooting three civilians activates two visible police pursuers.

## Scope

Included: one generated primitive/material street, solo first-person movement, mouse look, jump, pointer capture/release, unlimited hitscan sidearm, flee behavior, low-key hit removal, warning HUD, police pursuit, and reset. No cruiser, traffic stops, 911 system, inventory, dialogue trees, city simulation, multiplayer, backend, or external assets.

## Controls

- **W A S D** — move
- **Mouse** — look
- **Click** — capture pointer and fire
- **Q** — draw / holster gun
- **Space** — jump
- **Escape** — release pointer
- **R** — restart/reset

The HUD uses large icons, color, and short labels. Browser builds need WebAssembly and a current desktop Chromium/Firefox/Safari; keyboard and mouse are required. The first click both captures the pointer and fires when the gun is drawn.

## Local run

Install the official Godot 4 editor (Compatibility renderer) and make `godot` available on PATH, then run:

```sh
godot --editor --path .
# or
godot --path .
```

No downloaded engine, export template, cache, `.godot/` state, or generated export is committed.

## Test and web export

```sh
npm test
npm run export:web
# serve the static payload (never use file://)
python3 -m http.server 4173 --directory public
```

`export_presets.cfg` defines the **Web** preset with extension and thread support disabled so the export is single-threaded/non-isolated and needs no application server. `public/` is intentionally ignored; export a fresh release for delivery and record its size with `du -sh public`. The export script uses an installed `godot` locally. On a Linux build host without Godot, it downloads the pinned official Godot 4.4.1 editor and matching export templates into the ignored `.tools/` cache.

## Vercel

1. Import this repository in Vercel and select the feature branch or merged default branch to deploy.
2. Leave the root directory at the repository root and select framework **Other**.
3. Keep the settings supplied by `vercel.json`: build command `npm run export:web` and output directory `public`.
4. Select **Deploy**. Vercel downloads the pinned official Godot tools, creates `public/index.html` and its payload, then serves that directory with the configured WebAssembly and cache headers.

No Godot binary, export template, cache, or generated web payload is committed, and no Vercel environment variable is required.
