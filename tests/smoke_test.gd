extends SceneTree

func _initialize() -> void:
	var pack := load("res://scenes/main.tscn") as PackedScene
	if pack == null:
		push_error("SMOKE FAIL: scene missing")
		quit(1)
		return
	var scene := pack.instantiate()
	root.add_child.call_deferred(scene)
	call_deferred("_verify", scene)

func _verify(scene: Node) -> void:
	if scene.get_node_or_null("Player") == null or scene.get_node_or_null("Beast") == null or scene.get_node_or_null("UI") == null:
		push_error("SMOKE FAIL: critical nodes missing")
		quit(1)
		return
	if not scene.get_node("Player").has_method("take_hit") or not scene.get_node("Beast").has_method("take_hit"):
		push_error("SMOKE FAIL: damage APIs missing")
		quit(1)
		return
	print("SMOKE PASS: Godot main scene, actors, UI")
	quit(0)
