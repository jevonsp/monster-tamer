class_name TypeChartData
extends RefCounted

enum Efficacy {
	NOT_VERY,
	NORMAL,
	SUPER_EFFECTIVE,
}

const DEFAULT_TYPES: Array[String] = ["NONE", "FIRE", "WATER", "GRASS"]
const DEFAULT_MATRIX: Array = [
	[Efficacy.NORMAL, Efficacy.NORMAL, Efficacy.NORMAL, Efficacy.NORMAL],
	[Efficacy.NORMAL, Efficacy.NORMAL, Efficacy.NOT_VERY, Efficacy.SUPER_EFFECTIVE],
	[Efficacy.NORMAL, Efficacy.SUPER_EFFECTIVE, Efficacy.NORMAL, Efficacy.NOT_VERY],
	[Efficacy.NORMAL, Efficacy.NOT_VERY, Efficacy.SUPER_EFFECTIVE, Efficacy.NORMAL],
]
const DATA_PATH: String = "res://tools/type_chart_data.json"

var types: Array[String]
var matrix: Array

func _init() -> void:
	types = []
	matrix = []
	populate_defaults()

func populate_defaults() -> void:
	types = DEFAULT_TYPES.duplicate()
	matrix = []
	for row_values in DEFAULT_MATRIX:
		matrix.append(row_values.duplicate())
	enforce_matrix_shape()

func enforce_matrix_shape() -> void:
	var size := types.size()
	while matrix.size() < size:
		matrix.append([])
	for row_index in range(matrix.size()):
		var row = matrix[row_index]
		while row.size() < size:
			row.append(Efficacy.NORMAL)
		while row.size() > size:
			row.pop_back()
	while matrix.size() > size:
		matrix.pop_back()

func add_type(name: String) -> void:
	types.append(name)
	enforce_matrix_shape()

func remove_type(index: int) -> void:
	if index < 0 or index >= types.size():
		return
	types.remove_at(index)
	matrix.remove_at(index)
	for row in matrix:
		if index < row.size():
			row.remove_at(index)
	enforce_matrix_shape()

func set_type_name(index: int, name: String) -> void:
	if index < 0 or index >= types.size():
		return
	types[index] = name

func set_efficacy(row: int, col: int, value: int) -> void:
	if row < 0 or row >= matrix.size():
		return
	if col < 0 or col >= matrix[row].size():
		return
	matrix[row][col] = clamp(value, Efficacy.NOT_VERY, Efficacy.SUPER_EFFECTIVE)

func get_efficacy(row: int, col: int) -> int:
	if row < 0 or row >= matrix.size() or col < 0 or col >= matrix[row].size():
		return Efficacy.NORMAL
	return matrix[row][col]

func to_serializable() -> Dictionary:
	var serializable := {
		"types": types.duplicate(),
	}
	var matrix_dump := []
	for row in matrix:
		matrix_dump.append(row.duplicate())
	serializable["matrix"] = matrix_dump
	return serializable

func save_to_file(path: String = DATA_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	var json_string := JSON.stringify(to_serializable(), "\t")
	file.store_string(json_string)
	file.close()
	return true

static func load_from_file(path: String = DATA_PATH) -> TypeChartData:
	var loader := TypeChartData.new()
	if not FileAccess.file_exists(path):
		loader.populate_defaults()
		loader.save_to_file(path)
		return loader
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		loader.populate_defaults()
		return loader
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()
	if parse_result != OK or not json.data is Dictionary:
		loader.populate_defaults()
		return loader
	var data = json.data
	loader.types = []
	if data.has("types"):
		for name in data.types:
			loader.types.append(str(name))
	if loader.types.is_empty():
		loader.types = DEFAULT_TYPES.duplicate()
	loader.matrix = []
	if data.has("matrix"):
		for row_values in data.matrix:
			var row := []
			for entry in row_values:
				row.append(int(entry))
			loader.matrix.append(row)
	loader.enforce_matrix_shape()
	return loader
