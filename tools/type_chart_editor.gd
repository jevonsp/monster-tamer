class_name TypeChartEditor
extends Control

const DATA_PATH: String = TypeChartData.DATA_PATH
const CHART_SCRIPT_PATH: String = "res://classes/TypeChart.gd"
const PANEL_MIN_WIDTH: float = 220.0
const CELL_WIDTH: float = 90.0
const CELL_HEIGHT: float = 38.0
const LIGHT_BUTTON_COLOR: Color = Color(0.86, 0.86, 0.86)
const LIGHT_BUTTON_HOVER_COLOR: Color = Color(0.93, 0.93, 0.93)
const LIGHT_BUTTON_PRESSED_COLOR: Color = Color(0.78, 0.78, 0.78)
const LIGHT_BUTTON_DISABLED_COLOR: Color = Color(0.8, 0.8, 0.8, 0.85)

const GRID_COLORS: Dictionary = {
	TypeChartData.Efficacy.NOT_VERY: Color(0.96, 0.46, 0.46),
	TypeChartData.Efficacy.NORMAL: Color(0.96, 0.96, 0.96),
	TypeChartData.Efficacy.SUPER_EFFECTIVE: Color(0.46, 0.96, 0.52),
}

const LABELS: Dictionary = {
	TypeChartData.Efficacy.NOT_VERY: "Not Very",
	TypeChartData.Efficacy.NORMAL: "Normal",
	TypeChartData.Efficacy.SUPER_EFFECTIVE: "Super",
}

var chart_data: TypeChartData
var type_list_container: VBoxContainer
var matrix_grid: GridContainer
var add_button: Button
var remove_button: Button
var save_button: Button
var status_label: Label

func _ready() -> void:
	_build_ui()
	chart_data = TypeChartData.load_from_file(DATA_PATH)
	var generator := TypeChartGenerator.new()
	if not generator.sync_types_from_script(chart_data, CHART_SCRIPT_PATH):
		_update_status("Failed to load enum names from TypeChart.gd", false)
		return
	add_button.pressed.connect(_on_add_type_pressed)
	remove_button.pressed.connect(_on_remove_type_pressed)
	save_button.pressed.connect(_on_save_pressed)
	_build_type_list()
	_build_matrix()
	_update_status("Type chart ready", true)

func _build_ui() -> void:
	_clear_children(self)
	anchor_right = 1.0
	anchor_bottom = 1.0

	var main := VBoxContainer.new()
	main.name = "Main"
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_theme_constant_override("separation", 8)
	add_child(main)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	main.add_child(top_bar)

	add_button = Button.new()
	add_button.text = "Add Type"
	add_button.disabled = true
	_apply_light_button_theme(add_button)
	top_bar.add_child(add_button)

	remove_button = Button.new()
	remove_button.text = "Remove Type"
	remove_button.disabled = true
	_apply_light_button_theme(remove_button)
	top_bar.add_child(remove_button)

	save_button = Button.new()
	save_button.text = "Save & Generate"
	_apply_light_button_theme(save_button)
	top_bar.add_child(save_button)

	status_label = Label.new()
	status_label.text = "Ready"
	main.add_child(status_label)

	var content_row := HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 12)
	main.add_child(content_row)

	var type_list_panel := PanelContainer.new()
	type_list_panel.custom_minimum_size = Vector2(PANEL_MIN_WIDTH, 0.0)
	content_row.add_child(type_list_panel)

	var type_panel_body := VBoxContainer.new()
	type_panel_body.add_theme_constant_override("separation", 6)
	type_list_panel.add_child(type_panel_body)

	var type_label := Label.new()
	type_label.text = "Types"
	type_panel_body.add_child(type_label)

	type_list_container = VBoxContainer.new()
	type_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	type_panel_body.add_child(type_list_container)

	var matrix_panel := PanelContainer.new()
	matrix_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	matrix_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_child(matrix_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	matrix_panel.add_child(scroll)

	matrix_grid = GridContainer.new()
	matrix_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	matrix_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	matrix_grid.add_theme_constant_override("h_separation", 2)
	matrix_grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(matrix_grid)

	var legend_bar := HBoxContainer.new()
	legend_bar.add_theme_constant_override("separation", 8)
	main.add_child(legend_bar)

	var legend_label := Label.new()
	legend_label.text = "Legend:"
	legend_bar.add_child(legend_label)

	legend_bar.add_child(_create_legend_item("Not Very", GRID_COLORS[TypeChartData.Efficacy.NOT_VERY]))
	legend_bar.add_child(_create_legend_item("Normal", GRID_COLORS[TypeChartData.Efficacy.NORMAL]))
	legend_bar.add_child(_create_legend_item("Super", GRID_COLORS[TypeChartData.Efficacy.SUPER_EFFECTIVE]))

func _build_type_list() -> void:
	_clear_children(type_list_container)
	for index in range(chart_data.types.size()):
		var line_edit := LineEdit.new()
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.text = chart_data.types[index]
		line_edit.editable = false
		type_list_container.add_child(line_edit)


func _build_matrix() -> void:
	matrix_grid.columns = chart_data.types.size() + 1
	_clear_children(matrix_grid)
	matrix_grid.add_child(_create_matrix_axis_label("Atk \\ Def"))
	for column_name in chart_data.types:
		matrix_grid.add_child(_create_matrix_header_label("Def\n%s" % column_name))
	for row_index in range(chart_data.types.size()):
		matrix_grid.add_child(_create_matrix_header_label("Atk\n%s" % chart_data.types[row_index]))
		for column_index in range(chart_data.types.size()):
			var cell_button := Button.new()
			cell_button.focus_mode = Control.FOCUS_NONE
			cell_button.custom_minimum_size = Vector2(CELL_WIDTH, CELL_HEIGHT)
			_apply_light_button_theme(cell_button)
			cell_button.set_meta("row", row_index)
			cell_button.set_meta("col", column_index)
			cell_button.pressed.connect(_on_cell_pressed.bind(cell_button))
			_refresh_cell(cell_button, chart_data.get_efficacy(row_index, column_index))
			matrix_grid.add_child(cell_button)

func _create_matrix_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(CELL_WIDTH, 32.0)
	return label

func _create_matrix_axis_label(text: String) -> Label:
	var label := _create_matrix_label(text)
	label.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18))
	return label

func _create_matrix_header_label(text: String) -> Label:
	var label := _create_matrix_label(text)
	label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))
	return label

func _create_legend_item(text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(20.0, 20.0)
	swatch.color = color
	row.add_child(swatch)

	var label := Label.new()
	label.text = text
	row.add_child(label)
	return row

func _apply_light_button_theme(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _create_button_stylebox(LIGHT_BUTTON_COLOR))
	button.add_theme_stylebox_override("hover", _create_button_stylebox(LIGHT_BUTTON_HOVER_COLOR))
	button.add_theme_stylebox_override("pressed", _create_button_stylebox(LIGHT_BUTTON_PRESSED_COLOR))
	button.add_theme_stylebox_override("focus", _create_button_stylebox(LIGHT_BUTTON_HOVER_COLOR))
	button.add_theme_stylebox_override("disabled", _create_button_stylebox(LIGHT_BUTTON_DISABLED_COLOR))
	button.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	button.add_theme_color_override("font_hover_color", Color(0.08, 0.08, 0.08))
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.08, 0.08))
	button.add_theme_color_override("font_focus_color", Color(0.08, 0.08, 0.08))
	button.add_theme_color_override("font_disabled_color", Color(0.28, 0.28, 0.28))

func _create_button_stylebox(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.62, 0.62, 0.62)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _refresh_cell(cell: Button, value: int) -> void:
	cell.text = LABELS.get(value, "Normal")
	cell.add_theme_color_override("font_color", Color(0, 0, 0))
	cell.self_modulate = GRID_COLORS.get(value, Color(0.9, 0.9, 0.9))

func _on_cell_pressed(button: Button) -> void:
	var row = button.get_meta("row")
	var col = button.get_meta("col")
	if row is int and col is int:
		var current := chart_data.get_efficacy(row, col)
		var next := (current + 1) % 3
		chart_data.set_efficacy(row, col, next)
		_refresh_cell(button, next)

func _on_add_type_pressed() -> void:
	_update_status("Types are defined by TypeChart.Type and cannot be added here", false)

func _on_remove_type_pressed() -> void:
	_update_status("Types are defined by TypeChart.Type and cannot be removed here", false)

func _on_save_pressed() -> void:
	var generator := TypeChartGenerator.new()
	if not generator.sync_types_from_script(chart_data, CHART_SCRIPT_PATH):
		_update_status("Failed to reload enum names from TypeChart.gd", false)
		return
	_build_type_list()
	_build_matrix()
	if not chart_data.save_to_file(DATA_PATH):
		_update_status("Failed to save type chart data", false)
		return
	if not generator.generate(chart_data, CHART_SCRIPT_PATH):
		_update_status("Failed to update TYPE_CHART block in %s" % CHART_SCRIPT_PATH, false)
		return
	_update_status("Saved and updated TYPE_CHART", true)

func _update_status(message: String, success: bool) -> void:
	status_label.text = message
	var color := Color(0.15, 0.65, 0.15) if success else Color(0.85, 0.18, 0.18)
	status_label.add_theme_color_override("font_color", color)

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
