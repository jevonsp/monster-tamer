extends Node3D

const _MONSTER_ROOT := "res://content/monsters"
const _MOVES_ROOT := "res://content/moves"
const _RESOURCE_EXTS: PackedStringArray = ["tres", "res"]
const _PLAYER_3D_SCENE := preload("res://gameplay/field/character_3d/player_3d/player_3d.tscn")

@onready var _dev_layer: CanvasLayer = $DevUiLayer

var _monster_list: Array[MonsterData] = []
var _move_list: Array[Move] = []

var _party_root: Node
var _party_handler: PartyHandler3D

var _dev_panel: PanelContainer
var _dev_toggle: Button
var _opt_player_species: OptionButton
var _opt_enemy_species: OptionButton
var _spin_player_level: SpinBox
var _spin_enemy_level: SpinBox
var _player_move_opts: Array[OptionButton] = []
var _enemy_move_opts: Array[OptionButton] = []


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_scan_monsters()
	_scan_moves()
	_setup_party_handler()
	_build_dev_panel()


func _setup_party_handler() -> void:
	_party_root = Node.new()
	_party_root.name = "PartyRoot"
	add_child(_party_root)
	var player_stub := _PLAYER_3D_SCENE.instantiate() as Player3D
	player_stub.name = "PlayerStub"
	player_stub.process_mode = Node.PROCESS_MODE_DISABLED
	player_stub.visible = false
	_party_root.add_child(player_stub)
	_party_handler = player_stub.party_handler
	PlayerContext3D.party_handler = _party_handler


func _scan_monsters() -> void:
	var paths: PackedStringArray = []
	_collect_resource_paths(_MONSTER_ROOT, paths)
	paths.sort()
	for p: String in paths:
		var r := load(p)
		if r == null:
			continue
		if r is MonsterData:
			_monster_list.append(r as MonsterData)
	if _monster_list.is_empty():
		push_error("BattleTestScene: no MonsterData under %s" % _MONSTER_ROOT)


func _scan_moves() -> void:
	var paths: PackedStringArray = []
	_collect_resource_paths(_MOVES_ROOT, paths)
	paths.sort()
	for p: String in paths:
		var r := load(p)
		if r == null:
			continue
		if r is Move:
			_move_list.append(r as Move)
	if _move_list.is_empty():
		push_error("BattleTestScene: no Move under %s" % _MOVES_ROOT)


func _collect_resource_paths(dir_path: String, out_paths: PackedStringArray) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		push_error("BattleTestScene: cannot open %s" % dir_path)
		return
	var err := da.list_dir_begin()
	if err != OK:
		push_error("BattleTestScene: list_dir_begin failed for %s" % dir_path)
		return
	var entry := da.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = da.get_next()
			continue
		var full := dir_path.path_join(entry)
		if da.current_is_dir():
			_collect_resource_paths(full, out_paths)
		elif entry.get_extension() in _RESOURCE_EXTS:
			out_paths.append(full)
		entry = da.get_next()
	da.list_dir_end()


func _build_dev_panel() -> void:
	_dev_toggle = Button.new()
	_dev_toggle.text = "Hide dev panel"
	_dev_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_dev_toggle.offset_left = -200.0
	_dev_toggle.offset_top = 8.0
	_dev_toggle.offset_right = -8.0
	_dev_toggle.offset_bottom = 40.0
	_dev_toggle.pressed.connect(_on_toggle_dev_panel_pressed)
	_dev_layer.add_child(_dev_toggle)

	var panel := PanelContainer.new()
	_dev_panel = panel
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.offset_right = 440.0
	panel.offset_bottom = 620.0
	_dev_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Battle test"
	vbox.add_child(title)

	_opt_player_species = _add_species_row(vbox, "Player species")
	_spin_player_level = _add_level_row(vbox, "Player level")
	_player_move_opts = _add_move_rows(vbox, "Player moves")
	_add_button(vbox, "Player: species default moves", _on_player_default_moves_pressed)

	vbox.add_child(HSeparator.new())

	_opt_enemy_species = _add_species_row(vbox, "Enemy species")
	_spin_enemy_level = _add_level_row(vbox, "Enemy level")
	_enemy_move_opts = _add_move_rows(vbox, "Enemy moves")
	_add_button(vbox, "Enemy: species default moves", _on_enemy_default_moves_pressed)

	vbox.add_child(HSeparator.new())

	_add_button(vbox, "Start battle", _on_start_battle_pressed)
	_add_button(vbox, "Reset encounter", _on_reset_encounter_pressed)

	if not _monster_list.is_empty():
		_fill_species_option(_opt_player_species)
		_fill_species_option(_opt_enemy_species)
		_opt_enemy_species.select(mini(1, _opt_enemy_species.item_count - 1))
	for ob: OptionButton in _player_move_opts:
		_fill_move_option(ob)
	for ob: OptionButton in _enemy_move_opts:
		_fill_move_option(ob)

	if not _monster_list.is_empty():
		_apply_species_default_moves(_monster_list[0], int(_spin_player_level.value), _player_move_opts)
		var ei := mini(1, _monster_list.size() - 1)
		_apply_species_default_moves(_monster_list[ei], int(_spin_enemy_level.value), _enemy_move_opts)

	_apply_light_text_recursive(panel)
	_apply_light_text_recursive(_dev_toggle)


func _apply_light_text_recursive(n: Node) -> void:
	if n is Button:
		var b := n as Button
		for c: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
			b.add_theme_color_override(c, Color.WHITE)
	elif n is OptionButton:
		var o := n as OptionButton
		for c: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
			o.add_theme_color_override(c, Color.WHITE)
	elif n is Label:
		(n as Label).add_theme_color_override(&"font_color", Color.WHITE)
	elif n is SpinBox:
		var s := n as SpinBox
		s.add_theme_color_override(&"font_color", Color.WHITE)
		var le: LineEdit = s.get_line_edit()
		le.add_theme_color_override(&"font_color", Color.WHITE)
	for c in n.get_children():
		_apply_light_text_recursive(c)


func _add_species_row(parent: VBoxContainer, label_text: String) -> OptionButton:
	var hb := HBoxContainer.new()
	parent.add_child(hb)
	var lbl := Label.new()
	lbl.text = label_text
	hb.add_child(lbl)
	var ob := OptionButton.new()
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(ob)
	_apply_light_text_recursive(hb)
	return ob


func _add_level_row(parent: VBoxContainer, label_text: String) -> SpinBox:
	var hb := HBoxContainer.new()
	parent.add_child(hb)
	var lbl := Label.new()
	lbl.text = label_text
	hb.add_child(lbl)
	var sp := SpinBox.new()
	sp.min_value = 1.0
	sp.max_value = 100.0
	sp.value = 12.0
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_apply_light_text_recursive(hb)
	return sp


func _add_move_rows(parent: VBoxContainer, title: String) -> Array[OptionButton]:
	var lbl := Label.new()
	lbl.text = title
	parent.add_child(lbl)
	_apply_light_text_recursive(lbl)
	var out: Array[OptionButton] = []
	for i in 4:
		var hb := HBoxContainer.new()
		parent.add_child(hb)
		var sl := Label.new()
		sl.text = "Move %d" % (i + 1)
		sl.custom_minimum_size.x = 72.0
		hb.add_child(sl)
		var ob := OptionButton.new()
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(ob)
		_apply_light_text_recursive(hb)
		out.append(ob)
	return out


func _add_button(parent: VBoxContainer, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	_apply_light_text_recursive(b)


func _fill_species_option(ob: OptionButton) -> void:
	ob.clear()
	for md: MonsterData in _monster_list:
		ob.add_item(md.species if md.species else md.resource_path.get_file())


func _fill_move_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("—")
	for mv: Move in _move_list:
		var nm := mv.name if mv and mv.name else mv.resource_path.get_file()
		ob.add_item(nm)


func _move_index_from_option(ob: OptionButton) -> int:
	var sel := ob.selected
	if sel <= 0:
		return -1
	return sel - 1


func _sync_move_pickers_from_monster(m: Monster, pickers: Array[OptionButton]) -> void:
	for i in 4:
		var ob := pickers[i]
		var mv: Move = m.moves[i] if i < m.moves.size() else null
		if mv == null:
			ob.select(0)
			continue
		var idx := _move_list.find(mv)
		if idx >= 0:
			ob.select(idx + 1)
		else:
			ob.select(0)


func _apply_species_default_moves(data: MonsterData, level: int, pickers: Array[OptionButton]) -> void:
	var tmp := data.set_up(level)
	_sync_move_pickers_from_monster(tmp, pickers)


func _on_player_default_moves_pressed() -> void:
	if _opt_player_species.item_count <= 0:
		return
	var md := _monster_list[_opt_player_species.selected]
	_apply_species_default_moves(md, int(_spin_player_level.value), _player_move_opts)


func _on_enemy_default_moves_pressed() -> void:
	if _opt_enemy_species.item_count <= 0:
		return
	var md := _monster_list[_opt_enemy_species.selected]
	_apply_species_default_moves(md, int(_spin_enemy_level.value), _enemy_move_opts)


func _build_monster_from_ui(
		data: MonsterData,
		level: int,
		move_pickers: Array[OptionButton],
		is_player: bool,
) -> Monster:
	var m := data.set_up(level)
	m.is_player_monster = is_player
	m.is_fainted = false
	m.move_pp.clear()
	var new_moves: Array[Move] = []
	for i in 4:
		var mi := _move_index_from_option(move_pickers[i])
		if mi < 0:
			new_moves.append(null)
		else:
			new_moves.append(_move_list[mi])
	m.moves = new_moves
	for mv: Move in m.moves:
		if mv != null:
			m.set_pp(mv)
	return m


func _on_start_battle_pressed() -> void:
	if Battle.chassis == null or _monster_list.is_empty():
		return
	if Battle.chassis.in_battle:
		Battle.battle_ended.emit(null)
	Battle.chassis.reset_turn_state()

	var pdata: MonsterData = _monster_list[_clamp_index(_opt_player_species.selected, _monster_list.size())]
	var edata: MonsterData = _monster_list[_clamp_index(_opt_enemy_species.selected, _monster_list.size())]
	var plv := int(_spin_player_level.value)
	var elv := int(_spin_enemy_level.value)
	var pm := _build_monster_from_ui(pdata, plv, _player_move_opts, true)
	var em := _build_monster_from_ui(edata, elv, _enemy_move_opts, false)

	_party_handler.party.clear()
	_party_handler.party.append(pm)

	var chassis := Battle.chassis
	chassis.player_team = _party_handler.party
	chassis.enemy_team = [em]
	chassis.in_battle = true
	chassis.trainer = null
	chassis.player_actors = {0: pm}
	chassis.enemy_actors = {0: em}
	chassis.actors_changed.emit(chassis.player_actors, chassis.enemy_actors)
	Battle.battle_started.emit()


func _on_reset_encounter_pressed() -> void:
	if Battle.chassis == null or _monster_list.is_empty():
		return
	if Battle.chassis.in_battle:
		Battle.battle_ended.emit(null)
	Battle.chassis.reset_turn_state()

	var pdata: MonsterData = _monster_list[_clamp_index(_opt_player_species.selected, _monster_list.size())]
	var edata: MonsterData = _monster_list[_clamp_index(_opt_enemy_species.selected, _monster_list.size())]
	var plv := int(_spin_player_level.value)
	var elv := int(_spin_enemy_level.value)
	var pm := _build_monster_from_ui(pdata, plv, _player_move_opts, true)
	var em := _build_monster_from_ui(edata, elv, _enemy_move_opts, false)

	_party_handler.party.clear()
	_party_handler.party.append(pm)

	var chassis := Battle.chassis
	chassis.player_team = _party_handler.party
	chassis.enemy_team = [em]
	chassis.in_battle = false
	chassis.trainer = null
	chassis.player_actors.clear()
	chassis.enemy_actors.clear()


func _clamp_index(i: int, size: int) -> int:
	if size <= 0:
		return 0
	return clampi(i, 0, size - 1)


func _on_toggle_dev_panel_pressed() -> void:
	_dev_panel.visible = not _dev_panel.visible
	_dev_toggle.text = "Show dev panel" if not _dev_panel.visible else "Hide dev panel"
