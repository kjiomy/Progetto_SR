extends VehicleBody3D
@onready var L : float = abs($Wheel_FL.position.z - $Wheel_BL.position.z) # Distanza tra ruote anteriori e posteriori
@onready var W : float = abs($Wheel_FL.position.x - $Wheel_FR.position.x) # Distanza tra le ruote sterzanti


func _ready() -> void:
	DDS.subscribe("Torque")
	DDS.subscribe("Theta")

func _process(delta: float) -> void:
	#print(theRobot.global_position.x, " ", -theRobot.global_position.z, " ", theRobot.global_rotation.y)
	DDS.publish("tick", DDS.DDS_TYPE_FLOAT, delta)

	var torque = DDS.read("Torque")
	var theta = DDS.read("Theta")
	
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
	
	if(torque != null):
		self.set_engine_force(torque) 
