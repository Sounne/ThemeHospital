
extends OptionButton

export(int, 0,4) var default_speed = 2
onready var game = get_node("/root/Game")

func _ready():
	if !game.multiplayer:
		set_disabled(false)
	add_item(tr("TXT_SLOWEST"), 0)
	add_item(tr("TXT_SLOWER"), 1)
	add_item(tr("TXT_NORMAL"), 2)
	add_item(tr("TXT_MAX"), 3)
	add_item(tr("TXT_SOME_MORE"), 4)
	select(default_speed)

func _on_SpeedSelector_item_selected( ID ):
	game.speed = game.speed_array[ID]


func _on_SpeedSelector_mouse_enter():
	game.feedback.display("TUTO_SPEED")