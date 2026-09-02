extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload available")
	if state == null:
		quit(1)
		return
	state.call("new_game", "P1.3 Transition", "CLASS_WARRIOR")
	var before: Dictionary = state.call("to_serialized")
	var layer := Stage1TransitionLayer.new()
	root.add_child(layer)
	await process_frame
	var finished := [0]
	layer.transition_finished.connect(func() -> void: finished[0] += 1)
	layer.fade_to_black(0.08)
	await create_timer(0.2).timeout
	_check(layer.visible, "fade to black remains a valid overlay")
	_check(finished[0] == 1, "fade to black emits completion")
	_check(state.call("to_serialized") == before, "fade to black does not change GameState")
	layer.fade_from_black(0.08, "LIRIA")
	await create_timer(0.55).timeout
	_check(not layer.visible, "fade from black releases overlay")
	_check(finished[0] == 2, "fade from black emits completion")
	_check(state.call("to_serialized") == before, "fade from black does not change GameState")
	layer.queue_free()
	if failures.is_empty():
		print("P13_TRANSITION_CONTRACT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P13_TRANSITION_CONTRACT=FAIL")
	quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
