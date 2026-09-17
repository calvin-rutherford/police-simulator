# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Run/control/export instructions and checkpoint semantics: `README.md`. Target engine: Godot 4.5, Compatibility renderer.
- Economy, wave progression, combat tuning, and save schema: `rules.gd`; validated atomic checkpoint persistence: `save_store.gd`. JSON numeric counters must be restored as integers before gameplay.
- Scene flow/combat orchestration: `main.gd`; procedural town, inhabitants, and path grid: `town.gd`. All visuals/audio are repository-native procedural assets.
- Focused validation: `npm test` (`tests/smoke_test.gd`), which uses an isolated `.cache` save. See README for direct binary invocation when Snap cannot access hidden worktrees.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
