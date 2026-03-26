extends Button

var item_repr: Item = null

@onready var texture_rect: TextureRect = $MarginContainer/HBoxContainer/TextureRect
@onready var name_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/VBoxContainer/NameLabel
@onready var quantity_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/VBoxContainer/QuantityLabel
@onready var description_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/DescriptionLabel


func _ready() -> void:
	var path: NodePath = get_path()
	focus_neighbor_left = path


func display(amount: int, item: Item) -> void:
	item_repr = item
	display_texture(item)
	display_name(item)
	display_quantity(amount)
	display_description(item)


func display_texture(item: Item) -> void:
	if item.inventory_texture:
		texture_rect.texture = item.inventory_texture
	else:
		texture_rect.texture = null


func display_name(item: Item) -> void:
	if item.name:
		name_label.text = item.name
	else:
		name_label.text = ""


func display_quantity(amount: int) -> void:
	quantity_label.text = "x %s" % [amount]


func display_description(item: Item) -> void:
	if item.description:
		description_label.text = item.description
	else:
		description_label.text = ""
