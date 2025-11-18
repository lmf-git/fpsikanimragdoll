extends CharacterController
class_name DummyTarget

## Dummy target that can be shot and responds with partial ragdoll
## Inherits all functionality from CharacterController

@export var auto_recover: bool = true
@export var recovery_time: float = 2.0  # Time before recovering from hits
@export var health: float = 100.0

var active_ragdoll_bones: Array[PhysicalBone3D] = []

func _ready():
	super._ready()

	# Dummy targets don't need player input or processing
	set_physics_process(false)
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)

	# Disable cameras on dummy target
	if fps_camera:
		fps_camera.queue_free()
	if tps_camera:
		tps_camera.queue_free()

	# Set up as stationary target
	print("Dummy target ready: ", name)

func _apply_partial_ragdoll(bone_name: String, impulse: Vector3):
	"""Override to track active ragdoll bones"""
	if not skeleton:
		return

	print("Dummy target hit on bone: ", bone_name)

	# Find the physical bone
	var physical_bone: PhysicalBone3D = null
	for child in skeleton.get_children():
		if child is PhysicalBone3D and child.bone_name == bone_name:
			physical_bone = child
			break

	if not physical_bone:
		print("  Physical bone not found!")
		return

	# If bone is already simulating, don't add it again
	if physical_bone in active_ragdoll_bones:
		# Just add more impulse
		physical_bone.apply_central_impulse(impulse)
		return

	# Start physics simulation if not already active
	if active_ragdoll_bones.is_empty():
		skeleton.physical_bones_start_simulation()

	active_ragdoll_bones.append(physical_bone)

	# Apply impulse to the hit bone
	physical_bone.apply_central_impulse(impulse)

	# Also enable nearby connected bones for more realistic effect
	_enable_connected_bones(bone_name, impulse * 0.5)

	# Schedule recovery
	if auto_recover:
		var recover_timer = get_tree().create_timer(recovery_time)
		recover_timer.timeout.connect(func(): _recover_all_bones())

	print("  Partial ragdoll applied to ", active_ragdoll_bones.size(), " bones")

func _enable_connected_bones(bone_name: String, impulse: Vector3):
	"""Enable physics on bones connected to the hit bone"""
	if not skeleton:
		return

	# Define bone connections (which bones should also ragdoll when hit)
	var bone_connections = {
		# Head/neck
		"characters3d.com___Head": ["characters3d.com___Neck"],
		"characters3d.com___Neck": ["characters3d.com___Head", "characters3d.com___Upper_Chest"],

		# Torso
		"characters3d.com___Upper_Chest": ["characters3d.com___Chest", "characters3d.com___Neck"],
		"characters3d.com___Chest": ["characters3d.com___Spine", "characters3d.com___Upper_Chest"],
		"characters3d.com___Spine": ["characters3d.com___Hips", "characters3d.com___Chest"],

		# Right arm
		"characters3d.com___R_Upper_Arm": ["characters3d.com___R_Lower_Arm", "characters3d.com___R_Shoulder"],
		"characters3d.com___R_Lower_Arm": ["characters3d.com___R_Hand", "characters3d.com___R_Upper_Arm"],
		"characters3d.com___R_Hand": ["characters3d.com___R_Lower_Arm"],

		# Left arm
		"characters3d.com___L_Upper_Arm": ["characters3d.com___L_Lower_Arm", "characters3d.com___L_Shoulder"],
		"characters3d.com___L_Lower_Arm": ["characters3d.com___L_Hand", "characters3d.com___L_Upper_Arm"],
		"characters3d.com___L_Hand": ["characters3d.com___L_Lower_Arm"],

		# Right leg
		"characters3d.com___R_Upper_Leg": ["characters3d.com___R_Lower_Leg", "characters3d.com___Hips"],
		"characters3d.com___R_Lower_Leg": ["characters3d.com___R_Foot", "characters3d.com___R_Upper_Leg"],
		"characters3d.com___R_Foot": ["characters3d.com___R_Lower_Leg"],

		# Left leg
		"characters3d.com___L_Upper_Leg": ["characters3d.com___L_Lower_Leg", "characters3d.com___Hips"],
		"characters3d.com___L_Lower_Leg": ["characters3d.com___L_Foot", "characters3d.com___L_Upper_Leg"],
		"characters3d.com___L_Foot": ["characters3d.com___L_Lower_Leg"],
	}

	if bone_name not in bone_connections:
		return

	var connected_bones = bone_connections[bone_name]
	for connected_bone_name in connected_bones:
		var physical_bone: PhysicalBone3D = null
		for child in skeleton.get_children():
			if child is PhysicalBone3D and child.bone_name == connected_bone_name:
				physical_bone = child
				break

		if physical_bone and physical_bone not in active_ragdoll_bones:
			active_ragdoll_bones.append(physical_bone)
			physical_bone.apply_central_impulse(impulse * 0.3)  # Weaker impulse on connected bones

func _recover_all_bones():
	"""Recover all active ragdoll bones"""
	print("Recovering ", active_ragdoll_bones.size(), " bones...")

	# Stop physics simulation on the skeleton
	if not ragdoll_enabled and skeleton:
		skeleton.physical_bones_stop_simulation()

	active_ragdoll_bones.clear()
	print("All bones recovered")

func take_damage(amount: float):
	"""Take damage (for future health system)"""
	health -= amount
	print("Dummy target took ", amount, " damage. Health: ", health)

	if health <= 0:
		_on_death()

func _on_death():
	"""Handle death - full ragdoll"""
	print("Dummy target died!")
	if skeleton:
		skeleton.physical_bones_start_simulation()
		ragdoll_enabled = true
