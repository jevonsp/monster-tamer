class_name EmoteCommand
extends Command

@export var emote_type: Emote.Type = Emote.Type.EXCLAIM
@export var is_autocomplete: bool = true


func _trigger_impl(owner) -> Flow:
	if owner is not Character3D:
		return Flow.NEXT
	var character: Character3D = owner as Character3D
	character.emote.play_emote(_emote_to_stringname(emote_type), is_autocomplete)
	await character.emote.emote_finished

	return Flow.NEXT


func _emote_to_stringname(emote: Emote.Type) -> StringName:
	return StringName(Emote.Type.keys()[emote].to_lower())
