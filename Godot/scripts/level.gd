extends Node3D

@onready var overlook_cam: Camera3D = $OverlookCamera
@export var maze: PackedScene
@export var robot: PackedScene
@onready var main_menu: CanvasLayer = $MainMenu
@onready var width_input: SpinBox = $MainMenu/VBoxContainer/HBoxWidth/WidthSpinBox
@onready var height_input: SpinBox = $MainMenu/VBoxContainer/HBoxHeight/HeightSpinBox
var chase_cam: Camera3D

var use_chase_cam: bool = false

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if not main_menu.visible and event.is_action_pressed("ui_accept"):
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

func spawn_robot_at(target_node: MazeNode) -> Robot:
	if robot:
		var robot_instance = robot.instantiate()
		robot_instance.name = "my_robot"
		add_child(robot_instance)
		
		robot_instance.global_position = target_node.global_position + Vector3(0, 0.5, 0)
		return robot_instance
	return null


func _on_generate_button_pressed() -> void:
	var maze_instance: Maze = maze.instantiate()
	maze_instance.width = int(width_input.value)
	maze_instance.height = int(height_input.value)
	add_child(maze_instance)
	
	
	main_menu.visible = false
	if maze_instance.solvepath.size() > 0:
		var robot_instance: Robot = spawn_robot_at(maze_instance.solvepath[0])
		
		for node in maze_instance.solvepath:
			robot_instance.punti.append([node.global_position.x, node.global_position.z])
			
		robot_instance.punti.append([-999,-999])
		print(robot_instance.punti)
		
		var center = Vector3(maze_instance.width * maze_instance.cell_size / 2.0, 0, maze_instance.height * maze_instance.cell_size / 2.0)
		overlook_cam.position = center + Vector3(0, maze_instance.width * 8, 0)
		overlook_cam.look_at(center)
		
		update_camera_mode()
