extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.save_enabled = false
	game.sound_on = false
	root.add_child(game)
	game.sound_on = false
	game.music.stop()
	for page in ["title", "build", "battle"]:
		if page == "battle":
			game.rng.seed = 7
			game.start_battle()
			game.active = 0
			game.phase = "hero"
			game.mode = ""
		else: game.screen = page
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://dicebound-" + page + ".png")
	game.queue_free()
	await process_frame
	quit()
