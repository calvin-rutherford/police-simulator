extends CanvasLayer
class_name FrontierUI

const INK := Color("#29394a")
const CREAM := Color("#fff0cf")
const GOLD := Color("#f4cd7c")
const MINT := Color("#a5dcca")
var game: Node3D
var hud: Control
var modal: Control
var stats: Label
var phase_label: Label
var weapon_label: Label
var prompt: Label
var notice: Label
var crosshair: Label
var flash: ColorRect
var radar: FrontierRadar
var load_button: Button
var new_button: Button
var shop_feedback: Label
var sound_controls: Control
var sound_button: Button
var sound_icon: FrontierIcon
var health_value: Label
var armor_value: Label

func setup(owner_game: Node3D) -> void:
	game = owner_game
	_build_hud()
	sound_controls = Control.new()
	add_child(sound_controls)
	sound_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sound_button = _button(sound_controls, "M  Sound", Rect2(1100, 250, 160, 42), game.audio.toggle_mute)
	sound_icon = _icon(sound_controls, "sound", Vector2(1056, 250), 42)
	var volume := HSlider.new()
	sound_controls.add_child(volume)
	volume.position = Vector2(1100, 301)
	volume.size = Vector2(160, 25)
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = game.audio.volume
	volume.tooltip_text = "Sound volume"
	volume.value_changed.connect(game.audio.set_volume)

func _icon(parent: Node, kind: String, pos: Vector2, width: float = 60, tint: Color = GOLD, face: int = 0) -> FrontierIcon:
	var icon := FrontierIcon.new()
	icon.kind = kind
	icon.tint = tint
	icon.face = face
	icon.position = pos
	icon.size = Vector2.ONE * width
	parent.add_child(icon)
	return icon

func _panel(parent: Node, rect: Rect2, color: Color = INK) -> Panel:
	var panel := Panel.new()
	parent.add_child(panel)
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_bottom = 3
	style.border_color = Color("#182735")
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _label(parent: Node, text: String, pos: Vector2, font_size: int = 20, color: Color = CREAM) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.position = pos
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", INK if primary else CREAM)
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = (GOLD if primary else Color("#4c6674")).lightened(0.12 if state_name == "hover" else 0)
		if state_name == "disabled": style.bg_color = Color("#58606a")
		style.set_corner_radius_all(9)
		if state_name == "focus":
			style.set_border_width_all(2)
			style.border_color = MINT
		button.add_theme_stylebox_override(state_name, style)
	button.pressed.connect(func():
		game.audio.unlock()
		game.audio.play("ui")
		action.call())
	return button

func _build_hud() -> void:
	hud = Control.new()
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := _panel(hud, Rect2(20, 18, 1010, 98))
	_label(top, "*  SUNSET SHERIFF", Vector2(18, 10), 18, GOLD)
	_icon(top, "health", Vector2(16, 45), 30)
	health_value = _label(top, "", Vector2(52, 42), 25)
	_icon(top, "armor", Vector2(120, 44), 30)
	armor_value = _label(top, "", Vector2(156, 42), 25)
	stats = _label(top, "", Vector2(225, 42), 25)
	_icon(top, "food", Vector2(420, 45), 30)
	phase_label = _label(top, "", Vector2(545, 12), 21, MINT)
	var map_panel := _panel(hud, Rect2(1050, 18, 210, 216))
	_label(map_panel, "N  /  TOWN TRAILS", Vector2(16, 8), 15, GOLD)
	radar = FrontierRadar.new()
	map_panel.add_child(radar)
	radar.position = Vector2(15, 35)
	radar.size = Vector2(180, 153)
	radar.game = game
	radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(map_panel, "YOU •  ALLY •  FOE •", Vector2(14, 192), 13, MINT)
	var bottom := _panel(hud, Rect2(20, 603, 1240, 98))
	weapon_label = _label(bottom, "", Vector2(18, 10), 23, GOLD)
	_label(bottom, "WASD  move   •   MOUSE  aim   •   CLICK  fire   •   R  reload   •   Q / 1–3  weapon   •   SPACE  jump", Vector2(18, 46), 17)
	_label(bottom, "E  interact     F  eat snack (+40)     N  start night     M  sound     ESC  pause", Vector2(18, 71), 14, MINT)
	prompt = _label(hud, "", Vector2(170, 540), 22, CREAM)
	prompt.size.x = 940
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_outline_color", INK)
	prompt.add_theme_constant_override("outline_size", 6)
	notice = _label(hud, "", Vector2(140, 132), 20, GOLD)
	notice.size.x = 880
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_color_override("font_outline_color", INK)
	notice.add_theme_constant_override("outline_size", 6)
	crosshair = _label(hud, "+", Vector2(626, 338), 30, CREAM)
	flash = ColorRect.new()
	add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 0.5, 0.4, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

func clear_modal() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = Control.new()
	add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(sound_controls): move_child(sound_controls, get_child_count() - 1)

func _shade() -> void:
	var shade := ColorRect.new()
	modal.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.08, 0.13, 0.2, 0.57)

func show_title(saved: Dictionary, message: String = "") -> void:
	clear_modal()
	hud.hide()
	var panel := _panel(modal, Rect2(65, 60, 530, 605), Color("#293c4c"))
	_label(panel, "A LITTLE TOWN. A BIG SHERIFF HEART.", Vector2(32, 29), 17, MINT)
	_label(panel, "SUNSET\nSHERIFF", Vector2(28, 63), 62, GOLD)
	_label(panel, "Build your posse. Protect your people.", Vector2(32, 216), 22)
	_label(panel, "Shop in the sunshine. Defend after dark.\nA cozy, block-built frontier adventure.", Vector2(32, 257), 19)
	var progress := "No checkpoint yet — your town is waiting!"
	if not saved.is_empty():
		progress = "DAY %d  •  $%d  •  %d foes stopped\n%d deputies  /  %d of 2 defenses  /  %d snacks" % [saved.day, saved.money, saved.kills, saved.deputies, saved.structures.size(), saved.food]
	_label(panel, progress, Vector2(32, 326), 19, MINT)
	new_button = _button(panel, "*  New Game", Rect2(32, 404, 220, 55), _confirm_new if not saved.is_empty() else game.new_game, true)
	load_button = _button(panel, "Load Game", Rect2(266, 404, 230, 55), game.load_game)
	load_button.disabled = saved.is_empty()
	_label(panel, "Keyboard + mouse  •  Local autosave\nNight retries return to your sunset checkpoint.", Vector2(32, 480), 17)
	var info := _label(panel, message, Vector2(32, 536), 15, GOLD)
	info.size = Vector2(465, 56)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var badge := _panel(modal, Rect2(855, 539, 359, 104), Color("#384d58"))
	_label(badge, "HOWDY, PARTNER!", Vector2(20, 15), 23, GOLD)
	_label(badge, "Original primitive art. No gore.\nYour neighbors are always safe.", Vector2(20, 49), 17)

func _confirm_new() -> void:
	clear_modal()
	_shade()
	var panel := _panel(modal, Rect2(350, 208, 580, 300))
	_label(panel, "Start a fresh frontier?", Vector2(30, 25), 31, GOLD)
	_label(panel, "New Game replaces your local checkpoint.\nYour current town will be left behind.", Vector2(30, 89), 21)
	_button(panel, "Keep my town", Rect2(30, 205, 240, 55), game.show_title)
	_button(panel, "New Game", Rect2(290, 205, 260, 55), game.new_game, true)

func show_pause() -> void:
	clear_modal()
	_shade()
	var panel := _panel(modal, Rect2(375, 151, 530, 416))
	_label(panel, "TAKE A BREATHER", Vector2(32, 28), 31, GOLD)
	_label(panel, "The town is paused.\nDay progress autosaves. At night, Load\nreturns to your pre-wave sunset checkpoint.", Vector2(32, 89), 20)
	_button(panel, "Back to town", Rect2(32, 205, 466, 58), game.resume_game, true)
	_button(panel, "Save & title" if game.phase == "day" else "Title (keep sunset save)", Rect2(32, 281, 466, 54), game.return_to_title)

func show_result(victory: bool) -> void:
	clear_modal()
	_shade()
	var panel := _panel(modal, Rect2(320, 163, 640, 395))
	_label(panel, "SUNRISE! TOWN SAFE" if victory else "THE TOWN NEEDS YOU", Vector2(30, 26), 31, GOLD)
	var text: String
	if victory:
		text = "Night %d cleared! Day %d wage: +$%d\nHealth, town, and defenders restored.\nDaily supplies: at least 24 rounds + 8 shells.\nShop, explore, then ring the bell again." % [game.state.day - 1, game.state.day, FrontierRules.wage(game.state.day)]
	else:
		text = "The bell fell silent." if game.town_health <= 0 else "You ran out of sheriff sparkle."
		text += "\nNo worries! Retry from your sunset checkpoint.\nYour pre-night purchases and coins are safe.\nYou can prepare differently before trying again."
	_label(panel, text, Vector2(30, 92), 21)
	_button(panel, "Prepare for tonight" if victory else "Retry sunset checkpoint", Rect2(30, 254, 580, 54), game.resume_game if victory else game.load_game, true)
	_button(panel, "Back to title", Rect2(30, 322, 580, 44), game.return_to_title)

func show_shop(shop: String, feedback: String = "", success: bool = false) -> void:
	clear_modal()
	_shade()
	var panel := _panel(modal, Rect2(220, 40, 840, 640))
	var keeper: Dictionary = FrontierTown.KEEPERS[shop]
	_icon(panel, "keeper", Vector2(25, 18), 80, Color(keeper.color), keeper.face)
	_label(panel, "%s • %s" % [keeper.name, shop], Vector2(120, 16), 28, GOLD)
	_label(panel, keeper.line, Vector2(120, 54), 17)
	_label(panel, "$%d    HP %d    Vest %d    Snacks %d" % [game.state.money, game.state.health, game.state.armor, game.state.food], Vector2(120, 83), 22, MINT)
	var row := 0
	for id in FrontierRules.CATALOG:
		var item: Dictionary = FrontierRules.CATALOG[id]
		if item.shop != shop: continue
		var card := _panel(panel, Rect2(24, 135 + row * 105, 792, 96), Color("#3b5260"))
		_icon(card, id, Vector2(12, 15))
		_label(card, item.name, Vector2(86, 12), 22)
		_label(card, item.description, Vector2(86, 50), 16, MINT)
		_button(card, "$%d  +" % item.price, Rect2(624, 20, 150, 54), game.purchase.bind(id), true)
		row += 1
	if shop == "Saloon":
		_icon(panel, "food", Vector2(55, 285), 100)
		_label(panel, "F  >  HP +40\nTake your picnic into the night!", Vector2(185, 300), 27, MINT)
	if shop == "Sheriff Office":
		_icon(panel, "guard_post", Vector2(55, 285), 90)
		_icon(panel, "tower", Vector2(175, 285), 90)
		_label(panel, "Build on the striped sites outside.\n$150 post / $280 tower • 2 defenses total", Vector2(295, 300), 20, MINT)
	shop_feedback = _label(panel, ("+  " if success else "!  ") + feedback if not feedback.is_empty() else "", Vector2(28, 465), 21, MINT if success else GOLD)
	shop_feedback.size = Vector2(780, 65)
	shop_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(panel, "%d / 6 deputies    •    %d / 2 defenses    •    F eats a snack" % [game.state.deputies, game.state.structures.size()], Vector2(28, 536), 19, MINT)
	_button(panel, "<  Back to town  [E / Esc]", Rect2(26, 580, 788, 44), game.resume_game)

func show_build(site: int, feedback: String = "") -> void:
	clear_modal()
	_shade()
	var panel := _panel(modal, Rect2(240, 55, 800, 605))
	_label(panel, "+  BUILD A DEFENSE", Vector2(30, 20), 32, GOLD)
	_label(panel, "$%d     %d / 2 defenses    •    Site %d" % [game.state.money, game.state.structures.size(), site + 1], Vector2(30, 66), 24, MINT)
	_label(panel, "Win nights to finish. Your guards protect the bell!", Vector2(30, 105), 20)
	var occupied: Dictionary = {}
	for structure in game.state.structures:
		if structure.site == site: occupied = structure
	var row := 0
	for kind in FrontierRules.STRUCTURES:
		var spec: Dictionary = FrontierRules.STRUCTURES[kind]
		var card := _panel(panel, Rect2(25, 154 + row * 135, 750, 120), Color("#3b5260"))
		_icon(card, kind, Vector2(15, 15), 86)
		_label(card, spec.name, Vector2(120, 10), 26)
		_label(card, ("NIGHT  >  *  One night" if spec.nights == 1 else "NIGHT  NIGHT  >  *  Two nights") + ("\nClose guard • 22 power" if spec.nights == 1 else "\nHigh lookout • 32 power / longer reach"), Vector2(120, 50), 19, MINT)
		var buy := _button(card, "$%d  +" % spec.price, Rect2(575, 30, 152, 55), game.construct.bind(kind), true)
		buy.disabled = not occupied.is_empty() or game.state.structures.size() >= 2
		row += 1
	if not occupied.is_empty():
		var spec: Dictionary = FrontierRules.STRUCTURES[occupied.kind]
		feedback = "%s: %d / %d nights  %s" % [spec.name, spec.nights - occupied.remaining, spec.nights, "* READY" if occupied.remaining == 0 else "> Win the next night"]
	_label(panel, feedback, Vector2(30, 447), 22, GOLD)
	_button(panel, "<  Back to town  [E / Esc]", Rect2(25, 528, 750, 52), game.resume_game)

func refresh() -> void:
	sound_button.text = "M  Muted" if game.audio.muted else "M  Sound"
	sound_icon.kind = "muted" if game.audio.muted else "sound"
	sound_icon.queue_redraw()
	if game.state.is_empty(): return
	var state: Dictionary = game.state
	health_value.text = str(state.health)
	armor_value.text = str(state.armor)
	stats.text = "$%d   F: %d" % [state.money, state.food]
	if game.phase == "day":
		phase_label.text = "DAY %d  >  NIGHT  >  $ DAWN\n%d / 2 defenses  •  N to start night" % [state.day, state.structures.size()]
	else:
		phase_label.text = "NIGHT %d / DEFEND\n%d foes left  •  Bell %d / 300" % [state.day, game.remaining_foes(), game.town_health]
	var id: String = state.selected
	weapon_label.text = "%s   %d / %d loaded   •   %d reserve     %s" % [FrontierRules.WEAPONS[id].name, state.loaded[id], FrontierRules.WEAPONS[id].magazine, state.ammo[id] - state.loaded[id], "RELOADING..." if game.reload_time > 0 else "[ R ] reload"]
	prompt.text = game.interaction_prompt() if game.is_playing() else ""
	notice.text = game.notice_text if game.notice_time > 0 else ""
	crosshair.text = "×" if game.hit_time > 0 else "+"
	crosshair.modulate = GOLD if game.hit_time > 0 else CREAM
	flash.color.a = game.hurt_time * 0.7
	radar.queue_redraw()
