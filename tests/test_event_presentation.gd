extends "res://tests/test_events.gd"
## Presentation assets and saved feedback must agree with real event consequences.
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.adventure = false
	game.blank_step_test = false
	game.save_enabled = false; game.sound_on = false
	root.add_child(game)
	await process_frame
	check(EventPresentation.NAMES.size() == 6, "each event has a distinct NPC")
	var scene_regions: Array = []
	var npc_regions: Array = []
	var image: Image = EventPresentation.NPCS.get_image()
	check(image != null and image.has_mipmaps() == false, "NPC atlas is available as a crisp sprite asset")
	var heroes: Array = []
	for h in range(3):
		var region: Rect2 = EventPresentation.hero_region(h)
		check(Rect2(Vector2.ZERO, EventPresentation.HEROES.get_size()).encloses(region), "story hero sprite is in bounds")
		for previous in heroes: check(not previous.intersects(region), "story hero sprites do not overlap")
		heroes.append(region)
	for id in range(6):
		var background: Rect2 = EventPresentation.atlas_region(EventPresentation.SCENES, id)
		var npc: Rect2 = EventPresentation.atlas_region(EventPresentation.NPCS, id)
		check(Rect2(Vector2.ZERO, EventPresentation.SCENES.get_size()).encloses(background), "background atlas region is in bounds")
		check(Rect2(Vector2.ZERO, EventPresentation.NPCS.get_size()).encloses(npc), "NPC atlas region is in bounds")
		for previous in scene_regions: check(not previous.intersects(background), "background scenes do not overlap")
		for previous in npc_regions: check(not previous.intersects(npc), "NPC sprites do not overlap")
		scene_regions.append(background); npc_regions.append(npc)
		check(image.get_pixel(int(npc.position.x), int(npc.position.y)).a == 0, "NPC cell has a real transparent background")
		for choice in range(2):
			check(EventPresentation.tags(id, choice).size() == 2, "both choices have visible cost/reward badges")
			reset_journey()
			game.reveal_event(id)
			var previous_hp: Array = game.trip_hp.duplicate()
			var previous_owned: Array = game.owned_faces.duplicate(true)
			game.resolve_event(choice)
			check(not game.event_feedback.is_empty(), "resolved event produces structured visual feedback")
			var expected_hp = 0
			var shown_hp = 0
			for h in range(3): expected_hp += game.trip_hp[h] - previous_hp[h]
			for change in game.event_feedback:
				if change.kind == "hp": shown_hp += change.value
				elif change.kind in ["face", "face_loss"]: check(game.owned_faces[change.hero][change.face] - previous_owned[change.hero][change.face] == change.value, "visual reward/loss matches actual ownership")
				elif change.kind in ["curse", "cleanse"]: check(game.owned_faces[change.hero][12] - previous_owned[change.hero][12] == change.value, "visual curse/cleanse matches actual lock state")
			check(shown_hp == expected_hp, "wound feedback shows the exact paid HP")
			var committed_hp: Array = game.trip_hp.duplicate()
			var committed_owned: Array = game.owned_faces.duplicate(true)
			var rng_state: int = game.rng.state
			game._process(1.0)
			check(game.trip_hp == committed_hp and game.owned_faces == committed_owned and game.rng.state == rng_state, "reveal animation does not pay again or reroll gameplay")
	reset_journey()
	game.reveal_event(1); game.resolve_event(0)
	var config = ConfigFile.new()
	game.write_journey(config)
	var saved: Array = game.event_feedback.duplicate(true)
	game.event_feedback = []
	game.load_journey(config)
	check(game.event_feedback == saved and game.event_reveal_elapsed >= 0.65, "saved consequence chips restore ready to continue")
	var legacy = ConfigFile.new()
	legacy.set_value("journey", "stage", "resolved")
	legacy.set_value("journey", "current", 0)
	legacy.set_value("journey", "hp", [4, 6, 6])
	legacy.set_value("journey", "outcome", "Saved wound and reward from an older version.")
	game.load_journey(legacy)
	check(game.event_feedback.is_empty() and game.trip_hp == [4, 6, 6] and game.journey_stage == "resolved", "older outcomes keep their consequences without invented reward chips")
	print("EVENT PRESENTATION: ", checks, " checks; ", failures, " failures.")
	image = null; config = null; legacy = null
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
