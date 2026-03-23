# Godot-Idiomatic Style Refactor Plan

## Summary

Refactor the project in mechanical, style-only batches that move it closer to
idiomatic Godot and GDScript while preserving established project patterns where
they are already stable.

## Work Order

1. Foundation and rules
   - Rewrite `STYLE.md` into the canonical "Godot idiomatic, project-compatible"
     guide.
   - Align lint and report config with that guide without introducing unrelated
     quality gates.
2. Core shared types and resources
   - Normalize `main/Global.gd`, `classes/*.gd`, `moves/Move*.gd`, `items/*.gd`,
     `monsters/*.gd`, `statuses/*.gd`, and
     `world_objects/encounter/EncounterEntry.gd`.
3. Battle subsystem
   - Refactor `battle/*.gd` and rename obvious path outliers safely.
4. Player and overworld gameplay
   - Refactor `player/*.gd`, `maps/*.gd`, root gameplay components, and
     `world_objects/**`.
5. UI subsystem
   - Refactor `ui/**`, including safe renames for focus-handler path outliers.
6. Main scene bootstrap and title flow
   - Normalize `main/main.gd` and `main/title_screen.gd`.
7. Tests
   - Update `tests/*.gd` only for renamed symbols, paths, and style consistency.
8. Final convergence pass
   - Sweep for remaining naming/order inconsistencies and stale references.

## Script-Level Rules

- Order members as: `class_name`, `extends`, `signal`, `enum`, `const`,
  exported vars, regular vars, `@onready`, lifecycle, public methods, private
  helpers.
- Use `PascalCase` for `class_name`, `snake_case` for functions, vars, and
  signals, and `UPPER_SNAKE_CASE` for constants.
- Keep stable model and resource script filenames such as `Monster.gd`,
  `Move.gd`, and `Item.gd` in `PascalCase`.
- Keep scene, handler, and controller scripts in `snake_case`.
- Do not change logic, data meaning, or runtime behavior.

## Validation

- Run existing tests after each major batch.
- Run repo lint and report tooling using `gdlint.json`.
- Verify renamed scripts still resolve from scenes and resources.
- Check signal connections and autoload references after symbol or path renames.

## Assumptions

- Goal is "Godot idiomatic first" while preserving stable repo patterns.
- Safe mechanical renames are allowed.
- `addons/` stays out of scope except for lint and report configuration if
  needed.
