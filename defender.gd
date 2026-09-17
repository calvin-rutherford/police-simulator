extends CharacterBody3D
class_name FrontierActor

var game: Node3D
var kind := "bandit"
var friendly := false
var health := 65
var max_health := 65
var dead := false
var model: Node3D
var health_label: Label3D
var cooldown := 0.0
var path_timer := 0.0
var path := PackedVector2Array()
var path_index := 1
var home := Vector3.ZERO
var hit_flash := 0.0
var age := 0.0

func setup(owner_game: Node3D, archetype: String, spawn: Vector3) -> void:
	game = owner_game
	kind = archetype
	friendly = kind in ["deputy", "turret"]
	position = spawn
	home = spawn
	collision_layer = 8 if friendly else 4
	collision_mask = 1 | 16
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 2.0 if kind != "monster" else 2.8
	shape.position.y = capsule.height / 2
	shape.shape = capsule
	add_child(shape)
	if friendly:
		max_health = 180 if kind == "turret" else 110
	else:
		max_health = FrontierRules.ENEMIES[kind].health
	health = max_health
	if kind == "turret":
		model = Node3D.new()
		add_child(model)
		FrontierVisuals.cylinder(model, Vector3(0, 0.5, 0), 0.55, 1, Color("#699fa8"))
		FrontierVisuals.box(model, Vector3(0, 1.2, 0), Vector3(0.85, 0.55, 0.8), Color("#f2cc79"))
		FrontierVisuals.cylinder(model, Vector3(0, 1.3, -0.6), 0.15, 1.1, Color("#778697")).rotation.x = PI / 2
	else:
		model = FrontierVisuals.person(self, Color("#78aeb8") if friendly else Color(FrontierRules.ENEMIES[kind].color), kind)
	health_label = FrontierVisuals.label(self, "", Vector3(0, 3.3 if kind == "monster" else 2.7, 0), Color("#bcebd2") if friendly else Color("#ffd0bf"), 16)
	_update_label()
	cooldown = randf_range(0.3, 1.3)

func _update_label() -> void:
	var title: String = kind.capitalize() if friendly else FrontierRules.ENEMIES[kind].name
	health_label.text = "%s\n%d / %d" % [title, health, max_health]

func aim_point() -> Vector3:
	return global_position + Vector3(0, 1.25, 0)

func take_damage(damage: int) -> void:
	if dead:
		return
	health = maxi(0, health - damage)
	hit_flash = 0.15
	game.damage_number(aim_point(), damage, friendly)
	_update_label()
	if health == 0:
		dead = true
		collision_layer = 0
		health_label.text = "Repairing at dawn" if friendly else "★"
		game.actor_defeated(self)
		var tween := create_tween()
		tween.tween_property(model, "scale", Vector3.ONE * 0.05, 0.25)
		if not friendly:
			tween.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(game) or not game.is_playing():
		return
	age += delta
	hit_flash = maxf(0, hit_flash - delta)
	model.position.y = 0.1 if hit_flash > 0 else 0.0
	if game.phase != "night":
		return
	cooldown -= delta
	path_timer -= delta
	var target: Node3D = game.pick_target(self)
	if target == null:
		return
	var destination: Vector3 = target.global_position
	var distance := Vector2(global_position.x - destination.x, global_position.z - destination.z).length()
	var reach: float = (30.0 if kind == "turret" else 22.0) if friendly else float(FrontierRules.ENEMIES[kind].range)
	var target_point: Vector3 = game.aim_point(target)
	var can_attack: bool = distance <= reach and game.clear_shot(aim_point(), target_point, self, target)
	if can_attack:
		_face(destination)
		if cooldown <= 0:
			cooldown = (0.65 if kind == "turret" else 0.95) if friendly else float(FrontierRules.ENEMIES[kind].delay)
			var damage: int = (22 if kind == "turret" else 19) if friendly else int(FrontierRules.ENEMIES[kind].damage)
			if kind in ["bandit", "turret", "deputy"]:
				game.tracer(aim_point(), target_point, Color("#9fe1d6") if friendly else Color("#ffa38e"))
			game.damage_target(target, damage)
		velocity.x = 0
		velocity.z = 0
	elif kind != "turret":
		if path_timer <= 0:
			path = game.town.route(global_position, destination)
			path_index = 1 if path.size() > 1 else 0
			path_timer = 0.7 + randf() * 0.2
		var waypoint := destination
		if path_index < path.size():
			waypoint = Vector3(path[path_index].x, global_position.y, path[path_index].y)
			if global_position.distance_to(waypoint) < 0.65:
				path_index += 1
		var direction := (waypoint - global_position) * Vector3(1, 0, 1)
		var speed: float = 3.5 if friendly else float(FrontierRules.ENEMIES[kind].speed)
		velocity.x = direction.normalized().x * speed
		velocity.z = direction.normalized().z * speed
		_face(waypoint)
		model.rotation.z = sin(age * 9) * 0.045
	if kind != "turret":
		velocity.y -= 20 * delta
		move_and_slide()

func _face(target: Vector3) -> void:
	var flat := Vector3(target.x, global_position.y, target.z)
	if global_position.distance_squared_to(flat) > 0.01:
		look_at(flat, Vector3.UP)
