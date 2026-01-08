extends CardEffect

func apply(main: Node, _instance_id: int) -> bool:
	main.block += 5
	return true
