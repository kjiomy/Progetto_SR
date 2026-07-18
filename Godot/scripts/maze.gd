extends Node3D
class_name Maze

@export var width: int = 5
@export var height: int = 5
var grid: Array[Array] = []
var solvepath: Array[MazeNode] = []
@export var maze_node_scene: PackedScene = preload("res://scenes/maze_node.tscn")
@export var cell_size: float = 10.0
@export var wall_height: float = 5.0
@export var wall_thickness: float = 0.1
@export var wall_material: Material
@export var floor_material: Material

func _ready() -> void:
	init_nodes()
	gen_maze(Vector2i(0, 0))
	render_maze()
	solvepath = solve_bfs(Vector2i(0, 0), Vector2i(width - 1, height - 1))
	#print_maze(solvepath)
	var green_mat := StandardMaterial3D.new()
	green_mat.albedo_color = Color(0.1, 0.8, 0.2,0.5)
	green_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	for node in solvepath:
		node.highlight_with_material(green_mat)

func init_nodes() -> void:
	grid.clear()
	
	for x in range(width):
		var row: Array[MazeNode] = []
		for y in range(height):
			var node: MazeNode = maze_node_scene.instantiate()
			node.name = "Cell_%d_%d" % [x, y]
			
			node.position = Vector3(x * cell_size, 0, y * cell_size)
			
			add_child(node)
			row.append(node)
		grid.append(row)
			
	for x in range(width):
			for y in range(height):
				# UP (North): Decreasing Y
				if y > 0:
					grid[x][y].north = grid[x][y - 1]
					
				# DOWN (South): Increasing Y
				if y < height - 1:
					grid[x][y].south = grid[x][y + 1]
					
				# LEFT (West): Decreasing X (FIXED: was .east)
				if x > 0:
					grid[x][y].west = grid[x - 1][y]
					
				# RIGHT (East): Increasing X (FIXED: was height - 1 and .east)
				if x < width - 1:
					grid[x][y].east = grid[x + 1][y]

func gen_maze(start: Vector2i = Vector2i(0,0)) -> void:
	var stack: Array[MazeNode] = []
	var visited: Array[MazeNode] = []

	visited.append(grid[start.x][start.y])
	stack.append(grid[start.x][start.y])
	
	while not stack.is_empty():
		var current: MazeNode = stack.back() 
		
		var unvisited_neigh: Array[MazeNode] = []
		for n in current.neighbors:
			if n != null and n not in visited:
				unvisited_neigh.append(n)
				
		if not unvisited_neigh.is_empty():
			var next_node: MazeNode = unvisited_neigh.pick_random()
			current.remove_wall_between(next_node)
			visited.append(next_node)
			stack.append(next_node)
		else:
			stack.pop_back()

func print_maze(path: Array[MazeNode] = []) -> void:
	# Convert the path array to a Dictionary for super fast O(1) lookups inside the loop
	var path_map := {}
	for node in path:
		path_map[node] = true
		
	for y in range(height):
		var top: String = ""
		var mid: String = ""
		var bottom: String = ""
		
		for x in range(width):
			var current: MazeNode = grid[x][y]
			
			top += "##" if current.northwall else "# "
			top += "#"
			
			mid += "#" if current.westwall else " "
			
			# --- THIS IS THE CENTER OF THE CELL ---
			if path_map.has(current):
				mid += "O"  # Draw the path trail!
			else:
				mid += " "  # Empty corridor
			# --------------------------------------
				
			mid += "#" if current.eastwall else " "
			
			bottom += "##" if current.southwall else "# "
			bottom += "#"
			
		print(top)
		print(mid)
		print(bottom)

func solve_dijkstra(start_pos: Vector2i = Vector2i(0, 0), end_pos: Vector2i = Vector2i(width - 1, height - 1)) -> Array[MazeNode]:
	var start_node: MazeNode = grid[start_pos.x][start_pos.y]
	var end_node: MazeNode = grid[end_pos.x][end_pos.y]
	
	# Track the shortest known distance to each node
	var distances: Dictionary = {}
	# Track the "breadcrumb" trail to reconstruct the path later
	var previous: Dictionary = {}
	# List of nodes left to evaluate
	var unvisited: Array[MazeNode] = []
	
	# 1. Initialization
	for x in range(width):
		for y in range(height):
			var node: MazeNode = grid[x][y]
			distances[node] = INF  # INF is Godot's built-in constant for Infinity
			unvisited.append(node)
			
	distances[start_node] = 0.0
	
	# 2. Main Dijkstra Loop
	while not unvisited.is_empty():
		# Find the unvisited node with the smallest distance
		var current: MazeNode = null
		var min_dist: float = INF
		var min_index: int = -1
		
		for i in range(unvisited.size()):
			var node: MazeNode = unvisited[i]
			if distances[node] < min_dist:
				min_dist = distances[node]
				current = node
				min_index = i
		
		# If the smallest distance is INF, remaining nodes are unreachable (trapped)
		if current == null or min_dist == INF:
			break
			
		# Optimization: If we reached the destination, we can stop searching early!
		if current == end_node:
			break
			
		unvisited.remove_at(min_index)
		
		# 3. Evaluate neighbors (ONLY unwalled corridors!)
		for neighbor in current.unwalled_neighbors:
			if neighbor in unvisited:
				# Every step in our grid costs exactly 1.0
				var alt_dist: float = distances[current] + 1.0
				if alt_dist < distances[neighbor]:
					distances[neighbor] = alt_dist
					previous[neighbor] = current
					
	# 4. Reconstruct the shortest path by working backward from the end
	var path: Array[MazeNode] = []
	var curr: MazeNode = end_node
	
	while curr in previous:
		path.push_front(curr)
		curr = previous[curr]
		
	# If a valid path was found (or start == end), prepend the starting node
	if not path.is_empty() or start_node == end_node:
		path.push_front(start_node)
		
	return path

func solve_bfs(start_pos: Vector2i = Vector2i(0, 0), end_pos: Vector2i = Vector2i(width - 1, height - 1)) -> Array[MazeNode]:
	var start_node: MazeNode = grid[start_pos.x][start_pos.y]
	var end_node: MazeNode = grid[end_pos.x][end_pos.y]
	
	# Track the "breadcrumb" trail to reconstruct the path later
	var previous: Dictionary = {}
	
	# Fast O(1) lookup to check if a node has already been queued
	var visited: Dictionary = { start_node: true }
	
	# The FIFO (First-In, First-Out) Queue
	var queue: Array[MazeNode] = [start_node]
	
	# 1. Main BFS Loop
	while not queue.is_empty():
		# Pop the oldest node from the front of the queue
		var current: MazeNode = queue.pop_front()
		
		# Early exit: If we reached the destination, we are done!
		if current == end_node:
			break
			
		# 2. Check all open corridors
		for neighbor in current.unwalled_neighbors:
			if not visited.has(neighbor):
				visited[neighbor] = true
				previous[neighbor] = current
				queue.append(neighbor)
				
	# 3. Reconstruct the shortest path by working backward from the end
	var path: Array[MazeNode] = []
	var curr: MazeNode = end_node
	
	while curr in previous:
		path.push_front(curr)
		curr = previous[curr]
		
	# If a valid path was found (or start == end), prepend the starting node
	if not path.is_empty() or start_node == end_node:
		path.push_front(start_node)
		
	return path

func render_maze() -> void:
	# Create a parent CSGCombiner3D to group and optimize all walls
	var wall_container := CSGCombiner3D.new()
	wall_container.name = "Walls"
	wall_container.use_collision = true # Automatically creates physics collisions for the player!
	add_child(wall_container)
	
	for x in range(width):
		for y in range(height):
			var current: MazeNode = grid[x][y]
			
			# 1. Draw NORTH wall
			if current.northwall:
				var wall := _create_wall_piece(Vector3(cell_size, wall_height, wall_thickness))
				# Position at the top edge (negative Z direction) of the cell
				wall.position = current.position + Vector3(0, wall_height / 2.0, -cell_size / 2.0)
				wall_container.add_child(wall)
				
			# 2. Draw WEST wall
			if current.westwall:
				var wall := _create_wall_piece(Vector3(wall_thickness, wall_height, cell_size))
				# Position at the left edge (negative X direction) of the cell
				wall.position = current.position + Vector3(-cell_size / 2.0, wall_height / 2.0, 0)
				wall_container.add_child(wall)
				
			# 3. Draw SOUTH wall (ONLY for the bottom-most row of the maze)
			if y == height - 1 and current.southwall:
				var wall := _create_wall_piece(Vector3(cell_size, wall_height, wall_thickness))
				wall.position = current.position + Vector3(0, wall_height / 2.0, cell_size / 2.0)
				wall_container.add_child(wall)
				
			# 4. Draw EAST wall (ONLY for the right-most column of the maze)
			if x == width - 1 and current.eastwall:
				var wall := _create_wall_piece(Vector3(wall_thickness, wall_height, cell_size))
				wall.position = current.position + Vector3(cell_size / 2.0, wall_height / 2.0, 0)
				wall_container.add_child(wall)
	# --- 5. GENERATE FLOOR ---
	var floor_thickness: float = 0.5
	var floor_piece := CSGBox3D.new()
	floor_piece.name = "Floor"
	
	# Match the total footprint of the maze grid
	floor_piece.size = Vector3(width * cell_size, floor_thickness, height * cell_size)
	
	# Center the floor over the grid along X and Z
	var center_x: float = (width - 1) * cell_size / 2.0
	var center_z: float = (height - 1) * cell_size / 2.0
	
	# Position Y at -floor_thickness / 2.0 so the top surface sits perfectly flush at Y = 0
	floor_piece.position = Vector3(center_x, -floor_thickness / 2.0, center_z)
	
	if floor_material:
		floor_piece.material = floor_material
		
	wall_container.add_child(floor_piece)

# Helper function to instantiate a standardized wall brick
func _create_wall_piece(size: Vector3) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.size = size
	if wall_material:
		box.material = wall_material
	return box
