extends Node3D

@onready var overlook_cam: Camera3D = $OverlookCamera
@onready var maze: Maze = $Maze
@export var robot: PackedScene
var chase_cam: Camera3D

var use_chase_cam: bool = false

func _ready() -> void:
	maze.gen_maze(Vector2i(0, 0))
	maze.render_maze()
	maze.solvepath = maze.solve_bfs(Vector2i(0, 0), Vector2i(maze.width - 1, maze.height - 1))
	
	if maze.solvepath.size() > 0:
		spawn_robot_at(maze.solvepath[0])
		var center = Vector3(maze.width * maze.cell_size / 2.0, 0, maze.height * maze.cell_size / 2.0)
		overlook_cam.position = center + Vector3(0, maze.width * 8, 0)
		overlook_cam.look_at(center)
		
		update_camera_mode()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		use_chase_cam = !use_chase_cam
		update_camera_mode()

func update_camera_mode() -> void:
	if use_chase_cam:
		var robot_node = get_node_or_null("my_robot") 
		if robot_node:
			chase_cam = robot_node.get_node("SpringArm3D/ChaseCamera")
			chase_cam.make_current()
			print("Switched to Chase Camera")
	else:
		overlook_cam.make_current()
		print("Switched to Overlook Camera")

func spawn_robot_at(target_node: MazeNode) -> void:
	if robot:
		var robot_instance = robot.instantiate()
		robot_instance.name = "my_robot"
		add_child(robot_instance)
		
		robot_instance.global_position = target_node.global_position + Vector3(0, 0.5, 0)
