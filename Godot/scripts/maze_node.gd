extends Node3D
class_name MazeNode

var neighbors: Array[MazeNode] = [null, null, null, null]
var unwalled_neighbors: Array[MazeNode] = []

var north: MazeNode:
	get: return neighbors[0]
	set(value): neighbors[0] = value

var west: MazeNode:
	get: return neighbors[1]
	set(value): neighbors[1] = value

var south: MazeNode:
	get: return neighbors[2]
	set(value): neighbors[2] = value

var east: MazeNode:
	get: return neighbors[3]
	set(value): neighbors[3] = value

var northwall: bool = true
var westwall: bool = true
var southwall: bool = true
var eastwall: bool = true

func remove_wall_between(neighbor: MazeNode) -> void:
	if neighbor not in unwalled_neighbors:
		if neighbor == north:
			northwall = false
		elif neighbor == west:
			westwall = false
		elif neighbor == south:
			southwall = false
		elif neighbor == east:
			eastwall = false
		else:
			push_error("ERROR: tried removing wall between non-neighboring nodes")
			return
		unwalled_neighbors.append(neighbor)
		neighbor.remove_wall_between(self)

func highlight_with_material(new_material: Material) -> void:
	# Directly target the child MeshInstance3D by its name in the scene tree
	if has_node("NodeMesh"):
		$NodeMesh.material_override = new_material
