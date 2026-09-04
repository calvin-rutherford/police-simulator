extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	check(scene.civilians.size() == 5, "street spawns five civilians")
	check(scene.player.gun_drawn, "sidearm starts drawable")
	var start_z: float = scene.player.global_position.z
	Input.action_press("move_forward")
	for _frame in 12:
		await physics_frame
	Input.action_release("move_forward")
	check(scene.player.global_position.z < start_z, "WASD forward input moves player")
	var before_shots: int = scene.shots_fired
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	scene.player._unhandled_input(mouse)
	await process_frame
	check(scene.shots_fired == before_shots + 1, "click fires hitscan without ammo limit")
	var q_key := InputEventKey.new()
	q_key.keycode = KEY_Q
	q_key.pressed = true
	scene.player._unhandled_input(q_key)
	check(not scene.player.gun_drawn, "Q holsters the sidearm")
	scene.player._unhandled_input(q_key)
	check(scene.player.gun_drawn, "Q draws the sidearm again")
	scene.reset_game()
	scene.test_unsafe_shot()
	check(scene.get_status_snapshot()["fleeing"] > 0, "nearby civilians enter flee state after unsafe shot")
	scene.reset_game()
	scene.test_fire_at_civilian(0)
	scene.test_fire_at_civilian(1)
	scene.test_fire_at_civilian(2)
	check(scene.get_status_snapshot()["kills"] == 3, "civilian warning meter increments on valid hits")
	check(scene.get_status_snapshot()["police"], "police pursue at documented three-kill threshold")
	scene.reset_game()
	var reset_snapshot: Dictionary = scene.get_status_snapshot()
	check(reset_snapshot["kills"] == 0 and not reset_snapshot["police"] and not reset_snapshot["caught"], "R/reset clears consequence state")
	check(scene.civilians[0].active and not scene.civilians[0].is_fleeing(), "reset restores civilians")
	var passed := failures.is_empty()
	await create_timer(0.2).timeout
	scene.queue_free()
	await process_frame
	if passed:
		print("SMOKE PASS: movement, fire, flee, threshold pursuit, reset")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("SMOKE FAIL: %d checks" % failures.size())
		quit(1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
