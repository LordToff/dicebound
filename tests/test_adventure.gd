extends "res://tests/test_game.gd"
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_enabled = false; game.sound_on = false
	root.add_child(game)
	await process_frame
	game.start_battle();game.roll_anim=0
	check(game.boss.hp == 24 and game.order == [0,1,2,3],"Adventure boss and team-first order")
	check(game.heroes[0].block == 1,"turn-start safety Block")
	game.handle("free_move")
	check(game.free_move_active and not game.reachable.is_empty(),"free movement available without a die")
	game.board_click(game.heroes[0].pos)
	check(game.free_move_used,"free movement spent once")
	game.damage(3,12)
	check(game.boss_phase == 2,"half-health enrage")
	game.new_round()
	check("Rest" not in game.boss_roll,"enraged boss has three active intentions")
	var wins=0
	for scenario in range(50):
		game.journey_stage="prepare";game.reward=false
		game.rng.seed=scenario+100;seed(scenario+100)
		game.start_battle()
		var steps=0
		while game.screen == "battle" and steps<4000:
			steps+=1;game.roll_anim=0
			if game.active<3 and game.mode not in ["focus","stun","push_direction"]:
				if not game.free_move_used:
					game.handle("free_move")
					var best:Vector2i=game.heroes[game.active].pos
					for p in game.reachable:
						if p in game.danger_cells:continue
						if best in game.danger_cells or game.distance(p,game.boss.pos,2)<game.distance(best,game.boss.pos,2):best=p
					game.board_click(best);continue
				if not game.reforge_used:game.handle("reforge");continue
			auto_step()
		check(game.screen=="result","adventure encounter terminates")
		if game.victory:wins+=1
	check(wins>0,"default builds can win full random encounters")
	print("ADVENTURE: ",checks," checks, ",failures," failures; ",wins,"/50 benchmark wins.")
	game.queue_free();await process_frame
	quit(1 if failures else 0)
