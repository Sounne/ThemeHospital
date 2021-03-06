
extends State

func enter(owner):
	owner.moveIntoRoom()

func execute(owner):
	if owner.pathfinding.animation_completed == true || owner.pathfinding.found == false:
		owner.pathfinding.free()
		if owner.room_occuped.present_patient.size() != 0:
			owner.diagnose()
		owner.moveIntoRoom()

func exit(owner):
	owner.room_occuped.is_occuped = false
	owner.room_occuped = null