extends Button
var item: Item = null
@onready var texture_rect: TextureRect = $MarginContainer/HBoxContainer/TextureRect
@onready var name_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/VBoxContainer/NameLabel
@onready var price_label: Label = \
		$MarginContainer/HBoxContainer/Control/HBoxContainer/VBoxContainer/HBoxContainer/PriceLabel
@onready var quantity_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/VBoxContainer/HBoxContainer/QuantityLabel
@onready var description_label: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/DescriptionLabel

func _ready() -> void:
	var path: NodePath = get_path()
	focus_neighbor_left = path


func display(item_displaying: Item, amount: int) -> void:
	item = item_displaying
	_display_texture(item)
	_display_name(item)
	_display_price(item)
	_display_quantity(amount)
	_display_description(item)


func _display_texture(item_displaying: Item) -> void:
	if item_displaying.inventory_texture:
		texture_rect.texture = item_displaying.inventory_texture
	else:
		texture_rect.texture = null


func _display_name(item_displaying: Item) -> void:
	if item_displaying.name:
		name_label.text = item_displaying.name
	else:
		name_label.text = ""


func _display_price(item_displaying: Item) -> void:
	if item_displaying.price:
		price_label.text = "$: %s" % [item_displaying.price]
	else:
		price_label.text = "$: ?"
	

func _display_quantity(amount: int) -> void:
	if amount >= 0:
		quantity_label.text = "x %s" % [amount]
	elif amount <= -1:
		quantity_label.text = "x ∞"


func _display_description(item_displaying: Item) -> void:
	if item_displaying.description:
		description_label.text = item_displaying.description
	else:
		description_label.text = ""
