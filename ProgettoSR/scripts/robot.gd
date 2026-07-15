extends VehicleBody3D
@onready var L : float = abs($Wheel_FL.position.z - $Wheel_BL.position.z) # Distanza tra ruote anteriori e posteriori
@onready var W : float = abs($Wheel_FL.position.x - $Wheel_FR.position.x) # Distanza tra le ruote sterzanti


func _ready() -> void:
	self.can_sleep = false
	DDS.subscribe("Torque")
	DDS.subscribe("Theta")

func _process(delta: float) -> void:
	DDS.publish("tick", DDS.DDS_TYPE_FLOAT, delta)
	DDS.publish("X", DDS.DDS_TYPE_FLOAT, global_position.x)
	DDS.publish("Z", DDS.DDS_TYPE_FLOAT, global_position.z)
	
	# FIX: Otteniamo il vettore frontale 3D del veicolo (-Z in Godot)
	var forward_dir = global_transform.basis.z
	# Calcoliamo lo yaw 2D usando atan2, che combacerà esattamente con il math.atan2 di Python
	var yaw_2d = atan2(forward_dir.z, forward_dir.x)
	DDS.publish("Yaw", DDS.DDS_TYPE_FLOAT, yaw_2d)
	
	var current_speed = linear_velocity.length()
	DDS.publish("Speed", DDS.DDS_TYPE_FLOAT, current_speed)

	var torque = DDS.read("Torque")
	var theta = DDS.read("Theta")
	var brake_max = 100
	
	if theta != 0 and theta != null:
			var theta_abs_rad = deg_to_rad(abs(theta))
			var theta_tan = tan(theta_abs_rad)
			var modifier = (W / (2 * L)) * theta_tan

			var inner_theta = atan(theta_tan / (1 - modifier))
			var outer_theta = atan(theta_tan / (1 + modifier))
			
			if theta > 0:
				# Giriamo a sinistra, la ruota sinistra e' interna.
				$Wheel_FL.steering = inner_theta
				$Wheel_FR.steering = outer_theta
			else:
				# Giriamo a destra , la ruota destra e' interna
				$Wheel_FR.steering = -inner_theta
				$Wheel_FL.steering = -outer_theta
	else:
		# Se andiamo dritti azzeriamo lo sterzo di entrambe le ruote
		$Wheel_FL.steering = 0.0
		$Wheel_FR.steering = 0.0
	
	if torque != null:
		if torque < 0:
			self.set_engine_force(0.0)
			self.set_brake(clamp(-torque, 0.0, brake_max))
		else:
			self.set_brake(0.0)
			self.set_engine_force(torque)
