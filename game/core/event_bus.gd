extends Node

signal interaction_requested(actor_id: String)
signal dialogue_started(dialogue_id: String)
signal dialogue_closed
signal quest_updated(quest_id: String, status: String)
signal inventory_changed
signal save_changed

func request_interaction(actor_id: String) -> void:
	interaction_requested.emit(actor_id)
