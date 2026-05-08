# Project folder architecture (revised)

**Enacted in-repo:** directories moved with `git mv`, then `res://` paths bulk-updated in `.gd`, `.tscn`, `.tres`, `.import`, and related text files. Open the project once in Godot 4.x so `.godot/` caches refresh.

## Decisions

- **Monsters**: All `.gd` domain types live under [`core/monster/`](core/monster/) (including `_services`, `_evolution` scripts, `EvolutionHandler.gd`). Species folders, textures, and `.tres` live under [`content/monsters/`](content/monsters/); evolution table data (e.g. `EvoTableTest.tres`) under [`content/monsters/_evolution/`](content/monsters/_evolution/).
- **World map UI**: Minimap-only scenes and assets live under [`gameplay/field/world_map/`](gameplay/field/world_map/) beside the overworld stack.
- **Moves**: Move *resources* (`.tres`) under [`content/moves/`](content/moves/) (`hms/`, `basic_test/`, `moves/`). Move scripts and animation scenes stay with battle under [`gameplay/battle/moves/`](gameplay/battle/moves/).
- **Items**: [`core/item/item.gd`](core/item/item.gd); `.tres` under [`content/items/`](content/items/).
- **Rest**: `global` → `autoload`, `game` → `systems`, `main` → `app`, `classes/*` → `core/*`, `3d_migration` split into `gameplay/field` and `gameplay/battle` as before; loose `TypeChart.gd` / `InventoryPage.gd` → `core/`.

## Target tree (high level)

```text
autoload/          # singleton scripts (was global/)
systems/           # services (was game/)
app/               # boot / main scene (was main/)
core/
  monster/  item/  status/  story/  saving/
  TypeChart.gd  InventoryPage.gd
content/
  monsters/  moves/  items/
gameplay/
  field/           # grid, cell objects, player, wild zones, world commands, custom_grid_map, world_map
  battle/          # battle_3d, chassis, action, moves (scripts + anim scenes)
addons/  assets/  3p_assets/  ui/  shaders/  tests/  tools/
```
