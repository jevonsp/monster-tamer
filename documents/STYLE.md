## Monster Tamer GDScript Style Guide

This project follows idiomatic Godot and GDScript conventions wherever possible.
Existing project patterns are kept only when they are already stable and changing
them would add churn without improving clarity.

### Naming

- Use `PascalCase` for `class_name`, enums, and enum members.
- Use `snake_case` for functions, variables, signals, and non-class script names.
- Use `UPPER_SNAKE_CASE` for constants.
- Keep core model and resource filenames in their current stable `PascalCase`
  form when that matches the project convention, such as `Monster.gd`,
  `Move.gd`, and `Item.gd`.
- Prefer boolean names with `is_`, `has_`, `can_`, or `should_`.

### Script Ordering

Use this member order in GDScript files:

1. `class_name`
2. `extends`
3. `signal`
4. `enum`
5. `const`
6. exported variables
7. regular variables and computed properties
8. `@onready` variables
9. lifecycle callbacks
10. public methods
11. private helpers

If a script does not use one of those sections, omit it instead of leaving gaps.

### Functions and Visibility

- Use standard Godot callbacks: `_ready`, `_process`, `_physics_process`,
  `_input`, `_unhandled_input`.
- Public entry points should not start with `_`.
- Internal helpers should start with `_`.
- Keep `_ready` short and delegate setup to focused helpers when needed.
- Prefer guard clauses and early returns over deep nesting.

### Types and Collections

- Add explicit types where they improve clarity and can be stated without noise.
- Type arrays and dictionaries when the element type is known.
- Use typed return values for non-trivial public methods.
- Prefer `:=` only when the inferred type is obvious and useful; otherwise use an
  explicit type with `=`.

### Formatting and Syntax

- Use ASCII only.
- Keep line length within the repo lint limit.
- Keep dictionary, array, and argument formatting consistent and easy to scan.
- Use `await` only when the async boundary is part of the API or control flow.
- Use `@warning_ignore` sparingly and close to the statement it applies to.

### Signals and Globals

- Keep signals grouped near the top of the script.
- Use `snake_case` signal names.
- Use `Global` as the event bus between systems, with clear verb-based signal
  names such as `request_*`, `send_*`, `*_complete`, and `*_requested`.

### Project Conventions

- Keep each script focused on one responsibility.
- Handler and controller scripts should stay `snake_case`.
- Prefer the dominant existing term in the repo when several names could fit the
  same concept.
- Rename files or symbols only when the change is mechanical and all references
  can be updated atomically.

### Out of Scope

This refactor is style-only:

- no gameplay or UI behavior changes
- no data model changes
- no signal payload changes
- no logic rewrites for optimization
