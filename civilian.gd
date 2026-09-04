extends CharacterBody3D
class_name StreetCivilian

enum State { CALM, FLEEING, DOWN }

var game: Node
var state := State.CALM
var active := true
var flee_timer := 0.0
var tint := Color("#5bd6c0")

func setup(owner_game: Node, start: Vector3, color: Color) -> void:
	game = owner_game
	global_position = start
	tint = color
	add_to_group("civilian")
	_build_civilian()

func _build_civilian() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.5
	collider.shape = capsule
	collider.position.y = 0.75
	add_child(collider)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = 1.05
	body.mesh = body_mesh
	body.position.y = 0.72
	body.material_override = _material(tint)
	add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27
	head_mesh.height = 0.54
	head.mesh = head_mesh
	head.position.y = 1.48
	head.material_override = _material(Color("#ffc58a"))
	add_child(head)
	var marker := MeshInstance3D.new()
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(0.48, 0.06, 0.08)
	marker.mesh = marker_mesh
	marker.position = Vector3(0, 1.9, 0)
	marker.material_override = _material(Color("#ffd447"))
	add_child(marker)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat

func flee_from(source: Vector3) -> void:
	if not active:
		return
	state = State.FLEEING
	flee_timer = 5.0
	var away := global_position - source
	if away.length_squared() > 0.01:
		look_at(global_position + Vector3(away.x, 0, away.z), Vector3.UP)

func _physics_process(delta: float) -> void:
	if state != State.FLEEING:
		return
	flee_timer -= delta
	var away: Vector3 = global_position - game.player.global_position if game and is_instance_valid(game.player) else -transform.basis.z
	away.y = 0
	if away.length_squared() < 0.01:
		away = Vector3(1, 0, 0)
	away = away.normalized()
	velocity = away * 4.2
	move_and_slide()
	if flee_timer <= 0.0 or global_position.length() > 28.0:
		state = State.CALM
		velocity = Vector3.ZERO

func hit() -> void:
	if not active:
		return
	active = false
	state = State.DOWN
	visible = false
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
	if game and is_instance_valid(game):
		game.register_civilian_kill(self)

func is_fleeing() -> bool:
	return state == State.FLEEING

func reset_state(start: Vector3) -> void:
	global_position = start
	velocity = Vector3.ZERO
	state = State.CALM
	active = true
	visible = true
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
