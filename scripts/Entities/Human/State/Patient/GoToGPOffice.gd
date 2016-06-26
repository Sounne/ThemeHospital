
extends State

func enter(owner):
	owner.checkGPOffice()

func execute(owner):
	print("GoToAdaptedRoom")

func exit(owner):
	pass