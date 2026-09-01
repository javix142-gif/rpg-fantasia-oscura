extends Control

func _ready() -> void:
	print("PROMPT_0_SMOKE=PASS")
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
