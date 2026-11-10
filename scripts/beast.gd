extends CharacterBody2D

signal health_changed(value: float, maximum: float)
signal defeated

enum State { IDLE, CHASE, WINDUP, STRIKE, RECOVERY, HURT, DEAD }

const MAX_HP := 110.0
@onready var hitbox: Area2D = $Hitbox
var player: CharacterBody2D
var hp := MAX_HP
var state := State.IDLE
var timer := 0.0
var facing := -1
var cooldown := 0.0
var attack_registry: Dictionary = {}

func _ready() -> void:
	player = get_parent().get_node("Player") as CharacterBody2D
	health_changed.emit(hp, MAX_HP)

func _set_state(s: int) -> void:
	state = s
	timer = 0.0
	if s == State.STRIKE:
		attack_registry.clear()

func _physics_process(dt: float) -> void:
	timer += dt
	cooldown = maxf(0.0, cooldown - dt)
	if is_on_floor():
		velocity.y = maxf(0.0, velocity.y)
	else:
		velocity.y += 1200.0 * dt
	if state == State.DEAD:
		velocity.x = 0.0
		move_and_slide()
		queue_redraw()
		return
	var diff := 9999.0
	if is_instance_valid(player) and player.get("state") != 9:
		diff = player.global_position.x - global_position.x
	var distance := absf(diff)

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * dt)
			if distance <= 520.0:
				_set_state(State.CHASE)
		State.CHASE:
			if distance > 700.0:
				_set_state(State.IDLE)
			elif distance <= 95.0 and cooldown <= 0.0 and is_on_floor():
				velocity.x = 0.0
				_set_state(State.WINDUP)
			else:
				facing = 1 if diff > 0.0 else -1
				velocity.x = facing * 110.0
		State.WINDUP:
			velocity.x = 0.0
			if timer >= 0.46:
				_set_state(State.STRIKE)
		State.STRIKE:
			velocity.x = 0.0
			if timer >= 0.10 and timer <= 0.26:
				hitbox.position = Vector2(51 * facing, -44)
				hitbox.strike(15.0, facing, attack_registry)
			if timer >= 0.38:
				cooldown = 1.05
				_set_state(State.RECOVERY)
		State.RECOVERY:
			velocity.x = 0.0
			if timer >= 0.48:
				_set_state(State.CHASE)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 350.0 * dt)
			if timer >= 0.37:
				_set_state(State.CHASE)
	move_and_slide()
	queue_redraw()

func take_hit(amount: float, direction: int) -> bool:
	if state == State.DEAD:
		return false
	hp = maxf(0.0, hp - amount)
	health_changed.emit(hp, MAX_HP)
	if hp <= 0.0:
		_set_state(State.DEAD)
		defeated.emit()
	else:
		_set_state(State.HURT)
		velocity.x = direction * 100.0
	return true

# DEBUG ONLY, intentionally not production pixel art.
func _draw() -> void:
	var tint := Color("94716d")
	if state == State.WINDUP:
		tint = Color("d29378")
	elif state == State.STRIKE:
		tint = Color("d86657")
	elif state == State.HURT:
		tint = Color("e5c5a2")
	elif state == State.DEAD:
		tint = Color("46464c")
	draw_rect(Rect2(-34, -65, 68, 55), tint)
	draw_rect(Rect2(-22, -87, 44, 23), Color("aea29b"))
	draw_rect(Rect2(-28, -16, 14, 16), Color("49413f"))
	draw_rect(Rect2(14, -16, 14, 16), Color("49413f"))
	draw_line(Vector2(15 * facing, -75), Vector2(45 * facing, -91), Color("b1a998"), 8.0)
	if state == State.STRIKE and timer > 0.10 and timer < 0.26:
		draw_line(Vector2(12 * facing, -48), Vector2(95 * facing, -51), Color("d8a28b"), 9.0)
