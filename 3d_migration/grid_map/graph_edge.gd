class_name GraphEdge
extends RefCounted

enum MoveKind { WALK, LEDGE_JUMP }

var to_cell: Vector3i = Vector3i.ZERO
var step: Vector3i = Vector3i.ZERO
var move_kind: MoveKind = MoveKind.WALK
var via_cell: Vector3i = Vector3i.ZERO
