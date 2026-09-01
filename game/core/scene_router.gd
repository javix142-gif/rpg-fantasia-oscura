extends Node

signal route_changed(route: String)
var current_route: String = "menu"

func go_to(route: String) -> void:
	current_route = route
	route_changed.emit(route)
