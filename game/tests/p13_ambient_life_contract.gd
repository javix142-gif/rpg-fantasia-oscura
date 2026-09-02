extends SceneTree

const WORLD_SCRIPT = preload("res://world/village_world.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload available")
	if state == null:
		quit(1)
		return
	state.call("new_game", "P1.3 Ambient", "CLASS_WARRIOR")
	var host := Node2D.new()
	root.add_child(host)
	var world = WORLD_SCRIPT.new()
	host.add_child(world)
	await process_frame
	var ambient_fx := world.get_node_or_null("AmbientFX/AmbientFX") as LiriaAmbientFx
	var villager := world.get_npc("NPC_VILLAGER_A")
	_check(ambient_fx != null, "ambient FX node exists in the dedicated layer")
	_check(ambient_fx != null and ambient_fx.is_processing(), "ambient FX is processing")
	_check(villager != null, "ambient villager exists")
	if villager != null:
		var initial_position := villager.global_position
		var initial_state := villager.ambient_state()
		var moved := false
		var state_changed := false
		for _frame in range(300):
			await physics_frame
			if villager.global_position.distance_to(initial_position) > 0.5:
				moved = true
			if villager.ambient_state() != initial_state:
				state_changed = true
		_check(state_changed, "ambient villager leaves the initial idle state")
		_check(moved, "ambient villager performs a bounded short walk")
	if ambient_fx != null:
		_check(float(ambient_fx.get("_clock")) > 0.0, "ambient FX clock advances")
	host.queue_free()
	if failures.is_empty():
		print("P13_AMBIENT_LIFE_CONTRACT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P13_AMBIENT_LIFE_CONTRACT=FAIL")
	quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
