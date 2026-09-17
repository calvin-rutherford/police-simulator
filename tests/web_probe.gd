extends Node

# Compiled only into the separate local validation export. Never a production URL cheat.
var game: SunsetSheriffGame
var callback: JavaScriptObject
var elapsed := 0.0

func setup(owner_game: SunsetSheriffGame) -> void:
	game = owner_game
	callback = JavaScriptBridge.create_callback(_command)
	JavaScriptBridge.get_interface("window").frontierCommand = callback
	_publish()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 0.15:
		elapsed = 0
		_publish()

func _publish() -> void:
	var snapshot := {"mode": game.mode, "phase": game.phase, "state": game.state,
		"audio_unlocked": game.audio.unlocked, "muted": game.audio.muted, "ambience": game.audio.ambience.playing,
		"sound_context": game.audio.context, "shop": game.current_shop, "allies": game.allies.size(),
		"foes": game.remaining_foes(), "fps": Engine.get_frames_per_second(),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"residents": game.town.residents.size(), "save_error": game.saves.last_error,
		"reload": game.reload_time, "hurt": game.hurt_time, "recoil": game.player.recoil,
		"position": [game.player.position.x, game.player.position.y, game.player.position.z]}
	JavaScriptBridge.eval("window.frontier = " + JSON.stringify(snapshot), true)

func _command(args: Array) -> void:
	if args.is_empty(): return
	var request: Variant = JSON.parse_string(str(args[0]))
	if not request is Dictionary: return
	match request.get("action", ""):
		"new": game.ui.new_button.pressed.emit()
		"load": game.load_game()
		"resume": game.resume_game()
		"title": game.return_to_title()
		"shop":
			game.resume_game()
			for shop in game.town.shops:
				if shop.name == request.id:
					game.player.position = shop.position + Vector3(0, 0.1, 0)
					game.interact()
					break
		"buy": game.purchase(request.id)
		"site":
			game.resume_game()
			game.player.position = FrontierTown.PADS[int(request.site)] + Vector3(0, 0.1, 0)
			game.interact()
		"build": game.construct(request.id)
		"night":
			game.resume_game()
			game.player.position = Vector3(0, 0.1, 29)
			game.player.rotation.y = 0
			game.start_night()
		"arena":
			game.wave_queue.clear()
			game._clear_actors()
			var foe := game._spawn_hostile("bandit")
			foe.position = Vector3(0, 0.1, 24)
			foe.cooldown = 30
		"fire":
			for foe in game.hostiles:
				if is_instance_valid(foe) and not foe.dead:
					game.fire(game.player.camera.global_position, (foe.aim_point() - game.player.camera.global_position).normalized())
					break
		"reload": game.reload_gun()
		"hurt": game.damage_target(game.player, int(request.amount))
		"eat": game.eat_food()
		"clear":
			game.wave_queue.clear()
			for foe in game.hostiles:
				if is_instance_valid(foe) and not foe.dead: foe.take_damage(999)
		"bell_failure": game.damage_target(game.town.bell, 300)
		"view_saloon":
			game.resume_game()
			game.player.position = Vector3(-15, 0.1, -7)
			game.player.rotation.y = PI / 2
			game.player.head.rotation.x = 0
		"view_keeper":
			game.resume_game()
			game.player.position = Vector3(16, 0.1, -23)
			game.player.rotation.y = -PI / 2
			game.player.head.rotation.x = 0
	_publish()
