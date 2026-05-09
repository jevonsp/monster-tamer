extends Panel

const CONTROL_SCHEME_XBOX_SONY := 0
const CONTROL_SCHEME_NINTENDO := 1
const GAME_VARIANT_NORMAL := 0
const GAME_VARIANT_NUZLOCKE := 1

var _fallback_options: Resource = null

var settings_info: Dictionary = {
	"control_scheme": {
		button_text = "Control Scheme",
		options_text = [
			"Xbox/Sony",
			"Nintendo",
		],
	},
	"game_variant": {
		button_text = "Game Style",
		options_text = [
			"Normal",
			"Nuzlocke",
		],
	},
	"is_forgetful_saver": {
		button_text = "Do you forget to save?",
		options_text = [
			"No.",
			"Yes!",
		],
	},
}

@onready var option_button_0: Button = $MarginContainer/HBoxContainer/Buttons/OptionButton0
@onready var option_button_1: Button = $MarginContainer/HBoxContainer/Buttons/OptionButton1
@onready var option_button_2: Button = $MarginContainer/HBoxContainer/Buttons/OptionButton2
@onready var option_button_3: Button = $MarginContainer/HBoxContainer/Buttons/OptionButton3
@onready var button_label_0: Label = \
$MarginContainer/HBoxContainer/Buttons/OptionButton0/MarginContainer/Label
@onready var button_label_1: Label = \
$MarginContainer/HBoxContainer/Buttons/OptionButton1/MarginContainer/Label
@onready var button_label_2: Label = \
$MarginContainer/HBoxContainer/Buttons/OptionButton2/MarginContainer/Label
@onready var button_label_3: Label = \
$MarginContainer/HBoxContainer/Buttons/OptionButton3/MarginContainer/Label
@onready var label_0: Label = $MarginContainer/HBoxContainer/Settings/Label0
@onready var label_1: Label = $MarginContainer/HBoxContainer/Settings/Label1
@onready var label_2: Label = $MarginContainer/HBoxContainer/Settings/Label2
@onready var label_3: Label = $MarginContainer/HBoxContainer/Settings/Label3
@onready var button_label_pairs: Dictionary[int, Dictionary] = {
	0: {
		btn_lbl = button_label_0,
		reg_lbl = label_0,
	},
	1: {
		btn_lbl = button_label_1,
		reg_lbl = label_1,
	},
	2: {
		btn_lbl = button_label_2,
		reg_lbl = label_2,
	},
	3: {
		btn_lbl = button_label_3,
		reg_lbl = label_3,
	},
}


func _ready() -> void:
	option_button_3.visible = false
	button_label_pairs[3].btn_lbl.visible = false
	button_label_pairs[3].reg_lbl.visible = false
	visibility_changed.connect(_on_visibility_changed)
	var back := NodePath("../../../../../Menu/Content/VBoxContainer/Options")
	for b: Button in [option_button_0, option_button_1, option_button_2]:
		b.focus_neighbor_left = back
	display_settings()
	_bind_buttons()
	_on_visibility_changed()


func _exit_tree() -> void:
	if UiFlow != null:
		UiFlow.unregister_ui_layer(self)


func grab_entry_focus() -> void:
	display_settings()
	option_button_0.grab_focus()


func display_settings() -> void:
	var options: Resource = _options()
	button_label_pairs[0].btn_lbl.text = settings_info["control_scheme"].button_text
	match options.control_scheme:
		CONTROL_SCHEME_XBOX_SONY:
			button_label_pairs[0].reg_lbl.text = settings_info["control_scheme"].options_text[0]
		CONTROL_SCHEME_NINTENDO:
			button_label_pairs[0].reg_lbl.text = settings_info["control_scheme"].options_text[1]

	button_label_pairs[1].btn_lbl.text = settings_info["game_variant"].button_text
	match options.game_variant:
		GAME_VARIANT_NORMAL:
			button_label_pairs[1].reg_lbl.text = settings_info["game_variant"].options_text[0]
		GAME_VARIANT_NUZLOCKE:
			button_label_pairs[1].reg_lbl.text = settings_info["game_variant"].options_text[1]
	if not options.can_change_variant:
		option_button_1.disabled = true

	button_label_pairs[2].btn_lbl.text = settings_info["is_forgetful_saver"].button_text
	if options.is_forgetful_saver:
		button_label_pairs[2].reg_lbl.text = settings_info["is_forgetful_saver"].options_text[1]
	else:
		button_label_pairs[2].reg_lbl.text = settings_info["is_forgetful_saver"].options_text[0]


func _bind_buttons() -> void:
	var option_buttons = [option_button_0, option_button_1, option_button_2, option_button_3]
	for b: Button in option_buttons:
		b.pressed.connect(_on_option_button_pressed.bind(b))


func _on_option_button_pressed(button: Button) -> void:
	var options: Resource = _options()
	match button:
		option_button_0:
			options.control_scheme = (
				CONTROL_SCHEME_NINTENDO
				if options.control_scheme == CONTROL_SCHEME_XBOX_SONY
				else CONTROL_SCHEME_XBOX_SONY
			)
			var p0: Player3D = PlayerContext3D.player
			if p0:
				p0.player_info_handler.input_layout = options.control_scheme
			else:
				InputRemapper.apply(options.control_scheme)
		option_button_1:
			if options.can_change_variant:
				options.game_variant = (
					GAME_VARIANT_NUZLOCKE
					if options.game_variant == GAME_VARIANT_NORMAL
					else GAME_VARIANT_NORMAL
				)
				options.can_change_variant = false
		option_button_2:
			options.is_forgetful_saver = not options.is_forgetful_saver
		_:
			return
	SaverLoader.save_config()
	display_settings()


func _on_visibility_changed() -> void:
	if UiFlow == null:
		return
	if visible:
		UiFlow.register_ui_layer(self, true)
		return
	UiFlow.unregister_ui_layer(self)


func _options() -> Resource:
	if PlayerContext3D == null or PlayerContext3D.player_info_handler == null:
		if _fallback_options == null:
			_fallback_options = GameOptions.new()
			_fallback_options.reset_defaults()
		return _fallback_options
	var pih: PlayerInfo3D = PlayerContext3D.player_info_handler
	if pih.game_options == null:
		var options = GameOptions.new()
		options.reset_defaults()
		pih.game_options = options
	return pih.game_options
