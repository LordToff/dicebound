extends SceneTree
var game
var checks = 0
var failures = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func reset_journey() -> void:
	game.journey_stage = "prepare"
	game.event_pool = [0, 1, 2, 3, 4, 5]
	game.current_event = -1
	game.event_target = 0
	game.event_outcome = ""
	game.event_risk_die = 0
	game.event_journal = []
	game.trip_hp = [6, 6, 6]
	game.reward = false
	game.blank_min = 3
	game.screen = "camp"
	for h in range(3):
		game.owned_faces[h] = game.LIMITS.duplicate()
		game.builds[h] = [1, 2, 4, 0, 0, 0, 1, 3, 5, 0, 0, 0, 1, 7, 6, 0, 0, 0]
		game.builder = h
		game.apply_preset("Balanced")
	game.builder = 0

func seed_for_die(wanted: int) -> int:
	var r = RandomNumberGenerator.new()
	for candidate in range(10000):
		r.seed = candidate
		if r.randi_range(1, 6) == wanted: return candidate
	return 0

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_enabled = false
	game.sound_on = false
	root.add_child(game)
	await process_frame
	game.sound_on = false
	game.music.stop()
	check(JourneyEvents.DATA.size() == 6, "six original events exist")
	for id in range(6):
		check(JourneyEvents.DATA[id].choices.size() == 2, "event has two explicit choices")
		for choice in range(2):
			reset_journey()
			game.reveal_event(id)
			check(game.screen == "event" and game.current_event == id and game.event_pool.size() == 6, "reveal commits one event without consuming it")
			check(game.event_choice_allowed(choice), "fresh hero can pay either choice")
			game.resolve_event(choice)
			check(game.journey_stage == "resolved" and not id in game.event_pool and game.event_pool.size() == 5, "choice resolves and removes only triggering number")
			check(not game.event_outcome.is_empty() and game.event_journal.size() == 1, "choice records consequence")
			for h in range(3): check(game.build_error(h).is_empty(), "event produces a legal retained build")
			var owned: Array = game.owned_faces.duplicate(true)
			var hp: Array = game.trip_hp.duplicate()
			game.resolve_event(choice)
			check(game.owned_faces == owned and game.trip_hp == hp, "choice cannot pay or reward twice")
			game.reveal_event((id + 1) % 6)
			check(game.current_event == id, "returning to camp cannot reroll committed event")
	reset_journey()
	game.reveal_event(0)
	game.start_battle()
	check(game.screen == "event" and game.journey_stage == "event", "cannot skip unresolved event by starting battle")
	game.resolve_event(0)
	check(game.trip_hp[0] == 4 and game.owned_faces[0][9] == 1 and game.builds[0].count(9) == 0, "Bell pays HP and owns reward without free installation")
	var committed: Array = game.builds[0].duplicate()
	game.handle("soul")
	check(game.blank_min == 3, "Soul cannot change after an event is committed")
	game.equip_face(0, 9)
	check(game.builds[0] == committed, "no voluntary post-event equip")
	game.open_preparation()
	check(game.screen == "event" and game.trip_hp[0] == 4, "post-event builder route cannot heal away injuries")
	game.start_battle()
	check(game.heroes[0].hp == 4 and game.heroes[1].hp == 6, "battle startup preserves event HP per hero")
	game.journey_stage = "aftermath"
	game.open_preparation()
	check(game.trip_hp == [6, 6, 6], "between-battle recovery restores party once preparation begins")
	game.builder = 0
	game.equip_face(0, 9)
	check(game.builds[0][0] == 9 and game.build_error(0).is_empty(), "acquired Lantern Cut equips legally in next preparation")
	game.start_battle(); game.roll_anim = 0
	game.active = 0; game.phase = "hero"
	game.heroes[0].pos = Vector2i(2, 2)
	game.heroes[0].roll[0] = 0; game.heroes[0].spent[0] = false
	game.choose_ability(0); game.handle("target:3")
	check(game.boss.hp == 16, "Lantern Cut resolves for printed 2 damage")
	game.heroes[0].weak = true
	check(game.attack_value(0, 9) == 1, "Weakness reduces reward attack by 1")
	reset_journey()
	game.owned_faces[0][10] = 1
	game.equip_face(2, 10)
	game.start_battle(); game.roll_anim = 0
	game.active = 0; game.phase = "hero"
	game.heroes[0].roll[0] = 2; game.heroes[0].spent[0] = false
	game.choose_ability(0)
	check(game.mode == "confirm" and game.heroes[0].block == 0, "Iron Ward selection previews without paying")
	game.handle("activate")
	check(game.heroes[0].block == 2 and game.heroes[0].spent[0], "Iron Ward confirmation grants exact 2 Block")
	reset_journey()
	game.owned_faces[0][11] = 1
	game.equip_face(1, 11)
	game.start_battle(); game.roll_anim = 0
	game.active = 0; game.phase = "hero"
	game.heroes[0].roll[0] = 1; game.heroes[0].spent[0] = false
	game.choose_ability(0)
	check(game.reachable.has(Vector2i(1, 5)) and not game.reachable.has(Vector2i(0, 5)), "Pilgrim Step permits two orthogonal steps with turning")
	reset_journey()
	game.reveal_event(1); game.resolve_event(0)
	var curse_slot: int = game.builds[0].find(12)
	check(curse_slot >= 0 and game.owned_faces[0][12] == 1, "Stitcher creates tracked permanent Cursed Blank")
	game.journey_stage = "aftermath"; game.open_preparation()
	check(game.builds[0][curse_slot] == 12 and game.build_error(0).is_empty(), "recovery retains curse and it satisfies Blank minima")
	game.equip_face(curse_slot, 0)
	check(game.builds[0][curse_slot] == 12, "ordinary erasing cannot remove a lock")
	game.apply_preset("Assault")
	check(game.builds[0][curse_slot] == 12, "presets preserve locked sides")
	game.reward = true
	game.start_battle(); game.roll_anim = 0
	game.active = 0; game.phase = "hero"
	game.heroes[0].roll[curse_slot / 6] = curse_slot % 6
	game.heroes[0].spent[curse_slot / 6] = false
	game.choose_ability(curse_slot / 6)
	check(game.mode == "move_soul", "locked Blank is still a Blank for the reward Soul")
	game.journey_stage = "aftermath"; game.open_preparation()
	game.reveal_event(4); game.resolve_event(0)
	check(game.builds[0][curse_slot] == 0 and game.owned_faces[0][12] == 0, "Hospice cleansing permanently removes curse and lock")
	reset_journey()
	game.apply_preset("Assault")
	game.reveal_event(3); game.resolve_event(0)
	check(game.owned_faces[0][1] == 3 and game.builds[0].count(1) == 3 and game.owned_faces[0][9] == 1, "Orchard destroys an owned equipped copy without duplicating rewards")
	for die in range(1, 7):
		reset_journey()
		game.reveal_event(2); game.rng.seed = seed_for_die(die); game.resolve_event(0)
		check(game.event_risk_die == die, "Moth risk publishes actual d6")
		check(game.owned_faces[0][11] == (1 if die >= 4 else 0) and game.trip_hp[0] == (6 if die >= 4 else 4), "Moth risk threshold is exactly 4-6")
		reset_journey()
		game.reveal_event(5); game.rng.seed = seed_for_die(die); game.resolve_event(1)
		if die <= 2: check(game.owned_faces[0][1] == 3, "Procession 1-2 destroys a face")
		elif die <= 4: check(game.trip_hp[0] == 4, "Procession 3-4 wounds")
		else: check(game.owned_faces[0][9] == 1, "Procession 5-6 rewards")
	reset_journey()
	game.reveal_event(0); game.trip_hp[0] = 2
	check(not game.event_choice_allowed(0), "cannot pay unaffordable HP cost")
	game.resolve_event(0)
	check(game.event_pool.size() == 6 and game.owned_faces[0][9] == 0 and game.trip_hp[0] == 2, "failed payment is atomic")
	reset_journey()
	game.event_target = 2
	game.reveal_event(1); game.resolve_event(0)
	var config = ConfigFile.new()
	game.write_journey(config)
	var snapshots: Array = game.owned_faces.duplicate(true)
	var test_file = "user://events-test-roundtrip.cfg"
	check(config.save(test_file) == OK, "journey snapshot serializes successfully")
	var disk_config = ConfigFile.new()
	check(disk_config.load(test_file) == OK, "journey snapshot reads back from disk")
	game.owned_faces[2][10] = 0; game.event_pool = []; game.journey_stage = "prepare"
	game.load_journey(disk_config)
	check(game.owned_faces == snapshots and game.journey_stage == "resolved" and game.current_event == 1, "saved event ownership and committed outcome restore")
	game.resolve_event(0)
	check(game.owned_faces == snapshots, "restored outcome cannot be farmed again")
	reset_journey()
	game.event_pool = [5]
	game.rng.seed = 200
	game.reveal_event()
	check(game.current_event == 5 and game.event_die == 6, "unmapped results reroll without renumbering pool")
	game.resolve_event(0)
	game.journey_stage = "aftermath"; game.open_camp()
	game.reveal_event()
	check(game.screen == "camp" and game.current_event == -1 and game.event_pool.is_empty(), "empty pool returns to base without rolling")
	var kept: Array = game.owned_faces.duplicate(true)
	game.refill_events()
	check(game.event_pool == [0, 1, 2, 3, 4, 5] and game.owned_faces == kept, "explicit test refill retains permanent rewards")
	print("EVENT TESTS: ", checks, " checks; ", failures, " failures. All 12 event choices and every risk-die branch exercised.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_file))
	disk_config = null
	config = null
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if failures else 0)
