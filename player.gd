extends CharacterBody3D
class_name FrontierPlayer

signal fire_requested(origin: Vector3, direction: Vector3)
signal reload_requested
signal select_requested(index: int)

var input_enabled := false
var speed := 7.0
var head: Node3D
var camera: Camera3D
var weapon: Node3D
var muzzle: OmniLight3D
var weapon_id := "revolver"
var recoil := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 16
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	head = Node3D.new()
	head.position.y = 1.6
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 76
	camera.near = 0.04
	head.add_child(camera)
	set_weapon("revolver")

func set_weapon(id: String) -> void:
	weapon_id = id
	if is_instance_valid(weapon):
		weapon.queue_free()
	weapon = Node3D.new()
	camera.add_child(weapon)
	weapon.position = Vector3(0.38, -0.32, -0.65)
	var color := Color(FrontierRules.WEAPONS[id].color)
	FrontierVisuals.box(weapon, Vector3(0, -0.1, 0.1), Vector3(0.14, 0.3, 0.18), Color("#a87a5b")).rotation.x = -0.2
	if id == "revolver":
		FrontierVisuals.box(weapon, Vector3(0, 0.03, -0.14), Vector3(0.12, 0.12, 0.5), color)
		FrontierVisuals.cylinder(weapon, Vector3(0, -0.01, 0.03), 0.13, 0.2, Color("#d5dde1")).rotation.x = PI / 2
	elif id == "shotgun":
		for x in [-0.065, 0.065]:
			FrontierVisuals.cylinder(weapon, Vector3(x, 0, -0.26), 0.06, 0.7, Color("#7b8695")).rotation.x = PI / 2
		FrontierVisuals.box(weapon, Vector3(0, -0.07, -0.13), Vector3(0.23, 0.14, 0.35), color)
	else:
		FrontierVisuals.cylinder(weapon, Vector3(0, 0, -0.13), 0.21, 0.65, color).rotation.x = PI / 2
		FrontierVisuals.cylinder(weapon, Vector3(0, 0, -0.47), 0.24, 0.07, Color("#f7d680")).rotation.x = PI / 2
	muzzle = OmniLight3D.new()
	weapon.add_child(muzzle)
	muzzle.position.z = -0.55
	muzzle.light_color = color
	muzzle.light_energy = 0
	muzzle.omni_range = 4

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0024)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * 0.0024, -1.35, 1.35)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			fire_requested.emit(camera.global_position, -camera.global_basis.z)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_R: reload_requested.emit()
			KEY_Q: select_requested.emit(-1)
			KEY_1: select_requested.emit(0)
			KEY_2: select_requested.emit(1)
			KEY_3: select_requested.emit(2)

func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= 20 * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 7
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()
	global_position.x = clampf(global_position.x, -65, 65)
	global_position.z = clampf(global_position.z, -65, 65)
	recoil = move_toward(recoil, 0, delta * 2.4)
	weapon.position.z = -0.65 + recoil
	weapon.rotation.x = recoil * 0.8
	muzzle.light_energy = recoil * 12

func flash_muzzle() -> void:
	recoil = 0.15
