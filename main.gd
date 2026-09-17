extends Node3D
class_name SunsetSheriffGame

var state: Dictionary = {}
var saves := FrontierSave.new()
var town: FrontierTown
var player: FrontierPlayer
var ui: FrontierUI
var title_camera: Camera3D
var hostiles: Array[FrontierActor] = []
var allies: Array[FrontierActor] = []
var phase := "day"
var mode := "title"
var town_health := 300
var wave_queue: Array[String] = []
var spawn_timer := 0.0
var spawn_index := 0
var shot_time := 0.0
var reload_time := 0.0
var autosave_time := 10.0
var notice_text := ""
var notice_time := 0.0
var hit_time := 0.0
var hurt_time := 0.0
var current_shop := ""
var audio: AudioStreamPlayer
var shot_sound: AudioStreamWAV
var chime_sound: AudioStreamWAV

func _ready() -> void:
	town = FrontierTown.new()
	add_child(town)
	player = FrontierPlayer.new()
	add_child(player)
	player.fire_requested.connect(fire)
	player.reload_requested.connect(reload_gun)
	player.select_requested.connect(select_weapon)
	title_camera = Camera3D.new()
	add_child(title_camera)
	title_camera.position = Vector3(37, 27, 49)
	title_camera.look_at(Vector3(-2, 0, -5))
	title_camera.fov = 63
	ui = FrontierUI.new()
	add_child(ui)
	ui.setup(self)
	audio = AudioStreamPlayer.new()
	audio.volume_db = -14
	add_child(audio)
	shot_sound = _beep(340, 0.085)
	chime_sound = _beep(720, 0.2)
	show_title()
	get_tree().auto_accept_quit = false

func is_playing() -> bool:
	return mode == "playing"

func _set_mode(next_mode: String) -> void:
	mode = next_mode
	player.input_enabled = is_playing()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_playing() else Input.MOUSE_MODE_VISIBLE

func show_title() -> void:
	_set_mode("title")
	title_camera.make_current()
	town.set_night(false)
	var saved := saves.load_game()
	ui.show_title(saved, saves.last_error)

func new_game() -> void:
	_apply_state(FrontierRules.new_state())
	save_checkpoint()
	tell("Howdy, sheriff! $220 includes your first wage. Visit the shops, then press N.", 9)

func load_game() -> void:
	var saved := saves.load_game()
	if saved.is_empty():
		show_title()
		return
	var recovery := saves.last_error
	_apply_state(saved)
	tell(recovery if not recovery.is_empty() else "Checkpoint loaded. Prepare at your own pace, then ring in the night.", 7)

func _apply_state(saved: Dictionary) -> void:
	state = saved.duplicate(true)
	_clear_actors()
	phase = "day"
	town_health = 300
	wave_queue.clear()
	shot_time = 0
	reload_time = 0
	hurt_time = 0
	hit_time = 0
	autosave_time = 10
	player.position = Vector3(state.position[0], state.position[1], state.position[2])
	player.rotation.y = state.yaw
	player.head.rotation.x = state.pitch
	player.velocity = Vector3.ZERO
	player.speed = 8.75 if state.boots else 7.0
	player.set_weapon(state.selected)
	player.camera.make_current()
	town.set_night(false)
	_build_allies()
	resume_game()

func resume_game() -> void:
	_set_mode("playing")
	ui.clear_modal()
	ui.hud.show()
	ui.refresh()

func return_to_title() -> void:
	if phase == "day" and not state.is_empty():
		if not save_checkpoint():
			return # Do not silently discard unsaved daytime progress on an I/O error.
	_clear_actors()
	show_title()

func save_checkpoint() -> bool:
	if phase != "day" or state.is_empty():
		return false
	state.position = [player.position.x, player.position.y, player.position.z]
	state.yaw = wrapf(player.rotation.y, -PI, PI)
	state.pitch = player.head.rotation.x
	if not saves.save_game(state):
		tell(saves.last_error, 10)
		return false
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if phase == "day" and not state.is_empty() and not save_checkpoint():
			return
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "playing":
		_set_mode("paused")
		ui.show_pause()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
	if key == KEY_ESCAPE:
		if mode in ["paused", "shop"]:
			resume_game()
		elif is_playing():
			_set_mode("paused")
			ui.show_pause()
	elif key == KEY_E:
		if mode == "shop": resume_game()
		elif is_playing(): interact()
	elif key == KEY_N and is_playing() and phase == "day":
		start_night()

func nearest_interaction() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 4.0
	for shop in town.shops:
		var distance := player.position.distance_to(shop.position)
		if distance < best:
			best = distance
			nearest = shop
	if not nearest.is_empty(): return nearest
	for resident in town.residents:
		if player.position.distance_to(resident.node.global_position) < 3.5:
			return resident
	return {}

func interaction_prompt() -> String:
	var interaction := nearest_interaction()
	if not interaction.is_empty():
		if interaction.has("greeting"):
			return "[ E ]  Say howdy to " + interaction.name
		if phase == "night": return "Shops reopen at dawn. Protect the bell!"
		return "[ E ]  " + ("Ring the bell • start night %d" % state.day if interaction.name == "Town Bell" else "Shop at " + interaction.name)
	if phase == "day": return "Visit the signed shops • [ N ] start night when ready"
	return "Defend the bell! Coral dots are foes • Mint dots are your posse"

func interact() -> void:
	var interaction := nearest_interaction()
	if interaction.is_empty(): return
	if interaction.has("greeting"):
		tell(interaction.name + ": " + interaction.greeting, 7)
	elif phase == "day":
		if interaction.name == "Town Bell": start_night()
		else:
			current_shop = interaction.name
			_set_mode("shop")
			ui.show_shop(current_shop)

func purchase(id: String) -> void:
	if mode != "shop" or phase != "day" or not FrontierRules.CATALOG.has(id) or FrontierRules.CATALOG[id].shop != current_shop:
		return
	var old := state.duplicate(true)
	var message := FrontierRules.buy(state, id)
	if message.is_empty():
		if not save_checkpoint():
			state = old
			message = saves.last_error + " Purchase canceled."
		else:
			message = FrontierRules.CATALOG[id].name + " is yours! Checkpoint saved."
			player.speed = 8.75 if state.boots else 7.0
			if id in ["deputy", "turret"]: _build_allies()
			_sound(chime_sound)
	ui.show_shop(current_shop, message)
	ui.refresh()

func start_night() -> void:
	if phase != "day" or not is_playing(): return
	if not save_checkpoint(): return
	phase = "night"
	town.set_night(true)
	wave_queue = FrontierRules.wave(state.day)
	spawn_index = 0
	spawn_timer = 0.7
	tell("Night %d! Protect yourself and the town bell. Your sunset checkpoint is safe." % state.day, 7)
	_sound(chime_sound)

func _physics_process(delta: float) -> void:
	if not is_playing(): return
	shot_time = maxf(0, shot_time - delta)
	notice_time = maxf(0, notice_time - delta)
	hit_time = maxf(0, hit_time - delta)
	hurt_time = maxf(0, hurt_time - delta)
	if reload_time > 0:
		reload_time = maxf(0, reload_time - delta)
		if reload_time == 0:
			FrontierRules.reload_weapon(state, state.selected)
	if phase == "night":
		spawn_timer -= delta
		if not wave_queue.is_empty() and spawn_timer <= 0:
			_spawn_hostile(wave_queue.pop_front())
			spawn_timer = maxf(0.65, 2.3 - state.day * 0.1)
		if remaining_foes() == 0:
			win_night()
	else:
		autosave_time -= delta
		if autosave_time <= 0:
			save_checkpoint()
			autosave_time = 10

func _process(_delta: float) -> void:
	if is_instance_valid(ui): ui.refresh()

func remaining_foes() -> int:
	var count := wave_queue.size()
	for actor in hostiles:
		if is_instance_valid(actor) and not actor.dead: count += 1
	return count

func _spawn_hostile(kind: String) -> FrontierActor:
	var starts := [Vector3(0, 0.1, 46), Vector3(0, 0.1, -48), Vector3(-41, 0.1, 0), Vector3(41, 0.1, 1)]
	var actor := FrontierActor.new()
	add_child(actor)
	actor.setup(self, kind, starts[spawn_index % starts.size()] + Vector3(randf_range(-1.5, 1.5), 0, 0))
	spawn_index += 1
	hostiles.append(actor)
	return actor

func _clear_actors() -> void:
	for actor in hostiles + allies:
		if is_instance_valid(actor):
			remove_child(actor)
			actor.queue_free()
	hostiles.clear()
	allies.clear()

func _build_allies() -> void:
	for actor in allies:
		if is_instance_valid(actor):
			remove_child(actor)
			actor.queue_free()
	allies.clear()
	for index in state.deputies:
		_add_ally("deputy", Vector3(-3 if index % 2 == 0 else 3, 0.1, 5 + (index / 2) * 3))
	for index in state.turrets:
		_add_ally("turret", FrontierTown.PADS[index] + Vector3(0, 0.1, 0))

func _add_ally(kind: String, pos: Vector3) -> void:
	var actor := FrontierActor.new()
	add_child(actor)
	actor.setup(self, kind, pos)
	allies.append(actor)

func win_night() -> void:
	if phase != "night" or not is_playing(): return
	phase = "day"
	FrontierRules.dawn(state)
	town_health = 300
	_clear_actors()
	_build_allies()
	town.set_night(false)
	reload_time = 0
	save_checkpoint()
	_set_mode("dawn")
	ui.show_result(true)
	_sound(chime_sound)

func lose_night() -> void:
	if not is_playing() or phase != "night": return
	_set_mode("defeat")
	ui.show_result(false)

func select_weapon(index: int) -> void:
	if not is_playing(): return
	if index == -1: index = (state.weapons.find(state.selected) + 1) % state.weapons.size()
	if index < 0 or index >= state.weapons.size():
		tell("The Confetti Cannon is waiting at the Gunsmith. $850!", 4)
		return
	state.selected = state.weapons[index]
	reload_time = 0
	player.set_weapon(state.selected)

func reload_gun() -> void:
	if not is_playing() or reload_time > 0: return
	var id: String = state.selected
	if state.loaded[id] >= mini(state.ammo[id], FrontierRules.WEAPONS[id].magazine):
		if state.ammo[id] == 0: tell("Out of ammo! Resupply at the Gunsmith during the day.")
		return
	reload_time = FrontierRules.WEAPONS[id].reload

func fire(origin: Vector3, direction: Vector3) -> void:
	if not is_playing() or shot_time > 0 or reload_time > 0: return
	if not FrontierRules.consume_shot(state):
		reload_gun()
		tell("Click! Press R to reload. Ammo boxes are $35 at the Gunsmith.")
		return
	var weapon: Dictionary = FrontierRules.WEAPONS[state.selected]
	shot_time = weapon.delay
	player.flash_muzzle()
	_sound(shot_sound)
	for pellet in weapon.pellets:
		var ray_direction := direction.normalized()
		if weapon.spread > 0:
			# Symmetric pellet ring: predictable shotgun spread, independent of frame rate.
			var angle: float = TAU * pellet / weapon.pellets
			ray_direction = (direction + player.camera.global_basis.x * cos(angle) * weapon.spread + player.camera.global_basis.y * sin(angle) * weapon.spread).normalized()
		var end: Vector3 = origin + ray_direction * weapon.range
		var query := PhysicsRayQueryParameters3D.create(origin, end, 1 | 4 | 16)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			end = hit.position
			if hit.collider is FrontierActor and not hit.collider.friendly:
				hit.collider.take_damage(weapon.damage)
				hit_time = 0.18
		tracer(origin + Vector3(0, -0.12, 0), end, Color(weapon.color))
		if weapon.has("splash"):
			_party_burst(end)
			for actor in hostiles:
				if is_instance_valid(actor) and not actor.dead and actor.aim_point().distance_to(end) < weapon.splash and clear_shot(end + ray_direction * -0.1, actor.aim_point(), player, actor):
					actor.take_damage(weapon.damage / 2)
					hit_time = 0.18

func aim_point(target: Node3D) -> Vector3:
	if target == player: return player.position + Vector3(0, 1.2, 0)
	if target is FrontierActor: return target.aim_point()
	return town.bell.global_position + Vector3(0, 1.8, 0)

func clear_shot(from: Vector3, to: Vector3, shooter: Node3D, target: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 2 | 4 | 8 | 16)
	if shooter is CollisionObject3D: query.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target

func pick_target(actor: FrontierActor) -> Node3D:
	var target: Node3D = null
	var best := INF
	if not actor.friendly:
		target = town.bell
		best = actor.position.distance_to(town.bell.position) * 0.85
		if actor.position.distance_to(player.position) < best:
			target = player
			best = actor.position.distance_to(player.position)
	var candidates: Array[FrontierActor] = hostiles if actor.friendly else allies
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate.dead: continue
		var distance := actor.position.distance_to(candidate.position)
		if distance < best:
			best = distance
			target = candidate
	return target

func damage_target(target: Node3D, damage: int) -> void:
	if not is_playing() or phase != "night": return
	if target == player:
		FrontierRules.hurt(state, damage)
		hurt_time = 0.3
		if state.health == 0: lose_night()
	elif target == town.bell:
		town_health = maxi(0, town_health - damage)
		damage_number(aim_point(town.bell), damage, true)
		if town_health == 0: lose_night()
	elif target is FrontierActor:
		target.take_damage(damage)

func actor_defeated(actor: FrontierActor) -> void:
	if not actor.friendly:
		state.money += FrontierRules.ENEMIES[actor.kind].reward
		state.kills += 1
	else:
		tell("A %s is resting. They'll be back at dawn!" % actor.kind, 4)

func damage_number(pos: Vector3, damage: int, friendly: bool) -> void:
	var label := FrontierVisuals.label(self, "−%d" % damage, pos + Vector3(0, 0.8, 0), Color("#ffa997") if friendly else Color("#fff1a8"), 24)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.2, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(label.queue_free)

func tracer(from: Vector3, to: Vector3, color: Color) -> void:
	if from.distance_to(to) < 0.01: return
	var beam := FrontierVisuals.box(self, (from + to) / 2, Vector3(0.025, 0.025, from.distance_to(to)), color)
	beam.look_at(to)
	var tween := create_tween()
	tween.tween_interval(0.065)
	tween.tween_callback(beam.queue_free)

func _party_burst(pos: Vector3) -> void:
	for index in 12:
		var piece := FrontierVisuals.box(self, pos, Vector3.ONE * 0.16, Color.from_hsv(index / 12.0, 0.45, 1))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(piece, "position", pos + Vector3(randf_range(-2, 2), randf_range(0.1, 2), randf_range(-2, 2)), 0.4)
		tween.tween_property(piece, "scale", Vector3.ZERO, 0.5)
		tween.chain().tween_callback(piece.queue_free)

func tell(text: String, seconds: float = 4.0) -> void:
	notice_text = text
	notice_time = seconds

func _sound(stream: AudioStreamWAV) -> void:
	audio.stream = stream
	audio.play()

func _beep(frequency: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for index in samples:
		var envelope := 1.0 - float(index) / samples
		data.encode_s16(index * 2, int(sin(TAU * frequency * float(index) / rate) * 6500 * envelope))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
