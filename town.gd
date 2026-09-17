extends Node3D
class_name FrontierTown

const V := preload("res://visuals.gd")
var shops: Array[Dictionary] = []
var residents: Array[Dictionary] = []
var walls: Array[AABB] = []
var grid := AStarGrid2D.new()
var environment: Environment
var sun: DirectionalLight3D
var bell: Node3D
var rng := RandomNumberGenerator.new()
const PADS := [Vector3(-5, 0, -16), Vector3(5, 0, -16), Vector3(-5, 0, 17), Vector3(5, 0, 17)]

func _ready() -> void:
	rng.seed = 4501
	_build_sky()
	_build_desert()
	_build_town()
	_build_paths()

func _build_sky() -> void:
	var world := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#77bee0")
	sky_mat.sky_horizon_color = Color("#f8dfba")
	sky_mat.ground_bottom_color = Color("#d4a271")
	sky_mat.ground_horizon_color = Color("#f8dfba")
	sky_mat.sun_angle_max = 12
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d4e6f4")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("#ffe2ac")
	sun.light_energy = 0.45
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	add_child(sun)

func set_night(night: bool) -> void:
	var sky_mat: ProceduralSkyMaterial = environment.sky.sky_material
	sky_mat.sky_top_color = Color("#202b57") if night else Color("#77bee0")
	sky_mat.sky_horizon_color = Color("#956f98") if night else Color("#f8dfba")
	environment.ambient_light_color = Color("#b0bde9") if night else Color("#d4e6f4")
	environment.ambient_light_energy = 0.42 if night else 0.35
	sun.light_color = Color("#a2bde9") if night else Color("#ffe2ac")
	sun.light_energy = 0.5 if night else 0.45

func _build_desert() -> void:
	V.box(self, Vector3(0, -0.3, 0), Vector3(300, 0.6, 300), Color("#eac491"), true)
	V.box(self, Vector3(0, 0.008, 0), Vector3(17, 0.016, 85), Color("#dcb282"))
	for index in 65:
		var angle := rng.randf_range(0, TAU)
		var radius := rng.randf_range(46, 118)
		var pos := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		if index % 4 == 0:
			var rock := V.cylinder(self, pos + Vector3(0, 0.65, 0), rng.randf_range(0.8, 2.1), 1.3, Color("#bd8b76"), 0.6)
			rock.rotation.y = angle
		else:
			_cactus(pos, rng.randf_range(0.75, 1.5))
	for index in 16:
		var angle := TAU * index / 16.0
		var pos := Vector3(cos(angle) * 132, 3, sin(angle) * 132)
		V.cylinder(self, pos, rng.randf_range(10, 18), rng.randf_range(10, 19), Color("#c68e7c"), 8)
		V.cylinder(self, pos + Vector3(0, 6, 0), 9, 7, Color("#dcaa83"), 7)

func _cactus(pos: Vector3, scale_factor: float) -> void:
	var cactus := Node3D.new()
	add_child(cactus)
	cactus.position = pos
	cactus.scale = Vector3.ONE * scale_factor
	var green := Color("#85a985")
	V.cylinder(cactus, Vector3(0, 1.4, 0), 0.3, 2.8, green, 0.23)
	for side in [-1.0, 1.0]:
		V.box(cactus, Vector3(side * 0.45, 1.2 + side * 0.3, 0), Vector3(0.8, 0.3, 0.35), green)
		V.cylinder(cactus, Vector3(side * 0.8, 1.65 + side * 0.3, 0), 0.2, 1.2, green, 0.16)
	V.cylinder(cactus, Vector3(0, 2.88, 0), 0.19, 0.18, Color("#efb4ab"))

func _build_town() -> void:
	_building(Vector3(-16, 0, -23), PI / 2, "GUNSMITH", Color("#95b6b1"), "Gunsmith", "Mabel", "Aim steady, sheriff! The cannon makes every night a party.")
	_building(Vector3(-16, 0, -7), PI / 2, "THE COZY SALOON", Color("#d59480"), "", "Sunny", "Welcome! Wages arrive each dawn. Our doors stay open for you.")
	_building(Vector3(-16, 0, 9), PI / 2, "CACTUS COTTAGE", Color("#d6b37b"), "", "Pip", "Bandits arrive from the four trails. Watch your little map!")
	_building(Vector3(-16, 0, 25), PI / 2, "TRADING POST", Color("#acb990"), "", "Fern", "The town bell starts the night. Take all the prep time you need.")
	_building(Vector3(16, 0, -23), -PI / 2, "GENERAL STORE", Color("#c3b0cc"), "General Store", "June", "Padded vests, lemonade, and speedy boots. Stay safe out there!")
	_building(Vector3(16, 0, -7), -PI / 2, "SHERIFF OFFICE", Color("#dfbf7f"), "Sheriff Office", "Marshal Kit", "Deputies and turrets repair at dawn. No friendly fire here!")
	_building(Vector3(16, 0, 9), -PI / 2, "SUNFLOWER HOME", Color("#8fbab5"), "", "Bea", "Sleepwalkers appear on night 4. Big marshmallow brutes on night 7!")
	_building(Vector3(16, 0, 25), -PI / 2, "BOOT HILL BAKERY", Color("#d8a5aa"), "", "Biscuit", "If a night goes wrong, retry your sunset checkpoint. You've got this!")
	_building(Vector3(0, 0, -39), 0, "SUNSET STATION", Color("#b3ba91"), "", "Dusty", "Keep the bell safe! If it falls, the bandits take the town.")
	# Plaza bell: the town's objective and start-night interaction.
	bell = StaticBody3D.new()
	bell.collision_layer = 16
	add_child(bell)
	bell.position = Vector3(0, 0, -3)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.2
	shape.height = 3
	collision.shape = shape
	collision.position.y = 1.5
	bell.add_child(collision)
	V.cylinder(bell, Vector3(0, 0.3, 0), 1.7, 0.6, Color("#bd9278"))
	for x in [-1.0, 1.0]:
		V.box(bell, Vector3(x, 1.9, 0), Vector3(0.22, 3, 0.22), Color("#886953"))
	V.box(bell, Vector3(0, 3.35, 0), Vector3(2.5, 0.25, 0.4), Color("#886953"))
	V.cylinder(bell, Vector3(0, 2.65, 0), 0.58, 0.8, Color("#f2cb72"), 0.3)
	V.label(bell, "★ TOWN BELL ★", Vector3(0, 4.2, 0), Color("#fff0bd"), 28)
	shops.append({"name": "Town Bell", "position": Vector3(0, 0, 0)})
	for pos in PADS:
		V.cylinder(self, pos + Vector3(0, 0.07, 0), 1.05, 0.14, Color("#9c9e97"))
		V.label(self, "POPPER PAD", pos + Vector3(0, 0.3, 0), Color("#f6e4bb"), 13)
	# Hitching rails, hay bales, barrels, wagons, water tower, and a friendly blocky horse.
	for side in [-1, 1]:
		for z in [-30, 1, 33]:
			for offset in [-1.4, 1.4]:
				V.box(self, Vector3(side * 8, 0.6, z + offset), Vector3(0.17, 1.2, 0.17), Color("#9a735a"))
			V.box(self, Vector3(side * 8, 0.95, z), Vector3(0.15, 0.16, 3.4), Color("#9a735a"))
			V.box(self, Vector3(side * 25, 0.5, z), Vector3(2, 1, 1.1), Color("#e9c975"))
			V.cylinder(self, Vector3(side * 24, 0.65, z + 2), 0.5, 1.3, Color("#a78064"))
	var wagon := Node3D.new()
	add_child(wagon)
	wagon.position = Vector3(-28, 0, 17)
	V.box(wagon, Vector3(0, 1, 0), Vector3(2.4, 0.6, 3.3), Color("#9e705c"))
	for x in [-1.3, 1.3]:
		for z in [-1, 1]:
			V.cylinder(wagon, Vector3(x, 0.65, z), 0.65, 0.18, Color("#645254")).rotation.z = PI / 2
		V.box(wagon, Vector3(x, 1.6, 0), Vector3(0.15, 0.8, 3.3), Color("#c29872"))
	V.box(wagon, Vector3(0, 1.05, 3), Vector3(0.2, 0.2, 3), Color("#886953"))
	for x in [27, 30]:
		for z in [-34, -31]:
			V.box(self, Vector3(x, 3, z), Vector3(0.3, 6, 0.3), Color("#937961"))
	V.cylinder(self, Vector3(28.5, 6, -32.5), 2.5, 3, Color("#95b0b4"))
	V.cylinder(self, Vector3(28.5, 7.8, -32.5), 2.8, 0.8, Color("#ae7d70"), 0)
	var horse := Node3D.new()
	add_child(horse)
	horse.position = Vector3(-7, 0, 3)
	V.box(horse, Vector3(0, 1.15, 0), Vector3(0.7, 0.8, 1.5), Color("#b78b72"))
	V.box(horse, Vector3(0, 1.9, -0.65), Vector3(0.45, 0.9, 0.5), Color("#b78b72"))
	V.box(horse, Vector3(0, 2.12, -0.92), Vector3(0.48, 0.4, 0.7), Color("#c59b80"))
	V.box(horse, Vector3(0, 1.58, 0), Vector3(0.8, 0.12, 0.7), Color("#d69a96"))
	for x in [-0.24, 0.24]:
		for z in [-0.5, 0.5]:
			V.box(horse, Vector3(x, 0.43, z), Vector3(0.18, 0.86, 0.2), Color("#96715d"))
		V.box(horse, Vector3(x, 2.12, -1.12), Vector3(0.04, 0.08, 0.1), Color("#433f4b"))
		V.box(horse, Vector3(x * 0.6, 2.49, -0.66), Vector3(0.13, 0.28, 0.17), Color("#96715d"))

func _wall(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := V.box(parent, pos, size, color, true)
	var center := body.global_position
	var world_size := size
	if absf(sin(parent.rotation.y)) > 0.5:
		world_size = Vector3(size.z, size.y, size.x)
	walls.append(AABB(center - world_size / 2, world_size))

func _building(pos: Vector3, angle: float, title: String, color: Color, shop: String, resident: String, greeting: String) -> void:
	var building := Node3D.new()
	add_child(building)
	building.position = pos
	building.rotation.y = angle
	V.box(building, Vector3(0, 0.025, 0.6), Vector3(11, 0.05, 11), Color("#b58f6c"))
	_wall(building, Vector3(-5, 2, 0), Vector3(0.35, 4, 8), color)
	_wall(building, Vector3(5, 2, 0), Vector3(0.35, 4, 8), color)
	_wall(building, Vector3(0, 2, -4), Vector3(10, 4, 0.35), color)
	for x in [-3.3, 3.3]:
		_wall(building, Vector3(x, 1.5, 4), Vector3(3.4, 3, 0.3), color)
		V.box(building, Vector3(x, 1.9, 4.18), Vector3(1.8, 1.6, 0.09), Color("#ffe1a0"))
		V.box(building, Vector3(x, 1.9, 4.25), Vector3(0.08, 1.6, 0.1), Color("#916c55"))
		V.box(building, Vector3(x, 1.9, 4.25), Vector3(1.8, 0.08, 0.1), Color("#916c55"))
	V.box(building, Vector3(0, 4.1, 0), Vector3(10.7, 0.3, 8.7), Color("#966c60"), true)
	V.box(building, Vector3(0, 4.5, 4), Vector3(10.5, 2.0, 0.4), color)
	V.box(building, Vector3(0, 5.52, 4), Vector3(10.8, 0.15, 0.6), Color("#f2d7a0"))
	V.box(building, Vector3(0, 3.05, 5.0), Vector3(11, 0.18, 2.8), Color("#f0c892"))
	for x in [-4.8, 4.8]:
		V.box(building, Vector3(x, 1.5, 5.9), Vector3(0.18, 3, 0.18), Color("#967158"), true)
	V.label(building, title, Vector3(0, 4.75, 4.4), Color("#fff0cb"), 25)
	V.box(building, Vector3(0, 1, -1.6), Vector3(5.4, 1.5, 0.8), Color("#987259"), true)
	V.box(building, Vector3(0, 1.8, -1.6), Vector3(5.7, 0.14, 1), Color("#edc991"))
	for x in [-3.4, 3.4]:
		V.cylinder(building, Vector3(x, 0.6, 1.3), 0.6, 1.2, Color("#bb9370"))
		V.box(building, Vector3(x, 1.23, 1.3), Vector3(1.7, 0.1, 1.4), Color("#e1bc85"))
		V.cylinder(building, Vector3(x, 1.43, 1.3), 0.13, 0.32, Color("#f3d9b3"))
	var person := Node3D.new()
	building.add_child(person)
	person.position = Vector3(0, 0.06, -2.8)
	person.rotation.y = PI
	V.person(person, color.darkened(0.15))
	V.label(person, resident, Vector3(0, 2.6, 0), Color("#fff0cb"), 18)
	residents.append({"node": person, "home": person.position, "name": resident, "greeting": greeting})
	if title in ["THE COZY SALOON", "CACTUS COTTAGE", "SUNFLOWER HOME"]:
		var guest := Node3D.new()
		building.add_child(guest)
		guest.position = Vector3(2.4, 0.06, 2.6)
		guest.rotation.y = -0.4
		V.person(guest, Color("#929ecb"))
		residents.append({"node": guest, "home": guest.position, "name": "Neighbor", "greeting": "Howdy, sheriff! We're cheering for you."})
	if not shop.is_empty():
		shops.append({"name": shop, "position": building.to_global(Vector3(0, 0, 6.4))})
		# A second interaction spot lets the shop work from inside as well as the porch.
		shops.append({"name": shop, "position": building.to_global(Vector3(0, 0, 0))})
	var lamp := OmniLight3D.new()
	building.add_child(lamp)
	lamp.position = Vector3(0, 2.8, 3)
	lamp.light_color = Color("#ffcf80")
	lamp.light_energy = 0.9
	lamp.omni_range = 8

func _build_paths() -> void:
	grid.region = Rect2i(-68, -68, 137, 137)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for wall in walls:
		for x in range(floori(wall.position.x - 0.5), ceili(wall.end.x + 0.5) + 1):
			for z in range(floori(wall.position.z - 0.5), ceili(wall.end.z + 0.5) + 1):
				grid.set_point_solid(Vector2i(x, z))

func _walkable(pos: Vector3) -> Vector2i:
	var cell := Vector2i(clampi(roundi(pos.x), -67, 67), clampi(roundi(pos.z), -67, 67))
	if not grid.is_point_solid(cell):
		return cell
	for radius in range(1, 6):
		for x in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, z)
				if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
					return candidate
	return cell

func route(from: Vector3, to: Vector3) -> PackedVector2Array:
	return grid.get_point_path(_walkable(from), _walkable(to))

func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	for index in residents.size():
		var resident: Dictionary = residents[index]
		# Residents stay in their own businesses/homes and never enter combat groups.
		resident.node.position.y = resident.home.y + sin(time * 1.8 + index) * 0.018
		resident.node.rotation.y = PI + sin(time * 0.5 + index) * 0.18
