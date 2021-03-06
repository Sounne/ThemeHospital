
extends Node

var tmpData = Array()
var client_packets_list = Array() setget addServerPacket,getServerPacketsList
var server_packets_list = Array() setget addClientPacket,getClientPacketsList
var current_player_id = null
onready var global_client = get_node("/root/GlobalClient")
onready var global_server = get_node("/root/GlobalServer")
onready var server_data_base = get_node("/root/ServerDataBase")

var current_parsing = {
	server = false,
	client = false
}

func _ready():
	set_process(true)

func _process(delta):
	checkPacketToInterpret()


func checkPacketToInterpret():
	if (client_packets_list.size() > 0):
		setCurrentParsing("client", true)
		parsePacket(client_packets_list[0])
		client_packets_list.remove(0)
	
	if (server_packets_list.size() > 0):
		setCurrentParsing("server", true)
		current_player_id = server_packets_list[0][1]
		parsePacket(server_packets_list[0][0])
		server_packets_list.remove(0)


func parsePacket(packet):
	storeData(packet)
	var keyword = tmpData[0]
	
	if (keyword == "/game"):
		parseGame()
	elif (keyword == "/nickname"):
		setNickname()
	elif (keyword == "/chat"):
		parseMessage(packet)
	elif (keyword == "/info"):
		parseInfo()


func storeData(packet):
	tmpData.clear()
	var data = ""
	
	for character in range (packet.length()):
		if (packet[character] == ' '):
			if (!checkForEmptyness(data)):
				tmpData.push_back(data)
				data = ""
		else:
			data += packet[character]
	
	if (!checkForEmptyness(data)):
		tmpData.push_back(data)


func checkForEmptyness(data):
	if (data.empty()):
		return true
	
	for character in range (data.length()):
		if (data[character] != ' '):
			return false
	
	return true


func parseGame():
	var packet_id = tmpData[1]
	
	if ( packet_id == "0" ):
		playerIdPacket()
	elif ( packet_id == "1" ):
		playerReadyPacket()
	elif ( packet_id == "2" ):
		gameStartedPacket()
	elif ( packet_id == "3" ):
		checkNicknamePacket()
	elif ( packet_id == "4" ):
		updateLobbyData()
	elif ( packet_id == "5" ):
		updateMapRoom()
	elif ( packet_id == "6" ):
		updateMapItems()
	elif ( packet_id == "7" ):
		kickedFromServer()
	elif ( packet_id == "8" ):
		updatePlayerContainer()
	elif ( packet_id == "9" ):
		muteUnmutePlayer()
	elif ( packet_id == "10" ):
		displayAuctionMenu()
	elif ( packet_id == "11" ):
		acceptBid()
	elif ( packet_id == "12" ):
		setCurrentMoney()


func playerIdPacket(): #Packet 0
	global_client.setClientId(tmpData[2].to_int())
	get_tree().get_current_scene().queue_free()
	get_tree().change_scene("res://scenes/network/Lobby.scn")

func playerReadyPacket(): #Packet 1
	global_server.setPlayerReady(current_player_id, bool(tmpData[2].to_int()))

func gameStartedPacket(): #Packet 2
	var scene = tmpData[2]
	
	if (scene == "0"):
		var current_data = 3
		for data in range ( (tmpData.size()-2)/2 ):
			global_client.addPlayerInList(tmpData[current_data], tmpData[current_data+1].to_int())
			current_data += 2
		
		get_tree().get_current_scene().queue_free()
		get_tree().change_scene("res://scenes/network/MapSelect.scn")
	elif (scene == "1"):
		get_tree().get_current_scene().queue_free()
		get_tree().change_scene("res://scenes/LoadingScreen.scn")

func checkNicknamePacket(): #Packet 3
	var nickname_is_ok = bool(tmpData[2].to_int())
	var current_scene = get_tree().get_current_scene()
	
	if ( current_scene != null && current_scene.get_name() == "lobby" ):
		current_scene.displayNicknameMenu(nickname_is_ok)
	elif ( current_scene != null && current_scene.get_name() == "GameScene" ):
		client_packets_list.insert(1, client_packets_list[0])


func updateLobbyData(): #Packet 4
	var label_to_update = tmpData[2]
	var scene = get_tree().get_current_scene()
	
	if (scene != null && scene.get_name() == "lobby"):
		if (label_to_update == "0"):
			scene.clearConnectedClientsLabel()
			for connected_client in range (3, tmpData.size()):
				scene.addConnectedClient("- " + tmpData[connected_client] + "\n")
		elif (label_to_update == "1"):
			scene.clearReadyPlayersLabel()
			for ready_client in range (3, tmpData.size()):
				scene.addReadyPlayer("- " + tmpData[ready_client] + "\n")
	elif (scene != null && scene.get_name() != "GameScene"):
		client_packets_list.push_back(client_packets_list[0])


func updateMapRoom(): #Packet 5
	var room_from = Vector2(tmpData[2].to_int(), tmpData[3].to_int())
	var room_to = Vector2(tmpData[4].to_int(), tmpData[5].to_int())
	var room_id = tmpData[6].to_int()
	
	var root = get_tree().get_current_scene()
	var map = null
	
	if (root != null && root.get_name() == "GameScene"):
		map = root.get_node("Map")
	else:
		return
	
	if (current_parsing.server):
		if ( server_data_base.removeMoney( map.getResources().getCostFromId(room_id), current_player_id  )):
			global_server.addPacket("/game 5 " + tmpData[2] + " " + tmpData[3] + " " + tmpData[4] + " " + tmpData[5] + " " + tmpData[6])
	elif (current_parsing.client):
		if ( map.get_name() != null ):
			map.new_room("new", map.getResources().getRoomFromId(room_id))
			map.new_room("from", room_from)
			map.new_room("current", room_to)
			map.new_room("to", room_to)
			map.new_room("create", null)


func updateMapItems(): #Packet 6
	if ( current_parsing.server ):
		updateMapItemsFromServer()
	elif ( current_parsing.client ):
		updateMapItemsFromClient()

func updateMapItemsFromServer():
	var update_type = tmpData[2]
	var item_name = tmpData[3]
	var rotation = tmpData[4].to_float()
	var position = Vector3(tmpData[5].to_int(), 0,  tmpData[6].to_int())
	var packet = "/game 6 "
	
	if (update_type == "0"):
		server_data_base.addItemInList(item_name, current_player_id, rotation, position)
		packet += "0 " + str(current_player_id) + " " + item_name + " " + server_data_base.getLastItemName() + " " + str(rotation) + " " + str(position.x) + " " + str(position.z)
	elif (update_type == "1"):
		if ( server_data_base.moveItem( item_name, current_player_id, rotation, position) ):
			packet += "1 " + item_name + " " + str(rotation) + " " + str(position.x) + " " + str(position.z)
		else:
			return
	
	global_server.addPacket(packet)

func updateMapItemsFromClient():
	var root = get_tree().get_current_scene()
	
	if (root != null && root.get_name() == "GameScene"):
		var update_type = tmpData[2].to_int()
		var item_from = tmpData[3].to_int()
		
		if (update_type == 0):
			if ( item_from == global_client.getClientId() ):
				root.setNameFirstItemTempArray(tmpData[5])
				root.setUpFirstItemTempArray()
			else:
				var node = root.getObjectResources().createObject(tmpData[4])
				root.add_child(node)
				node.setObjectStats(tmpData[4], tmpData[6], tmpData[7], tmpData[8])
				node.set_name(tmpData[5])
				node.setUpNetworkItem()
		elif (update_type == 1):
			root.moveItem(tmpData[3], tmpData[4], Vector3(tmpData[5], 0, tmpData[6]))


func kickedFromServer(): #Packet 7
	if ( current_parsing.client ):
		get_node("/root/GlobalClient").disconnectFromServer()
		var scene = load("res://scenes/network/WarningServerDisconnected.scn").instance()
		scene.displayKickedFromServer()
		get_tree().get_current_scene().add_child(scene, true)


func updatePlayerContainer(): #Packet 8
	if ( current_parsing.client ):
		var root = get_tree().get_current_scene()
		
		if (root.get_name() == "GameScene"):
			var menu_bar = root.get_node("In_game_gui/HUD/MenuBar")
			menu_bar.clearPlayerContainer()
			
			var data = 2
			
			for count in range ( (tmpData.size()-2)/2 ):
				if (global_client.getClientId() != tmpData[data+1].to_int()):
					menu_bar.addPlayerInPlayerContainer(tmpData[data], tmpData[data+1].to_int())
				data += 2

func muteUnmutePlayer(): #Packet 9
	if (tmpData[2] == "0"):
		global_server.unmutePlayer(current_player_id, tmpData[3])
	elif (tmpData[2] == "1"):
		global_server.mutePlayer(current_player_id, tmpData[3])

func displayAuctionMenu(): #Packet 10
	if ( current_parsing.server ):
		global_server.addPacket("/game 10")
	elif ( current_parsing.client ):
		var root = get_tree().get_current_scene()
		
		if ( root != null && root.get_name() == "GameScene" ):
			root.get_node("./In_game_gui/TownMap").set_hidden(false)
			root.get_node("./In_game_gui/TownMap").toggleAuctionMenuVisibility( 4200 )
			server_data_base.setAuctionSale( 4200 )


func acceptBid(): #Packet 11
	var root = get_tree().get_current_scene()
	
	if ( root == null || root.get_name() != "GameScene" ):
		return
	
	if ( current_parsing.server ):
		if ( ServerDataBase.acceptPlayerBid( current_player_id ) ):
			global_server.addPacket("/game 11 " + str(current_player_id))
	elif ( current_parsing.client ):
		root.get_node("./In_game_gui/TownMap").auction_menu.updateNextBid( tmpData[2].to_int() )


func setCurrentMoney(): #Packet 12
	var root = get_tree().get_current_scene()
	
	if ( root != null && root.get_name() == "GameScene" ):
		var money = tmpData[2].to_int()
		root.get_node("Player").setMoney(money)


func setNickname(): 
	if ( current_parsing.server ):
		var nickname = tmpData[1]
		global_server.setNickname(current_player_id, nickname)


func setCurrentParsing(current_parser, boolean):
	current_parsing.client = false
	current_parsing.server = false
	
	current_parsing[current_parser] = boolean


func parseMessage(packet):
	var message = packet.substr(6, packet.length() - 6)
	
	if (current_parsing.server):
		global_server.sendMessageToAll(current_player_id, message)
	elif (current_parsing.client):
		global_client.addMessage(message)


func parseInfo():
	var info = ""
	
	for word in range ( 1, tmpData.size() ):
		if (tmpData[word].begins_with("MSG")):
			info += tr(tmpData[word]) + " "
		else:
			info += tmpData[word] + " "
	
	info += "\n" 
	
	global_client.addMessage(info)

func addServerPacket(packet, client_id):
	var client_data = Array()
	client_data.push_back(packet)
	client_data.push_back(client_id)
	server_packets_list.push_back(client_data)

func getServerPacketsList():
	return server_packets_list


func addClientPacket(packet):
	client_packets_list.push_back(packet)

func getClientPacketsList():
	return client_packets_list