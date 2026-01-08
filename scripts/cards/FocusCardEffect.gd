extends CardEffect

func apply(main: Node, _instance_id: int) -> bool:
	main.energy += 1
	return true
