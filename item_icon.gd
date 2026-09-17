extends Control
class_name FrontierIcon

var kind := "food"
var tint := Color("#f4cd7c")
var face := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / 64.0)
	match kind:
		"health":
			draw_circle(Vector2(21, 22), 15, Color("#f29c88"))
			draw_circle(Vector2(43, 22), 15, Color("#f29c88"))
			draw_colored_polygon(PackedVector2Array([Vector2(7, 27), Vector2(57, 27), Vector2(32, 59)]), Color("#f29c88"))
		"food", "medicine":
			draw_circle(Vector2(32, 33), 24, Color("#f3e1b7"))
			for p in [Vector2(23, 26), Vector2(41, 26), Vector2(32, 42)]:
				draw_circle(p, 10, Color("#ce965d"))
				draw_circle(p - Vector2(2, 2), 2, Color("#825b45"))
		"armor":
			draw_colored_polygon(PackedVector2Array([Vector2(10, 12), Vector2(24, 8), Vector2(32, 17), Vector2(40, 8), Vector2(54, 12), Vector2(48, 32), Vector2(49, 56), Vector2(15, 56), Vector2(16, 32)]), Color("#89c5d0"))
			draw_line(Vector2(32, 19), Vector2(32, 54), Color("#e8e1b6"), 3)
		"ammo", "confetti_ammo", "confetti":
			for x in [14, 30, 46]:
				draw_rect(Rect2(x - 5, 23, 11, 31), tint)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 23), Vector2(x, 10), Vector2(x + 6, 23)]), Color("#e1a675"))
		"guard_post", "tower":
			var top := 12 if kind == "tower" else 30
			for x in [15, 45]: draw_line(Vector2(x, top), Vector2(x, 57), Color("#cfa477"), 6)
			draw_rect(Rect2(8, top, 49, 9), tint)
			draw_line(Vector2(15, top + 12), Vector2(45, 54), Color("#cfa477"), 4)
			draw_colored_polygon(PackedVector2Array([Vector2(6, top), Vector2(32, top - 11), Vector2(58, top)]), Color("#9acabb"))
		"keeper", "deputy":
			var skin := Color(["#f5cba1", "#c48d66", "#8c5d48", "#dfad87"][face % 4])
			draw_rect(Rect2(10, 43, 44, 21), tint)
			draw_rect(Rect2(18, 19, 28, 29), skin)
			draw_rect(Rect2(20, 7, 24, 16), tint.lightened(0.25))
			draw_rect(Rect2(9, 19, 46, 6), tint.lightened(0.25))
			for x in [25, 39]: draw_circle(Vector2(x, 32), 2, Color("#343443"))
			draw_line(Vector2(27, 41), Vector2(36, 41), Color("#975954"), 2)
		"boots":
			for x in [12, 36]:
				draw_rect(Rect2(x, 12, 12, 32), Color("#ce965d"))
				draw_rect(Rect2(x, 40, 23, 13), tint)
		"sound", "muted":
			draw_colored_polygon(PackedVector2Array([Vector2(8, 25), Vector2(20, 25), Vector2(34, 13), Vector2(34, 51), Vector2(20, 39), Vector2(8, 39)]), tint)
			if kind == "muted":
				draw_line(Vector2(42, 23), Vector2(57, 41), Color("#ff9d8a"), 5)
				draw_line(Vector2(57, 23), Vector2(42, 41), Color("#ff9d8a"), 5)
			else:
				draw_arc(Vector2(33, 32), 19, -0.9, 0.9, 12, tint, 4)
		_: draw_circle(Vector2(32, 32), 23, tint)
