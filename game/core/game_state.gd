extends Node

signal state_changed

const SAVE_VERSION: int = 1
const GAME_VERSION: String = "0.1.0-p1"
const CLASS_IDS: Array[String] = ["CLASS_WARRIOR", "CLASS_SWORDSMAN", "CLASS_ARCHER", "CLASS_SORCERER", "CLASS_CLERIC"]
const CLASS_NAMES: Dictionary = {
	"CLASS_WARRIOR": "Guerrero",
	"CLASS_SWORDSMAN": "Espadachín",
	"CLASS_ARCHER": "Arquero",
	"CLASS_SORCERER": "Hechicero",
	"CLASS_CLERIC": "Clérigo"
}
const VALID_ITEM_IDS: Array[String] = ["ITEM_LANTERN", "ITEM_LIRIA_TOKEN"]

var state: Dictionary = {}

func _ready() -> void:
	if state.is_empty():
		_reset_empty()

func _reset_empty() -> void:
	state = {
		"save_version": SAVE_VERSION,
		"game_version": GAME_VERSION,
		"player": {"player_name": "", "class_id": "", "current_map": "REGION_LIRIA", "position": {"x": 480.0, "y": 360.0}, "level": 1, "hp": 100, "mp": 40, "tutorial_flags": {}},
		"party": {"members": []},
		"world": {"region_id": "REGION_LIRIA", "state": "NORMAL", "flags": {"LIRIA": "NORMAL"}},
		"quests": {"MQ00_01": {"status": "NOT_STARTED", "stage": 0, "rewarded": false}},
		"factions": {},
		"economy": {"gold": 25},
		"corruption": {"value": 0},
		"inventory": {"items": {}}
	}

func new_game(player_name: String, class_id: String) -> bool:
	var clean_name := player_name.strip_edges()
	if clean_name.is_empty() or not CLASS_IDS.has(class_id):
		return false
	_reset_empty()
	state["player"]["player_name"] = clean_name
	state["player"]["class_id"] = class_id
	state["player"]["position"] = {"x": 480.0, "y": 360.0}
	state_changed.emit()
	return true

func has_profile() -> bool:
	return not String(state.get("player", {}).get("player_name", "")).is_empty()

func set_position(position: Vector2) -> void:
	if state.is_empty():
		return
	state["player"]["position"] = {"x": position.x, "y": position.y}

func get_position() -> Vector2:
	var pos: Dictionary = state.get("player", {}).get("position", {"x": 480.0, "y": 360.0})
	return Vector2(float(pos.get("x", 480.0)), float(pos.get("y", 360.0)))

func set_flag(flag_id: String, value: Variant = true) -> void:
	state["world"]["flags"][flag_id] = value
	state_changed.emit()

func has_flag(flag_id: String) -> bool:
	return state.get("world", {}).get("flags", {}).has(flag_id)

func get_flag(flag_id: String, fallback: Variant = null) -> Variant:
	return state.get("world", {}).get("flags", {}).get(flag_id, fallback)

func start_quest(quest_id: String) -> bool:
	if not state["quests"].has(quest_id):
		state["quests"][quest_id] = {"status": "NOT_STARTED", "stage": 0, "rewarded": false}
	var quest: Dictionary = state["quests"][quest_id]
	if String(quest.get("status", "NOT_STARTED")) == "COMPLETE":
		return false
	quest["status"] = "ACTIVE"
	quest["stage"] = maxi(1, int(quest.get("stage", 0)))
	state["quests"][quest_id] = quest
	set_flag(quest_id + "_STARTED", true)
	state_changed.emit()
	if get_node_or_null("/root/EventBus") != null:
		get_node("/root/EventBus").quest_updated.emit(quest_id, "ACTIVE")
	return true

func advance_quest(quest_id: String, stage: int) -> bool:
	if not state["quests"].has(quest_id):
		return false
	var quest: Dictionary = state["quests"][quest_id]
	if String(quest.get("status", "")) != "ACTIVE":
		return false
	quest["stage"] = maxi(int(quest.get("stage", 0)), stage)
	state["quests"][quest_id] = quest
	state_changed.emit()
	return true

func complete_quest(quest_id: String) -> bool:
	if not state["quests"].has(quest_id):
		return false
	var quest: Dictionary = state["quests"][quest_id]
	if String(quest.get("status", "")) == "COMPLETE":
		return false
	quest["status"] = "COMPLETE"
	quest["stage"] = 4
	state["quests"][quest_id] = quest
	set_flag("MQ00_01_COMPLETE", true)
	state_changed.emit()
	if get_node_or_null("/root/EventBus") != null:
		get_node("/root/EventBus").quest_updated.emit(quest_id, "COMPLETE")
	return true

func quest_status(quest_id: String) -> String:
	return String(state.get("quests", {}).get(quest_id, {}).get("status", "NOT_STARTED"))

func quest_stage(quest_id: String) -> int:
	return int(state.get("quests", {}).get(quest_id, {}).get("stage", 0))

func add_item(item_id: String, amount: int = 1) -> bool:
	if not VALID_ITEM_IDS.has(item_id) or amount <= 0:
		return false
	var items: Dictionary = state["inventory"]["items"]
	items[item_id] = int(items.get(item_id, 0)) + amount
	state_changed.emit()
	if get_node_or_null("/root/EventBus") != null:
		get_node("/root/EventBus").inventory_changed.emit()
	return true

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	var items: Dictionary = state["inventory"]["items"]
	items[item_id] = int(items[item_id]) - amount
	if int(items[item_id]) <= 0:
		items.erase(item_id)
	state_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return VALID_ITEM_IDS.has(item_id) and amount > 0 and int(state.get("inventory", {}).get("items", {}).get(item_id, 0)) >= amount

func item_quantity(item_id: String) -> int:
	return int(state.get("inventory", {}).get("items", {}).get(item_id, 0))

func condition_passes(condition: Dictionary) -> bool:
	var kind := String(condition.get("type", ""))
	match kind:
		"HasFlag": return has_flag(String(condition.get("value", "")))
		"NotFlag": return not has_flag(String(condition.get("value", "")))
		"HasItem": return has_item(String(condition.get("value", "")), int(condition.get("amount", 1)))
		"QuestCompleted": return quest_status(String(condition.get("value", ""))) == "COMPLETE"
		"ClassEquals": return String(state.get("player", {}).get("class_id", "")) == String(condition.get("value", ""))
		_: return false

func apply_effect(effect: Dictionary) -> bool:
	var kind := String(effect.get("type", ""))
	match kind:
		"SetFlag": set_flag(String(effect.get("value", "")), effect.get("data", true))
		"GiveItem": return add_item(String(effect.get("value", "")), int(effect.get("amount", 1)))
		"RemoveItem": return remove_item(String(effect.get("value", "")), int(effect.get("amount", 1)))
		"StartQuest": return start_quest(String(effect.get("value", "")))
		"CompleteQuest": return complete_quest(String(effect.get("value", "")))
		"AdvanceQuest": return advance_quest(String(effect.get("value", "")), int(effect.get("stage", 1)))
		_: return false
	return true

func to_serialized() -> Dictionary:
	return state.duplicate(true)

func load_serialized(payload: Variant) -> bool:
	if not validate_payload(payload):
		return false
	state = (payload as Dictionary).duplicate(true)
	state_changed.emit()
	return true

func validate_payload(payload: Variant) -> bool:
	if not payload is Dictionary:
		return false
	var data: Dictionary = payload
	if int(data.get("save_version", -1)) != SAVE_VERSION:
		return false
	for section in ["player", "party", "world", "quests", "factions", "economy", "corruption", "inventory"]:
		if not data.has(section) or not data[section] is Dictionary:
			return false
	var player: Dictionary = data["player"]
	return not String(player.get("player_name", "")).is_empty() and CLASS_IDS.has(String(player.get("class_id", ""))) and String(data["world"].get("state", "")) == "NORMAL"
