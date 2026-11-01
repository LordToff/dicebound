extends "res://tests/test_game.gd"
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.sound_on = false
	game.music.stop()
	var wins = 0
	var best_hp = 18
	game.blank_min = 2
	for h in range(3): game.builds[h] = [1, 1, 2, 4, 0, 0, 1, 3, 5, 7, 0, 0, 1, 2, 4, 6, 0, 0]
	for scenario in range(200):
		game.reward = false
		game.rng.seed = scenario + 100
		seed(scenario + 100)
		game.start_battle()
		var steps = 0
		while game.screen == "battle" and steps < 6000:
			steps += 1
			auto_step()
		best_hp = mini(best_hp, game.boss.hp)
		if game.victory:
			wins += 1
			print("WIN seed ", scenario + 100, " rounds ", game.round_no)
	print("200 runs: ", wins, " wins, best boss hp ", best_hp)
	game.queue_free()
	await process_frame
	quit()
