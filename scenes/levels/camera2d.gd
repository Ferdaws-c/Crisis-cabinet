extends Camera2D

@export var tilemap_path: NodePath

func _ready() -> void:
	set_camera_limits()

func set_camera_limits() -> void:
	# If a tilemap is assigned, we read its boundaries automatically
	if not tilemap_path.is_empty():
		var tilemap = get_node(tilemap_path) as TileMap
		if tilemap:
			var map_rect = tilemap.get_used_rect()
			var cell_size = tilemap.tile_set.tile_size
			
			# Multiply the grid count by the cell size to get pixel bounds
			limit_left = map_rect.position.x * cell_size.x
			limit_top = map_rect.position.y * cell_size.y
			limit_right = map_rect.end.x * cell_size.x
			limit_bottom = map_rect.end.y * cell_size.y
