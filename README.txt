# The7seas

A multiplayer co-op survival game built in Godot 4.7; sail, gather, craft, and upgrade your boat with friends.

![Gameplay screenshot](docs/screenshot.png)

## Features

- Online co-op multiplayer with public and private (code-based) lobbies
- Inventory and crafting system with recipes
- Boats with craftable upgrade modules
- Full Demo Level

## Running the game

**Requirements:** [Godot 4.7](https://godotengine.org/download)

1. Clone the repo and open the folder in Godot (select `project.godot`).
2. Press **Play**.

**Playing with friends**

- **Public game:** the host presses **Host**, then the other player presses **Join**.
- **Private lobby:** the host types a code into the text box and presses **Host**. The other player enters the same code in the join box and presses **Join**.

**Testing multiplayer alone:** when you run from the editor, Godot launches two instances of the game so you can test host and client together. To change this, go to **Debug → Customize Run Instances** and set the number of instances (1 for a single window).

## Automated asset validation

[![Validate](https://github.com/Felix-Young-Git/The7Seas-multiplayer-coop-game/actions/workflows/validate.yml/badge.svg)](https://github.com/Felix-Young-Git/The7Seas-multiplayer-coop-game/actions/workflows/validate.yml)

I built a Python tool to catch asset and reference problems automatically, both to learn more about testing and to keep the game's file naming, references, and art consistent. It runs on every push through GitHub Actions.

**What it checks**

| Check | What it catches |
|---|---|
| Naming | Files not in lowercase `snake_case` |
| Image sizes | PNGs that aren't multiples of the tile size, or are too large |
| References | `res://` paths in `.tscn`, `.tres`, and `.gd` files that point to files that don't exist |

**How it's tested:** the validator has its own Pytest suite (11 tests) covering normal cases, edge cases (paths with spaces, ignored folders), and exit codes, so changes to the tool don't break it silently.

**What it found:** on its first run against the game it reported 44 errors and 52 warnings, including file naming issues, asset sizing, and broken references left after moving folders. It also caught a problem that was invisible on my Windows machine: a case-only file rename (`Stone.tres` → `stone.tres`) that Git hadn't recorded, which broke references on the Linux CI runner.

**Run it yourself**

```bash
pip install -r requirements-dev.txt
python -m pytest -v                      # test the validator
python tools/asset_validator.py .        # validate the game's assets
```

The tooling lives in `tools/` (ignored by Godot via `.gdignore`), with the workflow in `.github/workflows/`.

## Project structure

```
addons/      Epic Online Services Godot (EOSG) plugin
Assets/      game images and art (from online sources, see Credits)
Enemies/     early enemy prototypes (currently unused)
Resources/   item and recipe resources
Scenes/      most scenes, including the player
Scripts/     game logic (inventory, crafting, items, ...)
Tilemap/     game and water tilemaps
UI/          interface scenes
tools/       asset validator and its tests
```

## Status

## Status

The game is playable as a demo level. Known issues are tracked in [GitHub Issues](https://github.com/Felix-Young-Git/The7Seas-multiplayer-coop-game/issues), including:

- The player can sail off the edge of the map
- Little in-game feedback about what's happening or what to do next
- Softlocks are possible in some situations

**Note:** the first time you press Play after a while, the connection relay has to spin up, so the game can take longer to load.

## Credits

- **Art:** [Sprout Lands](https://cupnooble.itch.io/sprout-lands-asset-pack) ([free basic pack / premium pack]) by [Cup Nooble](https://cupnooble.itch.io/), used under the pack's license.
- **Online multiplayer:** [Epic Online Services Godot (EOSG)](https://github.com/3ddelano/epic-online-services-godot) by [3ddelano](https://github.com/3ddelano), MIT License. Online features use Epic Online Services; this project is not affiliated with or endorsed by Epic Games or Godot Engine.
