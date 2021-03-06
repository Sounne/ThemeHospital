
extends Control

onready var game = get_node("/root/Game")
onready var gamescn = get_node("/root/Game").scene
onready var player = gamescn.player

onready var panel = get_node("Panel")
onready var bench = panel.get_node("Bench")
onready var plant = panel.get_node("Plant")
onready var radiator = panel.get_node("Radiator")
onready var drink = panel.get_node("Drink")
onready var fire = panel.get_node("Fire")
onready var reception_desk = panel.get_node("ReceptionistDesk")
onready var bench_label = bench.get_node("Label")
onready var plant_label = plant.get_node("Label")
onready var radiator_label = radiator.get_node("Label")
onready var drink_label = drink.get_node("Label")
onready var fire_label = fire.get_node("Label")
onready var price_label = get_node("Informations/VBoxContainer/Price")
onready var total_label = get_node("Informations/VBoxContainer/Total")
onready var reception_desk_label = reception_desk.get_node("Label")
onready var label_array = [bench_label, plant_label, radiator_label, drink_label, fire_label, reception_desk_label]
onready var object_resources = gamescn.getObjectResources()
onready var temp_array = gamescn.getTempObjectsNodesArray()

var items_count_array = []
var number_of_buttons = 2
var price = 0
var total = 0

func _ready():
	setTextInformations(price, total)

func updateValues():
	items_count_array.clear()
	items_count_array.append(bench.getValue())
	items_count_array.append(plant.getValue())
	items_count_array.append(radiator.getValue())
	items_count_array.append(drink.getValue())
	items_count_array.append(fire.getValue())
	items_count_array.append(reception_desk.getValue())

func resetvalues():
	var default_text = tr("TXT_COUNT") + "0"
	bench.setValue(0)
	plant.setValue(0)
	radiator.setValue(0)
	drink.setValue(0)
	fire.setValue(0)
	reception_desk.setValue(0)
	setTextInformations(price, total)
	for current in label_array:
		current.set_text(default_text)

func countString(value):
	var count_string = tr("TXT_COUNT") + str(value)

func _on_Accept_pressed():
	var max_count = panel.get_child_count() - number_of_buttons
	var count = 0
	updateValues()

	while (count < max_count):
		while (items_count_array[count] > 0):
			var node = object_resources.array_scn[count].instance()
			
			if (gamescn.player.money >= node.price):
				gamescn.player.money -= node.price
			
				gamescn.add_child(node)
				var node_info = []
				temp_array.append(node)
				node.available.on()
				node.is_selected = true
				node.can_selected = true
				node.set_process_input(true)
				items_count_array[count] -= 1
			else:
				game.feedback.display("FEEDBACK_ENOUGH_MONEY")
				return false
		count += 1

	if (!temp_array.empty()):
		temp_array[0].hideOtherObjects()
		gamescn.setHaveObject(true)
	resetvalues() 
	self.hide()

func hideOtherObjects():
	for current in temp_array:
		current.hide()
	if (!temp_array.empty()):
		temp_array[0].show()

func _on_Close_pressed():
	self.hide()

func setTextInformations(price, total):
	price_label.set_text(tr("PRICE_LABEL") + str(price))
	total_label.set_text("Total : " + str(total))