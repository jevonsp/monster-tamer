extends Button
@onready var texture_rect: TextureRect = $MarginContainer/HBoxContainer/TextureRect
@onready var name_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/VBoxContainer/NameLabel
@onready var quantity_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/VBoxContainer/QuantityLabel
@onready var description_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/DescriptionLabel

func display(amount: int, item: Item) -> void:
	display_texture(item)
	display_name(item)
	display_quantity(amount)
	display_description(item)


func display_texture(item: Item) -> void:
	if item.inventory_texture:
		texture_rect.texture = item.inventory_texture 


func display_name(item: Item) -> void:
	if item.name:
		name_label.text = item.name


func display_quantity(amount: int) -> void:
	quantity_label.text = "x %s" % [amount]


func display_description(item: Item) -> void:
	if item.description:
		description_label.text = item.description
