# UI migration API reference

This document lists the functions introduced or changed when business logic was moved off UI `Control` nodes into autoloads and `PartyHandler` / `BattleSession`. Each section includes **before** (conceptual), **after** (current API), and **usage examples**.

Autoloads are registered in `project.godot`: `ItemInteraction`, `StoreService`, `MoveLearningService`.

---

## 1. `ItemInteraction` (`game/item_interaction.gd`)

Global singleton: item rules plus async give/use flows (`Ui` / `Inventory` / `EvolutionHandler`).

### Rule helpers (no side effects beyond reading `item`)

| Function | Returns | Purpose |
|----------|---------|---------|
| `can_use_outside_battle(item: Item) -> bool` | `true` if `item.use_effect != null` | Field “Use” from bag/party pick |
| `can_give_to_monster(item: Item) -> bool` | `true` only for held items (no catch-only, no use-only) | Field “Give” |
| `can_use_in_battle(item: Item) -> bool` | `true` if use or catch effect | Battle bag |
| `battle_item_blocked_reason(item: Item, is_trainer_battle: bool) -> String` | `""` OK; `"cant_use"` or `"trainer_catch"` | Why battle can’t enqueue |

**Before:** Same logic lived in private helpers on `ui/inventory/inventory.gd` (`_can_use_outside_battle`, `_can_give_to_monster`) and duplicated checks in `ui/party/party.gd`.

**After:** One implementation; inventory and party call the autoload methods.

**Example — gate a custom UI before opening party:**

```gdscript
func _on_item_button_pressed(item: Item) -> void:
	if not ItemInteraction.can_use_outside_battle(item):
		push_warning("Not usable outside battle")
		return
	# ... open party to pick target
```

**Example — battle bag branch:**

```gdscript
var reason: String = ItemInteraction.battle_item_blocked_reason(some_item, is_trainer_battle)
match reason:
	"cant_use":
		await show_message("That item isn't usable!")
	"trainer_catch":
		await show_message("This is a trainer battle!!")
	_:
		Battle.add_item_to_turn_queue.emit(some_item)
```

### Instance async functions (mutate monsters / emit signals / await UI)

| Function | Awaits | Purpose |
|----------|--------|---------|
| `give_item_to_monster(item, monster, text_box_sender: Node) -> void` | Text boxes | Hold, optional swap confirm, `Inventory.give_item_to` |
| `use_item_on_monster_after_party_pick(item, monster) -> void` | Evolution or item use | `EvolutionHandler` or `Inventory.use_item_on` + `Ui.item_finished_using` |

Private helpers: `_show_item_given_text`, `_confirm_item_swap` (same file).

**Before:** `inventory.gd` and `party.gd` each had `_give_item_to_monster`, `_confirm_item_swap`, `_show_item_given_text`. Inventory `use()` inlined evolution + `Inventory.use_item_on`.

**After:** Single implementation; pass `self` for inventory/party so the text box knows the owning control.

**Example — give from a new screen:**

```gdscript
func _on_confirm_give(item: Item, monster: Monster) -> void:
	await ItemInteraction.give_item_to_monster(item, monster, self)
	# inventory signals already fired; UI can close
```

**Example — use after picking a monster (field):**

```gdscript
func _after_monster_chosen_for_use(item: Item, monster: Monster) -> void:
	await ItemInteraction.use_item_on_monster_after_party_pick(item, monster)
	# If evolution ran, returns after evolution_process_finished
	# Else returns after item use + item_finished_using
```

---

## 2. `StoreService` (`game/store_service.gd`)

Global singleton. Owns **money**, **stock dictionaries**, and **seller rules** (e.g. key items). No `Control` references.

### Public functions

| Function | Returns | Side effects |
|----------|---------|--------------|
| `try_buy(player_ref, current_category, item, amount, shop_inventory) -> Dictionary` | `{ "ok": bool, "message": String }` | On success: spends **one** `item.price` (legacy behavior), reduces stock by `amount` |
| `try_sell(player_ref, player_inventory, current_category, item, amount) -> Dictionary` | `{ "ok": bool, "message": String }` | Removes from player, credits money |
| `credit_player_for_sale(player_ref, item, amount) -> void` | — | Sell value = `max(1, int(price/2)) * amount` |
| `increase_npc_stock(npc_inventory, item, amount) -> void` | — | Restocks NPC `InventoryPage` dict |

Private: `_can_player_afford`, `_check_enough_stock`, `_pay_for_item`, `_reduce_stock`.

**Before:** `ui/store/store.gd` implemented `_buy`, `_sell`, `_credit_player_for_sale`, stock helpers inline.

**After:** Store UI calls `StoreService` and shows `r.message` when `not r.ok`.

**Example — buy from UI after quantity chosen:**

```gdscript
func _buy(amount: int) -> void:
	var item: Item = last_focused_item_button.item
	var r: Dictionary = StoreService.try_buy(
		player_ref,
		current_category,
		item,
		amount,
		inventory,  # active shop view; same ref as npc stock when buying
	)
	if r.ok:
		_grab_item_focus()
		return
	var ta: Array[String] = [r.message]
	Ui.send_text_box.emit(null, ta, true, false, false)
	await Ui.text_box_complete
	_grab_item_focus()
```

**Example — sell:**

```gdscript
func _sell(amount: int) -> void:
	var r: Dictionary = StoreService.try_sell(
		player_ref,
		player_inventory,
		current_category,
		last_focused_item_button.item,
		amount,
	)
	if r.ok:
		_display_current()
		return
	if r.message != "":
		Ui.send_text_box.emit(null, [r.message], true, false, false)
		await Ui.text_box_complete
```

**Example — restock NPC after a quest:**

```gdscript
StoreService.increase_npc_stock(npc_shop_inventory, rare_potion, 3)
```

---

## 3. `MoveLearningService` (`game/move_learning_service.gd`)

Global singleton. Replaces the deleted `MoveLearningController` node script.

### `show_move_learned_message`

| Function | Purpose |
|----------|---------|
| `show_move_learned_message(monster: Monster, move: Move) -> void` | One text box; `await Ui.text_box_complete` |

**Before:** `class_name MoveLearningController` on `ui/text_box/move_learning_controller.gd`.

**After:** Same call sites use `MoveLearningService.show_move_learned_message`.

**Example — level-up outside summary (e.g. `Monster.gd`):**

```gdscript
await MoveLearningService.show_move_learned_message(self, move_to_learn)
```

### Instance (summary-focused; takes `summary: Control`)

| Function | Purpose |
|----------|---------|
| `resolve_move_learning(summary, monster, move) -> void` | Full flow: empty slot vs replace vs cancel |
| `ask_remove_move(summary) -> void` | Replace move after player picks slot |
| `handle_cancel_learning(summary) -> bool` | Stop learning |
| `set_move_learning_processing(summary, value, reason) -> void` | Toggle `summary.processing` |
| `clean_up_learning_move(summary) -> void` | Emit `Ui.move_learning_finished`, close summary, refresh party |
| `ask_delete_existing_move`, `confirm_replace_move`, `confirm_stop_learning`, `show_did_not_learn` | Text prompts |
| `announce_move_learned(monster, move) -> void` | Same text as `show_move_learned_message` |

**Example — from summary (delegates to autoload):**

```gdscript
# summary.gd
func _resolve_move_learning(monster: Monster, move: Move) -> void:
	await MoveLearningService.resolve_move_learning(self, monster, move)
```

---

## 4. `PartyHandler` (`player/party_handler.gd`)

Not an autoload; lives on the `Player` node. New functions support storage UI and silent release.

### New / changed

| Function | Signatures / behavior |
|----------|------------------------|
| `can_deposit_from_party() -> bool` | `true` iff `party.size() > 1` |
| `can_release_monster(monster: Monster) -> bool` | `false` iff `party.size() == 1` and `party.has(monster)` |
| `remove_monster(monster: Monster, with_farewell: bool = true) -> void` | If `with_farewell`, shows goodbye text; then removes from party/storage |

**Before:** Storage duplicated logic in `guard_clause_deposit` / `can_release`; release called `party_handler.remove(monster)` (wrong name).

**After:** Storage calls `can_deposit_from_party()`, `can_release_monster()`, and `remove_monster(monster, false)` after confirmations.

**Example — storage release without double farewell:**

```gdscript
await player.party_handler.remove_monster(monster, false)
```

**Example — check before deposit button:**

```gdscript
if not player.party_handler.can_deposit_from_party():
	await show_message("You can't deposit your last monster!")
	return
```

---

## 5. `BattleSession` (`battle/battle_session.gd`)

`class_name BattleSession`. Node child of `Battle` in `battle.tscn`. Holds combat state; **no** `Control` inheritance.

### Fields

`player_actor`, `enemy_actor`, `player_party`, `enemy_party`, `is_wild_battle`, `enemy_trainer`.

### Methods

| Method | Purpose |
|--------|---------|
| `set_player_actor(monster)` | Sets actor + `was_active_in_battle` |
| `set_enemy_actor(monster)` | Sets enemy |
| `switch_actors(old, new)` | Updates player/enemy slot |
| `set_player_party(party)` | Replaces party array reference |
| `start_wild_battle(monster_data, level)` | Spawn wild enemy, set actors |
| `start_trainer_battle(trainer)` | Build enemy party, set actors |
| `reset_stats()` | Zero stages / reset multipliers for both parties |
| `clear_actors()` | Null actors |
| `clear_parties()` | Clear trainer + parties |
| `clear_all_battle_state()` | `reset_stats` + `clear_actors` + `clear_parties` + `is_wild_battle = true` |

**Before:** Same logic lived on `battle.gd` (`Control`).

**After:** `battle.gd` exposes getters/setters that forward to `session` so `battle.player_actor` still works everywhere.

**Example — external code (unchanged):**

```gdscript
var hp: int = battle.player_actor.hitpoints
Battle.switch_battle_actors.emit(old_m, new_m)
```

**Example — direct session access from a new battle node:**

```gdscript
var session: BattleSession = battle.get_node("BattleSession") as BattleSession
session.reset_stats()
```

---

## 6. `battle.gd` bridge (`battle/battle.gd`)

`Control` that owns UI nodes and `@onready var session = $BattleSession`.

Properties **forwarding** to `session`:

- `player_actor`, `enemy_actor`, `player_party`, `enemy_party`, `is_wild_battle`, `enemy_trainer` (get/set as appropriate)
- `enemy_party` is read-only getter (same array reference as `session.enemy_party`)

`set_player_actor` / `set_enemy_actor` / `switch_actors` / `end_battle` / `_start_wild_battle` / `_start_trainer_battle` / `_clear_all` orchestrate UI + session.

**Example — still valid after migration:**

```gdscript
func _on_debug_fill_battle(battle: Control) -> void:
	print(battle.player_actor.name)
	battle.player_party = saved_party_array
```

---

## Quick “where do I call X?”

| Task | Call |
|------|------|
| “Can I use this in the field?” | `ItemInteraction.can_use_outside_battle(item)` |
| “Can I give this to hold?” | `ItemInteraction.can_give_to_monster(item)` |
| “Battle bag allowed?” | `ItemInteraction.battle_item_blocked_reason(item, is_trainer_battle)` |
| “Execute give with dialogs” | `await ItemInteraction.give_item_to_monster(item, monster, self)` |
| “Use item on monster (evolve or use)” | `await ItemInteraction.use_item_on_monster_after_party_pick(item, monster)` |
| Shop transaction | `StoreService.try_buy` / `try_sell` |
| Move learn text only | `await MoveLearningService.show_move_learned_message(monster, move)` |
| Full move learn UI | `MoveLearningService.resolve_move_learning(summary, monster, move)` |
| Deposit / release rules | `party_handler.can_deposit_from_party()`, `can_release_monster(m)` |
| Remove monster quietly | `party_handler.remove_monster(m, false)` |
| Battle state (internal) | `BattleSession` methods on `battle.session` |

---

## Files removed

- `ui/text_box/move_learning_controller.gd` (replaced by `MoveLearningService` autoload)
- `MoveLearningController` node removed from `ui/summary/summary.tscn`
