
extends ConfirmationDialog

onready var hire_manager = get_node("/root/Game").scene.hire_manager
onready var player = get_node("/root/Game").scene.player

func _ready():
	get_cancel().connect("pressed", self, "_on_CancelButton_pressed")

func _on_ConfirmationDialog_confirmed():
	player.decreaseExpense(hire_manager.staff_selected.salary)
	hire_manager.remove_child(hire_manager.staff_selected)

func _on_CancelButton_pressed():
	get_parent().get_parent().show()
	hide()