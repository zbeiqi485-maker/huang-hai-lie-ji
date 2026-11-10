extends Area2D

@export var team := 1

func strike(amount: float, direction: int, registry: Dictionary) -> int:
	var count := 0
	for area in get_overlapping_areas():
		if area.name != "Hurtbox":
			continue
		var victim := area.get_parent()
		if not victim.has_method("take_hit"):
			continue
		if victim == get_parent():
			continue
		var id := victim.get_instance_id()
		if registry.has(id):
			continue
		registry[id] = true
		if victim.take_hit(amount, direction):
			count += 1
	return count
