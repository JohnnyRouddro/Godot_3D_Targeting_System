extends KinematicBody

onready var target = $arrow.target

var velocity = Vector3.FORWARD
var speed = 0

var targeting_speed = 2

var targeting = false
var targeting_value = 0
var current_basis =  Transform()
var rotated_basis = Transform()
var final_quat = Transform()

func update_status():
	get_node("../Control/cam").text = "Camera target: " + String(targeting)

func _ready():
	update_status()

func _input(event):
	if event is InputEventKey:
		if event.as_text() == "F":
			if event.pressed:
				targeting_value = 0
				targeting = !targeting
				update_status()

func _physics_process(delta):
	

	# space to go up, ctrl to go down
	
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	if Input.is_action_pressed("up") || Input.is_action_pressed("down") || Input.is_action_pressed("right") || Input.is_action_pressed("left") || Input.is_action_pressed("forward") || Input.is_action_pressed("backward"):
		speed = 10
		velocity = Vector3(Input.get_action_strength("left") - Input.get_action_strength("right"),
							Input.get_action_strength("up") - Input.get_action_strength("down"),
							Input.get_action_strength("forward") - Input.get_action_strength("backward")).rotated(Vector3.UP, h_rot).normalized()
	else:
		speed = 0

	move_and_slide(velocity * speed, Vector3.UP)


func _process(delta):

	if target != $arrow.target:
		target = $arrow.target
		targeting_value = 0
	
	if targeting:
		rotated_basis = target.global_transform.looking_at($Camroot/h.global_transform.origin, Vector3.UP).basis
		
		$Camroot/h/v.rotation.x = lerp_angle($Camroot/h/v.rotation.x, 0, delta * targeting_speed * 4)
			
		if targeting_value <= 1:
			targeting_value += delta * targeting_speed
		# this one will lock
		$Camroot/h.global_transform.basis = $Camroot/h.global_transform.basis.slerp(rotated_basis, targeting_value)
		
		# this one will follow target instead of locking
#		$Camroot/h.global_transform.basis = $Camroot/h.global_transform.basis.slerp(rotated_basis, delta * targeting_speed * 4)
	else:
		$Camroot/h.rotation.x = lerp_angle($Camroot/h.rotation.x, 0, delta * targeting_speed * 4)
		$Camroot/h.rotation.z = lerp_angle($Camroot/h.rotation.z, 0, delta * targeting_speed * 4)





