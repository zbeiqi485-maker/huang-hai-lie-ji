extends Control

var fingers: Dictionary = {}
var counts: Dictionary = {}
var mouse_action := ""
var orientation_timer := 0.0
var portrait := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)

func _process(dt: float) -> void:
	orientation_timer -= dt
	if orientation_timer <= 0.0:
		orientation_timer = 0.35
		var window_size := DisplayServer.window_get_size()
		portrait = window_size.y > window_size.x
	queue_redraw()

func _buttons() -> Dictionary:
	var scale := minf(size.x / 1280.0, size.y / 720.0)
	var y := size.y - 116.0 * scale
	return {
		"move_left": Rect2(Vector2(25 * scale, y), Vector2(102, 92) * scale),
		"move_right": Rect2(Vector2(140 * scale, y), Vector2(102, 92) * scale),
		"jump": Rect2(Vector2(size.x - 460 * scale, y), Vector2(102, 92) * scale),
		"dodge": Rect2(Vector2(size.x - 346 * scale, y), Vector2(102, 92) * scale),
		"attack_heavy": Rect2(Vector2(size.x - 232 * scale, y), Vector2(102, 92) * scale),
		"attack_light": Rect2(Vector2(size.x - 118 * scale, y), Vector2(102, 92) * scale),
		"fullscreen": Rect2(Vector2(size.x - 252 * scale, 22 * scale), Vector2(98, 58) * scale),
		"restart": Rect2(Vector2(size.x - 138 * scale, 22 * scale), Vector2(98, 58) * scale)
	}

func _find_action(p: Vector2) -> String:
	var rects := _buttons()
	for action in rects:
		if (rects[action] as Rect2).has_point(p):
			return action
	return ""

func _press(action: String) -> void:
	if action.is_empty():
		return
	var count := int(counts.get(action, 0)) + 1
	counts[action] = count
	if count != 1:
		return
	if action == "fullscreen":
		get_parent().call("try_fullscreen")
	elif action == "restart":
		get_parent().call_deferred("restart_game")
	else:
		Input.action_press(StringName(action))

func _release(action: String) -> void:
	if action.is_empty():
		return
	var count := maxi(0, int(counts.get(action, 0)) - 1)
	counts[action] = count
	if count == 0 and action not in ["fullscreen", "restart"]:
		Input.action_release(StringName(action))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var action := _find_action(event.position)
			if not action.is_empty():
				fingers[event.index] = action
				_press(action)
				get_viewport().set_input_as_handled()
		elif fingers.has(event.index):
			_release(str(fingers[event.index]))
			fingers.erase(event.index)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var old := str(fingers[event.index])
		if old in ["move_left", "move_right"]:
			var next := _find_action(event.position)
			if next in ["move_left", "move_right"] and old != next:
				_release(old)
				fingers[event.index] = next
				_press(next)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_action = _find_action(event.position)
			if not mouse_action.is_empty():
				_press(mouse_action)
				get_viewport().set_input_as_handled()
		elif not mouse_action.is_empty():
			_release(mouse_action)
			mouse_action = ""
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var scale := minf(size.x / 1280.0, size.y / 720.0)
	var p := get_parent().get_node("Player")
	var b := get_parent().get_node("Beast")
	var font := ThemeDB.fallback_font
	var x := 26.0 * scale
	var y := 32.0 * scale
	_bar(Vector2(x, y), 266.0 * scale, 22.0 * scale, float(p.hp) / 100.0, Color("902f39"))
	_bar(Vector2(x, y + 29 * scale), 220 * scale, 14 * scale, float(p.sp) / 100.0, Color("607563"))
	draw_string(font, Vector2(x + 6 * scale, y + 17 * scale), "HP %d/100" % int(p.hp), HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(12, int(18 * scale)), Color("fff0dd"))
	draw_string(font, Vector2(x, y + 88 * scale), "TRAINING BEAST %d/110" % int(b.hp), HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(12, int(19 * scale)), Color("e0d2c1"))
	_bar(Vector2(x, y + 99 * scale), 220 * scale, 10 * scale, float(b.hp) / 110.0, Color("aa746b"))
	var message := "TRAINING GROUNDS / DEV-001"
	if int(p.state) == 9:
		message = "HUNTER FALLEN / RESET"
	elif int(b.state) == 6:
		message = "TRAINING BEAST DEFEATED / RESET"
	draw_string(font, Vector2(size.x * 0.5 - 230 * scale, 47 * scale), message, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(12, int(22 * scale)), Color("d6c8b5"))
	draw_string(font, Vector2(x, size.y - 144 * scale), "DEBUG SHAPES | NOT FINAL ART", HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(15 * scale)), Color("b1aaa3"))
	var labels := {"move_left":"LEFT","move_right":"RIGHT","jump":"JUMP","dodge":"DODGE","attack_heavy":"HEAVY","attack_light":"HIT","fullscreen":"FULL","restart":"RESET"}
	for action in _buttons():
		var r: Rect2 = _buttons()[action]
		var selected := int(counts.get(action, 0)) > 0
		draw_rect(r, Color(0.48, 0.34, 0.30, 0.88) if selected else Color(0.15, 0.17, 0.20, 0.85))
		draw_rect(r, Color("b7ac9c"), false, 2.0)
		draw_string(font, Vector2(r.position.x + 8 * scale, r.position.y + r.size.y * 0.59), str(labels[action]), HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(18 * scale)), Color("f1e6d8"))
	if portrait or size.y > size.x:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.07, 0.08, 0.94))
		draw_string(font, Vector2(size.x * 0.08, size.y * 0.48), "ROTATE PHONE TO LANDSCAPE", HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(16, int(size.x * 0.032)), Color("f0debc"))

func _bar(at: Vector2, w: float, h: float, ratio: float, tint: Color) -> void:
	draw_rect(Rect2(at, Vector2(w, h)), Color("0d0e11"))
	draw_rect(Rect2(at + Vector2(2, 2), Vector2(maxf(0, (w - 4) * clampf(ratio, 0, 1)), maxf(1, h - 4))), tint)
	draw_rect(Rect2(at, Vector2(w, h)), Color("a39889"), false, 2.0)
