extends SceneTree
var game
var checks = 0
var failures = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_enabled = false
	game.sound_on = false
	root.add_child(game)
	await process_frame
	game.sound_on = false
	game.music.stop()
	for h in range(3): check(game.build_error(h) == "", "default build legal")
	game.builds[0][3] = 1
	check(not game.build_error(0).is_empty(), "Soul minimum enforced")
	game.builds[0][3] = 0
	game.blank_min = 2
	game.builds[0][3] = 7
	check(not game.build_error(0).is_empty(), "ownership enforced")
	game.builds[0][3] = 0
	game.blank_min = 3
	game.rng.seed = 42
	game.start_battle(); game.roll_anim = 0
	check(game.heroes.size() == 3 and game.boss.hp == 18, "encounter baseline")
	check(game.footprint(game.boss.pos, 2).size() == 4, "boss footprint")
	check(game.distance(Vector2i(2, 2), Vector2i(3, 2), 2) == 1, "near-edge footprint range")
	check(game.distance(Vector2i(2, 1), Vector2i(3, 2), 2) == 2, "diagonals are not adjacent")
	check(not game.free_at(Vector2i(3, 2), 0), "boss blocks hero movement")
	check(not game.free_at(Vector2i(8, 8), 3), "whole footprint respects edge")
	var retained = game.order.duplicate()
	game.new_round()
	check(game.order == retained, "initiative retained across rounds")
	game.active = 0
	game.phase = "hero"
	game.heroes[0].block = 2
	game.damage(0, 1)
	check(game.heroes[0].hp == 6 and game.heroes[0].block == 1, "Block absorbs and is consumed")
	game.damage(0, 10)
	check(game.heroes[0].down and game.heroes[0].hp == 0, "overkill discarded into Downed")
	game.damage(0, 1, true)
	check(not game.heroes[0].dead, "new Downed protected during acting turn")
	game.heal(0)
	check(game.heroes[0].hp == 1 and game.heroes[0].broken and game.recovery.has(0), "heal revives and queues recovery")
	game.damage(0, 1)
	check(game.heroes[0].dead, "Broken second zero is death")
	game.start_battle(); game.roll_anim = 0
	game.heroes[0].pos = Vector2i(2, 2)
	var movement = game.movement_options(0, 3, true)
	check(not movement.has(Vector2i(1, 1)), "Tactical Movement cannot turn")
	check(movement.has(Vector2i(0, 2)), "Tactical Movement can stop early")
	game.active = 0
	game.phase = "hero"
	game.heroes[0].dice[0] = 4
	game.heroes[0].roll[0] = 0
	game.heroes[0].spent[0] = false
	game.select_die(0)
	check(game.heroes[0].block == 1 and game.heroes[0].spent[0], "Basic Defense gives exact printed Block")
	game.heroes[0].dice[6] = 6
	game.heroes[0].roll[1] = 0
	game.heroes[0].spent = [true, false, false]
	game.select_die(1)
	check(game.mode == "focus" and game.heroes[0].spent[1], "Focus consumes own result")
	game.select_die(2)
	check(game.mode == "", "Focus rerolls other unresolved result")
	game.start_battle(); game.roll_anim = 0
	game.heroes[0].pos = Vector2i(2, 2)
	game.heroes[0].react = [0]
	game.active = 3
	game.phase = "boss"
	game.pending = {"action": "Strike", "targets": [0], "reacted": []}
	game.resume_attack()
	check(game.mode == "reaction", "attack opens Reaction window")
	game.use_reaction()
	check(game.heroes[0].block == 1 and game.mode == "reaction_move", "Tactical Defense grants Block plus optional movement")
	game.board_click(Vector2i(1, 2))
	check(game.heroes[0].pos == Vector2i(1, 2), "Reaction may leave attack range")
	game.start_battle(); game.roll_anim = 0
	game.active = 3
	game.phase = "boss"
	game.heroes[0].pos = Vector2i(2, 2)
	game.boss_roll = ["Fracture", "Brace", "Brace"]
	game.boss_step = 0
	game.resolve_boss()
	check(game.mode == "fracture" and game.pending.target == 0, "Fracture selects eligible adjacent hero")
	game.handle("fracture:0")
	check(game.heroes[0].dice[0] == 0 and game.builds[0][0] == 1, "Fracture temporary; original build retained")
	game.start_battle(); game.roll_anim = 0
	game.boss.hp = 1
	game.damage(3, 1)
	check(game.screen == "result" and game.victory and game.reward, "victory immediately grants per-hero Soul")
	game.start_battle(); game.roll_anim = 0
	for h in range(3):
		game.damage(h, 10, true)
	check(game.screen == "result" and not game.victory, "all Downed immediately loses")
	game.start_battle(); game.roll_anim = 0
	game.active = 0
	game.phase = "hero"
	game.heroes[0].roll[0] = 3
	game.heroes[0].spent[0] = false
	game.select_die(0)
	check(game.mode == "move_soul", "reward Blank offers Move 1")
	game.board_click(game.heroes[0].pos)
	check(game.heroes[0].soul_used and game.heroes[0].spent[0], "Soul use is spent even at zero movement")
	game.reward = false
	game.start_battle(); game.roll_anim = 0
	game.heroes[0].pos = Vector2i(0, 2)
	game.heroes[0].spent = [true, true, true]
	game.apply_push(0, Vector2i.LEFT, true)
	check(game.heroes[0].hp == 5, "board-edge collision deals unavoidable damage")
	check(not game.heroes[0].stun, "Stunned with no unresolved dice does not defer")
	game.heroes[0].spent = [false, true, true]
	game.apply_push(0, Vector2i.LEFT, true)
	check(game.heroes[0].stun, "collision sets Stunned when unresolved die exists")
	var saved_hp: int = game.heroes[0].hp
	game.apply_push(0, Vector2i.LEFT, false)
	check(game.heroes[0].hp == saved_hp, "Shove explicitly waives collision penalty")
	game.start_battle(); game.roll_anim = 0
	var routes = game.boss_route_options(0, 2)
	check(not routes.is_empty(), "boss has shortest legal routes toward deployment")
	for p in routes: check(game.free_at(p, 3), "boss route fits entire footprint")
	game.active = 0
	game.turn_index = game.order.find(0)
	game.damage(1, 10, true)
	game.heal(1)
	game.finish_turn()
	check(game.active == 1 and game.recovery_active, "recovery activation follows current full turn")
	# A controlled but legal roll fixture exercises an entire winning encounter.
	# All dice show installed Basic Strikes; each boss die has an Advance side.
	game.reward = false
	game.start_battle(); game.roll_anim = 0
	game.heroes[0].pos = Vector2i(2, 2)
	game.heroes[1].pos = Vector2i(5, 2)
	game.heroes[2].pos = Vector2i(3, 4)
	var fixture_round = 0
	var fixture_steps = 0
	while game.screen == "battle" and fixture_steps < 500:
		fixture_steps += 1
		if fixture_round != game.round_no:
			fixture_round = game.round_no
			game.boss_roll = ["Advance", "Advance", "Advance"]
			for h in range(3):
				game.heroes[h].roll = [0, 0, 0]
				game.heroes[h].spent = [false, false, false]
				game.heroes[h].react = []
		auto_step()
	check(game.victory and game.boss.hp == 0, "full legal-roll winning encounter reaches victory")
	check(game.reward and game.battles_won >= 1, "winning encounter unlocks Bound Soul reward")
	check_polish_ui()
	var wins = 0
	for scenario in range(20):
		game.reward = false
		game.rng.seed = scenario + 100
		seed(scenario + 100)
		game.start_battle(); game.roll_anim = 0
		var steps = 0
		while game.screen == "battle" and steps < 6000:
			steps += 1
			auto_step()
		check(game.screen == "result", "full simulated encounter %d terminates" % scenario)
		if game.victory: wins += 1
	print("TESTS: ", checks, " checks; ", failures, " failures. 20 complete simulated encounters; ", wins, " wins.")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func auto_step() -> void:
	game.roll_anim = 0
	if game.mode == "push_direction":
		var choice = game.pending.choices[0]
		game.apply_push(game.pending.target, choice.dir, game.pending.collision)
		if game.pending.boss_push: game.boss_complete()
		else: game.consume()
		return
	if game.active == 3:
		match game.mode:
			"boss_move": game.handle("auto_move")
			"reaction": game.use_reaction()
			"reaction_move":
				var best = game.heroes[game.pending.reactor].pos
				for p in game.reachable:
					if game.distance(p, game.boss.pos, 2) > game.distance(best, game.boss.pos, 2): best = p
				game.board_click(best)
			"attack_ready": game.execute_attack()
			"fracture":
				var u: Dictionary = game.heroes[game.pending.target]
				for i in range(17, -1, -1):
					if u.dice[i] != 0:
						game.handle("fracture:%d" % i)
						break
			_: game.resolve_boss()
		return
	var h: int = game.active
	var u: Dictionary = game.heroes[h]
	var remaining = game.unresolved(h)
	if remaining.is_empty(): game.finish_turn(); return
	if game.mode == "stun": game.select_die(remaining[0]); return
	if game.mode == "focus": game.select_die(remaining[0]); return
	if game.selected < 0:
		# Move before attacking when not adjacent; heal first if needed.
		var chosen: int = remaining[0]
		for d in remaining:
			var face: int = u.dice[d * 6 + u.roll[d]]
			if face == 7 and u.hp < 6: chosen = d; break
			if face in [2, 3] and game.distance(u.pos, game.boss.pos, 2) > 1: chosen = d; break
		game.select_die(chosen)
		return
	match game.mode:
		"move", "move_soul":
			var best: Vector2i = u.pos
			for p in game.reachable:
				if game.distance(p, game.boss.pos, 2) < game.distance(best, game.boss.pos, 2): best = p
			game.board_click(best)
		"attack":
			if game.distance(u.pos, game.boss.pos, 2) == 1: game.board_click(game.boss.pos)
			else: game.consume()
		"heal":
			var target: int = h
			for other in range(3):
				if not game.heroes[other].dead and game.distance(u.pos, game.heroes[other].pos) <= 1 and game.heroes[other].hp < game.heroes[target].hp: target = other
			game.board_click(game.heroes[target].pos)
		_: game.consume()

func check_polish_ui() -> void:
	game.reward = false
	game.start_battle(); game.roll_anim = 0
	game.active = 0
	game.phase = "hero"
	game.heroes[0].roll = [2, 0, 1]
	game.heroes[0].spent = [false, false, false]
	game.heroes[0].react = []
	game.choose_ability(0)
	check(game.mode == "confirm" and not game.heroes[0].spent[0] and game.heroes[0].block == 0, "Guard preview does not spend die")
	game.handle("cancel_ability")
	check(not game.heroes[0].spent[0] and game.heroes[0].block == 0, "cancelling an ability is free")
	game.choose_ability(0)
	game.handle("activate")
	check(game.heroes[0].spent[0] and game.heroes[0].block == 1, "Guard confirm grants exact Block and spends once")
	game.request_end_turn()
	check(game.end_confirm and game.active == 0, "end turn warns before discarding unused dice")
	game.handle("cancel_ability")
	check(not game.end_confirm and game.active == 0, "end-turn warning can be cancelled")
	game.builder = 0
	for preset in ["Balanced", "Assault", "Support"]:
		game.apply_preset(preset)
		check(game.build_error(0).is_empty(), "preset respects ownership and construction: " + preset)
	game.apply_preset("Balanced")
	var before: Array = game.builds[0].duplicate()
	game.equip_face(3, 1)
	check(game.builds[0] == before, "builder refuses illegal non-Blank gain")
	game.equip_face(0, 7)
	check(game.builds[0][0] == 7 and game.builds[0].count(7) == 1 and game.build_error(0).is_empty(), "unique owned ability swaps without duplication")
	game.apply_preset("Balanced")
	game.builds[0][3] = 1
	game.equip_face(3, 0)
	check(game.build_error(0).is_empty(), "builder allows clearing an illegal build")
	game.start_battle(); game.roll_anim = 0
	game.active = 0
	game.phase = "hero"
	game.heroes[0].pos = Vector2i(2, 2)
	game.heroes[0].roll = [0, 0, 0]
	game.heroes[0].spent = [false, false, false]
	game.boss.block = 1
	game.choose_ability(0)
	check(game.legal_ability_targets(1).has(3), "target-button list includes adjacent boss footprint")
	game.handle("target:3")
	check(game.boss.hp == 18 and game.boss.block == 0 and game.heroes[0].spent[0], "target button resolves actual Block and spends exact die")
