extends Node3D
class_name StreetBeatGame

const CIVILIAN_KILL_THRESHOLD := 3
const CIVILIAN_COLORS := [Color("#5bd6c0"), Color("#ff9f68"), Color("#b08cff"), Color("#68b5ff"), Color("#ffd447")]
const POLICE_STARTS := [Vector3(-2.8, 0.1, -16.0), Vector3(2.8, 0.1, -16.0)]

var player: StreetPlayer
var civilians: Array[StreetCivilian] = []
var police: Array[StreetPolice] = []
var civilian_kills := 0
var shots_fired := 0
var police_pursuit_active := false
var caught := false
var status_text := "SAFE"
var status_color := Color("#5bd6c0")
var status_label: Label
var objective_label: Label
var warning_label: Label
var gun_label: Label
var flash_panel: ColorRect
var audio_player: AudioStreamPlayer
var alert_audio: AudioStreamWAV
var shot_audio: AudioStreamWAV

func _ready() -> void:
	add_to_group("game")
	_build_environment()
	_build_street()
	_build_player()
	_build_civilians()
	_build_police()
	_build_hud()
	_build_audio()
	_update_hud()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#17213b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#91a6d8")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_color = Color("#fff0c2")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

func _build_street() -> void:
	# One compact graybox block: road, sidewalks, colorful building blocks and lane paint.
	add_box(Vector3(0, -0.15, 0), Vector3(40, 0.3, 40), Color("#536079"), true)
	add_box(Vector3(0, 0.02, 0), Vector3(7.4, 0.12, 40), Color("#242b43"), true)
	add_box(Vector3(-5.0, 0.04, 0), Vector3(2.5, 0.16, 40), Color("#d6d8dc"), true)
	add_box(Vector3(5.0, 0.04, 0), Vector3(2.5, 0.16, 40), Color("#d6d8dc"), true)
	add_box(Vector3(0, 0.1, -5.0), Vector3(0.12, 0.03, 40), Color("#ffd447"), false)
	for z in [-16.0, -11.0, -6.0, -1.0, 4.0, 9.0, 14.0]:
		add_box(Vector3(-1.7, 0.1, z), Vector3(0.08, 0.03, 2.3), Color("#ffd447"), false)
		add_box(Vector3(1.7, 0.1, z), Vector3(0.08, 0.03, 2.3), Color("#ffd447"), false)
	for z in [-14.0, -7.0, 0.0, 7.0, 14.0]:
		add_box(Vector3(-10.0, 2.6, z), Vector3(5.5, 5.2, 5.0), Color("#485a91" if int(z) % 2 == 0 else "#7c4f79"), true)
		add_box(Vector3(10.0, 2.6, z), Vector3(5.5, 5.2, 5.0), Color("#c46b5d" if int(z) % 2 == 0 else "#4d8c83"), true)
		add_box(Vector3(-6.3, 1.1, z + 2.0), Vector3(0.15, 1.6, 0.15), Color("#26314f"), true)
		add_box(Vector3(6.3, 1.1, z + 2.0), Vector3(0.15, 1.6, 0.15), Color("#26314f"), true)
	# Friendly visual signposts: color blocks communicate the playable space without text.
	add_box(Vector3(-4.0, 1.7, -18.0), Vector3(0.16, 3.3, 0.16), Color("#26314f"), true)
	add_box(Vector3(-4.0, 3.2, -18.0), Vector3(1.5, 0.75, 0.12), Color("#f45b69"), true)
	add_box(Vector3(4.0, 1.7, -18.0), Vector3(0.16, 3.3, 0.16), Color("#26314f"), true)
	add_box(Vector3(4.0, 3.2, -18.0), Vector3(1.5, 0.75, 0.12), Color("#5bd6c0"), true)

func add_box(position: Vector3, size: Vector3, color: Color, collidable: bool) -> Node3D:
	var holder: Node3D
	if collidable:
		holder = StaticBody3D.new()
	else:
		holder = Node3D.new()
	holder.position = position
	add_child(holder)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	holder.add_child(mesh)
	if collidable:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		holder.add_child(collision)
	return holder

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat

func _build_player() -> void:
	player = StreetPlayer.new()
	player.name = "Player"
	player.position = Vector3(0, 0.1, 12)
	add_child(player)
	player.fire_requested.connect(_on_fire)
	player.weapon_changed.connect(_on_weapon_changed)

func _build_civilians() -> void:
	var starts := [Vector3(-2.1, 0.1, 7.0), Vector3(2.1, 0.1, 3.0), Vector3(-2.0, 0.1, -1.0), Vector3(2.0, 0.1, -6.0), Vector3(-2.0, 0.1, -12.0)]
	for index in starts.size():
		var civilian := StreetCivilian.new()
		civilian.name = "Civilian_%02d" % index
		add_child(civilian)
		civilian.setup(self, starts[index], CIVILIAN_COLORS[index])
		civilians.append(civilian)

func _build_police() -> void:
	for index in 2:
		var officer := StreetPolice.new()
		officer.name = "Police_Pursuer_%02d" % index
		add_child(officer)
		officer.setup(self, POLICE_STARTS[index])
		officer.reset_state(officer.global_position)
		police.append(officer)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ReadableHUD"
	add_child(layer)
	var top := ColorRect.new()
	top.color = Color(0.04, 0.06, 0.12, 0.92)
	top.position = Vector2(18, 18)
	top.size = Vector2(245, 208)
	layer.add_child(top)
	var title := _label("★ STREET BEAT", Vector2(18, 12), 26, Color("#ffd447"))
	top.add_child(title)
	var controls := _label("W A S D   MOVE\nMOUSE   LOOK\nCLICK   FIRE\nQ   GUN\nESC   FREE\nR   RESET", Vector2(20, 55), 18, Color("#f5f7ff"))
	top.add_child(controls)
	var badge := ColorRect.new()
	badge.color = Color("#f45b69")
	badge.position = Vector2(278, 18)
	badge.size = Vector2(250, 48)
	layer.add_child(badge)
	objective_label = _label("★ KEEP PEOPLE SAFE", Vector2(14, 8), 22, Color("#17213b"))
	badge.add_child(objective_label)
	var warning_panel := ColorRect.new()
	warning_panel.color = Color(0.04, 0.06, 0.12, 0.92)
	warning_panel.position = Vector2(920, 18)
	warning_panel.size = Vector2(342, 150)
	layer.add_child(warning_panel)
	warning_label = _label("⚠ 0 / 3\nSAFE", Vector2(20, 17), 27, Color("#5bd6c0"))
	warning_panel.add_child(warning_label)
	gun_label = _label("🔫 READY", Vector2(20, 88), 22, Color("#ffd447"))
	warning_panel.add_child(gun_label)
	var crosshair := _label("+", Vector2(625, 340), 38, Color("#ffd447"))
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)
	status_label = _label("SAFE", Vector2(0, 650), 28, Color("#5bd6c0"))
	status_label.size = Vector2(1280, 48)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(status_label)
	flash_panel = ColorRect.new()
	flash_panel.color = Color(1, 0.83, 0.28, 0.22)
	flash_panel.position = Vector2.ZERO
	flash_panel.size = Vector2(1280, 720)
	flash_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_panel.visible = false
	layer.add_child(flash_panel)

func _label(text: String, position: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "GeneratedFeedback"
	add_child(audio_player)
	shot_audio = _make_beep(440.0, 0.08)
	alert_audio = _make_beep(180.0, 0.24)

func _make_beep(frequency: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for index in samples:
		var envelope := 1.0 - float(index) / float(samples)
		data.encode_s16(index * 2, int(sin(TAU * frequency * float(index) / rate) * 10000.0 * envelope))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream

func _on_fire(origin: Vector3, direction: Vector3) -> void:
	if not player.gun_drawn:
		return
	_fire_hitscan(origin, direction)

func _fire_hitscan(origin: Vector3, direction: Vector3) -> void:
	shots_fired += 1
	player.flash_muzzle()
	_play_feedback(shot_audio)
	show_shot_flash()
	for civilian in civilians:
		if civilian.active and civilian.global_position.distance_to(origin) <= 14.0:
			civilian.flee_from(origin)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction.normalized() * 50.0)
	query.exclude = [player]
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target = hit.get("collider")
		if target is StreetCivilian:
			target.hit()
	status_text = "SHOT! RUNNERS FLEE"
	status_color = Color("#ffd447")
	_update_hud()

func show_shot_flash() -> void:
	if not flash_panel:
		return
	flash_panel.visible = true
	get_tree().create_timer(0.07).timeout.connect(_hide_shot_flash)

func _hide_shot_flash() -> void:
	if is_instance_valid(flash_panel):
		flash_panel.visible = false

func _play_feedback(stream: AudioStreamWAV) -> void:
	if audio_player:
		audio_player.stream = stream
		audio_player.play()

func register_civilian_kill(_civilian: StreetCivilian) -> void:
	civilian_kills += 1
	if civilian_kills >= CIVILIAN_KILL_THRESHOLD and not police_pursuit_active:
		_activate_police()
	_update_hud()

func _activate_police() -> void:
	police_pursuit_active = true
	status_text = "🚓 CHASE! PRESS R"
	status_color = Color("#f45b69")
	for officer in police:
		officer.activate()
	_play_feedback(alert_audio)
	_update_hud()

func show_caught() -> void:
	if caught:
		return
	caught = true
	status_text = "🚓 CAUGHT! PRESS R"
	status_color = Color("#f45b69")
	_update_hud()

func _on_weapon_changed(drawn: bool) -> void:
	gun_label.text = "🔫 READY" if drawn else "🔫 HOLSTER"
	gun_label.add_theme_color_override("font_color", Color("#ffd447") if drawn else Color("#a7b1c8"))

func _process(_delta: float) -> void:
	if police_pursuit_active and not caught:
		status_text = "🚓 CHASE! PRESS R"
		status_color = Color("#f45b69")
	_update_hud()

func _update_hud() -> void:
	if not warning_label or not status_label:
		return
	warning_label.text = "⚠ %d / %d\n%s" % [civilian_kills, CIVILIAN_KILL_THRESHOLD, "🚓 CHASE" if police_pursuit_active else "SAFE"]
	warning_label.add_theme_color_override("font_color", Color("#f45b69") if police_pursuit_active else Color("#5bd6c0"))
	status_label.text = status_text
	status_label.add_theme_color_override("font_color", status_color)

func reset_game() -> void:
	civilian_kills = 0
	shots_fired = 0
	police_pursuit_active = false
	caught = false
	status_text = "SAFE"
	status_color = Color("#5bd6c0")
	player.reset_state()
	var starts := [Vector3(-2.1, 0.1, 7.0), Vector3(2.1, 0.1, 3.0), Vector3(-2.0, 0.1, -1.0), Vector3(2.0, 0.1, -6.0), Vector3(-2.0, 0.1, -12.0)]
	for index in civilians.size():
		civilians[index].reset_state(starts[index])
	for index in police.size():
		police[index].reset_state(POLICE_STARTS[index])
	_update_hud()

# Deterministic behavior hooks used by the executable smoke test, not by gameplay UI.
func test_unsafe_shot() -> void:
	for civilian in civilians:
		if civilian.active and civilian.global_position.distance_to(player.global_position) <= 14.0:
			civilian.flee_from(player.global_position)

func test_fire_at_civilian(index: int) -> void:
	if index >= 0 and index < civilians.size() and civilians[index].active:
		civilians[index].hit()
		_update_hud()

func get_status_snapshot() -> Dictionary:
	var fleeing := 0
	for civilian in civilians:
		if civilian.is_fleeing():
			fleeing += 1
	return {"kills": civilian_kills, "shots": shots_fired, "fleeing": fleeing, "police": police_pursuit_active, "caught": caught, "gun_drawn": player.gun_drawn}
