extends VehicleBody3D
class_name Robot
@onready var L : float = abs($Wheel_FL.position.z - $Wheel_BL.position.z) # Distanza tra ruote anteriori e posteriori
@onready var W : float = abs($Wheel_FL.position.x - $Wheel_FR.position.x) # Distanza tra le ruote sterzanti

var punti = []




var indice = 0

const STRAIGHT = 0
const TURN = 1
const STOP = 2

func _ready() -> void:
	self.can_sleep = false
	DDS.subscribe("Torque")
	DDS.subscribe("Theta")
	DDS.subscribe("Control_Index")

var time_passed: float = 0.0
var publish_rate: float = 0.05

func _physics_process(delta: float) -> void:
	var torque = DDS.read("Torque")
	var theta = DDS.read("Theta")
	var Control_Index = DDS.read("Control_Index")
	#print("Posizione robot", position)
	if Control_Index != null:
		indice = Control_Index
	else:
		pass
	
	
	var brake_max = 30
	
	if theta != null and theta != 0:
		var theta_abs_rad = deg_to_rad(abs(theta))
		var theta_tan = tan(theta_abs_rad)
		var modifier = (W / (2 * L)) * theta_tan

		var inner_theta = atan(theta_tan / (1 - modifier))
		var outer_theta = atan(theta_tan / (1 + modifier))
		
		if theta > 0:
			$Wheel_FL.steering = inner_theta
			$Wheel_FR.steering = outer_theta
		else:
			$Wheel_FR.steering = -inner_theta
			$Wheel_FL.steering = -outer_theta
	else:
		$Wheel_FL.steering = 0.0
		$Wheel_FR.steering = 0.0
	
	if torque != null:
		if torque < 0:
			self.set_engine_force(0.0)
			self.set_brake(clamp(-torque, 0.0, brake_max))
		else:
			self.set_brake(0.0)
			self.set_engine_force(torque)


	time_passed += delta
	if time_passed >= publish_rate:
		time_passed = 0.0 
		
		DDS.publish("tick", DDS.DDS_TYPE_FLOAT, delta)
		DDS.publish("X", DDS.DDS_TYPE_FLOAT, global_position.x)
		DDS.publish("Z", DDS.DDS_TYPE_FLOAT, global_position.z)
		
		var forward_dir = global_transform.basis.z
		var yaw_2d = atan2(forward_dir.x, forward_dir.z)
		DDS.publish("Yaw", DDS.DDS_TYPE_FLOAT, yaw_2d)
		
		var cur_trajectory = calc_trajectory_type(indice)
		var current_speed = linear_velocity.length()
		DDS.publish("Speed", DDS.DDS_TYPE_FLOAT, current_speed)
		DDS.publish("X_dest", DDS.DDS_TYPE_FLOAT, punti[indice][0])
		DDS.publish("Z_dest", DDS.DDS_TYPE_FLOAT, punti[indice][1])
		DDS.publish("Robot_index", DDS.DDS_TYPE_INT, indice)
		DDS.publish("Trajectory_Type", DDS.DDS_TYPE_INT, cur_trajectory)
		

func calc_trajectory_type(idx: int) -> int:
	if idx >= punti.size() - 1:
		return STOP
	
	var p1 := Vector2(self.position.x,self.position.z)
	var p2 := Vector2(punti[idx][0], punti[idx][1])
	var p3 := Vector2(punti[idx + 1][0], punti[idx + 1][1])
	
	var dir1 := (p2 - p1).normalized()
	var dir2 := (p3 - p2).normalized()
	
	# Qui l'angolo minimo per la traiettoria "dritta" e' abbastanza
	# largo dato che tutte le curve del labirtinto sono di 90 gradi
	# e non vogliamo che una piccola variazione di traiettoria
	# triggeri lo stato di curva
	if dir1.dot(dir2) > 0.5: 
		return STRAIGHT
	else:
		return TURN
		
