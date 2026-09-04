extends CharacterBody3D
class_name StreetPlayer

signal fire_requested(origin: Vector3, direction: Vector3)
signal weapon_changed(drawn: bool)

const WALK_SPEED := 7.0
const JUMP_SPEED := 7.0
const LOOK_SENSITIVITY := 0.0025

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gun_drawn := true
var input_enabled := true
var camera: Camera3D
var head: Node3D
var weapon: Node3D
var muzzle: OmniLight3D

func _ready() -> void:
	_build_body()
	_build_weapon()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_body() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	head = Node3D.new()
	head.name = "Head"
	head.position.y = 1.55
	add_child(head)
	camera = Camera3D.new()
	camera.name = "FirstPersonCamera"
	camera.fov = 78.0
	camera.near = 0.05
	head.add_child(camera)

func _build_weapon() -> void:
	weapon = Node3D.new()
	weapon.name = "UnrestrictedSidearm"
	weapon.position = Vector3(0.42, -0.34, -0.72)
	camera.add_child(weapon)
	var grip := MeshInstance3D.new()
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.13, 0.34, 0.16)
	grip.mesh = grip_mesh
	grip.position = Vector3(0, -0.13, 0)
	grip.rotation_degrees.x = -12
	grip.material_override = _material(Color("#222b43"))
	weapon.add_child(grip)
	var slide := MeshInstance3D.new()
	var slide_mesh := BoxMesh.new()
	slide_mesh.size = Vector3(0.22, 0.14, 0.52)
	slide.mesh = slide_mesh
	slide.material_override = _material(Color("#d8e0ea"))
	weapon.add_child(slide)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(0.225, 0.035, 0.20)
	stripe.mesh = stripe_mesh
	stripe.position.z = -0.13
	stripe.position.y = -0.01
	stripe.material_override = _material(Color("#f45b69"))
	weapon.add_child(stripe)
	muzzle = OmniLight3D.new()
	muzzle.light_color = Color("#ffd447")
	muzzle.light_energy = 0.0
	muzzle.omni_range = 3.0
	muzzle.position.z = -0.34
	weapon.add_child(muzzle)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	return mat

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if input_enabled and gun_drawn and camera:
			fire_requested.emit(camera.global_position, -camera.global_transform.basis.z)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		toggle_weapon()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().call_group("game", "reset_game")
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and input_enabled:
		rotate_y(-event.relative.x * LOOK_SENSITIVITY)
		head.rotate_x(-event.relative.y * LOOK_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_SPEED
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	if direction:
		velocity.x = direction.x * WALK_SPEED
		velocity.z = direction.z * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED * 8.0 * delta)
	move_and_slide()
	global_position.x = clamp(global_position.x, -19.0, 19.0)
	global_position.z = clamp(global_position.z, -19.0, 19.0)

func toggle_weapon() -> void:
	gun_drawn = not gun_drawn
	weapon.visible = gun_drawn
	weapon_changed.emit(gun_drawn)

func flash_muzzle() -> void:
	if muzzle:
		muzzle.light_energy = 4.0
		get_tree().create_timer(0.06).timeout.connect(_clear_muzzle)

func _clear_muzzle() -> void:
	if is_instance_valid(muzzle):
		muzzle.light_energy = 0.0

func reset_state() -> void:
	global_position = Vector3(0, 0.1, 12)
	rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO
	gun_drawn = true
	weapon.visible = true
	input_enabled = true
