class_name QuestDefinition
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var stages: Array[String] = []
@export var completion_effects: Array[Dictionary] = []
