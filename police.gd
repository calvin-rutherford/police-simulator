extends CharacterBody3D
class_name StreetPolice

var game: Node
var active := false
var speed := 3.3

func setup(owner_game: Node, start: Vector3) -> void:
	game = owner_game
	global_position = start
	add_to_group("police")
	_build_police()

func _build_police() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.4
	body_mesh.height = 1.2
	body.mesh = body_mesh
	body.position.y = 0.78
	body.material_override = _material(Color("#4265d6"))
	add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head.mesh = head_mesh
	head.position.y = 1.58
	head.material_override = _material(Color("#ffc58a"))
	add_child(head)
	var badge := MeshInstance3D.new()
	var badge_mesh := BoxMesh.new()
	badge_mesh.size = Vector3(0.18, 0.18, 0.04)
	badge.mesh = badge_mesh
	badge.position = Vector3(0, 1.05, -0.38)
	badge.material_override = _material(Color("#ffd447"))
	add_child(badge)
	var siren := OmniLight3D.new()
	siren.light_color = Color("#f45b69")
	siren.light_energy = 2.0
	siren.omni_range = 4.0
	siren.position.y = 2.0
	add_child(siren)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	return mat

func activate() -> void:
	active = true
	visible = true
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false

func _physics_process(_delta: float) -> void:
	if not active or not game or not is_instance_valid(game.player):
		return
	var target: Vector3 = game.player.global_position
	var chase: Vector3 = target - global_position
	chase.y = 0
	if chase.length() > 1.8:
		velocity = chase.normalized() * speed
		look_at(global_position + Vector3(chase.x, 0, chase.z), Vector3.UP)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		game.player.input_enabled = false
		game.show_caught()

func reset_state(start: Vector3) -> void:
	global_position = start
	velocity = Vector3.ZERO
	active = false
	visible = false
