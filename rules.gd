extends RefCounted
class_name FrontierRules

# All economy and combat tuning lives here. Ammunition counts include loaded rounds.
const VERSION := 1
const WEAPONS := {
	"revolver": {"name": "Star Revolver", "damage": 26, "pellets": 1, "spread": 0.0, "range": 65.0, "delay": 0.32, "magazine": 6, "reload": 1.1, "color": "#f6cd65"},
	"shotgun": {"name": "Double-barrel", "damage": 15, "pellets": 6, "spread": 0.085, "range": 26.0, "delay": 0.8, "magazine": 2, "reload": 1.45, "color": "#d89b70"},
	"confetti": {"name": "Confetti Cannon", "damage": 95, "pellets": 1, "spread": 0.0, "range": 65.0, "delay": 0.65, "magazine": 5, "reload": 1.7, "color": "#b992ee", "splash": 5.5},
}
const CATALOG := {
	"ammo": {"name": "Trail ammo box", "price": 35, "description": "+36 revolver rounds / +12 shells", "shop": "Gunsmith"},
	"confetti_ammo": {"name": "Party cartridges", "price": 65, "description": "+15 confetti shots (cannon required)", "shop": "Gunsmith"},
	"confetti": {"name": "Confetti Cannon", "price": 850, "description": "Big colorful splash! Includes 20 shots", "shop": "Gunsmith"},
	"armor": {"name": "Sheriff's padded vest", "price": 90, "description": "Refill 75 armor; absorbs damage first", "shop": "General Store"},
	"medicine": {"name": "Cactus lemonade", "price": 30, "description": "Restore all sheriff health", "shop": "General Store"},
	"boots": {"name": "Silver-spur boots", "price": 220, "description": "Permanent +25% movement speed", "shop": "General Store"},
	"deputy": {"name": "Hire a deputy", "price": 180, "description": "A friendly defender / maximum 6", "shop": "Sheriff Office"},
	"turret": {"name": "Town popper turret", "price": 350, "description": "Automatic plaza defense / maximum 4", "shop": "Sheriff Office"},
}
const ENEMIES := {
	"bandit": {"name": "Bandit", "health": 65, "speed": 2.6, "damage": 9, "range": 13.0, "delay": 1.6, "reward": 12, "color": "#dd7974"},
	"zombie": {"name": "Sleepwalker", "health": 115, "speed": 2.0, "damage": 13, "range": 1.9, "delay": 1.15, "reward": 18, "color": "#95bd79"},
	"monster": {"name": "Marshmallow brute", "health": 240, "speed": 1.65, "damage": 22, "range": 2.4, "delay": 1.5, "reward": 30, "color": "#b895df"},
}

static func new_state() -> Dictionary:
	return {"version": VERSION, "day": 1, "money": 220, "health": 100, "armor": 0,
		"weapons": ["revolver", "shotgun"], "selected": "revolver",
		"ammo": {"revolver": 48, "shotgun": 20, "confetti": 0},
		"loaded": {"revolver": 6, "shotgun": 2, "confetti": 0},
		"deputies": 0, "turrets": 0, "boots": false, "kills": 0,
		"position": [0.0, 0.1, 29.0], "yaw": 0.0, "pitch": 0.0}

static func wage(day: int) -> int:
	return 120 + mini(day - 1, 12) * 25

static func wave(day: int) -> Array[String]:
	var result: Array[String] = []
	for index in mini(4 + (day - 1) * 2, 36):
		if day >= 7 and index % 3 == 0:
			result.append("monster")
		elif day >= 4 and index % 2 == 0:
			result.append("zombie")
		else:
			result.append("bandit")
	return result

static func buy(state: Dictionary, item: String) -> String:
	if not CATALOG.has(item):
		return "Unknown item."
	var price: int = CATALOG[item].price
	if state.money < price:
		return "Not enough coins yet."
	if item == "deputy" and state.deputies >= 6:
		return "All six deputies are on the team!"
	if item == "turret" and state.turrets >= 4:
		return "All four turret pads are occupied!"
	if item == "boots" and state.boots:
		return "You already own these boots."
	if item == "confetti" and "confetti" in state.weapons:
		return "You already own the cannon."
	if item == "confetti_ammo" and not "confetti" in state.weapons:
		return "Buy the Confetti Cannon first."
	if item == "armor" and state.armor >= 75:
		return "Your vest is already full."
	if item == "medicine" and state.health >= 100:
		return "You're already healthy!"
	state.money -= price
	match item:
		"ammo":
			state.ammo.revolver += 36
			state.ammo.shotgun += 12
		"confetti_ammo": state.ammo.confetti += 15
		"confetti":
			state.weapons.append("confetti")
			state.ammo.confetti += 20
			state.loaded.confetti = 5
		"armor": state.armor = 75
		"medicine": state.health = 100
		"boots": state.boots = true
		"deputy": state.deputies += 1
		"turret": state.turrets += 1
	return ""

static func hurt(state: Dictionary, damage: int) -> void:
	var absorbed := mini(state.armor, maxi(0, damage))
	state.armor -= absorbed
	state.health = maxi(0, state.health - maxi(0, damage) + absorbed)

static func consume_shot(state: Dictionary) -> bool:
	var id: String = state.selected
	if state.loaded[id] <= 0 or state.ammo[id] <= 0:
		return false
	state.loaded[id] -= 1
	state.ammo[id] -= 1
	return true

static func reload_weapon(state: Dictionary, id: String) -> void:
	state.loaded[id] = mini(WEAPONS[id].magazine, state.ammo[id])

static func dawn(state: Dictionary) -> void:
	state.day += 1
	state.money += wage(state.day)
	state.health = 100
	# A daily supply floor prevents ammunition soft-locks without replacing the shop.
	state.ammo.revolver = maxi(state.ammo.revolver, 24)
	state.ammo.shotgun = maxi(state.ammo.shotgun, 8)
	for id in state.weapons:
		reload_weapon(state, id)

# Save files are untrusted input. Reject malformed or impossible states, never partly apply them.
static func valid_state(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var base := new_state()
	for key in base:
		if not value.has(key):
			return false
	for key in ["version", "day", "money", "health", "armor", "deputies", "turrets", "kills"]:
		if not _whole(value[key]):
			return false
	if value.version != VERSION or value.day < 1 or value.day > 100000:
		return false
	if value.money < 0 or value.money > 100000000 or value.health < 1 or value.health > 100 or value.armor < 0 or value.armor > 75:
		return false
	if value.deputies < 0 or value.deputies > 6 or value.turrets < 0 or value.turrets > 4 or value.kills < 0:
		return false
	if not value.boots is bool or not value.weapons is Array or value.weapons.size() < 2 or value.weapons.size() > 3:
		return false
	if value.weapons[0] != "revolver" or value.weapons[1] != "shotgun":
		return false
	if value.weapons.size() == 3 and value.weapons[2] != "confetti":
		return false
	if not value.selected is String or not value.selected in value.weapons:
		return false
	if not value.ammo is Dictionary or not value.loaded is Dictionary:
		return false
	for id in WEAPONS:
		if not value.ammo.has(id) or not value.loaded.has(id) or not _whole(value.ammo[id]) or not _whole(value.loaded[id]):
			return false
		if value.ammo[id] < 0 or value.ammo[id] > 100000000 or value.loaded[id] < 0 or value.loaded[id] > mini(WEAPONS[id].magazine, value.ammo[id]):
			return false
	if not value.position is Array or value.position.size() != 3:
		return false
	for coordinate in value.position:
		if not _number(coordinate) or absf(coordinate) > 140:
			return false
	if value.position[1] < -1 or value.position[1] > 20:
		return false
	return _number(value.yaw) and _number(value.pitch) and absf(value.pitch) <= 1.4

static func _whole(value: Variant) -> bool:
	return _number(value) and float(value) == floorf(float(value))

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
