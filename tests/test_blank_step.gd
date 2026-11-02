extends SceneTree
var game
var checks = 0
var failures = 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func reset_blanks() -> void:
	game.start_battle(); game.roll_anim = 0
	game.active = 0; game.phase = "hero"
	for h in range(3):
		game.heroes[h].roll = [3, 4, 5]
		game.heroes[h].spent = [false, false, false]
		game.heroes[h].react = []
		game.heroes[h].soul_used = false
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.adventure = false
	game.blank_step_test = false
	game.save_enabled = false; game.sound_on = false
	root.add_child(game)
	await process_frame
	check(not game.blank_step_test and not game.blank_step_enabled(), "test option defaults off")
	reset_blanks()
	game.choose_ability(0)
	check(game.mode == "confirm", "ordinary Blank grants no movement with option off")
	game.handle("cancel_ability")
	game.handle("blank_step_toggle")
	check(game.blank_step_enabled() and not game.reward and game.blank_min == 3, "test switch grants movement without granting a Soul")
	game.choose_ability(0)
	check(game.mode == "move_soul" and not game.heroes[0].spent[0], "selecting a Blank previews free before commitment")
	check(game.reachable.has(Vector2i(1, 6)) and not game.reachable.has(Vector2i(1, 5)), "Blank step is exactly one orthogonal square")
	game.board_click(Vector2i(1, 6))
	check(game.heroes[0].spent[0] and game.heroes[0].soul_used and game.heroes[0].pos == Vector2i(1, 6), "movement spends one result and the shared turn allowance")
	game.choose_ability(1)
	check(game.mode == "confirm" and not game.heroes[0].spent[1], "second Blank cannot grant a second step")
	game.handle("cancel_ability")
	game.handle("blank_step_toggle"); game.handle("blank_step_toggle")
	check(game.heroes[0].soul_used, "off/on does not refill the per-turn allowance")
	game.choose_ability(1)
	check(game.mode == "confirm", "toggle cycling cannot exploit extra movement")
	game.handle("cancel_ability")
	game.active = 1
	game.choose_ability(0)
	check(game.mode == "move_soul" and not game.heroes[1].soul_used, "each hero has a separate once-per-turn use")
	game.handle("blank_step_toggle")
	check(game.mode == "" and not game.heroes[1].spent[0] and game.reachable.is_empty(), "turning off cancels an unspent test step for free")
	game.reward = true
	check(game.blank_step_enabled(), "earned Soul remains active with test switch off")
	game.choose_ability(0)
	game.board_click(game.heroes[1].pos)
	check(game.heroes[1].soul_used, "choosing zero movement still spends the once-per-turn use")
	game.handle("blank_step_toggle")
	game.choose_ability(1)
	check(game.mode == "confirm", "earned Soul and test option share one allowance")
	game.handle("cancel_ability")
	game.order = [0, 1, 2, 3]; game.turn_index = -1
	game.next_turn()
	check(game.active == 0 and not game.heroes[0].soul_used, "allowance refreshes at the next hero turn")
	game.reward = false; game.blank_step_test = true
	game.heroes[0].dice[3] = 12
	game.heroes[0].roll[0] = 3; game.heroes[0].spent[0] = false
	game.choose_ability(0)
	check(game.mode == "move_soul", "Cursed Blank supports test movement while its tile remains locked")
	check(game.CELL == 70 and game.CELL * 9 > 600, "battlefield uses enlarged cells")
	check(game.board_cell(game.BOARD + Vector2(1, 1)) == Vector2i(0, 0), "screen click mapping starts at the first square")
	check(game.board_cell(game.BOARD + Vector2.ONE * (game.CELL * 9 - 1)) == Vector2i(8, 8), "bottom-right square maps correctly")
	check(game.board_cell(game.BOARD - Vector2.ONE) == Vector2i(-1, -1), "outside clicks cannot accidentally select the first square")
	for d in range(3): check(not game.ability_card_rect(d).intersects(Rect2(game.BOARD, Vector2.ONE * game.CELL * 9)), "ability card does not overlap the board")
	print("BLANK STEP / LAYOUT: ", checks, " checks; ", failures, " failures.")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
