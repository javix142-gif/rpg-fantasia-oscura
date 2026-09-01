class_name InteractionTarget
extends Area2D

signal activated(target_id: String)

@export var target_id: String = ""
@export var prompt: String = "Interactuar"
@export var action: String = "inspect"

func interaction_data() -> Dictionary:
	return {"id": target_id, "prompt": prompt, "action": action}

func activate() -> void:
	activated.emit(target_id)
