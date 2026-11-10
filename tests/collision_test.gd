extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("COLLISION FAIL: " + message)
	quit(1)

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("scene missing")
		return
	var world := packed.instantiate()
	root.add_child(world)
	var p = world.get_node("Player")
	var e = world.get_node("Beast")
	p.global_position = Vector2(450, 569)
	e.global_position = Vector2(530, 569)
	await physics_frame
	await physics_frame
	await physics_frame
	var sword: Area2D = p.get_node("Hitbox")
	sword.position = Vector2(60, -44)
	await physics_frame
	await physics_frame
	var registry := {}
	var oldhp: float = e.hp
	var hits: int = sword.strike(14.0, 1, registry)
	print("HITTEST sword overlaps=", sword.get_overlapping_areas().size(), " actualhits=", hits, " damage=", oldhp - float(e.hp))
	if hits != 1 or absf(oldhp - float(e.hp) - 14.0) > 0.01:
		_fail("sword did not hit enemy exactly once")
		return
	var hits_again: int = sword.strike(14.0, 1, registry)
	if hits_again != 0 or absf(oldhp - float(e.hp) - 14.0) > 0.01:
		_fail("same swing hit enemy twice")
		return
	var claw: Area2D = e.get_node("Hitbox")
	claw.position = Vector2(-51, -44)
	await physics_frame
	await physics_frame
	p.invulnerable_after_hit = 0.0
	p._set_state(7)
	p.timer = 0.15
	var player_hp: float = p.hp
	var rh := {}
	var dodge_hits: int = claw.strike(15.0, -1, rh)
	if dodge_hits != 0 or p.hp != player_hp:
		_fail("claw damaged player during dodge invulnerability")
		return
	p._set_state(0)
	var rh2 := {}
	var regular_hits: int = claw.strike(15.0, -1, rh2)
	print("HITTEST claw overlaps=", claw.get_overlapping_areas().size(), " hits=", regular_hits)
	if regular_hits != 1 or absf(player_hp - float(p.hp) - 15.0) > 0.01:
		_fail("claw did not hurt player outside dodge")
		return
	print("COLLISION PASS: sword hitbox, no duplicate damage, claw, dodge i-frames")
	quit(0)
