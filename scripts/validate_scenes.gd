extends SceneTree

func _init() -> void:
	var scenes: Array[String] = [
		"res://scenes/Main.tscn",
		"res://scenes/Paddle.tscn",
		"res://scenes/Ball.tscn",
		"res://scenes/Brick.tscn"
	]
	var ok: bool = true
	for path in scenes:
		var res: Resource = ResourceLoader.load(path)
		if res == null:
			push_error("Failed to load scene: %s" % path)
			ok = false
			continue
		if res is PackedScene:
			var inst: Node = (res as PackedScene).instantiate()
			inst.queue_free()
		else:
			push_error("Not a PackedScene: %s" % path)
			ok = false
	if ok:
		print("Scene validation OK")
	quit()
