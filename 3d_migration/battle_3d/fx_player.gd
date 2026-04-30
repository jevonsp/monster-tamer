extends AnimationPlayer

const BALL_SINGLE = preload("uid://ddedh5jwmoi1a")

@onready var player_texture_rect: TextureRect = $"../PlayerTextureRect"
@onready var enemy_texture_rect: TextureRect = $"../EnemyTextureRect"
@onready var item_sprite: Sprite2D = $"../Path2D/PathFollow2D/ItemSprite"


func play_hit(target: Monster) -> void:
	if player_texture_rect.actor == target:
		play("player_0_hit")
	if enemy_texture_rect.actor == target:
		play("enemy_0_hit")
	await animation_finished


func play_throw_item(item: Item) -> void:
	if item.texture:
		item_sprite.texture = item.texture
	play("throw_item")
	await animation_finished

	item_sprite.texture = BALL_SINGLE


func play_item_wiggle(times: int) -> void:
	pass
