extends SceneTree

var failures: Array[String] = []
var checks := 0
const SAVE := "res://.cache/test_checkpoint.json"

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(SAVE + suffix)

func _rules() -> void:
	var state := FrontierRules.new_state()
	check(FrontierRules.valid_state(state), "new state validates")
	check(state.money == 220 and state.weapons == ["revolver", "shotgun"], "starting wage and both starter weapons")
	check(FrontierRules.wave(1).size() == 4 and FrontierRules.wave(3).size() == 8, "waves grow")
	check("zombie" in FrontierRules.wave(4) and "monster" in FrontierRules.wave(7), "later archetypes unlock")
	check(FrontierRules.wave(100).size() == 36, "wave cap bounds scene cost")
	var before: int = state.money
	check(not FrontierRules.buy(state, "confetti").is_empty() and state.money == before, "unaffordable purchase is atomic")
	check(not FrontierRules.buy(state, "confetti_ammo").is_empty(), "cannon ammunition requires cannon")
	state.money = 10000
	check(FrontierRules.build(state, "guard_post", 0).is_empty(), "guard post starts construction")
	check(FrontierRules.build(state, "tower", 1).is_empty(), "tower starts construction")
	before = state.money
	check(not FrontierRules.build(state, "tower", 2).is_empty() and state.structures.size() == 2 and state.money == before, "combined two-structure limit is atomic")
	check(state.structures[0].remaining == 1 and state.structures[1].remaining == 2, "different construction durations")
	var fresh := FrontierRules.new_state()
	check(not FrontierRules.build(fresh, "tower", 0).is_empty() and fresh.money == 220, "unaffordable build is atomic")
	check(not FrontierRules.build(fresh, "guard_post", -1).is_empty(), "invalid site rejected")
	FrontierRules.build(fresh, "guard_post", 0)
	fresh.money = 500
	check(not FrontierRules.build(fresh, "tower", 0).is_empty() and fresh.money == 500, "occupied site rejected")
	check(FrontierRules.buy(state, "food").is_empty() and state.food == 3, "food purchases real inventory")
	check(not FrontierRules.eat(state) and state.food == 3, "full-health snack is not wasted")
	state.health = 45
	check(FrontierRules.eat(state) and state.health == 85 and state.food == 2, "snack heals and consumes one")
	check(FrontierRules.eat(state) and state.health == 100, "snack health capped")
	for _i in 6: FrontierRules.buy(state, "deputy")
	check(not FrontierRules.buy(state, "deputy").is_empty() and state.deputies == 6, "six-deputy limit")
	check(FrontierRules.buy(state, "confetti").is_empty() and state.ammo.confetti == 20, "novelty weapon unlock includes ammo")
	check(not FrontierRules.buy(state, "confetti").is_empty(), "duplicate unlock rejected")
	FrontierRules.buy(state, "armor")
	FrontierRules.hurt(state, 80)
	check(state.armor == 0 and state.health == 95, "armor absorbs damage before health")
	FrontierRules.hurt(state, -30)
	check(state.health == 95, "negative damage cannot heal")
	for _i in 6: check(FrontierRules.consume_shot(state), "loaded revolver fires")
	check(not FrontierRules.consume_shot(state), "empty magazine cannot fire")
	check(state.ammo.revolver == 42, "ammunition is consumed once per shot")
	FrontierRules.reload_weapon(state, "revolver")
	check(state.loaded.revolver == 6 and state.ammo.revolver == 42, "reload moves reserve without creating ammunition")
	before = state.money
	state.ammo.shotgun = 0
	FrontierRules.dawn(state)
	check(state.day == 2 and state.money == before + FrontierRules.wage(2), "exactly one next-day wage")
	check(state.health == 100 and state.ammo.shotgun == 8, "dawn heals and provides supply floor")
	check(state.structures[0].remaining == 0 and state.structures[1].remaining == 1, "post completes after one won night, tower halfway")
	check(state.deputies == 6 and "confetti" in state.weapons, "permanent purchases survive dawn")
	FrontierRules.dawn(state)
	check(state.structures[1].remaining == 0, "tower completes after two won nights")
	FrontierRules.dawn(state)
	check(state.structures[0].remaining == 0, "finished construction never underflows")
	_cleanup()
	var store := FrontierSave.new(SAVE)
	check(store.load_game().is_empty(), "no save returns an empty result")
	state.position = [2.0, 0.1, 10.0]
	state.yaw = 0.8
	check(store.save_game(state), "checkpoint write")
	var restored := store.load_game()
	check(restored == state, "full save/load round trip including purchases, ammo, health, pose and progression")
	state.money += 10
	check(store.save_game(state), "atomic checkpoint rotation")
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string("broken JSON")
	file.close()
	check(store.load_game() == restored and not store.last_error.is_empty(), "corrupt primary recovers backup")
	var bad := state.duplicate(true)
	bad.structures.append({"site": 2, "kind": "tower", "remaining": 1})
	check(not store.save_game(bad) and store.load_game() == restored, "invalid state cannot destroy checkpoint")
	bad = state.duplicate(true)
	bad.structures[1].site = 0
	check(not FrontierRules.valid_state(bad), "duplicate saved site rejected")
	bad = state.duplicate(true)
	bad.structures[0].remaining = 2
	check(not FrontierRules.valid_state(bad), "impossible saved duration rejected")
	bad = state.duplicate(true)
	bad.food = -1
	check(not FrontierRules.valid_state(bad), "negative food rejected")
	bad = state.duplicate(true)
	bad.ammo.revolver = "oops"
	check(not FrontierRules.valid_state(bad), "malformed ammo rejected")
	bad = state.duplicate(true)
	bad.position = [0, INF, 0]
	check(not FrontierRules.valid_state(bad), "non-finite position rejected")
	bad = state.duplicate(true)
	bad.version = 999
	check(not FrontierRules.valid_state(bad), "unknown version rejected")
	var legacy := state.duplicate(true)
	legacy.version = 1
	legacy.turrets = 4
	legacy.erase("structures")
	legacy.erase("food")
	file = FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var migrated := store.load_game()
	check(migrated.structures.size() == 2 and migrated.money == state.money + 700 and migrated.version == 2, "old slice migrates two turrets and refunds extras")
	check(migrated.structures[0].site is int and migrated.food is int, "JSON construction/inventory counters restore as integers")
	var preset := ConfigFile.new()
	preset.load("res://export_presets.cfg")
	check(not preset.get_value("preset.0.options", "variant/thread_support", true), "Web export needs no cross-origin isolation")
	_cleanup()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.cache")
	_rules()
	var game: SunsetSheriffGame = load("res://main.tscn").instantiate()
	game.saves = FrontierSave.new(SAVE)
	root.add_child(game)
	await process_frame
	check(game.mode == "title" and game.ui.load_button.disabled, "launch title handles missing save")
	check(game.town.residents.size() >= 22, "homes, saloon and shops populated")
	check(game.hostiles.is_empty(), "civilians are never hostiles")
	game.ui.new_button.pressed.emit()
	await physics_frame
	await physics_frame
	check(game.mode == "playing" and game.phase == "day", "New Game enters playable daytime")
	var start_z := game.player.position.z
	Input.action_press("move_forward")
	for _i in 12: await physics_frame
	Input.action_release("move_forward")
	check(game.player.position.z < start_z, "WASD movement works")
	game.player.position = Vector3(-9.6, 0.1, -23)
	game.interact()
	check(game.mode == "shop" and game.current_shop == "Gunsmith", "porch E interaction opens correct shop")
	var money: int = game.state.money
	game.purchase("ammo")
	check(game.state.money == money - 35 and game.saves.load_game().money == game.state.money, "shop purchase saves immediately")
	game.resume_game()
	game.player.position = Vector3(0, 0.1, 29)
	game.state.money = 2000
	game.current_shop = "Sheriff Office"
	game._set_mode("shop")
	game.purchase("deputy")
	game.current_site = 0
	game._set_mode("build")
	game.construct("guard_post")
	game.current_site = 1
	game.construct("tower")
	check(game.allies.size() == 1 and game.state.structures.size() == 2, "construction has no instant guard benefit")
	check(game.saves.load_game().structures[1].remaining == 2, "construction purchase saves immediately")
	var before_failure := game.state.duplicate(true)
	game.saves = FrontierSave.new("res://.cache/missing/directory/save.json")
	game.current_shop = "Saloon"
	game._set_mode("shop")
	game.purchase("food")
	check(game.state == before_failure, "failed purchase save refunds money and inventory")
	game.saves = FrontierSave.new(SAVE)
	game.purchase("food")
	check(game.state.food == 3, "saloon purchase works through game UI")
	game.resume_game()
	game.start_night()
	var checkpoint := game.saves.load_game()
	check(game.phase == "night" and game.wave_queue.size() == 4, "N begins first wave and sunset save")
	game.wave_queue.clear()
	var foe := game._spawn_hostile("bandit")
	foe.position = Vector3(0, 0.1, 24)
	await physics_frame
	await physics_frame
	var origin := game.player.camera.global_position
	game.fire(origin, (foe.aim_point() - origin).normalized())
	check(foe.health == 39 and game.state.loaded.revolver == 5, "raycast hit depletes hostile health and ammo")
	game.select_weapon(1)
	game.shot_time = 0
	game.fire(origin, (foe.aim_point() - origin).normalized())
	check(foe.dead, "shotgun pellet spread defeats a close foe")
	await physics_frame
	await process_frame
	check(game.phase == "day" and game.mode == "dawn" and game.state.day == 2, "last foe triggers dawn victory and advancement")
	check(game.state.money == checkpoint.money + 12 + FrontierRules.wage(2), "victory includes bounty and one wage")
	check(game.state.structures[0].remaining == 0 and game.state.structures[1].remaining == 1 and game.allies.size() == 2, "dawn creates finished guard and tower scaffold progress")
	game.resume_game()
	game.start_night()
	game.wave_queue.clear()
	foe = game._spawn_hostile("zombie")
	foe.position = Vector3(0, 0.1, 8)
	await physics_frame
	await physics_frame
	var health := foe.health
	# Exercise actual deputy and turret AI attacks against a visible target.
	for ally in game.allies:
		ally.cooldown = 0
		ally._physics_process(0.02)
	check(foe.health < health, "deputy/turret AI damages hostiles")
	var ally: FrontierActor = game.allies[0]
	game.damage_target(ally, 999)
	check(ally.dead and ally.health == 0, "defenders have depleting health and are disabled when defeated")
	game.state.armor = 10
	game.damage_target(game.player, 25)
	check(game.state.health == 85 and game.state.armor == 0, "player combat damage respects armor")
	game.damage_target(game.town.bell, 300)
	check(game.mode == "defeat", "bell destruction causes town takeover failure")
	game.load_game()
	check(game.mode == "playing" and game.phase == "day" and game.state.day == 2 and game.state.health == 100, "retry restores sunset without duplicating wages")
	check(game.allies.size() == 2 and not game.allies[0].dead, "retry restores purchased defenders")
	check(game.state.structures[1].remaining == 1 and game.state.food == 3, "failure/reload does not advance construction or lose sunset food")
	game.start_night()
	game.damage_target(game.player, 1000)
	check(game.mode == "defeat" and game.state.health == 0, "player defeat transition")
	game.load_game()
	game.return_to_title()
	check(not game.ui.load_button.disabled, "title tracks saved progress and enables Load")
	game.ui.load_button.pressed.emit()
	check(game.state.day == 2 and game.mode == "playing", "Load button restores playable progress")
	check(game.town.route(Vector3(-40, 0, -23), Vector3(0, 0, -23)).size() > 15, "hostile routes go around buildings")
	check(game.audio.unlocked, "button interaction unlocks audio")
	game.audio.toggle_mute()
	check(game.audio.muted, "mute control works")
	game.audio.toggle_mute()
	game.audio.stop()
	game.queue_free()
	# Let the audio mixer release short-lived playback resources before shutdown.
	await create_timer(0.25).timeout
	_cleanup()
	print("SUNSET SHERIFF: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
