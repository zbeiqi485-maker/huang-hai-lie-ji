extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var beast: CharacterBody2D = $Beast
@onready var ui: Control = $UI

func _ready() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"attack_light": [KEY_J],
		"attack_heavy": [KEY_U],
		"dodge": [KEY_K, KEY_SHIFT],
		"restart": [KEY_R],
		"fullscreen": [KEY_F]
	}
	for action in bindings:
		var name := StringName(action)
		if not InputMap.has_action(name):
			InputMap.add_action(name)
		for key in bindings[action]:
			var e := InputEventKey.new()
			e.physical_keycode = key
			if not InputMap.action_has_event(name, e):
				InputMap.action_add_event(name, e)

func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("restart"):
		restart_game()
	if Input.is_action_just_pressed("fullscreen"):
		try_fullscreen()

func restart_game() -> void:
	get_tree().reload_current_scene()

func try_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){var e=document.documentElement;var p=document.fullscreenElement?Promise.resolve():e.requestFullscreen();Promise.resolve(p).then(function(){if(screen.orientation&&screen.orientation.lock){screen.orientation.lock('landscape').catch(function(){});}}).catch(function(){});})();")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# DEBUG ENVIRONMENT: temporary geometry, not production art.
func _draw() -> void:
	draw_rect(Rect2(-50, -40, 1380, 800), Color("17191c"))
	draw_rect(Rect2(0, 80, 1280, 490), Color("282c32"))
	for i in range(8):
		var x := float(i) * 190.0
		draw_rect(Rect2(x - 20, 310 + (i % 3) * 20, 96, 260), Color("34383d"))
	draw_rect(Rect2(0, 570, 1280, 150), Color("554e47"))
	draw_line(Vector2(0, 568), Vector2(1280, 568), Color("9d8b78"), 4.0)
	for i in range(22):
		var x := float(i) * 60.0
		draw_line(Vector2(x, 580 + (i % 3) * 5), Vector2(x + 34, 580 + (i % 3) * 5), Color("665b50"), 3.0)
