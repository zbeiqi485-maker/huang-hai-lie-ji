extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("FUNCTIONAL FAIL: " + message)
	quit(1)

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene cannot load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	var player = scene.get_node("Player")
	var enemy = scene.get_node("Beast")
	var ui = scene.get_node("UI")
	if player == null or enemy == null or ui == null:
		_fail("Required nodes missing")
		return

	var starting_hp: float = player.hp
	if not player.take_hit(20.0, 1):
		_fail("First hit was rejected")
		return
	if absf(float(player.hp) - (starting_hp - 20.0)) > 0.1:
		_fail("Health damage incorrect")
		return
	if player.take_hit(20.0, 1):
		_fail("Post-hit immunity did not protect player")
		return
	player.invulnerable_after_hit = 0.0
	player._set_state(7)
	player.timer = 0.16
	if not player.is_invulnerable():
		_fail("Dodge invincibility missing inside window")
		return
	player.timer = 0.30
	if player.is_invulnerable():
		_fail("Dodge invincibility did not end")
		return
	player._set_state(0)

	var stamina_before: float = player.sp
	if not player._spend(25.0):
		_fail("Stamina could not be spent")
		return
	if absf(float(player.sp) - stamina_before + 25.0) > 0.01:
		_fail("Stamina spending incorrect")
		return

	# Two separate screen touch IDs must keep independent held actions.
	var left_touch := InputEventScreenTouch.new()
	left_touch.index = 1
	left_touch.position = Vector2(68, 650)
	left_touch.pressed = true
	Input.parse_input_event(left_touch)
	var attack_touch := InputEventScreenTouch.new()
	attack_touch.index = 2
	attack_touch.position = Vector2(1200, 650)
	attack_touch.pressed = true
	Input.parse_input_event(attack_touch)
	await process_frame
	print("TOUCH DIAG size=", ui.size, " counts=", ui.counts, " fingers=", ui.fingers, " left=", Input.is_action_pressed("move_left"), " attack=", Input.is_action_pressed("attack_light"))
	if not Input.is_action_pressed("move_left") or not Input.is_action_pressed("attack_light"):
		_fail("Multi-touch movement and attack were not held independently")
		return
	left_touch.pressed = false
	attack_touch.pressed = false
	Input.parse_input_event(left_touch)
	Input.parse_input_event(attack_touch)
	await process_frame
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("attack_light"):
		_fail("Multi-touch release left a stuck action")
		return

	if not enemy.take_hit(200.0, 1) or float(enemy.hp) > 0.0:
		_fail("Enemy damage or death failed")
		return

	print("FUNCTIONAL PASS: health, immunity, dodge timing, stamina, multi-touch, enemy death")
	quit(0)
