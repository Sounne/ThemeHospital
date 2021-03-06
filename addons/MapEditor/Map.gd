
tool
extends Control

var editor = null

var tiles = []
var zoom = 10
var node2d = null

var is_inside = false
var current_tile = Vector2(-1,-1)
var current_color = Color(0,0,0)
var painting = false

var square_from = Vector2(-1,-1)
var square_to = Vector2(-1,-1)

const tile_type = {"Decoration":0, "Lobby":1}

class Tile:
	var type = "Decoration"
	var x = -1
	var y = -1

var size_x = 0
var size_y = 0

func coord_to_index(x, y):
	return (y*size_y)+x

func _init(_x, _y, _editor):
	size_x = _x
	size_y = _y
	editor = _editor
	print("[MAP EDITOR] Create new Map of ", size_x, "X", size_y, " tiles")
	
	for y in range(size_y):
		for x in range(size_x):
			var tile = Tile.new()
			tile.x = x
			tile.y = y
			tiles.append(tile)
	print("[MAP EDITOR] Map generated !")
	
	node2d = Node2D.new()
	node2d.set_scale(Vector2(zoom,zoom))
	add_child(node2d)
	node2d.connect("draw", self, "draw_map")
	
	set_process_input(true)
	print("[MAP EDITOR] Node for map initialized !")

func _input(event):
	if ((event.type == InputEvent.MOUSE_MOTION) or (event.type == InputEvent.MOUSE_BUTTON)):
		var pos = node2d.get_global_pos()
		var size = node2d.get_scale()
		var rect = Rect2(pos.x, pos.y, size.x * size_x, size.y * size_y)
		is_inside = rect.has_point(event.pos)
		
		if(is_inside):
			var pos_mouse_in_node = Vector2(event.pos.x - pos.x, event.pos.y - pos.y)
			current_tile = Vector2(floor(pos_mouse_in_node.x / size.x), floor(pos_mouse_in_node.y / size.y))
		else:
			current_tile = Vector2(-1,-1)
		if (event.is_action_pressed("left_click")):
			painting = true
		elif (event.is_action_released("left_click")):
			painting = false
		elif (event.is_action_pressed("right_click")):
			if (square_from == Vector2(-1,-1)):
				square_from = current_tile
				change_tile(square_from.x, square_from.y)
			else:
				square_to = current_tile
				for tile in get_list(square_from, square_to):
					tile.type = editor.current_brush
				node2d.update()
				square_from = Vector2(-1,-1)
				square_to = Vector2(-1,-1)
		if(painting):
			if(current_tile != Vector2(-1,-1)):
				change_tile(current_tile.x, current_tile.y)
				node2d.update()

func draw_map():
	for tile in tiles:
		if(tile.type == "Decoration"):
			node2d.draw_rect(Rect2(tile.x,tile.y,1,1), Color(0.153, 0.682, 0.384))
		if(tile.type == "Lobby"):
			node2d.draw_rect(Rect2(tile.x,tile.y,1,1), Color(0.498, 0.549, 0.553))

func change_tile(x, y):
	tiles[coord_to_index(x, y)].type = editor.current_brush
	node2d.update()

func change_zoom(_zoom):
	zoom = _zoom
	node2d.set_scale(Vector2(zoom,zoom))

func is_valid():
	for tile in tiles:
		if (tile.type == "Lobby"):
			return true
	return false

func get_list(from, to):
	if (from > to):
		var swap_tmp = from
		from = to
		to = swap_tmp
	
	var selection = []
	if(from.y > to.y):
		for tile in tiles:
			if ((tile.x >= from.x && tile.x <= to.x) && (tile.y <= from.y && tile.y >= to.y)):
				selection.append(tile)
	else:
		for tile in tiles:
			if ((tile.x >= from.x && tile.x <= to.x) && (tile.y >= from.y && tile.y <= to.y)):
				selection.append(tile)
	
	return selection