extends RefCounted
class_name FrontierSave

const DEFAULT_PATH := "user://sunset_sheriff_v1.json"
var path: String
var last_error := ""

func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path

func load_game() -> Dictionary:
	last_error = ""
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = _parse(file.get_as_text())
		if FrontierRules.valid_state(parsed):
			# JSON numbers are floats; restore integer counters before gameplay uses them.
			for key in ["version", "day", "money", "health", "armor", "deputies", "food", "kills"]:
				parsed[key] = int(parsed[key])
			for structure in parsed.structures:
				structure.site = int(structure.site)
				structure.remaining = int(structure.remaining)
			for id in FrontierRules.WEAPONS:
				parsed.ammo[id] = int(parsed.ammo[id])
				parsed.loaded[id] = int(parsed.loaded[id])
			if candidate != path:
				last_error = "Recovered the previous safe checkpoint."
			return parsed
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		last_error = "Save unreadable. Start a new game to make a fresh checkpoint."
	return {}

func save_game(state: Dictionary) -> bool:
	last_error = ""
	if not FrontierRules.valid_state(state):
		last_error = "Invalid checkpoint; your previous save is untouched."
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Cannot write save. Check storage permissions."
		return false
	file.store_string(JSON.stringify(state, "\t", true, true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		last_error = "Storage write failed; your previous save is untouched."
		return false
	# Only rotate a valid primary into the backup (never replace a recovery with corruption).
	if FileAccess.file_exists(path):
		var previous := FileAccess.open(path, FileAccess.READ)
		if previous != null and FrontierRules.valid_state(_parse(previous.get_as_text())):
			if DirAccess.copy_absolute(path, path + ".bak") != OK:
				last_error = "Could not back up the checkpoint."
				return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		last_error = "Could not install the checkpoint."
		return false
	return true

func _parse(text: String) -> Variant:
	var json := JSON.new()
	if json.parse(text) != OK: return null
	var data: Variant = json.data
	# The first slice allowed four instant turrets. Preserve two as completed posts,
	# refund the others, and keep the same local save slot.
	if data is Dictionary and data.get("version") == 1:
		if not FrontierRules._whole(data.get("turrets")) or data.turrets < 0 or data.turrets > 4: return null
		if not FrontierRules._whole(data.get("money")): return null
		data.version = FrontierRules.VERSION
		data.food = 0
		data.structures = []
		for site in mini(int(data.turrets), 2):
			data.structures.append({"site": site, "kind": "guard_post", "remaining": 0})
		data.money += maxi(0, int(data.turrets) - 2) * 350
		data.erase("turrets")
	return data
