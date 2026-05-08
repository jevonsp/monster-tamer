class_name TeleportCommand
extends Command

@export var teleports_player: bool = false
@export var cell_path: NodePath


func _trigger_impl(owner: Node) -> Flow:
	if cell_path:
		var cell: CellObject = owner.get_node(cell_path)
		if cell:
			var position = cell.global_position
			if teleports_player:
				var player = PlayerContext3D.player
				player.position = position
			else:
				var character = owner as Character3D
				character.position = position

	return Flow.NEXT
