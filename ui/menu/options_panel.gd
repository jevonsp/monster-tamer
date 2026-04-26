extends Panel

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
	var back := NodePath("../../../../../Menu/Content/VBoxContainer/Options")
	for b: Button in [option_button_0, option_button_1, option_button_2]:
		b.focus_neighbor_left = back
	display_settings()
	_bind_buttons()


func grab_entry_focus() -> void:
	display_settings()
	option_button_0.grab_focus()


func display_settings() -> void:
	button_label_pairs[0].btn_lbl.text = settings_info["control_scheme"].button_text
	match GameOptions.control_scheme:
		GameOptions.ControlScheme.XBOX_SONY:
			button_label_pairs[0].reg_lbl.text = settings_info["control_scheme"].options_text[0]
		GameOptions.ControlScheme.NINTENDO:
			button_label_pairs[0].reg_lbl.text = settings_info["control_scheme"].options_text[1]

	button_label_pairs[1].btn_lbl.text = settings_info["game_variant"].button_text
	match GameOptions.game_variant:
		GameOptions.GameVariant.NORMAL:
			button_label_pairs[1].reg_lbl.text = settings_info["game_variant"].options_text[0]
		GameOptions.GameVariant.NUZLOCKE:
			button_label_pairs[1].reg_lbl.text = settings_info["game_variant"].options_text[1]
	if not GameOptions.can_change_variant:
		option_button_1.disabled = true

	button_label_pairs[2].btn_lbl.text = settings_info["is_forgetful_saver"].button_text
	if GameOptions.is_forgetful_saver:
		button_label_pairs[2].reg_lbl.text = settings_info["is_forgetful_saver"].options_text[1]
	else:
		button_label_pairs[2].reg_lbl.text = settings_info["is_forgetful_saver"].options_text[0]


func _bind_buttons() -> void:
	var option_buttons = [option_button_0, option_button_1, option_button_2, option_button_3]
	for b: Button in option_buttons:
		b.pressed.connect(_on_option_button_pressed.bind(b))


func _on_option_button_pressed(button: Button) -> void:
	match button:
		option_button_0:
			GameOptions.control_scheme = (
				GameOptions.ControlScheme.NINTENDO
				if GameOptions.control_scheme == GameOptions.ControlScheme.XBOX_SONY
				else GameOptions.ControlScheme.XBOX_SONY
			)
			var p0: Player3D = PlayerContext3D.player
			if p0:
				p0.info.input_layout = GameOptions.control_scheme
			else:
				InputRemapper.apply(GameOptions.control_scheme)
		option_button_1:
			if GameOptions.can_change_variant:
				GameOptions.game_variant = (
					GameOptions.GameVariant.NUZLOCKE
					if GameOptions.game_variant == GameOptions.GameVariant.NORMAL
					else GameOptions.GameVariant.NORMAL
				)
				GameOptions.can_change_variant = false
		option_button_2:
			GameOptions.is_forgetful_saver = not GameOptions.is_forgetful_saver
		_:
			return
	SaverLoader.save_config()
	display_settings()
