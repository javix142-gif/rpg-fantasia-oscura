class_name CSInventorySystem
extends RefCounted

static func can_pay(host: Node, cost: Dictionary) -> bool:
	for k_variant in cost.keys():
		var k := String(k_variant)
		if int(host.inventory.get(k, 0)) < int(cost[k]):
			return false
	return true

static func pay(host: Node, cost: Dictionary) -> void:
	for k_variant in cost.keys():
		var k := String(k_variant)
		host.inventory[k] = int(host.inventory.get(k, 0)) - int(cost[k])
	host._mark_dirty("inventory_pay")

static func craft_item(host: Node, kind: String) -> void:
	if not host.CRAFT_RECIPES.has(kind):
		return
	var recipe: Dictionary = host.CRAFT_RECIPES[kind]
	if bool(recipe.get("unique", false)) and bool(host.owned_tools.get(kind, false)):
		host._spawn_floater(host.CENTER + Vector2(0, 82), "YA POSEES ESTE OBJETO", Color("dfb36d"))
		host._play_sound("error")
		return
	var cost: Dictionary = recipe["cost"]
	if not can_pay(host, cost):
		host._spawn_floater(host.CENTER + Vector2(0, 82), "FALTAN MATERIALES", Color("ed7d78"))
		host._play_sound("error")
		return
	pay(host, cost)
	if kind == "hacha" or kind == "pico":
		host.owned_tools[kind] = true
		host.equipped_tool = kind
		if kind == "hacha":
			host.tutorial_crafted_axe = true
	else:
		host.inventory["venda"] = int(host.inventory["venda"]) + 1
	host._mark_dirty("craft")
	host._set_major("Fabricado: %s" % String(recipe["name"]), 1.4)
	host._play_sound("craft")

static func toggle_tool(host: Node, kind: String) -> void:
	if not bool(host.owned_tools.get(kind, false)):
		return
	host.equipped_tool = "" if host.equipped_tool == kind else kind
	host._mark_dirty("equipment")
	host._spawn_floater(host.CENTER + Vector2(0, 82), "Equipado: %s" % ("manos" if host.equipped_tool == "" else host.equipped_tool), Color("b9d6a8"))
	host._play_sound("ui")

static func eat(host: Node) -> void:
	if int(host.inventory["comida"]) <= 0:
		host._spawn_floater(host.CENTER + Vector2(0, 82), "Sin comida", Color("ed7d78"))
		return
	if host.hunger >= 99.0:
		host._spawn_floater(host.CENTER + Vector2(0, 82), "No tienes hambre", Color("d6c58d"))
		return
	host.inventory["comida"] -= 1
	host.hunger = minf(100.0, host.hunger + 30.0)
	host._mark_dirty("eat")
	host._spawn_floater(host.CENTER + Vector2(0, 82), "+30 hambre", Color("e6bb67"))
	host._play_sound("collect")

static func use_bandage(host: Node) -> void:
	if int(host.inventory["venda"]) <= 0:
		host._spawn_floater(host.CENTER + Vector2(0, 82), "Sin vendajes", Color("ed7d78"))
		return
	if host.hp >= 99.0:
		host._spawn_floater(host.CENTER + Vector2(0, 82), "PV completos", Color("d6c58d"))
		return
	host.inventory["venda"] -= 1
	host.hp = minf(100.0, host.hp + 28.0)
	host._mark_dirty("bandage")
	host._spawn_floater(host.CENTER + Vector2(0, 82), "+28 PV", Color("8ddd8d"))
	host._play_sound("collect")

static func chest_transfer(host: Node, item: String, to_chest: bool, all_items: bool = false) -> void:
	if host.chest_index < 0 or host.chest_index >= host.buildings.size():
		return
	var chest: Dictionary = host.buildings[host.chest_index]
	var store: Dictionary = chest["chest"]
	if to_chest:
		var have := int(host.inventory.get(item, 0))
		if have <= 0:
			return
		var amount := have if all_items else 1
		host.inventory[item] = have - amount
		store[item] = int(store.get(item, 0)) + amount
	else:
		var have := int(store.get(item, 0))
		if have <= 0:
			return
		var amount := have if all_items else 1
		store[item] = have - amount
		host.inventory[item] = int(host.inventory.get(item, 0)) + amount
	host._mark_dirty("chest_transfer")
	host._play_sound("ui")

static func chest_transfer_all(host: Node, to_chest: bool) -> void:
	for item_variant in host.MATERIAL_ORDER:
		chest_transfer(host, String(item_variant), to_chest, true)
