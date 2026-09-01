class_name Stage1DialogueService
extends RefCounted

## Small data-driven dialogue catalogue. Conditions/effects are generic and do
## not live in the UI.

func open_for_actor(actor_id: String) -> Dictionary:
	match actor_id:
		"NPC_IRIA": return _iria_dialogue()
		"NPC_HALVEN": return _halven_dialogue()
		"NPC_SMITH": return {"id": "DIALOGUE_SMITH", "start": "smith", "nodes": {"smith": {"speaker": "Bram", "text": "El yunque está caliente. Cuando vuelvas, revisamos esa linterna.", "choices": [{"text": "Gracias.", "next": ""}]}}}
		"NPC_MERCHANT": return {"id": "DIALOGUE_MERCHANT", "start": "merchant", "nodes": {"merchant": {"speaker": "Nella", "text": "Tengo fruta fresca y buenos precios. Hoy sólo estamos aprendiendo el camino.", "choices": [{"text": "Hasta luego.", "next": ""}]}}}
		"NPC_FRIEND": return {"id": "DIALOGUE_FRIEND", "start": "friend", "nodes": {"friend": {"speaker": "Tomas", "text": "Liria se siente tranquila esta mañana. Aprovecha para conocer sus caminos.", "choices": [{"text": "Lo haré.", "next": ""}]}}}
		_: return {"id": "DIALOGUE_AMBIENT", "start": "hello", "nodes": {"hello": {"speaker": "Vecino", "text": "Qué buen día para trabajar en Liria.", "choices": [{"text": "Adiós.", "next": ""}]}}}

func node_for(dialogue: Dictionary, node_id: String) -> Dictionary:
	var nodes: Dictionary = dialogue.get("nodes", {})
	var node: Dictionary = nodes.get(node_id, {})
	if node.is_empty():
		return {}
	for condition in node.get("conditions", []):
		if not _condition_passes(condition):
			return {}
	return node

func _condition_passes(condition: Dictionary) -> bool:
	var state: Node = Engine.get_main_loop().root.get_node_or_null("GameState")
	return state != null and bool(state.call("condition_passes", condition))

func first_available(dialogue: Dictionary) -> Dictionary:
	return node_for(dialogue, String(dialogue.get("start", "")))

func _iria_dialogue() -> Dictionary:
	return {
		"id": "DIALOGUE_IRIA_MQ00_01",
		"start": "start",
		"nodes": {
			"start": {"speaker": "Iria", "text": "La plaza está despierta. ¿Puedes ayudarme a saludar a Halven y comprobar que todo está listo?", "conditions": [{"type": "NotFlag", "value": "MQ00_01_COMPLETE"}], "choices": [{"text": "Claro, voy a verlo.", "next": "started", "effects": [{"type": "StartQuest", "value": "MQ00_01"}]}, {"text": "Ahora no.", "next": "later"}]},
			"started": {"speaker": "Iria", "text": "Gracias. Halven está en su edificio, al este de la plaza. Después vuelve conmigo.", "conditions": [{"type": "ClassEquals", "value": _current_class_id()}], "choices": [{"text": "Entendido.", "next": ""}]},
			"later": {"speaker": "Iria", "text": "Cuando estés listo, aquí estaré.", "choices": [{"text": "Volveré.", "next": ""}]},
			"return": {"speaker": "Iria", "text": "La linterna de Halven ya está contigo. Con esto, MQ00_01 queda completa.", "conditions": [{"type": "HasFlag", "value": "MQ00_01_ITEM_RECEIVED"}], "choices": [{"text": "Entregar la linterna.", "next": "complete", "effects": [{"type": "CompleteQuest", "value": "MQ00_01"}]}]},
			"complete": {"speaker": "Iria", "text": "Un día sencillo, pero importante. Gracias por cuidar de Liria.", "conditions": [{"type": "QuestCompleted", "value": "MQ00_01"}], "choices": [{"text": "Cerrar diálogo.", "next": ""}]}
		}
	}

func _current_class_id() -> String:
	var state: Node = Engine.get_main_loop().root.get_node_or_null("GameState")
	if state == null:
		return ""
	var data := state.get("state") as Dictionary
	return String(data.get("player", {}).get("class_id", ""))

func _halven_dialogue() -> Dictionary:
	return {
		"id": "DIALOGUE_HALVEN_MQ00_01",
		"start": "start",
		"nodes": {
			"start": {"speaker": "Halven", "text": "Iria me pidió que te entregara esta vieja linterna. Puede ser útil en el camino exterior.", "conditions": [{"type": "HasFlag", "value": "MQ00_01_STARTED"}, {"type": "NotFlag", "value": "MQ00_01_ITEM_RECEIVED"}], "choices": [{"text": "La llevaré.", "next": "given", "effects": [{"type": "GiveItem", "value": "ITEM_LANTERN", "amount": 1}, {"type": "SetFlag", "value": "MQ00_01_ITEM_RECEIVED"}, {"type": "AdvanceQuest", "value": "MQ00_01", "stage": 3}]}, {"text": "Déjame pensarlo.", "next": ""}]},
			"given": {"speaker": "Halven", "text": "Cuídala. Cuando termines, regresa con Iria en la plaza.", "choices": [{"text": "De acuerdo.", "next": ""}]},
			"quiet": {"speaker": "Halven", "text": "Iria te está esperando en la plaza. Yo vigilaré el edificio.", "choices": [{"text": "Hasta luego.", "next": ""}]}
		}
	}
