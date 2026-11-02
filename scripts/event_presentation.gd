class_name EventPresentation
extends RefCounted
## Presentation only: never rolls gameplay dice or applies consequences.
const SCENES: Texture2D = preload("res://assets/events/scenes.png")
const NPCS: Texture2D = preload("res://assets/events/npcs.png")
const HEROES: Texture2D = preload("res://assets/events/heroes.png")
const NAMES = ["THE GRAVE BELLKEEPER", "THE IRON STITCHER", "THE MOTH FERRYMAN", "THE ORCHARD WARDEN", "THE HOSPICE SISTER", "THE HOLLOW GUIDE"]
const TINTS = [Color("e7b86a"), Color("e66d78"), Color("73d2bd"), Color("d78a7c"), Color("d8ceae"), Color("b39bdf")]

static func atlas_region(texture: Texture2D, event_id: int) -> Rect2:
	var cell = Vector2(texture.get_width() / 2.0, texture.get_height() / 3.0)
	return Rect2(Vector2(event_id % 2, event_id / 2) * cell, cell)

static func symbol(g, center: Vector2, kind: String, color: Color, size: float = 1.0) -> void:
	match kind:
		"hp":
			var pattern = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
			for y in range(pattern.size()):
				for x in range(7):
					if pattern[y][x] == "1": g.draw_rect(Rect2(center + Vector2(x - 3.5, y - 3) * 3 * size, Vector2.ONE * 3 * size), color)
		"ward":
			g.draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -13) * size, center + Vector2(12, -13) * size, center + Vector2(10, 3) * size, center + Vector2(0, 13) * size, center + Vector2(-10, 3) * size]), color)
			g.draw_line(center + Vector2(0, -8) * size, center + Vector2(0, 6) * size, color.darkened(0.5), 3 * size)
		"step":
			g.draw_rect(Rect2(center + Vector2(-5, -14) * size, Vector2(8, 19) * size), color)
			g.draw_rect(Rect2(center + Vector2(-5, 2) * size, Vector2(18, 8) * size), color)
		"curse", "cleanse":
			g.draw_rect(Rect2(center + Vector2(-10, -5) * size, Vector2(20, 17) * size), color)
			g.draw_rect(Rect2(center + Vector2(-7, -14) * size, Vector2(14, 13) * size), color, false, 3 * size)
			g.draw_rect(Rect2(center + Vector2(-2, 0) * size, Vector2(4, 7) * size), color.darkened(0.6))
			if kind == "cleanse": g.draw_line(center + Vector2(-15, 14) * size, center + Vector2(15, -17) * size, Color("f0eacb"), 3 * size)
		"aid":
			g.draw_rect(Rect2(center + Vector2(-4, -13) * size, Vector2(8, 26) * size), color)
			g.draw_rect(Rect2(center + Vector2(-13, -4) * size, Vector2(26, 8) * size), color)
		_:
			g.draw_line(center + Vector2(-12, 12) * size, center + Vector2(11, -14) * size, color, 5 * size)
			g.draw_line(center + Vector2(-12, 0) * size, center + Vector2(0, 12) * size, color, 4 * size)

static func face_symbol(face: int) -> String:
	if face in [4, 5, 10]: return "ward"
	if face in [2, 3, 11]: return "step"
	if face == 7: return "aid"
	return "blade"

static func draw_scene(g, r: Rect2, event_id: int) -> void:
	var tint: Color = TINTS[event_id]
	var elapsed: float = g.event_reveal_elapsed
	var hp_loss = 0
	var hp_targets = 0
	var curse = false
	var cleanse = false
	for change in g.event_feedback:
		if change.kind == "hp":
			hp_loss += absi(change.value)
			hp_targets += 1
		if change.kind == "curse": curse = true
		if change.kind == "cleanse": cleanse = true
	var impact = maxf(0.0, 1.0 - elapsed / 0.55) if g.journey_stage == "resolved" else 0.0
	var shake = Vector2(sin(elapsed * 126), cos(elapsed * 101)) * impact * (4 if hp_loss > 0 else 1)
	var scene_rect = Rect2(r.position + shake, r.size)
	g.draw_texture_rect_region(SCENES, scene_rect, atlas_region(SCENES, event_id))
	# Frame bars and foreground darkness keep the sprite silhouettes readable.
	g.draw_rect(Rect2(r.position, Vector2(r.size.x, 35)), Color(0.03, 0.04, 0.07, 0.72))
	g.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 68), Vector2(r.size.x, 68)), Color(0.03, 0.04, 0.07, 0.82))
	g.text_at(r.position + Vector2(14, 24), NAMES[event_id], 14, tint)
	var bob = Vector2(sin(g.time * 1.1 + event_id) * 1.0, sin(g.time * 1.8 + event_id) * 2.2)
	g.pixel_circle(r.position + Vector2(470, 230), 95, Color(tint, 0.045))
	var npc_rect = Rect2(r.position + Vector2(244, 88) + bob + shake, Vector2(380, 253))
	g.draw_rect(Rect2(r.position + Vector2(414, 324) + shake, Vector2(132, 12)), Color(0.01, 0.02, 0.03, 0.5))
	g.draw_texture_rect_region(NPCS, npc_rect, atlas_region(NPCS, event_id), Color(1, 1, 1, clampf(g.event_scene_elapsed * 3, 0, 1)))
	var approach = minf(1.0, elapsed) * 15 if g.journey_stage == "resolved" else 0.0
	var hero = r.position + Vector2(180 + approach, 303) + shake
	var companion = 0
	for h in range(3):
		if h != g.event_target:
			draw_hero_sprite(g, r.position + Vector2(48 + companion * 56, 339) + shake, h, 116, 0.84)
			companion += 1
	draw_hero_sprite(g, hero + Vector2(0, 32 + sin(g.time * 2.3) * 1.3), g.event_target, 160, 1.0)
	# Every scene has its own moving atmosphere; none of this consumes gameplay RNG.
	for i in range(22):
		var px = fmod(i * 83.0 + g.time * (7 + i % 4), r.size.x - 28) + 14
		var py = fmod(i * 59.0 - g.time * (9 + i % 7) + 8000, r.size.y - 105) + 38
		var p = r.position + Vector2(px, py)
		if event_id == 2:
			p.y += sin(g.time * 3 + i) * 9
			var wing = 3 + absi(int(sin(g.time * 9 + i) * 5))
			g.draw_line(p - Vector2(wing, 2), p + Vector2(wing, -2), Color(tint, 0.65), 2)
			g.draw_line(p - Vector2(wing, -2), p + Vector2(wing, 2), Color(tint, 0.65), 2)
		elif event_id == 4:
			g.draw_rect(Rect2(p.snapped(Vector2(2, 2)), Vector2(3, 2)), Color(0.9, 0.9, 0.8, 0.22))
		elif event_id in [0, 1, 3]:
			g.draw_rect(Rect2(p.snapped(Vector2(2, 2)), Vector2(2, 3 + i % 3)), Color(tint, 0.28 + 0.2 * sin(g.time + i)))
		else:
			g.draw_arc(p, 3 + sin(g.time * 2 + i) * 2, 0, PI, 6, Color(tint, 0.13), 2)
	if g.journey_stage == "resolved":
		var pulse = maxf(0, 1.0 - elapsed / 1.4)
		var glow: Color = g.RED if hp_loss > 0 else (g.COLORS[2] if curse else g.TEAL)
		g.draw_rect(r, Color(glow, impact * 0.12))
		for ring in range(3):
			g.draw_arc(hero + Vector2(0, 18), 20 + elapsed * 38 + ring * 12, 0, TAU, 32, Color(glow, pulse * 0.5), 2)
		if hp_loss > 0 and elapsed < 1.8:
			g.text_at(r.position + Vector2(25, 78 - elapsed * 12), "PARTY: -%d HP TOTAL" % hp_loss, 18, g.RED) if hp_targets > 1 else g.text_at(hero + Vector2(-32, -130 - elapsed * 18), "-%d HP" % hp_loss, 24, g.RED)
		if curse:
			for i in range(6):
				var p = hero + Vector2(sin(g.time * 2 + i) * (25 + i * 4), -10 - fmod(g.time * 24 + i * 19, 80))
				symbol(g, p, "curse", Color(g.COLORS[2], 0.38), 0.28)
		if cleanse and elapsed < 1.6: symbol(g, hero + Vector2(0, -120), "cleanse", Color(g.TEAL, pulse), 1.7)
		for change in g.event_feedback:
			if change.kind == "face" and elapsed < 2.2:
				var t = clampf(elapsed / 0.9, 0, 1)
				var destination = hero + Vector2(82, -97)
				var p = (r.position + Vector2(459, 184)).lerp(destination, t)
				var card = Rect2(p - Vector2(23, 28), Vector2(46, 56))
				var alpha = clampf((2.2 - elapsed) / 0.4, 0, 1)
				g.box(card, Color(g.PANEL, alpha), Color(g.GOLD, alpha))
				symbol(g, p, face_symbol(change.face), Color(g.TEAL, alpha), 1.1)
	# A fate die is a reveal, never a second gameplay roll.
	if g.event_risk_die > 0:
		var shown: int = g.event_risk_die if elapsed >= 0.45 else int(elapsed * 25) % 6 + 1
		var dice_rect = Rect2(r.end.x - 85, r.position.y + 46, 64, 61)
		g.box(dice_rect, g.PANEL, tint)
		g.text_at(dice_rect.position + Vector2(22, 36), str(shown), 28, g.INK)
		g.text_at(dice_rect.position + Vector2(12, 53), "FATE d6", 9, tint)

static func feedback_chip(g, rect: Rect2, change: Dictionary) -> void:
	var kind: String = change.kind
	var color: Color = g.TEAL
	var title = "JOURNEY SAVED"
	var caption = "Consequence retained"
	var icon = "ward"
	if kind == "face":
		title = "+%d %s" % [change.value, g.SHORT_NAMES[change.face]]
		caption = "OWNED / EQUIP NEXT PREP"
		icon = face_symbol(change.face)
	elif kind == "hp":
		color = g.RED; icon = "hp"
		title = "%d HP" % change.value
		caption = g.NAMES[change.hero] + " / ENTERS %d OF 6" % g.trip_hp[change.hero]
	elif kind == "curse":
		color = g.COLORS[2]; icon = "curse"
		title = "CURSED BLANK"
		caption = "LOCKED / PERMANENT"
	elif kind == "cleanse":
		icon = "cleanse"; title = "CURSE CLEANSED"; caption = "BLANK UNLOCKED"
	elif kind == "face_loss":
		color = g.RED; title = "-1 " + g.SHORT_NAMES[change.face]; caption = "OWNED COPY DESTROYED"; icon = face_symbol(change.face)
	elif kind == "safe":
		color = g.GOLD; title = "NO COST"; caption = "NOTHING TAKEN"; icon = "ward"
	g.box(rect, color.darkened(0.87), color.darkened(0.2))
	symbol(g, rect.position + Vector2(25, 30), icon, color, 0.8)
	g.text_at(rect.position + Vector2(49, 26), title, 13, color)
	g.text_at(rect.position + Vector2(49, 46), caption, 9, g.MUTED)

static func tags(event_id: int, choice: int) -> Array:
	var pairs = [
		[["-2 HP", "+ LANTERN CUT"], ["SAFE", "NO REWARD"]],
		[["PERMANENT CURSE", "+ IRON WARD"], ["-2 HP", "+ IRON WARD"]],
		[["RISK / d6", "4-6: GAIN / 1-3: -2 HP"], ["ALL HEROES -1 HP", "+ PILGRIM STEP"]],
		[["DESTROY A STRIKE", "+ LANTERN CUT"], ["PERMANENT CURSE", "+ FIRST AID"]],
		[["CLEANSE OR DEFENSE", "PERMANENT MERCY"], ["-1 HP", "+ FIRST AID"]],
		[["PERMANENT CURSE", "+ PILGRIM STEP"], ["RISK / d6", "FACE LOSS / WOUND / GAIN"]]
	]
	return pairs[event_id][choice]

static func hero_region(hero: int) -> Rect2:
	var cell = Vector2(HEROES.get_width() / 3.0, HEROES.get_height())
	return Rect2(Vector2(cell.x * hero, 0), cell)

static func draw_hero_sprite(g, foot: Vector2, hero: int, height: float, alpha: float) -> void:
	var source = hero_region(hero)
	var width = height * source.size.x / source.size.y
	var destination = Rect2(foot - Vector2(width / 2, height * 0.915), Vector2(width, height))
	g.draw_rect(Rect2(foot + Vector2(-height * 0.17, -3), Vector2(height * 0.34, 8)), Color(0.01, 0.02, 0.03, 0.4 * alpha))
	g.draw_texture_rect_region(HEROES, destination, source, Color(1, 1, 1, alpha))

static func portrait(g, rect: Rect2, hero: int) -> void:
	var source = hero_region(hero)
	source.position += source.size * Vector2(0.45, 0.04)
	source.size *= Vector2(0.5, 0.34)
	g.draw_texture_rect_region(HEROES, rect, source)
