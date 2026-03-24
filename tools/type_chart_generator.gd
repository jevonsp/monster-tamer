class_name TypeChartGenerator
extends RefCounted

const OUTPUT_PATH: String = "res://classes/TypeChart.gd"
const GENERATED_BEGIN: String = "# TYPE_CHART_GENERATED_BEGIN"
const GENERATED_END: String = "# TYPE_CHART_GENERATED_END"
const EFFICACY_NAMES: Dictionary = {
	TypeChartData.Efficacy.NOT_VERY: "NOT_VERY",
	TypeChartData.Efficacy.NORMAL: "NORMAL",
	TypeChartData.Efficacy.SUPER_EFFECTIVE: "SUPER_EFFECTIVE",
}

func generate(chart_data: TypeChartData, output_path: String = OUTPUT_PATH) -> bool:
	chart_data.enforce_matrix_shape()
	var source := FileAccess.get_file_as_string(output_path)
	if source.is_empty():
		return false

	var enum_names := _extract_enum_names(source)
	if enum_names.is_empty():
		return false
	if not _type_names_match(chart_data.types, enum_names):
		return false

	var chart_block := _build_chart_block(chart_data, enum_names)
	var updated_source := _replace_generated_block(source, chart_block)
	if updated_source.is_empty():
		return false

	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(updated_source)
	file.close()
	return true

func sync_types_from_script(chart_data: TypeChartData, output_path: String = OUTPUT_PATH) -> bool:
	var source := FileAccess.get_file_as_string(output_path)
	if source.is_empty():
		return false

	var enum_names := _extract_enum_names(source)
	if enum_names.is_empty():
		return false

	chart_data.types = enum_names.duplicate()
	chart_data.enforce_matrix_shape()
	return true

func _extract_enum_names(source: String) -> Array[String]:
	var enum_match := RegEx.new()
	if enum_match.compile("enum\\s+Type\\s*\\{([\\s\\S]*?)\\}") != OK:
		return []
	var result := enum_match.search(source)
	if result == null:
		return []

	var names: Array[String] = []
	for raw_line in result.get_string(1).split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		if line.ends_with(","):
			line = line.substr(0, line.length() - 1)
		if line.is_empty():
			continue
		names.append(line)
	return names

func _build_chart_block(chart_data: TypeChartData, type_names: Array[String]) -> String:
	var rows := []
	for row_idx in range(type_names.size()):
		var entries := []
		for col_idx in range(type_names.size()):
			var efficacy := chart_data.get_efficacy(row_idx, col_idx)
			var efficacy_name = EFFICACY_NAMES.get(efficacy, "NORMAL")
			entries.append("\t\tType.%s: %s," % [type_names[col_idx], efficacy_name])
		rows.append("\tType.%s: {\n%s\n\t}," % [type_names[row_idx], "\n".join(entries)])
	return "const TYPE_CHART: Dictionary = {\n%s\n}" % "\n".join(rows)

func _replace_generated_block(source: String, chart_block: String) -> String:
	var begin_index := source.find(GENERATED_BEGIN)
	var end_index := source.find(GENERATED_END)
	if begin_index == -1 or end_index == -1 or end_index <= begin_index:
		return ""

	var block_start := source.find("\n", begin_index)
	if block_start == -1:
		return ""
	block_start += 1

	var before := source.substr(0, block_start)
	var after := source.substr(end_index, source.length() - end_index)
	return before + chart_block + "\n" + after

func _type_names_match(current_types: Array[String], enum_names: Array[String]) -> bool:
	if current_types.size() != enum_names.size():
		return false
	for index in range(enum_names.size()):
		if current_types[index] != enum_names[index]:
			return false
	return true
