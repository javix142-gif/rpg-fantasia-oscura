class_name DialogueNode
extends Resource

@export var id: String = ""
@export var speaker: String = ""
@export_multiline var text: String = ""
@export var conditions: Array[Dictionary] = []
@export var choices: Array[Dictionary] = []
@export var effects: Array[Dictionary] = []
@export var next_node: String = ""
