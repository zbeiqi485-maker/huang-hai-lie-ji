extends CharacterBody2D

signal health_changed(value: float, maximum: float)
signal stamina_changed(value: float, maximum: float)
signal died

enum State { IDLE, RUN, AIR, LIGHT_1, LIGHT_2, LIGHT_3, HEAVY, DODGE, HURT, DEAD }

const SPEED := 260.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1200.0
const MAX_HP := 100.0
const MAX_SP := 100.0
const LIGHT_TIMES := [0.38, 0.44, 0.58]
const LIGHT_DAMAGE := [14.0, 17.0, 22.0]
const LIGHT_COST := 12.0
const HEAVY_COST := 30.0
const DODGE_COST := 25.0

@onready var hitbox: Area2D = $Hitbox

var hp := MAX_HP
var sp := MAX_SP
var facing := 1
var state := State.IDLE
var timer := 0.0
var regen_delay := 0.0
var invulnerable_after_hit := 0.0
var coyote := 0.0
var buffered_jump := 0.0
var queued_combo := false
var swing_registry: Dictionary = {}
var attack_visible := false

func _ready() -> void:
	health_changed.emit(hp, MAX_HP)
	stamina_changed.emit(sp, MAX_SP)

func _set_state(next_state: int) -> void:
	state = next_state
	timer = 0.0
	if state in [State.LIGHT_1, State.LIGHT_2, State.LIGHT_3, State.HEAVY]:
		swing_registry.clear()
		queued_combo = false

func _spend(amount: float) -> bool:
	if sp < amount:
		return false
	sp -= amount
	regen_delay = 0.65
	stamina_changed.emit(sp, MAX_SP)
	return true

func _free_state() -> bool:
	return state in [State.IDLE, State.RUN, State.AIR]

func _physics_process(dt: float) -> void:
	timer += dt
	regen_delay = maxf(0.0, regen_delay - dt)
	invulnerable_after_hit = maxf(0.0, invulnerable_after_hit - dt)
	if regen_delay <= 0.0 and sp < MAX_SP and state != State.DEAD:
		sp = minf(MAX_SP, sp + 25.0 * dt)
		stamina_changed.emit(sp, MAX_SP)

	if state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * dt)
		if not is_on_floor():
			velocity.y += GRAVITY * dt
		move_and_slide()
		queue_redraw()
		return

	if is_on_floor():
		coyote = 0.10
	else:
		coyote = maxf(0.0, coyote - dt)
	if Input.is_action_just_pressed("jump"):
		buffered_jump = 0.12
	else:
		buffered_jump = maxf(0.0, buffered_jump - dt)

	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.1 and _free_state():
		facing = 1 if axis > 0.0 else -1

	if Input.is_action_just_pressed("attack_light"):
		if state in [State.LIGHT_1, State.LIGHT_2]:
			var index := state - State.LIGHT_1
			var duration: float = LIGHT_TIMES[index]
			if timer >= duration * 0.4 and timer <= duration * 0.96:
				queued_combo = true
		elif _free_state() and is_on_floor() and _spend(LIGHT_COST):
			_set_state(State.LIGHT_1)

	if Input.is_action_just_pressed("attack_heavy") and _free_state() and is_on_floor() and _spend(HEAVY_COST):
		_set_state(State.HEAVY)

	if Input.is_action_just_pressed("dodge") and _free_state() and is_on_floor() and _spend(DODGE_COST):
		if absf(axis) > 0.1:
			facing = 1 if axis > 0.0 else -1
		_set_state(State.DODGE)

	if state in [State.LIGHT_1, State.LIGHT_2, State.LIGHT_3]:
		var i := state - State.LIGHT_1
		if timer >= LIGHT_TIMES[i]:
			if queued_combo and i < 2 and _spend(LIGHT_COST):
				_set_state(State.LIGHT_2 if i == 0 else State.LIGHT_3)
			else:
				_set_state(State.IDLE)
	elif state == State.HEAVY and timer >= 0.76:
		_set_state(State.IDLE)
	elif state == State.DODGE and timer >= 0.42:
		_set_state(State.IDLE)
	elif state == State.HURT and timer >= 0.45:
		_set_state(State.IDLE)

	if not is_on_floor():
		velocity.y += GRAVITY * dt
	else:
		velocity.y = maxf(0.0, velocity.y)

	if _free_state():
		velocity.x = axis * SPEED
		if buffered_jump > 0.0 and coyote > 0.0:
			velocity.y = JUMP_VELOCITY
			buffered_jump = 0.0
			coyote = 0.0
			_set_state(State.AIR)
	elif state == State.DODGE:
		velocity.x = facing * (140.0 / 0.42)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1050.0 * dt)
	move_and_slide()
	global_position.x = clampf(global_position.x, 35.0, 1245.0)

	if _free_state():
		if not is_on_floor():
			if state != State.AIR:
				_set_state(State.AIR)
		elif absf(axis) > 0.1:
			if state != State.RUN:
				_set_state(State.RUN)
		elif state != State.IDLE:
			_set_state(State.IDLE)

	hitbox.position = Vector2(60.0 * facing, -44.0)
	attack_visible = false
	if state in [State.LIGHT_1, State.LIGHT_2, State.LIGHT_3]:
		var idx := state - State.LIGHT_1
		var duration: float = LIGHT_TIMES[idx]
		if timer >= duration * 0.22 and timer <= duration * 0.55:
			attack_visible = true
			hitbox.strike(LIGHT_DAMAGE[idx], facing, swing_registry)
	elif state == State.HEAVY and timer >= 0.30 and timer <= 0.46:
		attack_visible = true
		hitbox.strike(32.0, facing, swing_registry)
	queue_redraw()

func is_invulnerable() -> bool:
	return invulnerable_after_hit > 0.0 or (state == State.DODGE and timer >= 0.08 and timer <= 0.28)

func take_hit(amount: float, hit_direction: int) -> bool:
	if state == State.DEAD or is_invulnerable():
		return false
	hp = maxf(0.0, hp - amount)
	health_changed.emit(hp, MAX_HP)
	if hp <= 0.0:
		_set_state(State.DEAD)
		died.emit()
	else:
		_set_state(State.HURT)
		invulnerable_after_hit = 0.75
		velocity.x = float(hit_direction) * 180.0
	return true

# DEBUG ONLY: never approve this procedural silhouette as formal game art.
func _draw() -> void:
	var body := Color("676d77")
	if state == State.HURT:
		body = Color("edb19b")
	elif is_invulnerable():
		body = Color("bcd4d7")
	elif state == State.DEAD:
		body = Color("373942")
	var step := sin(float(Time.get_ticks_msec()) * 0.017) * 5.0 if state == State.RUN else 0.0
	draw_rect(Rect2(-15, -68, 30, 48), body)
	draw_rect(Rect2(-13, -90, 26, 22), Color("c2b9aa"))
	draw_rect(Rect2(-14, -22 + step, 11, 21), Color("444b51"))
	draw_rect(Rect2(3, -22 - step, 11, 21), Color("444b51"))
	draw_line(Vector2(12 * facing, -65), Vector2(32 * facing, -40), Color("b5aaa0"), 7.0)
	if attack_visible:
		draw_line(Vector2(18 * facing, -41), Vector2(110 * facing, -64), Color("f5d4a5"), 11.0)
	elif state in [State.LIGHT_1, State.LIGHT_2, State.LIGHT_3, State.HEAVY]:
		draw_line(Vector2(20 * facing, -42), Vector2(62 * facing, -92), Color("aaa08f"), 9.0)
