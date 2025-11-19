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

	# CRITICAL: Start physics simulation on skeleton so physical bones become collidable
	# Without this, raycasts cannot hit PhysicalBone3D nodes
	# Set very high damping so bones stay in place until hit with force
	if skeleton:
		skeleton.physical_bones_start_simulation()
		print("Dummy target: Started physics simulation for hit detection")

		# Set high damping on all physical bones so they stay in place
		for child in skeleton.get_children():
			if child is PhysicalBone3D:
				child.linear_damp = 10.0  # Very high damping keeps bones from moving
				child.angular_damp = 10.0  # until hit with significant force

	# Set up as stationary target
	print("Dummy target ready: ", name)

func _apply_partial_ragdoll(bone_name: String, impulse: Vector3):
	"""Override to track active ragdoll bones and apply damage"""
	if not skeleton:
		return

	print("Dummy target hit on bone: ", bone_name, " with impulse: ", impulse.length())

	# Apply damage based on impulse strength
	var damage_amount = impulse.length() * 2.0  # Scale impulse to damage
	take_damage(damage_amount)

	# Find the physical bone
	var physical_bone: PhysicalBone3D = null
	for child in skeleton.get_children():
		if child is PhysicalBone3D and child.bone_name == bone_name:
			physical_bone = child
			break

	if not physical_bone:
		print("  Physical bone not found for: ", bone_name)
		return

	print("  Found physical bone: ", physical_bone.name)

	# Physics simulation is already running (started in _ready for hit detection)
	# Just reduce damping on hit bones so they can move naturally
	physical_bone.linear_damp = 0.3  # Restore normal damping for natural movement
	physical_bone.angular_damp = 0.5

	# If bone is already in active list, just add more impulse
	if physical_bone in active_ragdoll_bones:
		physical_bone.apply_central_impulse(impulse)
		print("  Applied additional impulse to active bone")
		return

	# Add bone to active list
	active_ragdoll_bones.append(physical_bone)

	# Apply impulse to the hit bone
	physical_bone.apply_central_impulse(impulse)
	print("  Applied impulse to new bone: ", impulse)

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
			# Reduce damping so bone can move
			physical_bone.linear_damp = 0.3
			physical_bone.angular_damp = 0.5
			physical_bone.apply_central_impulse(impulse * 0.3)  # Weaker impulse on connected bones

func _recover_all_bones():
	"""Recover all active ragdoll bones"""
	print("Recovering ", active_ragdoll_bones.size(), " bones...")

	# Restore high damping on all recovered bones to keep them in place
	for bone in active_ragdoll_bones:
		if is_instance_valid(bone):
			bone.linear_damp = 10.0  # High damping to return to rest pose
			bone.angular_damp = 10.0

	active_ragdoll_bones.clear()
	print("All bones recovered - high damping restored")

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
