## GDScript Style Guide – Monster Tamer

This guide captures the conventions used in this project for GDScript and Godot scenes.

---

### Naming & Types

- **Classes / resources**
  - Use **PascalCase** with `class_name` when a class is referenced from other scripts.
  - Examples: `Monster`, `Move`, `MonsterData`, `Item`, `TypeChart`, `Switch`, `EncounterZone`, `NPC`, `Trainer`.

- **Functions / variables**
  - Use **snake_case** for all functions and non-const variables.
  - Examples: `set_monster_data`, `check_vision_collision`, `update_held_keys`, `guard_clause_deposit`.

- **Constants & enums**
  - Use **UPPER_SNAKE_CASE** for constants, **PascalCase** for enums and enum members.
  - Examples: `DEFAULT_DELAY`, `EXPERIENCE_PER_LEVEL`, `TypeChart.Type`, `Direction.UP`.

- **Booleans**
  - Prefer `is_` / `has_` / `should_` / `can_` prefixes or clear adjectives.
  - Examples: `is_fainted`, `is_captured`, `is_trainer_battle`, `processing`, `in_battle`.

- **Types & collections**
  - Always type collections when the element type is known.
  - Examples:
    - `var party: Array[Monster] = []`
    - `var tiles_in_sight: Array[Vector2] = []`
    - `@export var move_level: Array[int] = []`
    - `var inventory: Dictionary[Item, int] = {}`

---

### Structure & Organization

- **Lifecycle functions**
  - Use standard Godot callbacks: `_ready`, `_process`, `_physics_process`, `_input`, `_unhandled_input`.
  - Keep `_ready` short; delegate to helpers like `_connect_signals`, `_bind_buttons`, `_setup_*`.

- **Public vs private helpers**
  - Public entry points: no leading `_`.
  - Private/internal helpers: start with `_`.
  - Examples:
    - Public: `set_up`, `add`, `trigger`, `execute`, `use`, `give`.
    - Private: `_update_bars`, `_grant_party_experience`, `_set_component_array`.

- **Regions**
  - Group related members with `#region` / `#endregion` where helpful:
    - Signals, node references, lifecycle, and flow sections (e.g. `#region LIFECYCLE`, `#region BATTLE FLOW`).

- **Single entry points**
  - Prefer explicit “single entry point” functions that encapsulate invariant work.
  - Examples:
    - `MonsterData.set_up(level)` for monster creation.
    - `party_handler.add(monster)` for adding monsters to party/storage.
    - `ui_handler._display_current_monsters()` to refresh battle UI.

---

### Signals & Global Autoload

- **Global signal bus (`Global`)**
  - Use the `Global` autoload as the event bus between systems.
  - Naming conventions:
    - Requests: `request_*` / `*_requested`  
      - Examples: `request_open_menu`, `player_party_requested`, `trainer_battle_requested`.
    - Send/notify: `send_*`  
      - Examples: `send_player_party`, `send_player_inventory`, `send_battle_text_box`.
    - Lifecycle/completion: `*_started`, `*_ended`, `*_complete`  
      - Examples: `battle_started`, `battle_ended`, `text_box_complete`.
  - Connect global signals in `_connect_signals` or `_ready` and keep connections grouped.

- **Local signals**
  - Use snake_case and keep them near the top of the script, optionally under a `#region`.

---

### Resources & Data Modeling

- **Resource classes**
  - Use Godot resources for game data: `MonsterData`, `Move`, `Item`, `EncounterEntry`, `TypeChart`.
  - Prefer exported, typed fields over ad-hoc dictionaries.

- **Capabilities via data**
  - Prefer modeling capabilities through exported fields instead of ad hoc flags.
  - Examples:
    - Item usability/holdability is determined by `use_effect`, `held_effect`, `catch_effect`.
  - When using flags, keep naming consistent (`is_usable`, `is_held`, etc.) and ensure all code paths agree on the same model.

- **Avoid magic sentinel values**
  - Do **not** use `[""]` as “no text”.
  - Prefer `[]` and `is_empty()` checks:
    - `@export_multiline var dialogue: Array[String] = []`
    - `if dialogue.is_empty():` means “no dialogue”.

---

### UI & Scene Components

- **Actor pattern**
  - UI elements that represent a monster or item should store a reference and expose an `update()` / `update_actor()` method.
  - Examples:
    - `hp_bar.actor`, `player_exp_bar.actor`, `player_level_label.actor`, `name_label.actor`, `party_texture_rect.actor`.
    - `panel.update_actor(monster)` sets the actor for multiple child nodes.

- **Input handling**
  - Use `_unhandled_input` in UI scenes for menu and text-box controls.
  - Early-return when `processing` is `false`.

- **Focus management**
  - Centralize focus logic into dedicated helpers when complex (e.g. storage and battle UI).
  - Use small maps (e.g. `_last_focused`) for default focus positions and restore focus after UI transitions.

---

### Collections & Control Flow

- **Collection initialization**
  - Always initialize arrays and dictionaries before use.
  - Examples:
    - `var getting_exp: Array[Monster] = []`
    - `var storage: Dictionary[int, Monster] = {}`

- **Dictionary access**
  - Use `.has(key)` when checking for key existence.
  - Use `.get(key, default)` for lookups with defaults.
  - Avoid relying on truthiness of `dict.get(key)` when semantics are about presence.

- **Iteration**
  - Use `for element in array:` when indices are not needed.
  - Use `for i in array.size():` when you need indexes.
  - For weighted tables (e.g. encounter tables), use cumulative sums and early returns.

---

### Constants, Magic Numbers & Balancing

- **General rule**
  - Any repeated numeric literal with gameplay or capacity meaning should become a constant.
  - Examples:
    - `const MAX_PARTY_SIZE := 6`
    - `const STORAGE_SIZE := 300`
    - `const STORAGE_PAGE_SIZE := 30`
    - `const STORAGE_PAGE_COUNT := 10`

- **Gameplay math**
  - Keep formulas and per-level rates in constants or helper methods, not inline in many places.
  - Example: `EXPERIENCE_PER_LEVEL` and `get_current_level_exp()`, `get_next_level_exp()`.

---

### Async, Await & Animations

- **Await style**
  - Use `await` for:
    - Global “done” signals (e.g. `Global.text_box_complete`, `Global.hitpoints_animation_complete`, `Global.experience_animation_complete`).
    - Tween completions (`await tween.finished`).
    - Animation completions (`await animation_finished`).
  - When the linter complains about redundant awaits but they are part of a consistent async API, use:
    - `@warning_ignore("redundant_await")` explicitly and sparingly.

- **Animation responsibilities**
  - Keep animation logic in small, focused scripts:
    - Battle sprite animations (`animation_player.gd`).
    - Item throw/wiggle/capture (`item_sprite.gd`).
    - Move animations container (`animation_container.gd`).

---

### Debugging & Logging

- **Prints**
  - Use `print` / `printerr` for debugging and tracing state.
  - Prefer concise, informative messages.
  - Remove or gate noisy debugging output (e.g. inside tight loops) when systems stabilize.

---

### File & Responsibility Boundaries

- **Single responsibility per script**
  - Handlers coordinate; UI scripts handle visuals and input; world objects handle overworld logic.
  - Examples:
    - `battle_handler.gd`, `party_handler.gd`, `inventory_handler.gd`, `update_handler.gd` coordinate systems.
    - `menu.gd`, `inventory.gd`, `party.gd`, `summary.gd`, `storage.gd`, `overworld_text_box.gd` manage UI.
    - `EncounterZone`, `WildZone`, `StaticObject`, `GroundItem`, `NPC`, `Trainer` manage overworld interactions.

- **Entry points**
  - Use `main.gd` for window setup and scene bootstrapping.
  - Use resource `set_up` functions (e.g. `MonsterData.set_up`) as the canonical way to construct runtime instances.

---

### When in Doubt

- Prefer **explicit types**, **named constants**, and **clear control flow** over cleverness.
- Follow patterns already used in existing scripts to keep the project internally consistent.

