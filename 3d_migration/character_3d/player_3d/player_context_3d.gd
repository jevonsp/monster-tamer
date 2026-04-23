extends Node

@warning_ignore_start("unused_signal")
signal walk_segmented_completed(graph_position: Vector3i)
signal toggle_player(value: bool)

@warning_ignore_restore("unused_signal")
var player: Player3D
var camera_3d: Camera3D
var party_handler: PartyHandler3D
var inventory_handler: InventoryHandler3D
var story_flag_handler: StoryFlagHandler3D
var travel_handler: TravelHandler3D
var player_info_handler: PlayerInfo3D
