extends VehicleBody3D
class_name Robot
@onready var L : float = abs($Wheel_FL.position.z - $Wheel_BL.position.z) # Distanza tra ruote anteriori e posteriori
@onready var W : float = abs($Wheel_FL.position.x - $Wheel_FR.position.x) # Distanza tra le ruote sterzanti

var punti = []

var indice = 0;

func _ready() -> void:
	self.can_sleep = false
	DDS.subscribe("Torque")
	DDS.subscribe("Theta")
	DDS.subscribe("Index")

var time_passed: float = 0.0
var publish_rate: float = 0.05

func _physics_process(delta: float) -> void:
	var torque = DDS.read("Torque")
	var theta = DDS.read("Theta")
	var index = DDS.read("Index")
	print("Posizione robot", position)
	if index != null:
		indice = index
	else:
		pass
	
	
	var brake_max = 200
	
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
		
		var current_speed = linear_velocity.length()
		DDS.publish("Speed", DDS.DDS_TYPE_FLOAT, current_speed)
		DDS.publish("X_dest", DDS.DDS_TYPE_FLOAT, punti[indice][0])
		DDS.publish("Z_dest", DDS.DDS_TYPE_FLOAT, punti[indice][1])
		DDS.publish("Indice", DDS.DDS_TYPE_INT, indice)
