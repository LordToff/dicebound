extends Control
# A local, hot-seat adaptation of the supplied October 31 prototype rules.
const BG = Color("101321")
const PANEL = Color("191e30")
const EDGE = Color("343b54")
const INK = Color("e6dfcb")
const MUTED = Color("9398ab")
const GOLD = Color("e7b86a")
const RED = Color("e66d78")
const TEAL = Color("73d2bd")
const COLORS = [Color("79b9df"), Color("dd997c"), Color("b39bdf")]
const NAMES = ["CAIRN", "EMBER", "VESPER"]
const FACES = ["Blank", "Basic Strike", "Basic Movement", "Tactical Movement", "Basic Defense", "Tactical Defense", "Focus", "First Aid", "Shove", "Lantern Cut", "Iron Ward", "Pilgrim Step", "Cursed Blank"]
const LIMITS = [18, 4, 2, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0]
const CATS = ["Blank", "Attack", "Movement", "Movement", "Defense", "Defense", "Skill", "Skill", "Skill", "Attack", "Defense", "Movement", "Blank"]
const SIGNS = ["-", "ATK", "MOV", "DASH", "BLK", "REACT", "FOCUS", "HEAL", "PUSH", "CUT", "WARD", "STEP2", "CURSE"]
const DESCS = ["No effect. A quiet face, waiting for a soul.", "Deal 1 damage to an adjacent unit. Block absorbs damage.", "Move up to 1 orthogonal square. No diagonal movement.", "Move up to 3 squares in a single straight line.", "Gain 1 Block. Unused Block expires at your next turn start.", "Reaction: when targeted, gain 1 Block and optionally step 1.", "Reroll one OTHER unresolved Action Die during your turn.", "Heal yourself or an adjacent hero 1 HP. Revives Downed heroes.", "Push an adjacent unit 1 square directly away. No collision penalty.", "TEST REWARD / Deal 2 damage to an adjacent unit. Cost: one rolled die.", "TEST REWARD / Gain 2 Block until your next turn starts.", "TEST REWARD / Move up to 2 orthogonal squares; you may turn.", "A permanent, locked Blank. Counts toward Soul minima. Cleanse it at an event to unlock it."]
const BOSS_DICE = [["Advance", "Advance", "Strike", "Strike", "Brace", "Drive Back"], ["Advance", "Skirmish", "Strike", "Sweep", "Brace", "Distort"], ["Advance", "Skirmish", "Strike", "Sweep", "Drive Back", "Fracture"]]
const BOARD = Vector2(40, 105)
const CELL = 70
var font: Font
var rng = RandomNumberGenerator.new()
var screen = "title"
var hits: Array = []
var heroes: Array = []
var builds: Array = []
var builder = 0
var paint_face = 1
var blank_min = 3
var boss = {"pos": Vector2i(3, 2), "hp": 18, "block": 0}
var order: Array = []
var initiative: Array = []
var boss_roll: Array = []
var turn_index = 0
var active = -1
var round_no = 0
var selected = -1
var mode = ""
var phase = ""
var move_budget = 0
var reachable: Dictionary = {}
var pending = {}
var boss_step = 0
var recovery: Array = []
var recovery_active = false
var replaced_slots: Array = []
var log_lines: Array = []
var toast = ""
var toast_time = 0.0
var time = 0.0
var particles: Array = []
var floats: Array = []
var shake = 0.0
var flash = 0.0
var sound_on = true
var audio: AudioStreamPlayer
var music: AudioStreamPlayer
var help_open = false
var hover_tip = ""
var victory = false
var reward = false
var blank_step_test = false
var battles_won = 0
var anim_lock = false
var effects: Array = []
var roll_anim = 0.0
var save_enabled = true
var build_slot = 0
var armed_die = -1
var end_confirm = false
var owned_faces: Array = []
var event_pool: Array = [0, 1, 2, 3, 4, 5]
var journey_stage = "prepare"
var trip_hp: Array = [6, 6, 6]
var current_event = -1
var event_target = 0
var event_die = 0
var event_risk_die = 0
var event_outcome = ""
var event_feedback: Array = []
var event_scene_elapsed = 0.0
var event_reveal_elapsed = 2.0
var event_journal: Array = []
var pool_page = 0
var hurt_timers = {}
const POWER = ["NO ACTION", "1 DAMAGE", "MOVE 1", "MOVE 3", "+1 BLOCK", "BLOCK + STEP", "REROLL 1", "+1 HP", "PUSH 1", "2 DAMAGE", "+2 BLOCK", "MOVE 2", "LOCKED BLANK"]
const SHORT_NAMES = ["Blank", "Basic Strike", "Step", "Tactical Dash", "Guard", "Tactical Defense", "Focus", "First Aid", "Shove", "Lantern Cut", "Iron Ward", "Pilgrim Step", "Cursed Blank"]
const BOSS_TIPS = {"Advance":"Move up to 2 toward the closest hero.", "Skirmish":"Move 1, then attack an adjacent hero for 1.", "Strike":"2 damage to the closest adjacent hero.", "Sweep":"1 damage to EVERY adjacent hero, including Downed.", "Brace":"Gain 2 Block until the next boss turn.", "Drive Back":"1 damage, then push 1. Collisions deal 1 + Stunned.", "Distort":"Closest hero within 2: Weakness 1 until boss next turn.", "Fracture":"An adjacent hero chooses an ability face to lose temporarily."}

func _ready() -> void:
	font = load("res://assets/pixel-mono.ttf")
	font.antialiasing = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.randomize()
	for h in range(3):
		builds.append([1, 2, 4, 0, 0, 0, 1, 3, 5, 0, 0, 0, 1, 7, 6, 0, 0, 0])
		owned_faces.append(LIMITS.duplicate())
	load_progress()
	audio = AudioStreamPlayer.new()
	add_child(audio)
	music = AudioStreamPlayer.new()
	add_child(music)
	music.volume_db = -12
	music.stream = load("res://assets/tribunal.ogg")
	music.stream.loop = true
	if sound_on: music.play()
	set_process(true)
	queue_redraw()

func load_progress() -> void:
	if not save_enabled: return
	var config = ConfigFile.new()
	if config.load("user://dicebound.cfg") != OK: return
	for h in range(3):
		var saved = config.get_value("party", str(h), [])
		if saved is Array and saved.size() == 18 and saved.all(func(f): return f is int and f >= 0 and f < FACES.size()): builds[h] = saved
	blank_min = int(config.get_value("party", "blanks", 3))
	if blank_min not in [2, 3]: blank_min = 3
	reward = bool(config.get_value("party", "reward", false))
	blank_step_test = bool(config.get_value("settings", "blank_step_test", false))
	battles_won = int(config.get_value("party", "wins", 0))
	load_journey(config)

func save_progress() -> void:
	if not save_enabled: return
	var config = ConfigFile.new()
	for h in range(3): config.set_value("party", str(h), builds[h])
	config.set_value("party", "blanks", blank_min)
	config.set_value("party", "reward", reward)
	config.set_value("party", "wins", battles_won)
	config.set_value("settings", "blank_step_test", blank_step_test)
	write_journey(config)
	config.save("user://dicebound.cfg")

func sfx(kind: String) -> void:
	if not sound_on:
		return
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data = PackedByteArray()
	var n = 12000 if kind.begins_with("event_") else (4200 if kind == "hit" else 2300)
	data.resize(n * 2)
	for i in range(n):
		var t = float(i) / 22050.0
		var frequencies = {"hit": 110.0, "heal": 660.0, "block": 270.0, "step": 150.0, "roll": 420.0, "carve": 880.0, "event_good": 440.0, "event_bad": 90.0, "event_reveal": 220.0}
		var base: float = frequencies.get(kind, 330.0)
		var f = base * (1.0 - t * 3.0) if kind in ["hit", "step", "event_bad"] else base * (1.0 + t * 2.0)
		var wave_value = sin(TAU * f * t) + 0.35 * sin(TAU * f * 1.5 * t)
		if kind == "hit": wave_value += sin(i * 713.7) * 0.7
		var v = wave_value * pow(1.0 - float(i) / n, 2) * 0.20
		data.encode_s16(i * 2, int(v * 22000))
	wav.data = data
	audio.stream = wav
	audio.play()

func _process(delta: float) -> void:
	time += delta
	if screen == "event":
		event_scene_elapsed += delta
		if journey_stage == "resolved": event_reveal_elapsed = minf(3.0, event_reveal_elapsed + delta)
	for h in hurt_timers.keys(): hurt_timers[h] = maxf(0.0, hurt_timers[h] - delta)
	toast_time = maxf(0, toast_time - delta)
	shake = maxf(0, shake - delta * 32)
	flash = maxf(0, flash - delta * 3)
	roll_anim = maxf(0, roll_anim - delta)
	for effect in effects: effect.life -= delta
	effects = effects.filter(func(effect): return effect.life > 0)
	for p in particles:
		p.pos += p.vel * delta
		p.vel.y += 100 * delta
		p.life -= delta
	particles = particles.filter(func(p): return p.life > 0)
	for f in floats:
		f.pos.y -= delta * 28
		f.life -= delta
	floats = floats.filter(func(f): return f.life > 0)
	queue_redraw()

func say(message: String) -> void:
	log_lines.push_front(message)
	if log_lines.size() > 40:
		log_lines.pop_back()

func notify(message: String) -> void:
	toast = message
	toast_time = 3.5

func text_at(p: Vector2, value: String, size_px: int = 16, color: Color = INK) -> void:
	draw_string(font, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func box(r: Rect2, fill: Color = PANEL, border: Color = EDGE) -> void:
	draw_rect(r, fill)
	draw_rect(r, border, false, 2)
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 2)), border.lightened(0.1))

func button(r: Rect2, label: String, id: String, enabled: bool = true, accent: Color = GOLD, tip: String = "") -> void:
	var over = r.has_point(get_local_mouse_position()) and enabled
	box(r, accent.darkened(0.70) if over else Color("202538"), accent if enabled else EDGE)
	var w = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	text_at(r.position + Vector2((r.size.x - w) / 2, r.size.y / 2 + 5), label, 15, accent if enabled else MUTED.darkened(0.4))
	if enabled:
		hits.append({"r": r, "id": id})
	if over and not tip.is_empty():
		hover_tip = tip

func wrapped(p: Vector2, value: String, width: int = 47, color: Color = MUTED, size_px: int = 14) -> void:
	var line = ""
	var y = p.y
	for word in value.split(" "):
		if line.length() + word.length() + 1 > width:
			text_at(Vector2(p.x, y), line, size_px, color)
			y += size_px + 6
			line = ""
		line += word + " "
	text_at(Vector2(p.x, y), line, size_px, color)

func _draw() -> void:
	hits.clear()
	hover_tip = ""
	draw_rect(Rect2(0, 0, 1280, 800), BG)
	draw_background()
	if screen == "title":
		draw_title()
	elif screen == "build":
		draw_build()
	elif screen == "battle":
		draw_battle()
	elif screen == "result":
		draw_result()
	elif screen == "camp":
		draw_camp()
	elif screen == "event":
		draw_event()
	button(Rect2(740, 27, 74, 30), "EXIT" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "FULL", "fullscreen", true, MUTED, "Toggle fullscreen for a larger view of the arena.")
	button(Rect2(827, 27, 258, 30), "TEST BLANK STEP: " + ("ON" if blank_step_test else "OFF"), "blank_step_toggle", true, TEAL if blank_step_test else MUTED, "Test rule: spend one rolled Blank to Move 1, once per hero turn. Earned Souls still work when this is off.")
	if screen != "title":
		button(Rect2(1100, 27, 64, 30), "RULES", "help", true, MUTED)
	button(Rect2(1176, 27, 74, 30), "SOUND" if sound_on else "MUTED", "sound", true, MUTED, "Toggle the soundtrack and sound effects.")
	if toast_time > 0:
		if screen == "battle":
			box(Rect2(40, 773, 1208, 24), Color("302b31"), GOLD)
			text_at(Vector2(52, 790), toast, 12, GOLD)
		else:
			box(Rect2(200, 744, 880, 36), Color("302b31"), GOLD)
			text_at(Vector2(218, 768), toast, 14, GOLD)
	if help_open:
		draw_help()
	if not hover_tip.is_empty() and not help_open and (screen not in ["build", "battle"] or toast_time <= 0):
		var tip_y = 773 if screen == "battle" else (744 if screen == "build" else 716)
		box(Rect2(66, tip_y, 1148, 24), Color("111827"), EDGE)
		text_at(Vector2(77, tip_y + 17), hover_tip, 13, INK)
	for effect in effects:
		var progress = 1.0 - effect.life / effect.duration
		var c: Color = Color(effect.color, 1.0 - progress)
		if effect.kind == "trail":
			draw_line(effect.pos, effect.to, c, 2)
			pixel_circle(effect.pos.lerp(effect.to, progress), 5, c)
		elif effect.kind == "slash":
			var a: Vector2 = effect.pos + Vector2(-27, 24) * (1.0 - progress * 0.3)
			var b: Vector2 = effect.pos + Vector2(30, -27) * (0.5 + progress)
			draw_line(a, b, c, 6 * (1.0 - progress) + 1)
			draw_line(a + Vector2(5, 2), b + Vector2(5, 2), Color(1, 0.9, 0.75, 1.0 - progress), 2)
		else:
			draw_arc(effect.pos, 12 + progress * 32, 0, TAU, 24, c, 3)
			draw_arc(effect.pos, 6 + progress * 24, 0, TAU, 16, Color(c, c.a * 0.4), 2)
	for p in particles:
		draw_rect(Rect2(p.pos.snapped(Vector2(2, 2)), Vector2.ONE * p.size), Color(p.color, clampf(p.life * 2, 0, 1)))
	for f in floats:
		text_at(f.pos, f.text, 24, f.color)
	if flash > 0:
		draw_rect(Rect2(0, 0, 1280, 800), Color(1, 0.35, 0.35, flash * 0.08))

func draw_background() -> void:
	# All artwork is drawn on a pixel grid, with a restricted 16-bit palette.
	for i in range(40):
		var x = fmod(i * 191.0 + time * (3 + i % 3), 1280)
		var y = fmod(i * 97.0 - time * (8 + i % 5) + 8000, 800)
		draw_rect(Rect2(int(x / 2) * 2, int(y / 2) * 2, 2, 2), Color(0.83, 0.49, 0.33, 0.12 + 0.16 * sin(time + i)))
	for i in range(4):
		var x = 15 + i * 410
		draw_rect(Rect2(x, 90, 16, 640), Color("151928"))

func draw_title() -> void:
	# Ruined cathedral, eclipse and ritual dais.
	for i in range(8):
		draw_rect(Rect2(720 + i * 38, 190 - (i % 3) * 26, 28, 350 + (i % 3) * 26), Color("202438"))
		draw_rect(Rect2(726 + i * 38, 210 - (i % 3) * 26, 12, 100), Color("343349"))
	pixel_circle(Vector2(950, 224), 112, Color("6c555a"))
	pixel_circle(Vector2(969, 209), 100, BG)
	for i in range(4):
		box(Rect2(741 - i * 22, 560 + i * 18, 400 + i * 44, 20), Color("292c40"), Color("39394d"))
	draw_boss(Vector2(940, 445), 3)
	for i in range(3):
		draw_hero(Vector2(808 + i * 130, 626), i, 2, false)
	text_at(Vector2(74, 103), "A TACTICAL DICE-BUILDING BOSS BATTLER", 15, GOLD)
	text_at(Vector2(68, 223), "DICEBOUND", 78, INK)
	text_at(Vector2(76, 267), "THE HOLLOW TRIBUNAL", 23, GOLD)
	draw_rect(Rect2(77, 296, 480, 2), EDGE)
	wrapped(Vector2(78, 338), "Three fractured souls. Eighteen carved faces. One creature that remembers what you were.", 43, MUTED, 18)
	button(Rect2(78, 452, 360, 58), "CARVE YOUR DICE  >", "build", true, GOLD)
	button(Rect2(78, 526, 174, 44), "HOW TO PLAY", "help", true, MUTED)
	button(Rect2(266, 526, 172, 44), "NEW JOURNEY", "quick", true, TEAL)
	button(Rect2(78, 590, 360, 36), "CAMP / TEST SIX EVENTS", "camp", true, COLORS[2])
	text_at(Vector2(78, 647), "BUILD / ROLL / POSITION / SURVIVE", 15, MUTED)
	text_at(Vector2(78, 679), "16-BIT ORIGINAL ART  +  PROCEDURAL CHIP AUDIO", 12, MUTED.darkened(0.15))
	text_at(Vector2(78, 761), "LOCAL THREE-HERO PLAY   ·   BASED ON YOUR OCT 31 RULES", 13, MUTED)

func pixel_circle(center: Vector2, radius: int, color: Color) -> void:
	for y in range(-radius, radius, 4):
		var width_px = int(sqrt(maxf(0, radius * radius - y * y)) / 4) * 4
		draw_rect(Rect2(center.x - width_px, center.y + y, width_px * 2, 4), color)

func draw_hero(center: Vector2, h: int, scale_px: int = 1, down: bool = false) -> void:
	var c: Color = COLORS[h]
	var s = float(scale_px)
	var pattern = ["    hhhh    ", "   hhhhh    ", "   hsssh    ", "   hsssh    ", "    ss     ", "  ccccccc   ", " cccAcccc   ", " cccAccccc  ", " cccAccccc  ", " ccccccccc  ", "  ccccccc   ", "  ccccccc   ", "   b b     ", "  bb bb    "]
	if h == 1:
		pattern = ["    hhh     ", "   hhhhh    ", "   ssssh    ", "   ssesh    ", "    ss      ", "  ccccc     ", "  cAcAcc    ", "  cAcAcc w  ", "  ccccc  w  ", "  cccccc w  ", "  cccccc w  ", "   cccc  w  ", "   b b      ", "  bb bb     "]
	if h == 2:
		pattern = ["    ccc     ", "   ccccc    ", "  ccccccc   ", "  ccseccc   ", "   csscc    ", "  ccccccc   ", "  cAAAccc   ", " cccAcccc   ", " cccAcccc   ", "  ccccccc   ", "  ccccccc   ", " ccccccccc  ", "  ccccccc   ", "  bb  bb    "]
	draw_rect(Rect2(center + Vector2(-15 * s, 9 * s), Vector2(30, 5) * s), Color(0.02, 0.02, 0.04, 0.65))
	for y in range(pattern.size()):
		for x in range(pattern[y].length()):
			var letter = pattern[y][x]
			var col = Color.TRANSPARENT
			match letter:
				"c": col = c.darkened(0.20 + float(x % 3) * 0.1)
				"A": col = c.lightened(0.3)
				"s": col = Color("e6c0a0")
				"h": col = Color("464056")
				"b": col = Color("4a4253")
				"e": col = GOLD
				"w": col = Color("99775c")
			if col.a > 0:
				var offset = Vector2(x * 2 - 12, y * 2 - 18) * s
				if down:
					offset = Vector2(offset.y, offset.x) * Vector2(1, 0.4)
					col = col.darkened(0.5)
				draw_rect(Rect2(center + offset, Vector2.ONE * 2 * s), col)
	if h == 0 and not down:
		draw_rect(Rect2(center + Vector2(12, -12) * s, Vector2(3, 22) * s), Color("b5c6d0"))
		draw_rect(Rect2(center + Vector2(8, 4) * s, Vector2(11, 3) * s), GOLD)

func draw_boss(center: Vector2, scale_px: int = 1) -> void:
	var s = float(scale_px)
	var pattern = ["   h         h   ", "   hh       hh   ", "    hh     hh    ", "     hhhhhhh     ", "     hhee hhh    ", "     hhh hhh     ", "      hhhhh      ", "  hhhhhrhhhhh    ", " hhhhhrrrhhhhh   ", "hhhhhhrrrhhhhhh  ", "hhh hhhhrhhh hhh ", "hhh hhhhhhhh hhh ", " hh hhhrrhhh hh  ", " hh  hhhhh   hh  ", " hh  hhhhh   hh  ", " hh  hhhhh   hh  ", " h   hh hh    h  ", "    hhh hhh      ", "   hhhh hhhh     "]
	draw_rect(Rect2(center + Vector2(-26, 23) * s, Vector2(52, 8) * s), Color("141421"))
	for y in range(pattern.size()):
		for x in range(pattern[y].length()):
			var ch = pattern[y][x]
			var col = Color.TRANSPARENT
			if ch == "h": col = [Color("77606b"), Color("987784"), Color("544b60")][(x + y) % 3]
			if ch == "r": col = Color("b54f65")
			if ch == "e": col = Color("ffd48a")
			if col.a:
				draw_rect(Rect2(center + Vector2(x * 3 - 25, y * 3 - 28) * s, Vector2.ONE * 3 * s), col)

func draw_build() -> void:
	text_at(Vector2(44, 54), "DICEBOUND", 25, GOLD)
	text_at(Vector2(44, 103), "CARVE YOUR FATE", 29, INK)
	text_at(Vector2(44, 133), "1  PICK A DIE SIDE     2  CHOOSE AN ABILITY     3  ENTER THE ARENA", 14, MUTED)
	for h in range(3):
		var x = 44 + h * 246
		box(Rect2(x, 160, 232, 85), COLORS[h].darkened(0.85), COLORS[h] if builder == h else EDGE)
		draw_hero(Vector2(x + 32, 206), h, 1)
		text_at(Vector2(x + 62, 191), NAMES[h], 18, COLORS[h])
		text_at(Vector2(x + 62, 214), "6 HP / THREE MIXED DICE", 10, MUTED)
		button(Rect2(x + 63, 221, 150, 19), "EDIT LOADOUT", "hero:%d" % h, true, COLORS[h])
	for i in range(3):
		var label: String = ["Balanced", "Assault", "Support"][i]
		button(Rect2(104 + i * 208, 263, 196, 29), label.to_upper() + " PRESET", "preset:" + label, true, COLORS[builder])
	for d in range(3):
		var y = 310 + d * 100
		var n = 6 - blank_sides(builds[builder].slice(d * 6, d * 6 + 6))
		text_at(Vector2(47, y + 28), ["I", "II", "III"][d], 18, GOLD)
		text_at(Vector2(42, y + 49), "%d%%" % roundi(n / 6.0 * 100), 11, MUTED)
		for side in range(6):
			var index = d * 6 + side
			var face: int = builds[builder][index]
			die(Rect2(105 + side * 104, y, 92, 78), face, "slot:%d" % index, false, build_slot == index)
	box(Rect2(790, 160, 444, 487))
	button(Rect2(809, 169, 196, 28), "STARTER FACES", "pool_starter", true, GOLD if pool_page == 0 else MUTED)
	button(Rect2(1016, 169, 196, 28), "FOUND FACES", "pool_found", true, GOLD if pool_page == 1 else MUTED)
	var shown_faces = range(1, 9) if pool_page == 0 else [9, 10, 11]
	for i in range(shown_faces.size()):
		var f: int = shown_faces[i]
		var r = Rect2(808 + (i % 2) * 207, 207 + (i / 2) * 72, 196, 63)
		var color = face_color(f)
		var count = builds[builder].count(f)
		var capacity = face_capacity(builder, f)
		var enabled = capacity > 0 and (count < capacity or capacity == 1 or builds[builder][build_slot] == f)
		box(r, color.darkened(0.86), GOLD if paint_face == f else color.darkened(0.4))
		text_at(r.position + Vector2(10, 19), SHORT_NAMES[f], 13, INK if enabled else MUTED)
		text_at(r.position + Vector2(10, 43), POWER[f], 13, color)
		text_at(r.position + Vector2(144, 56), "%d/%d" % [count, capacity], 10, MUTED)
		if enabled: hits.append({"r": r, "id": "paint:%d" % f})
		if r.has_point(get_local_mouse_position()): hover_tip = FACES[f] + ": " + DESCS[f]
	button(Rect2(809, 502, 402, 30), "CLEAR SIDE / INSTALL BLANK", "paint:0", true, MUTED)
	text_at(Vector2(809, 557), FACES[paint_face].to_upper(), 16, face_color(paint_face))
	wrapped(Vector2(809, 580), face_description(paint_face), 43, INK, 12)
	text_at(Vector2(809, 633), "Combat cost: 1 rolled die. No HP or gold cost.", 11, MUTED)
	text_at(Vector2(47, 635), "SOUL: %d BLANKS PER DIE / BODY: MOVE 3, DEFENSE 3, SKILL 3" % blank_min, 12, GOLD)
	text_at(Vector2(47, 660), "Percentages show each die's chance to roll an ability.", 12, MUTED)
	var error = build_error(builder)
	text_at(Vector2(47, 689), "LEGAL LOADOUT / READY TO FIGHT" if error.is_empty() else error, 13, TEAL if error.is_empty() else RED)
	button(Rect2(104, 708, 302, 27), "SOUL / %d BLANK MINIMUM" % blank_min, "soul", true, MUTED)
	button(Rect2(420, 708, 302, 27), "RESET THIS HERO", "reset_build", true, MUTED)
	var legal = true
	for h in range(3):
		if not build_error(h).is_empty(): legal = false
	button(Rect2(792, 665, 440, 47), "VENTURE OUT / ROLL EVENT  >", "start", legal)

func face_color(face: int) -> Color:
	if face in [1, 9]: return RED
	if face in [2, 3, 11]: return TEAL
	if face in [4, 5, 10]: return COLORS[0]
	if face in [6, 7, 8, 12]: return COLORS[2]
	return MUTED

func die(r: Rect2, face: int, id: String, spent: bool, chosen: bool) -> void:
	var color = face_color(face)
	box(r, Color("252b3f") if not spent else Color("151a28"), GOLD if chosen else (EDGE if spent else color.darkened(0.25)))
	var center = r.position + r.size / 2
	var alpha = 0.3 if spent else 1.0
	var icon_color = Color(color, alpha)
	if face in [1, 9]:
		draw_line(center + Vector2(-12, 8), center + Vector2(10, -14), icon_color, 4)
		draw_line(center + Vector2(-13, -1), center + Vector2(-2, 10), icon_color, 3)
	elif face in [2, 3, 11]:
		for k in range(2 if face == 3 else 1):
			var x = center.x - 8 + k * 12
			draw_polyline(PackedVector2Array([Vector2(x - 4, center.y - 12), Vector2(x + 5, center.y - 4), Vector2(x - 4, center.y + 4)]), icon_color, 3)
	elif face in [4, 5, 10]:
		draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -14), center + Vector2(12, -14), center + Vector2(10, 0), center + Vector2(0, 9), center + Vector2(-10, 0)]), icon_color)
		if face == 5: text_at(center + Vector2(-4, 1), "!", 16, BG)
	elif face == 7:
		draw_rect(Rect2(center + Vector2(-3, -15), Vector2(6, 24)), icon_color)
		draw_rect(Rect2(center + Vector2(-12, -6), Vector2(24, 6)), icon_color)
	elif face == 6:
		draw_rect(Rect2(center + Vector2(-11, -13), Vector2(22, 20)), icon_color, false, 3)
		draw_rect(Rect2(center + Vector2(-3, -6), Vector2(6, 6)), icon_color)
	elif face == 8:
		draw_line(center + Vector2(-12, -3), center + Vector2(10, -3), icon_color, 4)
		draw_polyline(PackedVector2Array([center + Vector2(1, -12), center + Vector2(11, -3), center + Vector2(1, 6)]), icon_color, 4)
	else:
		draw_rect(Rect2(center + Vector2(-3, -6), Vector2(6, 6)), icon_color)
	var label = SIGNS[face] if not spent else "SPENT"
	text_at(Vector2(r.position.x + (r.size.x - label.length() * 7) / 2, r.end.y - 9), label, 12, Color(color, alpha))
	if not id.is_empty():
		hits.append({"r": r, "id": id})
		if r.has_point(get_local_mouse_position()): hover_tip = FACES[face] + ": " + face_description(face)

func build_error(h: int) -> String:
	for d in range(3):
		var n = 0
		for s in range(6):
			if builds[h][d * 6 + s] in [0, 12]: n += 1
		if n < blank_min: return "Die %s needs %d Blank sides." % [["I", "II", "III"][d], blank_min]
	for f in range(1, FACES.size()):
		if builds[h].count(f) > face_capacity(h, f): return "Not enough owned copies of " + FACES[f]
	for category in ["Movement", "Defense", "Skill"]:
		var n = 0
		for f in builds[h]:
			if CATS[f] == category: n += 1
		if n > 3: return category + " exceeds Broken Body cap of 3."
	return ""

func start_battle() -> void:
	if journey_stage == "event":
		screen = "event"
		notify("Choose an event outcome before entering battle.")
		return
	if reward: blank_min = 3
	for h in range(3):
		if not build_error(h).is_empty():
			screen = "build"
			builder = h
			notify("Refit " + NAMES[h] + ": " + build_error(h))
			return
	var preserve_event = journey_stage in ["resolved", "battle"]
	if preserve_event: journey_stage = "battle"
	save_progress()
	screen = "battle"
	boss = {"pos": Vector2i(3, 2), "hp": 18, "block": 0}
	heroes.clear()
	log_lines.clear()
	initiative.clear()
	order.clear()
	recovery.clear()
	recovery_active = false
	for h in range(3):
		heroes.append({"pos": Vector2i(2 + h * 2, 6), "hp": trip_hp[h] if preserve_event else 6, "block": 0, "down": false, "dead": false, "broken": false, "protected": false, "weak": false, "stun": false, "dice": builds[h].duplicate(), "roll": [], "spent": [false, false, false], "react": [], "acted": false, "soul_used": false})
		initiative.append(rng.randi_range(1, 6))
	initiative.append(rng.randi_range(1, 6))
	order = [0, 1, 2, 3]
	order.sort_custom(func(a, b): return initiative[a] > initiative[b] if initiative[a] != initiative[b] else (a == 3 or (b != 3 and a < b)))
	round_no = 0
	selected = -1
	mode = ""
	anim_lock = false
	say("The Hollow One stirs. Initiative is fixed.")
	new_round()

func roll_hero(h: int) -> void:
	var u: Dictionary = heroes[h]
	u.roll = []
	u.spent = [false, false, false]
	u.react = []
	for d in range(3):
		var side = rng.randi_range(0, 5)
		u.roll.append(side)
		if u.dice[d * 6 + side] == 5 and not u.down and not u.dead:
			u.react.append(d)
			u.spent[d] = true
	if u.down or u.dead: u.spent = [true, true, true]

func new_round() -> void:
	if check_end(): return
	round_no += 1
	roll_anim = 0.45
	turn_index = -1
	for h in range(3):
		heroes[h].acted = false
		roll_hero(h)
	boss_roll.clear()
	for d in range(3): boss_roll.append(BOSS_DICE[d][rng.randi_range(0, 5)])
	say("ROUND %d / all Action Dice rolled openly." % round_no)
	sfx("roll")
	next_turn()

func next_turn() -> void:
	armed_die = -1
	end_confirm = false
	if check_end(): return
	selected = -1
	mode = ""
	reachable.clear()
	if not recovery.is_empty():
		active = recovery.pop_front()
		if heroes[active].dead or heroes[active].down:
			next_turn()
			return
		recovery_active = true
		roll_hero(active)
	else:
		recovery_active = false
		turn_index += 1
		while turn_index < 4 and order[turn_index] != 3 and (heroes[order[turn_index]].down or heroes[order[turn_index]].dead or heroes[order[turn_index]].acted):
			turn_index += 1
		if turn_index >= 4:
			new_round()
			return
		active = order[turn_index]
	if active == 3:
		boss.block = 0
		for u in heroes: u.weak = false
		boss_step = 0
		phase = "boss"
		say("The Hollow One activates. Resolve I > II > III.")
	else:
		var u: Dictionary = heroes[active]
		u.block = 0
		u.soul_used = false
		phase = "hero"
		if u.stun:
			mode = "stun"
			if unresolved(active).is_empty():
				mode = ""
		say(NAMES[active] + (" takes a recovery turn." if recovery_active else " begins their turn."))

func unresolved(h: int) -> Array:
	var out = []
	for d in range(3):
		if not heroes[h].spent[d]: out.append(d)
	return out

func finish_turn() -> void:
	if active < 3:
		heroes[active].acted = true
		heroes[active].stun = false
	for u in heroes: u.protected = false
	next_turn()

func footprint(pos: Vector2i, size_px: int = 1) -> Array:
	var out = []
	for y in range(size_px):
		for x in range(size_px): out.append(pos + Vector2i(x, y))
	return out

func distance(a: Vector2i, b: Vector2i, b_size: int = 1) -> int:
	var best = 100
	for p in footprint(b, b_size): best = mini(best, absi(a.x - p.x) + absi(a.y - p.y))
	return best

func free_at(pos: Vector2i, unit: int) -> bool:
	var cells = footprint(pos, 2 if unit == 3 else 1)
	for p in cells:
		if p.x < 0 or p.y < 0 or p.x > 8 or p.y > 8: return false
		if unit != 3 and p in footprint(boss.pos, 2): return false
		for h in range(heroes.size()):
			if h != unit and not heroes[h].dead and p == heroes[h].pos: return false
	return true

func unit_at(p: Vector2i) -> int:
	if p in footprint(boss.pos, 2): return 3
	for h in range(heroes.size()):
		if not heroes[h].dead and heroes[h].pos == p: return h
	return -1

func unit_pos(h: int) -> Vector2i:
	return boss.pos if h == 3 else heroes[h].pos

func unit_center(h: int) -> Vector2:
	return BOARD + Vector2(unit_pos(h)) * CELL + Vector2.ONE * (CELL if h == 3 else CELL / 2.0)

func neighbors(p: Vector2i) -> Array:
	return [p + Vector2i.LEFT, p + Vector2i.UP, p + Vector2i.RIGHT, p + Vector2i.DOWN]

func movement_options(h: int, steps: int, straight: bool = false) -> Dictionary:
	var start = unit_pos(h)
	var result = {start: 0}
	if straight:
		for dir in [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]:
			for n in range(1, steps + 1):
				var p = start + dir * n
				if not free_at(p, h): break
				result[p] = n
	else:
		var todo = [start]
		while not todo.is_empty():
			var p: Vector2i = todo.pop_front()
			if result[p] >= steps: continue
			for q in neighbors(p):
				if not result.has(q) and free_at(q, h):
					result[q] = result[p] + 1
					todo.append(q)
	return result

func move_unit(h: int, dest: Vector2i) -> void:
	var old = unit_center(h)
	if h == 3: boss.pos = dest
	else: heroes[h].pos = dest
	effects.append({"pos": old, "to": unit_center(h), "kind": "trail", "color": TEAL, "life": 0.5, "duration": 0.5})
	emit(old, TEAL, 8)
	emit(unit_center(h), TEAL, 8)
	sfx("step")

func select_die(d: int) -> void:
	if roll_anim > 0: return
	if active >= 3 or phase != "hero": return
	var u: Dictionary = heroes[active]
	if mode == "focus":
		if u.spent[d] or d == selected:
			notify("Choose another unresolved die.")
			return
		u.roll[d] = rng.randi_range(0, 5)
		if u.dice[d * 6 + u.roll[d]] == 5:
			u.react.append(d)
			u.spent[d] = true
		say(NAMES[active] + " focuses and rerolls die " + str(d + 1) + ".")
		sfx("roll")
		mode = ""
		selected = -1
		return
	if u.spent[d]:
		notify("This result is spent or stored as a Reaction.")
		return
	if mode == "stun":
		u.spent[d] = true
		mode = ""
		say(NAMES[active] + " sets aside a die for Stunned.")
		return
	selected = d
	var face: int = u.dice[d * 6 + u.roll[d]]
	mode = ""
	reachable.clear()
	match face:
		0, 12:
			if blank_step_enabled() and not u.soul_used:
				mode = "move_soul"
				reachable = movement_options(active, 1)
			else:
				consume()
		1, 9: mode = "attack"
		2, 3, 11:
			mode = "move"
			reachable = movement_options(active, 3 if face == 3 else (2 if face == 11 else 1), face == 3)
		4, 10:
			var gained = 2 if face == 10 else 1
			u.block += gained
			float_text(active, "+%d BLOCK" % gained, COLORS[0])
			emit(unit_center(active), COLORS[0], 22)
			sfx("block")
			consume()
		6:
			u.spent[d] = true
			mode = "focus"
			if unresolved(active).is_empty():
				mode = ""
				notify("No other unresolved die. Focus is spent.")
		7: mode = "heal"
		8: mode = "shove"

func consume() -> void:
	armed_die = -1
	if active < 3 and selected >= 0: heroes[active].spent[selected] = true
	selected = -1
	mode = ""
	reachable.clear()

func board_click(p: Vector2i) -> void:
	if screen != "battle" or anim_lock: return
	if mode == "boss_move":
		if reachable.has(p):
			move_unit(3, p)
			var action: String = pending.get("action", "Advance")
			mode = ""
			reachable.clear()
			if action == "Skirmish": prepare_attack(action)
			else: boss_complete()
		return
	if mode == "reaction_move":
		var h: int = pending.reactor
		if reachable.has(p):
			move_unit(h, p)
			reachable.clear()
			mode = ""
			resume_attack()
		return
	if mode == "push_direction":
		for item in pending.choices:
			if p in footprint(item.dest, 2 if pending.target == 3 else 1):
				apply_push(pending.target, item.dir, pending.get("collision", false))
				if pending.get("boss_push", false): boss_complete()
				else: consume()
				return
		return
	if phase != "hero" or active >= 3: return
	var target = unit_at(p)
	if mode in ["move", "move_soul"]:
		if reachable.has(p):
			if mode == "move_soul": heroes[active].soul_used = true
			move_unit(active, p)
			consume()
		else: notify("Choose a highlighted square. Pieces and edges block movement.")
	elif mode == "attack":
		if target >= 0 and target != active and distance(heroes[active].pos, unit_pos(target), 2 if target == 3 else 1) == 1:
			var amount = attack_value(active, heroes[active].dice[selected * 6 + heroes[active].roll[selected]])
			damage(target, amount)
			say(NAMES[active] + " attacks for %d." % amount)
			consume()
		else: notify("Basic Strike needs an adjacent unit (edge contact).")
	elif mode == "heal":
		if target >= 0 and target < 3 and distance(heroes[active].pos, heroes[target].pos) <= 1:
			heal(target)
			consume()
		else: notify("First Aid targets yourself or an adjacent hero.")
	elif mode == "shove":
		if target >= 0 and target != active and distance(heroes[active].pos, unit_pos(target), 2 if target == 3 else 1) == 1:
			choose_push(active, target, false, false)
		else: notify("Shove needs an adjacent unit.")

func emit(pos: Vector2, color: Color, count: int = 14) -> void:
	effects.append({"pos": pos, "kind": "ring", "color": color, "life": 0.4, "duration": 0.4})
	for i in range(count):
		particles.append({"pos": pos, "vel": Vector2(rng.randf_range(-95, 95), rng.randf_range(-140, 40)), "color": color, "life": rng.randf_range(0.25, 0.7), "size": rng.randi_range(2, 5)})

func float_text(h: int, value: String, color: Color) -> void:
	floats.append({"pos": unit_center(h) + Vector2(-25, -24), "text": value, "color": color, "life": 1.2})

func damage(target: int, amount: int, unavoidable: bool = false) -> void:
	var u: Dictionary = boss if target == 3 else heroes[target]
	if target < 3 and u.dead: return
	var absorbed = mini(u.block, amount) if not unavoidable else 0
	u.block -= absorbed
	var lost = maxi(0, amount - absorbed)
	float_text(target, "BLOCK" if lost == 0 else "-%d" % lost, COLORS[0] if lost == 0 else RED)
	emit(unit_center(target), RED if lost > 0 else COLORS[0])
	sfx("hit" if lost > 0 else "block")
	shake = 4 if lost > 0 else 1
	if lost > 0:
		flash = 0.55
		hurt_timers[target] = 0.30
		effects.append({"pos": unit_center(target), "kind": "slash", "color": GOLD, "life": 0.3, "duration": 0.3})
	if target == 3:
		u.hp = maxi(0, u.hp - lost)
	else:
		if u.down:
			if lost > 0 and not u.protected: u.dead = true
		else:
			u.hp = maxi(0, u.hp - lost)
			if u.hp == 0:
				if u.broken:
					u.dead = true
					say(NAMES[target] + " is slain. Their broken soul fades.")
				else:
					u.down = true
					u.protected = true
					u.block = 0
					u.weak = false
					u.stun = false
					u.react.clear()
					u.spent = [true, true, true]
					say(NAMES[target] + " is Downed. First Aid can recover them.")
	check_end()

func heal(h: int) -> void:
	var u: Dictionary = heroes[h]
	if u.dead: return
	var gained = mini(1, 6 - u.hp)
	u.hp += gained
	if u.down and gained > 0:
		u.down = false
		u.broken = true
		u.protected = false
		recovery.append(h)
		say(NAMES[h] + " recovers: Broken, with a queued full recovery turn.")
	float_text(h, "+%d HP" % gained, TEAL)
	emit(unit_center(h), TEAL, 20)
	sfx("heal")

func check_end() -> bool:
	if heroes.size() != 3 or screen != "battle": return screen == "result"
	var alive = false
	for u in heroes:
		if not u.dead and not u.down: alive = true
	if not alive or boss.hp <= 0:
		victory = alive and boss.hp <= 0
		screen = "result"
		journey_stage = "aftermath"
		if victory:
			battles_won += 1
			reward = true
			save_progress()
			sfx("heal")
		else:
			save_progress()
			sfx("hit")
		return true
	return false

func closest(candidates: Array, strike_priority: bool = false) -> int:
	if candidates.is_empty(): return -1
	var sorted = candidates.duplicate()
	sorted.shuffle()
	sorted.sort_custom(func(a, b):
		var da = distance(heroes[a].pos, boss.pos, 2)
		var db = distance(heroes[b].pos, boss.pos, 2)
		if da != db: return da < db
		if strike_priority and heroes[a].block != heroes[b].block: return heroes[a].block < heroes[b].block
		return false)
	return sorted[0]

func eligible(range_px: int, include_down: bool = false) -> Array:
	var out = []
	for h in range(3):
		if heroes[h].dead or (heroes[h].down and not include_down): continue
		if distance(heroes[h].pos, boss.pos, 2) <= range_px: out.append(h)
	return out

func resolve_boss() -> void:
	if phase != "boss" or not mode.is_empty() or boss_step >= 3: return
	var action: String = boss_roll[boss_step]
	pending = {"action": action, "reacted": []}
	say("Boss die %s: %s." % [["I", "II", "III"][boss_step], action])
	match action:
		"Advance", "Skirmish": offer_boss_move(2 if action == "Advance" else 1, action)
		"Brace":
			boss.block += 2
			float_text(3, "+2 BLOCK", COLORS[0])
			boss_complete()
		"Distort":
			var target = closest(eligible(2))
			if target < 0: fallback()
			else:
				heroes[target].weak = true
				float_text(target, "WEAKNESS", COLORS[2])
				boss_complete()
		"Fracture":
			var targets = eligible(1).filter(func(h): return heroes[h].dice.any(func(f): return f not in [0, 12]))
			var target = closest(targets)
			if target < 0: fallback()
			else:
				pending.target = target
				mode = "fracture"
		_: prepare_attack(action)

func offer_boss_move(steps: int, action: String) -> void:
	var targets = eligible(100)
	if targets.is_empty(): boss_complete(); return
	var target = closest(targets)
	reachable = boss_route_options(target, steps)
	if reachable.is_empty():
		if action == "Skirmish": prepare_attack(action)
		elif action == "Fallback":
			boss.block += 1
			float_text(3, "+1 BLOCK", COLORS[0])
			boss_complete()
		else: fallback()
	else:
		pending.action = action
		mode = "boss_move"
		pending.move_target = target

func boss_route_options(target: int, steps: int) -> Dictionary:
	# Reverse BFS finds true shortest legal routes around hero footprints.
	var costs = {}
	var todo = []
	for y in range(8):
		for x in range(8):
			var p = Vector2i(x, y)
			if free_at(p, 3) and distance(heroes[target].pos, p, 2) == 1:
				costs[p] = 0
				todo.append(p)
	while not todo.is_empty():
		var p: Vector2i = todo.pop_front()
		for q in neighbors(p):
			if not costs.has(q) and free_at(q, 3):
				costs[q] = costs[p] + 1
				todo.append(q)
	var out = {}
	if not costs.has(boss.pos): return out
	var options = movement_options(3, steps)
	for p in options:
		if options[p] > 0 and costs.has(p) and options[p] + costs[p] == costs[boss.pos]: out[p] = options[p]
	return out

func fallback() -> void:
	say("No legal effect: fallback Move 1, or gain 1 Block.")
	offer_boss_move(1, "Fallback")

func prepare_attack(action: String) -> void:
	pending.action = action
	var candidates = eligible(1, action == "Sweep")
	if candidates.is_empty():
		if action == "Skirmish": boss_complete()
		else: fallback()
		return
	if action == "Sweep": pending.targets = candidates
	else: pending.targets = [closest(candidates, action == "Strike")]
	pending.reacted = pending.get("reacted", [])
	phase = "boss"
	mode = "reaction"
	resume_attack()

func resume_attack() -> void:
	if screen != "battle": return
	var targets: Array = pending.targets
	for h in targets:
		if not heroes[h].down and not heroes[h].react.is_empty() and not h in pending.get("reacted", []):
			pending.reactor = h
			mode = "reaction"
			return
	mode = "attack_ready"

func use_reaction() -> void:
	var h: int = pending.reactor
	if heroes[h].react.is_empty(): return
	heroes[h].react.pop_front()
	heroes[h].block += 1
	pending.reacted.append(h)
	float_text(h, "+1 BLOCK", COLORS[0])
	emit(unit_center(h), COLORS[0], 18)
	reachable = movement_options(h, 1)
	mode = "reaction_move"
	sfx("block")

func execute_attack() -> void:
	var action: String = pending.action
	var targets: Array = pending.targets.duplicate()
	var legal = []
	for h in targets:
		if not heroes[h].dead and (not heroes[h].down or action == "Sweep") and distance(heroes[h].pos, boss.pos, 2) == 1: legal.append(h)
	if action != "Sweep" and legal.is_empty():
		pending.reacted = []
		prepare_attack(action)
		return
	for h in legal:
		damage(h, 2 if action == "Strike" else 1)
		if screen != "battle": return
	if action == "Drive Back" and not legal.is_empty():
		choose_push(3, legal[0], true, true)
		return
	boss_complete()

func boss_complete() -> void:
	mode = ""
	reachable.clear()
	boss_step += 1
	if boss_step >= 3: finish_turn()

func choose_push(source: int, target: int, collision: bool, boss_push: bool) -> void:
	var dirs = []
	var from = unit_pos(source)
	var pos = unit_pos(target)
	var old = distance(pos, from, 2 if source == 3 else 1) if target != 3 else distance(from, pos, 2)
	for dir in [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]:
		var dest = pos + dir
		var dist = distance(dest, from, 2 if source == 3 else 1) if target != 3 else distance(from, dest, 2)
		if dist > old: dirs.append({"dir": dir, "dest": dest})
	pending = {"target": target, "choices": dirs, "collision": collision, "boss_push": boss_push}
	mode = "push_direction"
	if dirs.is_empty():
		if boss_push: boss_complete()
		else: consume()

func apply_push(target: int, dir: Vector2i, collision: bool) -> void:
	var dest = unit_pos(target) + dir
	if free_at(dest, target):
		move_unit(target, dest)
	elif collision:
		damage(target, 1, true)
		if target < 3 and not heroes[target].down and not heroes[target].dead:
			if heroes[target].stun: damage(target, 1)
			elif not unresolved(target).is_empty():
				heroes[target].stun = true
				if active == target and not unresolved(target).is_empty(): mode = "stun"
		say("Collision! 1 unavoidable damage + Stunned.")
	else: say("Shove stops at the obstruction; no collision penalty.")

func draw_battle() -> void:
	var visual_mode = mode
	var display_reachable = reachable
	var hovered = hovered_die()
	if selected < 0 and hovered >= 0 and active < 3 and not heroes[active].spent[hovered] and mode.is_empty():
		var f: int = heroes[active].dice[hovered * 6 + heroes[active].roll[hovered]]
		if f in [2, 3, 11]: display_reachable = movement_options(active, 3 if f == 3 else (2 if f == 11 else 1), f == 3)
		elif f in [0, 12] and blank_step_enabled() and not heroes[active].soul_used: display_reachable = movement_options(active, 1)
		elif f in [1, 9]: visual_mode = "attack"
		elif f == 7: visual_mode = "heal"
		elif f == 8: visual_mode = "shove"
	text_at(Vector2(40, 44), "DICEBOUND", 24, GOLD)
	text_at(Vector2(248, 43), "THE HOLLOW TRIBUNAL / v0.5", 13, MUTED)
	text_at(Vector2(556, 43), "ROUND %02d" % round_no, 14, GOLD)
	for i in range(4):
		var h: int = order[i]
		var x = 712 + i * 134
		var color: Color = RED if h == 3 else COLORS[h]
		box(Rect2(x, 65, 126, 29), color.darkened(0.85), GOLD if active == h else EDGE)
		text_at(Vector2(x + 7, 84), ("HOLLOW" if h == 3 else NAMES[h]) + " [%d]" % initiative[h], 11, color)
	text_at(Vector2(40, 80), "THE HOLLOW ONE", 16, RED)
	text_at(Vector2(278, 80), "BLOCK %d" % boss.block, 12, COLORS[0])
	text_at(Vector2(557, 80), "%02d / 18 HP" % boss.hp, 14, INK)
	for n in range(18): draw_rect(Rect2(40 + n * 35, 88, 32, 7), RED if n < boss.hp else Color("332636"))
	var offset = Vector2(sin(time * 110), cos(time * 90)) * shake
	box(Rect2(BOARD - Vector2(5, 5), Vector2.ONE * CELL * 9 + Vector2(8, 8)), Color("141925"), Color("514151"))
	for torch_pos in [BOARD + Vector2(-18, 12), BOARD + Vector2(CELL * 9 + 16, 12), BOARD + Vector2(-18, CELL * 9 - 12), BOARD + Vector2(CELL * 9 + 16, CELL * 9 - 12)]:
		for ring in range(4, 0, -1): pixel_circle(torch_pos, ring * 7, Color(1.0, 0.5, 0.15, 0.018))
		draw_rect(Rect2(torch_pos + Vector2(-2, 1), Vector2(5, 13)), Color("79665b"))
		draw_rect(Rect2(torch_pos + Vector2(-3, -8 - int(sin(time * 12 + torch_pos.x) * 2)), Vector2(7, 10)), GOLD)
		draw_rect(Rect2(torch_pos + Vector2(-1, -5), Vector2(3, 5)), Color("fff0b4"))
	var mouse_cell = board_cell(get_local_mouse_position())
	for y in range(9):
		for x in range(9):
			var p = Vector2i(x, y)
			var r = Rect2(BOARD + Vector2(p) * CELL + offset, Vector2.ONE * (CELL - 2))
			var color = Color("282d3d") if (x + y) % 2 else Color("30374a")
			draw_rect(r, color)
			draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(CELL - 8, 1)), color.lightened(0.09))
			if (x * 13 + y * 7) % 11 == 0: draw_line(r.position + Vector2(12, 6), r.position + Vector2(18, 19), color.darkened(0.3), 2)
			if display_reachable.has(p):
				draw_rect(r, Color(0.35, 0.8, 0.68, 0.19))
				draw_rect(r.grow(-3), TEAL, false, 2)
				if display_reachable[p] > 0: text_at(r.position + Vector2(31, 40), str(display_reachable[p]), 17, TEAL)
			if active == 3 and mode in ["reaction", "reaction_move", "attack_ready"]:
				var occupant = unit_at(p)
				if occupant >= 0 and occupant in pending.get("targets", []): draw_rect(r.grow(-3), RED, false, 3)
			if visual_mode in ["attack", "heal", "shove"] and active < 3:
				var target = unit_at(p)
				if target >= 0:
					var dist = distance(heroes[active].pos, unit_pos(target), 2 if target == 3 else 1)
					if (dist == 1 and visual_mode != "heal") or (visual_mode == "heal" and target < 3 and dist <= 1):
						draw_rect(r, Color(0.8, 0.25, 0.35, 0.12) if visual_mode == "attack" else Color(0.3, 0.8, 0.6, 0.12))
						draw_rect(r.grow(-4), RED if visual_mode == "attack" else TEAL, false, 3)
			if mode == "push_direction":
				for choice in pending.choices:
					if p in footprint(choice.dest, 2 if pending.target == 3 else 1): draw_rect(r.grow(-5), GOLD, false, 2)
			if p == mouse_cell and display_reachable.has(p): draw_rect(r.grow(-2), Color(INK, 0.65), false, 2)
	for x in range(9): text_at(BOARD + Vector2(x * CELL + CELL / 2 - 4, CELL * 9 + 18), str(x + 1), 12, MUTED)
	for y in range(9): text_at(BOARD + Vector2(-21, y * CELL + CELL / 2 + 4), char(65 + y), 12, MUTED)
	var bc = unit_center(3) + offset
	pixel_circle(bc, 59 + int(sin(time * 2) * 3), Color(0.9, 0.23, 0.36, 0.09))
	var br = Rect2(BOARD + Vector2(boss.pos) * CELL + offset + Vector2(2, 2), Vector2.ONE * (CELL * 2 - 6))
	draw_rect(br, Color(0.60, 0.23, 0.32, 0.18))
	draw_rect(br, RED.darkened(0.3), false, 2)
	draw_boss(bc + Vector2(0, sin(time * 2) * 2), 2)
	if hurt_timers.get(3, 0.0) > 0: draw_rect(br, Color(1, 0.4, 0.4, hurt_timers[3] * 0.7))
	for h in range(3):
		var u: Dictionary = heroes[h]
		if u.dead: continue
		var center = unit_center(h) + offset
		if active == h:
			draw_rect(Rect2(center - Vector2(32, 32), Vector2(64, 64)), COLORS[h], false, 2)
			draw_rect(Rect2(center - Vector2(32, 32), Vector2(5, 5)), GOLD)
		draw_hero(center + Vector2(0, sin(time * 2.5 + h) * 1.5), h, 2, u.down)
		if hurt_timers.get(h, 0.0) > 0: draw_rect(Rect2(center - Vector2(24, 32), Vector2(48, 57)), Color(1, 0.7, 0.6, hurt_timers[h]))
		for n in range(6): draw_rect(Rect2(center + Vector2(-27 + n * 9, 29), Vector2(7, 4)), COLORS[h] if n < u.hp else Color("191b28"))
		if u.block > 0: text_at(center + Vector2(22, -23), str(u.block), 14, COLORS[0])
		if not u.react.is_empty(): text_at(center + Vector2(-29, -24), "!", 18, GOLD)
	box(Rect2(710, 108, 538, 503))
	text_at(Vector2(724, 131), "BOSS INTENTIONS / HOVER FOR DETAILS", 11, MUTED)
	for d in range(3):
		var x = 724 + d * 172
		var r = Rect2(x, 143, 160, 56)
		box(r, Color("242234"), GOLD if active == 3 and boss_step == d else EDGE)
		text_at(Vector2(x + 9, 160), ["I", "II", "III"][d], 10, MUTED)
		text_at(Vector2(x + 9, 184), boss_roll[d], 13, RED)
		if r.has_point(get_local_mouse_position()): hover_tip = BOSS_TIPS.get(boss_roll[d], "")
	if active < 3: draw_hero_console()
	else: draw_boss_console()
	if mode == "push_direction":
		for i in range(pending.choices.size()):
			var choice: Dictionary = pending.choices[i]
			var direction = "LEFT" if choice.dir == Vector2i.LEFT else ("RIGHT" if choice.dir == Vector2i.RIGHT else ("UP" if choice.dir == Vector2i.UP else "DOWN"))
			if not free_at(choice.dest, pending.target): direction += " / WALL"
			button(Rect2(724 + i * 128, 550, 122, 38), direction, "push:%d" % i, true, GOLD)
	for h in range(3):
		var x = 710 + h * 182
		var u: Dictionary = heroes[h]
		box(Rect2(x, 626, 174, 65), COLORS[h].darkened(0.87), COLORS[h].darkened(0.4))
		text_at(Vector2(x + 9, 646), NAMES[h], 13, COLORS[h])
		text_at(Vector2(x + 9, 665), "%d/6 HP  %d BLK" % [u.hp, u.block], 11, MUTED)
		var status = "DEAD" if u.dead else ("DOWN" if u.down else ("BROKEN" if u.broken else ("WEAK" if u.weak else "")))
		if u.stun: status += " STUN"
		text_at(Vector2(x + 88, 646), status, 9, RED)
		for d in range(3):
			var face: int = u.dice[d * 6 + u.roll[d]]
			text_at(Vector2(x + 9 + d * 53, 682), SIGNS[face], 9, GOLD if d in u.react else (MUTED.darkened(0.35) if u.spent[d] else face_color(face)))
	text_at(Vector2(724, 712), "ENCOUNTER CHRONICLE", 10, GOLD)
	for i in range(mini(3, log_lines.size())): text_at(Vector2(724, 731 + i * 17), str(log_lines[i]).left(73), 11, MUTED)

func draw_boss_console() -> void:
	text_at(Vector2(724, 229), "THE HOLLOW ONE / ACTIVATION", 18, RED)
	var instruction = "Resolve I, II, III in order. Space continues."
	match mode:
		"boss_move": instruction = "Choose a highlighted boss destination, or let the route helper choose."
		"reaction": instruction = NAMES[pending.reactor] + " is targeted. Tactical Defense can block and step."
		"reaction_move": instruction = "Gained 1 Block. Step to a green square, or stay."
		"attack_ready":
			var targets = []
			for h in pending.targets: targets.append(NAMES[h])
			instruction = pending.action + " targets " + ", ".join(targets) + ". Confirm to resolve."
		"fracture": instruction = NAMES[pending.target] + ": choose a face to lose for this encounter. Locked faces are protected."
		"push_direction": instruction = "Choose a gold direction. Wall collisions deal 1 unavoidable damage + Stunned."
	wrapped(Vector2(724, 265), instruction, 55, GOLD, 14)
	if mode == "reaction":
		button(Rect2(724, 347, 510, 42), "USE TACTICAL DEFENSE / +1 BLOCK, STEP 1", "react", true, TEAL)
		button(Rect2(724, 402, 510, 37), "DECLINE REACTION", "decline", true, MUTED)
	elif mode == "reaction_move": button(Rect2(724, 347, 510, 42), "STAY HERE / CONTINUE", "stay", true, TEAL)
	elif mode == "attack_ready": button(Rect2(724, 347, 510, 45), "RESOLVE " + pending.action.to_upper() + " [ENTER]", "attack_confirm", true, RED)
	elif mode == "fracture":
		for d in range(3):
			for side in range(6):
				var slot = d * 6 + side
				var f: int = heroes[pending.target].dice[slot]
				if f not in [0, 12]: button(Rect2(724 + side * 85, 334 + d * 50, 78, 40), SIGNS[f], "fracture:%d" % slot, true, face_color(f))
	elif mode == "boss_move": button(Rect2(724, 347, 510, 43), "CHOOSE A ROUTE FOR ME", "auto_move", true, TEAL)
	elif mode.is_empty(): button(Rect2(724, 347, 510, 45), "RESOLVE DIE " + ["I", "II", "III"][mini(boss_step, 2)] + " [SPACE]", "boss_next", true, RED)
	if mode not in ["fracture", "push_direction"]:
		wrapped(Vector2(724, 527), "Targets are rechecked after Reactions. If none remain legal, the boss uses its printed fallback.", 64, MUTED, 12)

func draw_result() -> void:
	text_at(Vector2(66, 68), "DICEBOUND / ENCOUNTER COMPLETE", 16, GOLD)
	text_at(Vector2(66, 164), "SOUL RECLAIMED" if victory else "THE FLAME FADES", 54, INK if victory else RED)
	text_at(Vector2(68, 214), "The Hollow One remembers silence." if victory else "Even broken souls may rise again.", 20, MUTED)
	for h in range(3):
		var x = 67 + h * 394
		box(Rect2(x, 280, 370, 266), PANEL, COLORS[h].darkened(0.4))
		draw_hero(Vector2(x + 63, 356), h, 2)
		text_at(Vector2(x + 123, 329), NAMES[h], 22, COLORS[h])
		text_at(Vector2(x + 123, 359), "BOUND SOUL" if victory else "SOUL UNBROKEN", 14, GOLD)
		wrapped(Vector2(x + 23, 425), "Reward: once each turn, spend one rolled Blank to Move 1. 6 HP. Three Blanks per die." if victory else "Clean restart: restored HP, recorded dice, and no persistent test penalty.", 35, MUTED, 14)
	if victory and blank_min == 2:
		wrapped(Vector2(68, 591), "Reward Soul requires three Blanks per die. Rebuild legally before the rematch; no two-Blank reward Soul is used.", 95, GOLD, 15)
	else:
		wrapped(Vector2(68, 591), "Recover at camp, rebuild your dice, then resolve an event before the next fight. Event injuries and curses carry into battle.", 95, MUTED, 15)
	button(Rect2(67, 665, 356, 52), "PREPARE NEXT JOURNEY", "return_build", true, GOLD)
	button(Rect2(445, 665, 356, 52), "CAMP / EVENTS", "camp", true, TEAL)
	button(Rect2(823, 665, 356, 52), "TITLE", "title", true, MUTED)

func draw_help() -> void:
	draw_rect(Rect2(0, 0, 1280, 800), Color(0.02, 0.03, 0.06, 0.92))
	box(Rect2(145, 65, 990, 670), PANEL, GOLD)
	text_at(Vector2(176, 111), "THE FIELD GUIDE", 28, GOLD)
	var lines = ["01  BUILD: three mixed six-sided dice per hero. Own copies matter.", "    Original Soul: at least 3 Blanks per die. Body caps: M3 / D3 / S3.", "02  ROLL: everyone rolls together each round. Initiative stays fixed.", "03  ACT: click a die, then a highlighted square or legal target.", "    Basic Strike = 1 damage. First Aid = 1 heal. No Numeric rolls.", "04  POSITION: orthogonal movement. FULL expands the browser view.", "    Boss: 2 x 2 squares. Tactical Movement: up to 3 straight.", "05  REACT: Tactical Defense stores automatically. Gain 1 Block and", "    optionally step when attacked. Unused Reactions expire next roll.", "06  SURVIVE: Block absorbs damage, expires at your own turn start.", "    At 0 HP: Downed. First Aid revives with Broken + a recovery turn.", "    A Broken hero reaching 0 dies. All Downed/dead = immediate loss.", "07  BOSS: resolve I, II, III. You choose legal routes, push directions", "    and the face lost to Fracture. Enemy intentions are public.", "08  WIN: reduce the boss's 18 HP to zero. Earn a Bound Move-1 Soul.", "", "CONTROLS  Mouse: select/use   1/2/3: dice   E: end turn   Esc: cancel/help", "", "One local player controls all three heroes. Hero ties use roster order.", "JOURNEY: prepare, resolve an event, then fight with its injuries.", "TEST BLANK STEP above: spend one Blank to Move 1 per hero turn."]
	for i in range(lines.size()): text_at(Vector2(177, 152 + i * 24), lines[i], 14, MUTED if i > 16 else INK)
	button(Rect2(853, 677, 245, 39), "BACK TO THE FIRE", "help", true, GOLD)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if screen == "battle" and phase == "hero" and not help_open and mode not in ["focus", "stun", "push_direction"]:
			handle("cancel_ability")
			accept_event()
			return
	if event is InputEventMouseMotion:
		var clickable = false
		for hit in hits:
			if hit.r.has_point(event.position): clickable = true
		if screen == "battle":
			var cell = board_cell(event.position)
			if reachable.has(cell): clickable = true
			if active < 3 and mode in ["attack", "heal", "shove"]:
				var target = unit_at(cell)
				if target >= 0 and selected >= 0:
					var f: int = heroes[active].dice[selected * 6 + heroes[active].roll[selected]]
					if target in legal_ability_targets(f): clickable = true
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(hits.size() - 1, -1, -1):
			if hits[i].r.has_point(event.position):
				var id: String = hits[i].id
				if help_open and id != "help": return
				handle(id)
				accept_event()
				return
		if help_open: return
		var p = Vector2i((event.position - BOARD) / CELL)
		if event.position.x >= BOARD.x and event.position.y >= BOARD.y and p.x < 9 and p.y < 9: board_click(p)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if screen == "battle" and phase == "hero" and not help_open and (end_confirm or selected >= 0) and mode not in ["focus", "stun", "push_direction"]:
				handle("cancel_ability")
			else: help_open = not help_open
		elif not help_open and screen == "battle":
			if event.keycode in [KEY_1, KEY_2, KEY_3]: choose_ability(event.keycode - KEY_1)
			if event.keycode == KEY_E and phase == "hero" and mode != "stun": request_end_turn()
			if event.keycode == KEY_ENTER:
				if mode == "confirm" and armed_die >= 0: handle("activate")
				elif mode == "attack_ready": handle("attack_confirm")
			if event.keycode == KEY_SPACE and phase == "boss" and mode.is_empty(): resolve_boss()

func _exit_tree() -> void:
	if is_instance_valid(audio):
		audio.stop()
		audio.stream = null
	if is_instance_valid(music):
		music.stop()
		music.stream = null

func handle(id: String) -> void:
	if id == "blank_step_toggle":
		blank_step_test = not blank_step_test
		if not blank_step_enabled() and mode == "move_soul":
			selected = -1
			mode = ""
			reachable.clear()
		save_progress()
		notify("Test rule " + ("ON: spend a rolled Blank to Move 1, once per hero turn." if blank_step_test else "OFF. Earned Soul movement remains available."))
		return
	if id == "fullscreen":
		var fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if id == "help": help_open = not help_open; return
	if id == "sound":
		sound_on = not sound_on
		music.stream_paused = not sound_on
		return
	if id == "build": screen = "build"
	elif id == "title": screen = "title"
	elif id == "quick" or id == "start" or id == "rematch": venture_out()
	elif id == "camp": open_camp()
	elif id == "event_roll": reveal_event()
	elif id == "event_fight": start_battle()
	elif id == "pool_starter": pool_page = 0
	elif id == "pool_found": pool_page = 1
	elif id == "refill_events": refill_events()
	elif id.begins_with("test_event:"): reveal_event(int(id.get_slice(":", 1)))
	elif id.begins_with("event_hero:"):
		event_target = int(id.get_slice(":", 1))
		save_progress()
	elif id.begins_with("event_choice:"): resolve_event(int(id.get_slice(":", 1)))
	elif id == "return_build": open_preparation()
	elif id == "soul":
		if journey_stage in ["event", "resolved", "battle"]:
			notify("Soul selection is locked for this journey.")
			return
		if reward: notify("The reward Soul requires 3 Blanks per die.")
		else: blank_min = 2 if blank_min == 3 else 3
	elif id == "reset_build": apply_preset("Balanced")
	elif id.begins_with("hero:"): builder = int(id.get_slice(":", 1))
	elif id.begins_with("paint:"):
		paint_face = int(id.get_slice(":", 1))
		equip_face(build_slot, paint_face)
	elif id.begins_with("slot:"):
		build_slot = int(id.get_slice(":", 1))
		paint_face = builds[builder][build_slot]
		sfx("step")
	elif id.begins_with("die:"): choose_ability(int(id.get_slice(":", 1)))
	elif id == "end": request_end_turn()
	elif id == "confirm_end": finish_turn()
	elif id == "activate":
		var d = armed_die
		armed_die = -1
		if d >= 0: select_die(d)
	elif id == "cancel_ability":
		armed_die = -1
		selected = -1
		end_confirm = false
		if mode != "stun": mode = ""
		reachable.clear()
	elif id.begins_with("target:"): board_click(unit_pos(int(id.get_slice(":", 1))))
	elif id.begins_with("preset:"): apply_preset(id.get_slice(":", 1))
	elif id == "spend": consume()
	elif id == "boss_next": resolve_boss()
	elif id == "auto_move":
		var cells = reachable.keys()
		if not cells.is_empty(): board_click(cells[0])
	elif id == "react": use_reaction()
	elif id == "decline":
		pending.reacted.append(pending.reactor)
		resume_attack()
	elif id == "stay": resume_attack()
	elif id == "attack_confirm": execute_attack()
	elif id.begins_with("push:"):
		var choice: Dictionary = pending.choices[int(id.get_slice(":", 1))]
		var is_boss: bool = pending.boss_push
		apply_push(pending.target, choice.dir, pending.collision)
		if is_boss: boss_complete()
		else: consume()
	elif id.begins_with("fracture:"):
		var slot = int(id.get_slice(":", 1))
		var h: int = pending.target
		if heroes[h].dice[slot] in [0, 12]: return
		heroes[h].dice[slot] = 0
		for d in range(3):
			if d * 6 + heroes[h].roll[d] == slot:
				# Keep the recorded result unless its supporting face is lost.
				heroes[h].spent[d] = true
				heroes[h].react.erase(d)
		say(NAMES[h] + " loses one face to Fracture (encounter only).")
		boss_complete()

func choose_ability(d: int) -> void:
	if active >= 3 or phase != "hero" or roll_anim > 0: return
	if mode in ["focus", "stun"]:
		select_die(d)
		return
	var u: Dictionary = heroes[active]
	if u.spent[d]:
		notify("Reaction stored automatically." if d in u.react else "This die has already been spent.")
		return
	end_confirm = false
	armed_die = -1
	var f: int = u.dice[d * 6 + u.roll[d]]
	if f in [4, 6, 10] or (f in [0, 12] and (not blank_step_enabled() or u.soul_used)):
		selected = d
		armed_die = d
		mode = "confirm"
		reachable.clear()
		sfx("step")
	else:
		select_die(d)
		sfx("step")

func ready_action_count() -> int:
	if active >= 3: return 0
	var count = 0
	for d in unresolved(active):
		var f: int = heroes[active].dice[d * 6 + heroes[active].roll[d]]
		if f not in [0, 12] or (blank_step_enabled() and not heroes[active].soul_used): count += 1
	return count

func request_end_turn() -> void:
	if mode == "stun": return
	if end_confirm or ready_action_count() == 0: finish_turn()
	else: end_confirm = true

func hovered_die() -> int:
	if active >= 3 or phase != "hero": return -1
	for d in range(3):
		if ability_card_rect(d).has_point(get_local_mouse_position()): return d
	return -1

func ability_card_rect(d: int) -> Rect2:
	return Rect2(724, 248 + d * 82, 510, 74)

func legal_ability_targets(f: int) -> Array:
	var targets = []
	if active >= 3: return targets
	for h in range(4):
		if h < 3 and heroes[h].dead: continue
		var dist = distance(heroes[active].pos, unit_pos(h), 2 if h == 3 else 1)
		if f == 7 and h < 3 and dist <= 1: targets.append(h)
		if f in [1, 8, 9] and h != active and dist == 1: targets.append(h)
	return targets

func draw_ability_card(d: int) -> void:
	var u: Dictionary = heroes[active]
	var f: int = u.dice[d * 6 + u.roll[d]]
	var r = ability_card_rect(d)
	var stored = d in u.react
	var spent: bool = u.spent[d] and not stored
	var hover = r.has_point(get_local_mouse_position())
	var color = face_color(f) if not spent else MUTED.darkened(0.4)
	if f in [0, 12] and blank_step_enabled() and not u.soul_used: color = TEAL
	box(r, color.darkened(0.86) if hover or selected == d else Color("202639"), GOLD if selected == d else color.darkened(0.28))
	draw_rect(Rect2(r.position, Vector2(4, r.size.y)), color)
	text_at(r.position + Vector2(13, 23), "[%d] %s" % [d + 1, SHORT_NAMES[f]], 16, INK if not spent else MUTED)
	var value: String = POWER[f]
	if f in [1, 9] and u.weak: value = "%d DMG / WEAK" % attack_value(active, f)
	if f in [0, 12] and blank_step_enabled(): value = "STEP USED" if u.soul_used else "MOVE 1"
	if roll_anim > 0: value = ". . ."
	text_at(r.position + Vector2(320, 25), value, 17, color)
	text_at(r.position + Vector2(13, 44), CATS[f].to_upper() + " / " + ("COST: 1 ROLLED DIE" if not stored else "STORED REACTION"), 10, color)
	var state = "READY / CLICK OR PRESS %d" % (d + 1)
	if spent: state = "SPENT THIS ROUND"
	elif stored: state = "AUTO: WHEN AN ATTACK TARGETS YOU"
	elif f in [1, 8, 9] and legal_ability_targets(f).is_empty(): state = "NO ADJACENT TARGET / MOVE CLOSER FIRST"
	elif f in [0, 12]:
		if blank_step_enabled(): state = "ONCE-PER-TURN STEP ALREADY USED" if u.soul_used else "SPEND THIS BLANK / ONCE PER HERO TURN"
		else: state = "NO EFFECT / ENABLE BLANK STEP ABOVE"
	text_at(r.position + Vector2(13, 62), state, 10, GOLD if stored else MUTED)
	if not spent: hits.append({"r": r, "id": "die:%d" % d})
	if hover: hover_tip = FACES[f] + " / " + face_description(f)

func draw_hero_console() -> void:
	var u: Dictionary = heroes[active]
	text_at(Vector2(724, 224), NAMES[active] + (" / RECOVERY" if recovery_active else " / YOUR TURN"), 18, COLORS[active])
	button(Rect2(1080, 207, 154, 29), "END TURN [E]", "end", mode != "stun", GOLD)
	if blank_step_enabled(): text_at(Vector2(724, 240), "BLANK STEP: " + ("USED THIS TURN" if u.soul_used else "READY / SPEND ONE ROLLED BLANK"), 10, MUTED if u.soul_used else TEAL)
	for d in range(3): draw_ability_card(d)
	if end_confirm:
		box(Rect2(718, 500, 522, 104), Color("302534"), GOLD)
		text_at(Vector2(731, 526), "%d unused ability result(s). End this turn?" % ready_action_count(), 13, GOLD)
		button(Rect2(731, 547, 241, 39), "YES / END TURN", "confirm_end", true, RED)
		button(Rect2(985, 547, 241, 39), "KEEP PLAYING", "cancel_ability", true, TEAL)
		return
	if selected < 0:
		text_at(Vector2(724, 524), "CHOOSE AN ABILITY, THEN A HIGHLIGHTED TARGET", 13, GOLD)
		text_at(Vector2(724, 549), "Hover a card to preview reach. 1 / 2 / 3 select.", 12, MUTED)
		if mode == "stun": wrapped(Vector2(724, 574), "STUNNED: choose one ready card to set its die aside.", 60, RED, 12)
		else: text_at(Vector2(724, 578), "Esc / right-click cancels an uncommitted choice.", 12, MUTED)
		return
	var f: int = u.dice[selected * 6 + u.roll[selected]]
	var instruction = "Choose a highlighted target."
	match mode:
		"move": instruction = "MOVE / choose a GREEN square. Numbers show steps."
		"move_soul": instruction = "BLANK STEP / Move 1. Once per hero turn."
		"attack": instruction = "ATTACK / choose a RED target or a button below."
		"heal": instruction = "HEAL / choose yourself or an adjacent hero."
		"shove": instruction = "SHOVE / choose an adjacent unit, then a direction."
		"focus": instruction = "FOCUS / choose ANOTHER ready card to reroll."
		"confirm": instruction = "PREVIEW / nothing has been spent yet."
		"push_direction": instruction = "PUSH / choose a direction below."
	text_at(Vector2(724, 519), instruction, 12, GOLD)
	if mode == "push_direction": return
	if mode == "confirm":
		var label = "GAIN %d BLOCK [ENTER]" % (2 if f == 10 else 1) if f in [4, 10] else ("USE FOCUS [ENTER]" if f == 6 else "DISCARD BLANK")
		button(Rect2(724, 550, 326, 39), label, "activate", true, face_color(f))
		button(Rect2(1063, 550, 171, 39), "CANCEL / FREE", "cancel_ability", true, MUTED)
	elif mode in ["attack", "heal", "shove"]:
		var targets = legal_ability_targets(f)
		if targets.is_empty(): text_at(Vector2(724, 545), "No legal target. Move closer using another ability.", 11, MUTED)
		else:
			for i in range(mini(targets.size(), 3)):
				var h: int = targets[i]
				var label = "HOLLOW" if h == 3 else NAMES[h]
				if f in [1, 9]:
					var unit: Dictionary = boss if h == 3 else heroes[h]
					label += " -%d HP" % maxi(0, attack_value(active, f) - unit.block)
				elif f == 7: label += " +%d HP" % mini(1, 6 - heroes[h].hp)
				button(Rect2(724 + i * 173, 534, 164, 30), label, "target:%d" % h, true, face_color(f))
		button(Rect2(724, 574, 245, 25), "CANCEL / FREE", "cancel_ability", true, MUTED)
		button(Rect2(982, 574, 252, 25), "DISCARD RESULT", "spend", true, MUTED)
	else:
		if mode != "focus": button(Rect2(724, 551, 245, 38), "CANCEL / FREE", "cancel_ability", true, MUTED)
		button(Rect2(982, 551, 252, 38), "DISCARD RESULT", "spend", true, MUTED)

func equip_face(slot: int, face: int) -> void:
	if journey_stage in ["event", "resolved", "battle"]:
		notify("Builds are committed until this encounter ends.")
		return
	if builds[builder][slot] == 12:
		notify("Cursed Blank is locked. Find an event that cleanses it.")
		return
	var previous: Array = builds[builder].duplicate()
	var old: int = builds[builder][slot]
	var swapped = false
	if face != old and face != 0 and builds[builder].count(face) >= face_capacity(builder, face):
		if face_capacity(builder, face) == 1:
			var source: int = builds[builder].find(face)
			builds[builder][source] = old
			swapped = true
	builds[builder][slot] = face
	var error = build_error(builder)
	if not error.is_empty() and face != 0:
		builds[builder] = previous
		notify(error + " Clear a side or swap two equipped abilities.")
		return
	sfx("carve")
	notify(("Moved your owned " if swapped else "Equipped ") + FACES[face] + (" / previous sides swapped." if swapped else ". No HP or gold cost."))

func apply_preset(which: String) -> void:
	if journey_stage in ["event", "resolved", "battle"]:
		notify("Builds are committed until this encounter ends.")
		return
	var previous: Array = builds[builder].duplicate()
	match which:
		"Assault": builds[builder] = [1, 1, 2, 0, 0, 0, 1, 3, 5, 0, 0, 0, 1, 7, 2, 0, 0, 0]
		"Support": builds[builder] = [1, 2, 4, 0, 0, 0, 7, 3, 5, 0, 0, 0, 6, 8, 2, 0, 0, 0]
		_: builds[builder] = [1, 2, 4, 0, 0, 0, 1, 3, 5, 0, 0, 0, 1, 7, 6, 0, 0, 0]
	for slot in range(18):
		if previous[slot] == 12: builds[builder][slot] = 12
	if not build_error(builder).is_empty():
		builds[builder] = previous
		notify("That preset needs faces you no longer own. Edit sides manually.")
		return
	build_slot = 0
	paint_face = builds[builder][0]
	sfx("carve")
	notify(which + " preset equipped. All ownership and Soul limits checked.")

# --- Between-encounter journey and original test events ---
func face_capacity(h: int, face: int) -> int:
	return owned_faces[h][face] if owned_faces.size() == 3 else LIMITS[face]

func blank_sides(sides: Array) -> int:
	return sides.count(0) + sides.count(12)

func attack_value(h: int, face: int) -> int:
	return maxi(0, (2 if face == 9 else 1) - (1 if heroes[h].weak else 0))

func write_journey(config: ConfigFile) -> void:
	config.set_value("journey", "version", 1)
	config.set_value("journey", "owned", owned_faces.duplicate(true))
	config.set_value("journey", "pool", event_pool.duplicate())
	config.set_value("journey", "stage", journey_stage)
	config.set_value("journey", "hp", trip_hp.duplicate())
	config.set_value("journey", "current", current_event)
	config.set_value("journey", "target", event_target)
	config.set_value("journey", "die", event_die)
	config.set_value("journey", "risk", event_risk_die)
	config.set_value("journey", "outcome", event_outcome)
	config.set_value("journey", "journal", event_journal.duplicate())
	config.set_value("journey", "feedback", event_feedback.duplicate(true))

func load_journey(config: ConfigFile) -> void:
	var stored = config.get_value("journey", "owned", [])
	if stored is Array and stored.size() == 3:
		for h in range(3):
			if stored[h] is Array and stored[h].size() == FACES.size() and stored[h].all(func(n): return n is int and n >= 0): owned_faces[h] = stored[h].duplicate()
	var pool = config.get_value("journey", "pool", [0, 1, 2, 3, 4, 5])
	if pool is Array:
		event_pool = []
		for id in pool:
			if id is int and id >= 0 and id < 6 and not id in event_pool: event_pool.append(id)
	var hp = config.get_value("journey", "hp", [6, 6, 6])
	if hp is Array and hp.size() == 3 and hp.all(func(n): return n is int and n >= 1 and n <= 6): trip_hp = hp.duplicate()
	journey_stage = str(config.get_value("journey", "stage", "prepare"))
	if journey_stage not in ["prepare", "event", "resolved", "battle", "aftermath"]: journey_stage = "prepare"
	current_event = clampi(int(config.get_value("journey", "current", -1)), -1, 5)
	event_target = clampi(int(config.get_value("journey", "target", 0)), 0, 2)
	event_die = clampi(int(config.get_value("journey", "die", 0)), 0, 6)
	event_risk_die = clampi(int(config.get_value("journey", "risk", 0)), 0, 6)
	event_outcome = str(config.get_value("journey", "outcome", "")).left(2000)
	event_feedback = []
	var changes = config.get_value("journey", "feedback", [])
	if changes is Array:
		for change in changes.slice(0, 8):
			if not change is Dictionary: continue
			if change.get("kind", "") not in ["hp", "face", "face_loss", "curse", "cleanse", "safe"]: continue
			if not change.get("hero", -1) is int or change.hero < 0 or change.hero > 2: continue
			if not change.get("value", null) is int: continue
			if change.kind in ["face", "face_loss"] and (not change.get("face", null) is int or change.face < 1 or change.face > 11): continue
			event_feedback.append(change.duplicate(true))
	event_reveal_elapsed = 2.0
	var journal = config.get_value("journey", "journal", [])
	if journal is Array:
		event_journal = []
		for entry in journal.slice(0, 20): event_journal.append(str(entry).left(500))
	if journey_stage in ["event", "resolved"] and current_event < 0: journey_stage = "prepare"

func recover_for_preparation() -> void:
	if journey_stage not in ["aftermath", "prepare"]: return
	trip_hp = [6, 6, 6]
	journey_stage = "prepare"
	current_event = -1
	event_die = 0
	event_risk_die = 0
	event_outcome = ""
	event_feedback = []
	event_scene_elapsed = 0.0
	if reward:
		blank_min = 3
		for h in range(3):
			for d in range(3):
				while blank_sides(builds[h].slice(d * 6, d * 6 + 6)) < 3:
					var removed = false
					for side in range(5, -1, -1):
						var slot = d * 6 + side
						if builds[h][slot] not in [0, 12]:
							builds[h][slot] = 0
							removed = true
							break
					if not removed: break

func open_preparation() -> void:
	if journey_stage in ["event", "resolved"]:
		screen = "event"
		notify("The journey is committed. Resolve the event, then fight; no free refitting.")
		return
	if journey_stage == "battle":
		start_battle()
		return
	recover_for_preparation()
	screen = "build"
	save_progress()

func open_camp() -> void:
	if journey_stage in ["aftermath", "prepare"]: recover_for_preparation()
	screen = "camp"
	save_progress()

func venture_out() -> void:
	if journey_stage in ["event", "resolved"]:
		screen = "event"
		return
	if journey_stage == "battle":
		start_battle()
		return
	recover_for_preparation()
	for h in range(3):
		if not build_error(h).is_empty():
			builder = h
			screen = "build"
			notify(build_error(h))
			return
	if event_pool.is_empty():
		screen = "camp"
		notify("The Event Pool is empty. Return to base; refill only to start a new test expedition.")
		return
	reveal_event()

func reveal_event(chosen_id: int = -1) -> void:
	if journey_stage in ["event", "resolved"]:
		screen = "event"
		return
	if journey_stage == "battle":
		notify("Finish the committed encounter before drawing another event.")
		return
	recover_for_preparation()
	for h in range(3):
		if not build_error(h).is_empty():
			screen = "build"
			builder = h
			notify("Complete a legal build before entering an event.")
			return
	if event_pool.is_empty():
		screen = "camp"
		return
	if chosen_id >= 0:
		if not chosen_id in event_pool:
			notify("That event has already left this pool.")
			return
		current_event = chosen_id
		event_die = chosen_id + 1
	else:
		# Unmapped numbers are rerolled; never renumber the remaining events.
		while true:
			event_die = rng.randi_range(1, 6)
			if event_die - 1 in event_pool:
				current_event = event_die - 1
				break
	journey_stage = "event"
	event_outcome = ""
	event_risk_die = 0
	event_feedback = []
	event_scene_elapsed = 0.0
	event_reveal_elapsed = 2.0
	screen = "event"
	sfx("event_reveal")
	save_progress()

func event_choice_allowed(choice: int) -> bool:
	if journey_stage != "event" or choice not in [0, 1]: return false
	var h = event_target
	if current_event == 0 and choice == 0: return trip_hp[h] > 2
	if current_event == 1 and choice == 1: return trip_hp[h] > 2
	if current_event == 2:
		return trip_hp[h] > 2 if choice == 0 else trip_hp.all(func(hp): return hp > 1)
	if current_event == 3 and choice == 0: return owned_faces[h][1] > 0
	if current_event == 4 and choice == 1: return trip_hp[h] > 1
	if current_event == 5 and choice == 1: return trip_hp[h] > 2
	if (current_event == 1 and choice == 0) or (current_event == 3 and choice == 1) or (current_event == 5 and choice == 0):
		return builds[h].any(func(f): return f != 12)
	return true

func grant_event_face(h: int, face: int) -> String:
	owned_faces[h][face] += 1
	return NAMES[h] + " permanently owns +1 " + FACES[face] + ". It stays in inventory until the NEXT preparation. "

func event_wound(h: int, value: int) -> String:
	trip_hp[h] -= value
	return NAMES[h] + " loses %d HP; enters battle at %d/6. " % [value, trip_hp[h]]

func add_cursed_blank(h: int) -> String:
	var slot = builds[h].find(0)
	if slot < 0:
		for i in range(18):
			if builds[h][i] != 12:
				slot = i
				break
	if slot < 0: return "No unlocked destination exists; curse placement fails. "
	builds[h][slot] = 12
	owned_faces[h][12] += 1
	return NAMES[h] + " gains a PERMANENT locked Cursed Blank on die %s, side %d. " % [["I", "II", "III"][slot / 6], slot % 6 + 1]

func destroy_basic_strike(h: int) -> String:
	if owned_faces[h][1] <= 0: return event_wound(h, 1)
	owned_faces[h][1] -= 1
	if builds[h].count(1) > owned_faces[h][1]:
		builds[h][builds[h].find(1)] = 0
	return NAMES[h] + " permanently loses one owned Basic Strike. A necessary equipped copy becomes Blank. "

func resolve_event(choice: int) -> void:
	if journey_stage != "event": return
	if not event_choice_allowed(choice):
		notify("Cannot pay this choice's printed cost. Choose another hero or option.")
		return
	var h = event_target
	var previous_hp: Array = trip_hp.duplicate()
	var previous_owned: Array = owned_faces.duplicate(true)
	var outcome = ""
	match current_event:
		0:
			if choice == 0: outcome = event_wound(h, 2) + grant_event_face(h, 9)
			else: outcome = "You leave the bell ringing. No reward, injury, or curse. "
		1:
			if choice == 0: outcome = grant_event_face(h, 10) + add_cursed_blank(h)
			else: outcome = event_wound(h, 2) + grant_event_face(h, 10)
		2:
			if choice == 0:
				event_risk_die = rng.randi_range(1, 6)
				outcome = "Risk die: %d. " % event_risk_die
				outcome += grant_event_face(h, 11) if event_risk_die >= 4 else event_wound(h, 2)
			else:
				for hero in range(3): outcome += event_wound(hero, 1)
				outcome += grant_event_face(h, 11)
		3:
			if choice == 0: outcome = destroy_basic_strike(h) + grant_event_face(h, 9)
			else: outcome = grant_event_face(h, 7) + add_cursed_blank(h)
		4:
			if choice == 0:
				var slot = builds[h].find(12)
				if slot >= 0:
					builds[h][slot] = 0
					owned_faces[h][12] = maxi(0, owned_faces[h][12] - 1)
					outcome = NAMES[h] + " permanently cleanses one Cursed Blank. Its lock is gone; that side remains Blank. "
				else: outcome = grant_event_face(h, 4)
			else: outcome = event_wound(h, 1) + grant_event_face(h, 7)
		5:
			if choice == 0: outcome = grant_event_face(h, 11) + add_cursed_blank(h)
			else:
				event_risk_die = rng.randi_range(1, 6)
				outcome = "Risk die: %d. " % event_risk_die
				if event_risk_die <= 2: outcome += destroy_basic_strike(h)
				elif event_risk_die <= 4: outcome += event_wound(h, 2)
				else: outcome += grant_event_face(h, 9)
	# Event consequences repair only the affected side; no voluntary post-event swap.
	event_outcome = outcome
	record_event_feedback(previous_hp, previous_owned)
	event_pool.erase(current_event)
	journey_stage = "resolved"
	event_journal.push_front(JourneyEvents.DATA[current_event].name + ": " + outcome)
	if event_journal.size() > 20: event_journal.resize(20)
	save_progress()

func refill_events() -> void:
	if journey_stage not in ["prepare", "aftermath"] or not event_pool.is_empty(): return
	recover_for_preparation()
	event_pool = [0, 1, 2, 3, 4, 5]
	save_progress()
	notify("New TEST expedition: six events restored. Owned faces and permanent curses remain.")

func draw_camp() -> void:
	text_at(Vector2(48, 61), "DICEBOUND / THE ROADS BETWEEN", 23, GOLD)
	text_at(Vector2(48, 120), "CAMPFIRE", 38, INK)
	text_at(Vector2(48, 156), "PREPARE  >  EVENT  >  LIMITED REFIT  >  BATTLE", 17, GOLD)
	for h in range(3):
		var x = 48 + h * 400
		box(Rect2(x, 191, 384, 183), COLORS[h].darkened(0.88), COLORS[h].darkened(0.3))
		draw_hero(Vector2(x + 48, 248), h, 2)
		text_at(Vector2(x + 100, 226), NAMES[h], 22, COLORS[h])
		text_at(Vector2(x + 100, 256), "%d / 6 HP" % trip_hp[h], 17, INK)
		text_at(Vector2(x + 18, 301), "PERMANENT CURSES: %d" % builds[h].count(12), 13, RED)
		text_at(Vector2(x + 18, 327), "FOUND FACES: CUT %d / WARD %d / STEP %d" % [owned_faces[h][9], owned_faces[h][10], owned_faces[h][11]], 12, TEAL)
		text_at(Vector2(x + 18, 352), "Rewards are equipped before the NEXT event.", 11, MUTED)
	text_at(Vector2(48, 418), "EVENT POOL / %d REMAIN" % event_pool.size(), 21, GOLD)
	text_at(Vector2(48, 449), "Roll normally, or choose a numbered event below to test it directly.", 14, MUTED)
	for i in range(6):
		var exists = i in event_pool
		var r = Rect2(48 + i * 200, 474, 184, 82)
		button(r, "TEST EVENT %d" % (i + 1) if exists else "RESOLVED", "test_event:%d" % i, exists and journey_stage == "prepare", GOLD if exists else MUTED)
	if journey_stage in ["event", "resolved"]:
		wrapped(Vector2(48, 594), "A journey is already committed. Resume its event; saved injuries, face losses and curses cannot be discarded by returning to camp.", 96, MUTED, 14)
	elif event_pool.is_empty():
		wrapped(Vector2(48, 594), "The Event Pool is empty: return to base without rolling. To keep testing, explicitly start a new test expedition. Permanent ownership and curses remain.", 96, MUTED, 14)
	else:
		wrapped(Vector2(48, 594), "All heroes recover before preparation. After you enter an event, its HP costs carry into battle. New rewards stay in inventory until your next preparation; curses stay locked until cleansed.", 96, MUTED, 14)
	button(Rect2(48, 678, 370, 49), "EDIT DICE / FOUND FACES" if journey_stage == "prepare" else "DICE COMMITTED", "build", journey_stage == "prepare", TEAL)
	var label = "ROLL NEXT EVENT"
	var action = "event_roll"
	if journey_stage in ["event", "resolved"]: label = "RESUME COMMITTED EVENT"
	if journey_stage == "battle": label = "RESTART COMMITTED FIGHT"; action = "rematch"
	if event_pool.is_empty() and journey_stage == "prepare": label = "NEW TEST EXPEDITION"; action = "refill_events"
	button(Rect2(438, 678, 470, 49), label, action, true, GOLD)
	button(Rect2(928, 678, 304, 49), "TITLE", "title", true, MUTED)

func draw_event() -> void:
	if current_event < 0: return
	var data: Dictionary = JourneyEvents.DATA[current_event]
	var resolved = journey_stage == "resolved"
	text_at(Vector2(40, 49), "DICEBOUND / EVENT %d" % (current_event + 1), 20, GOLD)
	text_at(Vector2(40, 98), data.name, 30, INK)
	text_at(Vector2(40, 125), data.tag, 12, GOLD)
	var scene = Rect2(40, 144, 640, 411)
	box(scene.grow(2), PANEL, GOLD.darkened(0.4))
	draw_event_art(scene, current_event)
	text_at(Vector2(53, 499), "CHOSEN HERO / PAYS AND RECEIVES" if not resolved else "CONSEQUENCES APPLIED / PARTY STATUS", 9, GOLD)
	for h in range(3):
		var r = Rect2(50 + h * 208, 506, 198, 42)
		box(r, COLORS[h].darkened(0.85), GOLD if event_target == h else COLORS[h].darkened(0.4))
		EventPresentation.portrait(self, Rect2(r.position + Vector2(5, 4), Vector2(33, 33)), h)
		text_at(r.position + Vector2(42, 17), NAMES[h], 13, COLORS[h])
		text_at(r.position + Vector2(42, 34), "%d / 6 HP" % trip_hp[h], 11, RED if trip_hp[h] < 6 else INK)
		var curses: int = builds[h].count(12)
		if curses > 0: text_at(r.position + Vector2(137, 17), "CURSE x%d" % curses, 9, COLORS[2])
		if not resolved: hits.append({"r": r, "id": "event_hero:%d" % h})
	box(Rect2(700, 144, 540, 411), Color("171c2d"), EDGE)
	text_at(Vector2(716, 171), "THE ROADS BETWEEN", 12, GOLD)
	wrapped(Vector2(716, 205), data.story, 60, INK, 14)
	if resolved:
		text_at(Vector2(716, 322), "THE CONSEQUENCE", 18, GOLD)
		var shown: Array = event_feedback
		if shown.is_empty(): shown = [{"kind":"record", "hero":event_target, "value":0}]
		for i in range(mini(4, shown.size())):
			if event_reveal_elapsed < i * 0.13: continue
			EventPresentation.feedback_chip(self, Rect2(716 + (i % 2) * 261, 337 + (i / 2) * 77, 247, 65), shown[i])
		text_at(Vector2(716, 518), "%d EVENTS REMAIN / OUTCOME SAVED" % event_pool.size(), 13, MUTED)
		box(Rect2(40, 575, 1200, 119), PANEL, EDGE)
		text_at(Vector2(57, 598), "THE CHOICE IS MADE", 12, GOLD)
		wrapped(Vector2(57, 624), event_outcome, 140, INK, 13)
		button(Rect2(40, 713, 1200, 42), "CONTINUE TO BATTLE / INJURIES AND CURSES RETAINED", "event_fight", event_reveal_elapsed >= 0.65, GOLD)
	else:
		text_at(Vector2(716, 350), "A BARGAIN AWAITS", 20, GOLD)
		wrapped(Vector2(716, 382), "Choose your hero in the scene. Then choose a bargain below. Wounds are immediate. New faces enter inventory; equip them during your next preparation.", 62, MUTED, 13)
		text_at(Vector2(716, 506), "EVENT DIE %d / %d REMAIN AFTER THIS CHOICE" % [event_die, event_pool.size() - 1], 12, MUTED)
		for choice in range(2):
			var r = Rect2(40 + choice * 610, 575, 590, 180)
			var option: Dictionary = data.choices[choice]
			var allowed = event_choice_allowed(choice)
			var over = r.has_point(get_local_mouse_position())
			box(r, Color("2a2c3e") if over and allowed else Color("202638"), GOLD if allowed else EDGE)
			text_at(r.position + Vector2(15, 25), option.name, 17, GOLD if allowed else MUTED)
			var badges: Array = EventPresentation.tags(current_event, choice)
			var cost_color = GOLD
			var cost_icon = "ward"
			if "CURSE" in badges[0]: cost_color = COLORS[2]; cost_icon = "curse"
			elif "HP" in badges[0]: cost_color = RED; cost_icon = "hp"
			elif "DESTROY" in badges[0]: cost_color = RED; cost_icon = "blade"
			elif "SAFE" in badges[0] or "CLEANSE" in badges[0]: cost_color = TEAL; cost_icon = "cleanse"
			EventPresentation.symbol(self, r.position + Vector2(555, 24), cost_icon, cost_color, 0.72)
			text_at(r.position + Vector2(15, 48), badges[0], 11, cost_color)
			text_at(r.position + Vector2(255, 48), badges[1], 11, TEAL)
			wrapped(r.position + Vector2(15, 73), option.text, 79, INK if allowed else MUTED, 11)
			button(Rect2(r.position + Vector2(15, 139), Vector2(560, 29)), "CHOOSE THIS BARGAIN" if allowed else "CANNOT PAY / CHOOSE ANOTHER HERO", "event_choice:%d" % choice, allowed, TEAL if choice == 0 else GOLD)

func draw_event_art(r: Rect2, event_id: int) -> void:
	EventPresentation.draw_scene(self, r, event_id)

func record_event_feedback(previous_hp: Array, previous_owned: Array) -> void:
	event_feedback = []
	for h in range(3):
		var hp_delta: int = trip_hp[h] - previous_hp[h]
		if hp_delta != 0: event_feedback.append({"kind":"hp", "hero":h, "value":hp_delta})
		for face in range(1, 12):
			var delta: int = owned_faces[h][face] - previous_owned[h][face]
			if delta != 0: event_feedback.append({"kind":"face" if delta > 0 else "face_loss", "hero":h, "face":face, "value":delta})
		var curse_delta: int = owned_faces[h][12] - previous_owned[h][12]
		if curse_delta != 0: event_feedback.append({"kind":"curse" if curse_delta > 0 else "cleanse", "hero":h, "value":curse_delta})
	if event_feedback.is_empty(): event_feedback.append({"kind":"safe", "hero":event_target, "value":0})
	event_reveal_elapsed = 0.0
	var harmful = event_feedback.any(func(change): return change.kind in ["hp", "curse", "face_loss"])
	sfx("event_bad" if harmful else "event_good")

func blank_step_enabled() -> bool:
	return reward or blank_step_test

func face_description(face: int) -> String:
	if face in [0, 12] and blank_step_enabled():
		return ("Locked face; still a Blank. " if face == 12 else "") + "Spend this rolled Blank to Move 1. Once per hero turn, shared by all Blanks. Cost: this die."
	return DESCS[face]

func board_cell(pos: Vector2) -> Vector2i:
	if not Rect2(BOARD, Vector2.ONE * CELL * 9).has_point(pos): return Vector2i(-1, -1)
	return Vector2i((pos - BOARD) / CELL)
