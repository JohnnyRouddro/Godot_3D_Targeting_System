extends Spatial

# All the modes, sorted from easy to hard to implement

# Direct: Like look_at() but uses positive z-axis
# Smooth - Follow: Non linear, Follows the target, no lock on
# Smooth - Lock: Non linear, locks on at end, not good for mecha feel
# Constant - Static: Linear, simpler code, for static target/player, good for static mechanical stuff
# Constant - Moving: Linear, more complex code, works with moving target/player, good for moving mecha

onready var target = $"../../targets/0" # setting the initial target

var mode_str = ["Direct", "Smooth - Follow", "Smooth - Lock", "Constant - Static", "Constant - Moving"]

const MODE_DIRECT = 0
const MODE_SMOOTH_FOLLOW = 1
const MODE_SMOOTH_TARGET = 2
const MODE_CONSTANT_STATIC = 3
const MODE_CONSTANT_MOVING = 4

const CONSTANT_INTERPOLATION = 3
const SMOOTH_TARGET_INTERPOLATION = 2
const SMOOTH_FOLLOW_INTERPOLATION = 5

export(int, "Direct", "Smooth - Follow", "Smooth - Lock", "Constant - Static", "Constant - Moving") var mode = MODE_DIRECT

var target_pos = Vector3()
var init_scale = Vector3()
var targeting = true
var look_value = 0
var initial_basis =  Transform().basis
var rotated_basis = Transform().basis

var distance
var velocity

# These two variables are only needed for CONSTANT MOVING mode
var angle
var target_locked = false

var target_material = SpatialMaterial.new()

func update_status():
	$"../../Control/arrow".text = "Arrow Target: " + (mode_str [mode] if targeting else String(targeting))

func random_target():
	target = $"../../targets".get_child(randi() % $"../../targets".get_child_count())
	target.material_override = target_material

func _ready():
	randomize()
	target_material.albedo_color = Color("#ff0000")
	target.material_override = target_material
	update_status()
	initial_basis = global_transform.basis.orthonormalized()
	angle = initial_basis.z.angle_to(rotated_basis.z)
	init_scale = scale # storing the scale initially as we'll lose it after calling orthonormalized()

func _input(event):
	if event is InputEventKey:
		if event.as_text() == "1" || event.as_text() == "2" || event.as_text() == "3" || event.as_text() == "4" || event.as_text() == "5" :
			if event.pressed:
				look_value = 0
				targeting = !targeting
				mode = event.as_text().to_int() - 1
				update_status()

				# setting the target rotation and initial rotation once (only needed for constant speed)
				if targeting:
					random_target()
					rotated_basis = target.global_transform.looking_at(global_transform.origin, Vector3.UP).basis
				else:
					target.material_override = null
					
					rotated_basis = Transform().basis
					target_locked = false
					get_node("../../Control/Label3").text = ""

				initial_basis = global_transform.basis.orthonormalized()
				angle = initial_basis.z.angle_to(rotated_basis.z)



func _process(delta):  

	if mode == MODE_DIRECT:

		if targeting:
			get_node("../../Control/Label3").text = "Target Locked!"
			rotated_basis = target.global_transform.looking_at(global_transform.origin, Vector3.UP).basis
			global_transform.basis = global_transform.basis.orthonormalized().slerp(rotated_basis, 1).scaled(init_scale)
		else:
			global_transform.basis = global_transform.basis.orthonormalized().slerp(Transform().basis, 1).scaled(init_scale)


	elif mode == MODE_SMOOTH_FOLLOW:

		if targeting:
			get_node("../../Control/Label3").text = "Following"

			rotated_basis = target.global_transform.looking_at(global_transform.origin, Vector3.UP).basis.orthonormalized()
			global_transform.basis = global_transform.basis.orthonormalized().slerp(rotated_basis, delta * SMOOTH_FOLLOW_INTERPOLATION).scaled(init_scale)
		else:
			global_transform.basis = global_transform.basis.orthonormalized().slerp(Transform().basis,  delta * SMOOTH_FOLLOW_INTERPOLATION).scaled(init_scale)


	elif mode == MODE_SMOOTH_TARGET && initial_basis.z.angle_to(rotated_basis.z) != 0:

		distance = initial_basis.z.angle_to(rotated_basis.z)
		velocity = SMOOTH_TARGET_INTERPOLATION / distance # v = (1/t) / d => v = d / t
		# this way we'll have the same speed instead of same duration from different distance

		if look_value < 1:
			look_value += delta * velocity
		else:
			if targeting:
				get_node("../../Control/Label3").text = "Target Locked!"

		if targeting:
			rotated_basis = target.global_transform.looking_at(global_transform.origin, Vector3.UP).basis

		global_transform.basis = global_transform.basis.orthonormalized().slerp(rotated_basis, look_value).scaled(init_scale)


	elif mode == MODE_CONSTANT_STATIC && initial_basis.z.angle_to(rotated_basis.z) != 0:

		distance = initial_basis.z.angle_to(rotated_basis.z)
		velocity = CONSTANT_INTERPOLATION / distance # v = (1/t) / d => v = d / t
		# this way we'll have the same speed instead of same duration from different distance

		if look_value <= 1:
			look_value += delta * velocity
		else:
			if targeting:
				get_node("../../Control/Label3").text = "Target Locked!"

		global_transform.basis = initial_basis.slerp(rotated_basis, look_value).scaled(init_scale)


	elif mode == MODE_CONSTANT_MOVING && initial_basis.z.angle_to(rotated_basis.z) != 0:

		if targeting:
			rotated_basis = target.global_transform.looking_at(global_transform.origin, Vector3.UP).basis

		distance = initial_basis.z.angle_to(rotated_basis.z)
		velocity = CONSTANT_INTERPOLATION / distance # v = (1/t) / d => v = d / t
		# this way we'll have the same speed instead of same duration from different distance

		if !target_locked:
			if rad2deg(angle) < rad2deg(initial_basis.z.angle_to(rotated_basis.z)):
				initial_basis = global_transform.basis.orthonormalized()
				angle = initial_basis.z.angle_to(rotated_basis.z)
				look_value = 0

		if look_value <= 1:
			look_value += delta * velocity
		else:
			if targeting:
				get_node("../../Control/Label3").text = "Target Locked!"
				target_locked = true

		if !target_locked:
			global_transform.basis = initial_basis.slerp(rotated_basis, look_value).scaled(init_scale)
		else:
			global_transform.basis = global_transform.basis.orthonormalized().slerp(rotated_basis, 1).scaled(init_scale)







