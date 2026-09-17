extends Node
class_name FrontierSound

# Original synthesized PCM. No audio starts until a pointer/key gesture reaches the game.
var unlocked := false
var muted := false
var volume := 0.65
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var context := "day"
var voice_index := 0

func _ready() -> void:
	var prefs := ConfigFile.new()
	if prefs.load("user://sound.cfg") == OK:
		muted = bool(prefs.get_value("audio", "muted", false))
		volume = clampf(float(prefs.get_value("audio", "volume", 0.65)), 0, 1)
	for i in 10:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	for id in ["ui", "buy", "deny", "step", "shot", "reload", "hit", "hurt", "enemy", "build", "complete", "eat", "bell", "day", "night", "saloon"]:
		sounds[id] = synthesize(id)
	_apply_volume()

func unlock() -> void:
	if unlocked: return
	unlocked = true
	set_context(context)

func toggle_mute() -> void:
	muted = not muted
	_apply_volume()
	_save_preferences()

func set_volume(value: float) -> void:
	volume = clampf(value, 0, 1)
	_apply_volume()
	_save_preferences()

func _save_preferences() -> void:
	var prefs := ConfigFile.new()
	prefs.set_value("audio", "muted", muted)
	prefs.set_value("audio", "volume", volume)
	prefs.save("user://sound.cfg")

func _apply_volume() -> void:
	for voice in voices: voice.volume_db = -80 if muted else linear_to_db(maxf(0.001, volume)) - 8
	ambience.volume_db = -80 if muted else linear_to_db(maxf(0.001, volume)) - 23

func play(id: String) -> void:
	if not unlocked or muted or not sounds.has(id): return
	var voice := voices[voice_index % voices.size()]
	voice_index += 1
	voice.stream = sounds[id]
	voice.play()

func set_context(next: String) -> void:
	context = next
	if not unlocked: return
	if ambience.stream == sounds[context] and ambience.playing: return
	ambience.stream = sounds[context]
	ambience.play()

func stop() -> void:
	ambience.stop()
	for voice in voices: voice.stop()

func synthesize(id: String) -> AudioStreamWAV:
	var loop := id in ["day", "night", "saloon"]
	var duration := 4.0 if loop else (0.65 if id in ["complete", "bell", "reload"] else 0.22)
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	for i in count:
		var t := float(i) / rate
		var env := pow(1.0 - t / duration, 2)
		var noise := rng.randf_range(-1, 1)
		var sample := 0.0
		match id:
			"shot": sample = (noise * 0.65 + sin(TAU * (160 - t * 220) * t) * 0.35) * env * exp(-t * 18)
			"step": sample = (noise * 0.3 + sin(TAU * 90 * t) * 0.5) * env * exp(-t * 28)
			"reload": sample = (noise * 0.65 + sin(TAU * 850 * t) * 0.3) * exp(-fmod(t, 0.2) * 55) * env
			"hit": sample = sin(TAU * 940 * t) * exp(-t * 24) * env
			"hurt": sample = sin(TAU * (180 - t * 160) * t) * env
			"enemy": sample = sin(TAU * (290 - t * 310) * t) * env * 0.6
			"deny": sample = sin(TAU * 140 * t) * env * 0.55
			"build": sample = (noise * 0.4 + sin(TAU * 260 * t)) * exp(-fmod(t, 0.1) * 45) * env
			"buy", "complete": sample = sin(TAU * [523, 659, 784, 1046][mini(3, int(t / duration * 4))] * t) * env
			"bell": sample = (sin(TAU * 660 * t) + 0.4 * sin(TAU * 991 * t)) * env * 0.6
			"eat": sample = noise * env * exp(-fmod(t, 0.07) * 35) * 0.5
			"day":
				sample = sin(TAU * 110 * t) * 0.025 + noise * 0.025
				if fmod(t, 1.0) < 0.18: sample += sin(TAU * (1900 * t + 18 * sin(t * 40))) * 0.15 * sin(PI * fmod(t, 1.0) / 0.18)
			"night": sample = noise * 0.025 + sin(TAU * 2800 * t) * pow(maxf(0, sin(TAU * 6 * t)), 12) * 0.10
			"saloon":
				var note: int = int(t * 4) % 16
				var melody := [262, 330, 392, 330, 349, 440, 392, 330, 262, 330, 392, 523, 440, 349, 294, 330]
				sample = (sin(TAU * melody[note] * t) + 0.3 * sin(TAU * melody[note] * 2 * t)) * exp(-fmod(t, 0.25) * 15) * 0.4
			_: sample = sin(TAU * 660 * t) * env * 0.6
		if loop: sample *= minf(1, minf(t * 100, (duration - t) * 100))
		bytes.encode_s16(i * 2, int(clampf(sample, -1, 1) * 16000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream
