extends CharacterBody3D
const SPEED = 5.0
const JUMP_VELOCITY = 4.5


func _ready() -> void:
	DDS.subscribe("X")
	DDS.subscribe("Y")
	DDS.subscribe("Theta")

func _process(delta: float) -> void:
	#print(theRobot.global_position.x, " ", -theRobot.global_position.z, " ", theRobot.global_rotation.y)
	DDS.publish("tick", DDS.DDS_TYPE_FLOAT, delta)

	var x = DDS.read("X")
	var y = DDS.read("Y")
	var theta = DDS.read("Theta")

	if (x != null)and(y != null)and(theta != null):
		self.global_position.x = -y
		self.global_position.z = -x
		self.global_rotation.y = theta


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
