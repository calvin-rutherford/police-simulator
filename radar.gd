extends Control
class_name FrontierRadar

var game: Node3D

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#29394a"))
	var center := size / 2
	var scale_factor := 1.55
	for side in [-1, 1]:
		for z in [-23, -7, 9, 25]:
			draw_rect(Rect2(center + Vector2(side * 16 - 4, z - 5) * scale_factor, Vector2(8, 10) * scale_factor), Color("#997f6b"))
	draw_line(center + Vector2(0, -70), center + Vector2(0, 70), Color("#655d59"), 13)
	draw_circle(center + Vector2(0, -3) * scale_factor, 4, Color("#f4d17b"))
	if not is_instance_valid(game.player): return
	for actor in game.hostiles + game.allies:
		if is_instance_valid(actor) and not actor.dead:
			var dot := center + Vector2(actor.position.x, actor.position.z) * scale_factor
			draw_circle(dot.clamp(Vector2(4, 4), size - Vector2(4, 4)), 3, Color("#a9e2d4") if actor.friendly else Color("#fa988b"))
	var player_pos := center + Vector2(game.player.position.x, game.player.position.z) * scale_factor
	player_pos = player_pos.clamp(Vector2(5, 5), size - Vector2(5, 5))
	draw_circle(player_pos, 4.5, Color.WHITE)
	var facing := Vector2(-sin(game.player.rotation.y), -cos(game.player.rotation.y))
	draw_line(player_pos, player_pos + facing * 11, Color.WHITE, 2)
