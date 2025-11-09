extends Node
class_name RagdollSetup

# Helper script to set up ragdoll physics on a skeleton
# This should be used as a tool script to automatically create PhysicalBone3D nodes

static func setup_ragdoll(skeleton: Skeleton3D) -> PhysicalBoneSimulator3D:
	if not skeleton:
		push_error("No skeleton provided for ragdoll setup")
		return null

	# Create physical bone simulator
	var simulator = PhysicalBoneSimulator3D.new()
	skeleton.add_child(simulator)
	simulator.owner = skeleton.get_tree().edited_scene_root if Engine.is_editor_hint() else skeleton

	# Define bone configurations for ragdoll
	# Format: [bone_name, shape_type, size, mass]
	var bone_configs = [
		# Spine
		["characters3d.com___Hips", "capsule", Vector3(0.3, 0.2, 0.3), 2.0],
		["characters3d.com___Spine", "capsule", Vector3(0.25, 0.15, 0.25), 1.5],
		["characters3d.com___Chest", "capsule", Vector3(0.3, 0.15, 0.3), 2.0],
		["characters3d.com___Upper_Chest", "capsule", Vector3(0.25, 0.15, 0.25), 1.5],
		["characters3d.com___Neck", "capsule", Vector3(0.1, 0.08, 0.1), 0.3],
		["characters3d.com___Head", "sphere", Vector3(0.15, 0.15, 0.15), 1.0],

		# Left Arm
		["characters3d.com___L_Shoulder", "sphere", Vector3(0.1, 0.1, 0.1), 0.3],
		["characters3d.com___L_Upper_Arm", "capsule", Vector3(0.08, 0.25, 0.08), 0.5],
		["characters3d.com___L_Lower_Arm", "capsule", Vector3(0.06, 0.25, 0.06), 0.4],
		["characters3d.com___L_Hand", "box", Vector3(0.05, 0.15, 0.08), 0.2],

		# Right Arm
		["characters3d.com___R_Shoulder", "sphere", Vector3(0.1, 0.1, 0.1), 0.3],
		["characters3d.com___R_Upper_Arm", "capsule", Vector3(0.08, 0.25, 0.08), 0.5],
		["characters3d.com___R_Lower_Arm", "capsule", Vector3(0.06, 0.25, 0.06), 0.4],
		["characters3d.com___R_Hand", "box", Vector3(0.05, 0.15, 0.08), 0.2],

		# Left Leg
		["characters3d.com___L_Upper_Leg", "capsule", Vector3(0.1, 0.4, 0.1), 1.5],
		["characters3d.com___L_Lower_Leg", "capsule", Vector3(0.08, 0.4, 0.08), 1.0],
		["characters3d.com___L_Foot", "box", Vector3(0.08, 0.05, 0.15), 0.3],

		# Right Leg
		["characters3d.com___R_Upper_Leg", "capsule", Vector3(0.1, 0.4, 0.1), 1.5],
		["characters3d.com___R_Lower_Leg", "capsule", Vector3(0.08, 0.4, 0.08), 1.0],
		["characters3d.com___R_Foot", "box", Vector3(0.08, 0.05, 0.15), 0.3],
	]

	# Create physical bones
	for config in bone_configs:
		var bone_name = config[0]
		var shape_type = config[1]
		var size = config[2]
		var mass = config[3]

		var bone_id = skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		# Create physical bone
		var physical_bone = PhysicalBone3D.new()
		physical_bone.name = "PhysicalBone_" + bone_name
		physical_bone.set_bone_name(bone_name)
		physical_bone.mass = mass
		physical_bone.friction = 0.5
		physical_bone.bounce = 0.0

		# Create collision shape
		var collision_shape = CollisionShape3D.new()
		var shape: Shape3D

		match shape_type:
			"sphere":
				var sphere = SphereShape3D.new()
				sphere.radius = size.x
				shape = sphere
			"capsule":
				var capsule = CapsuleShape3D.new()
				capsule.radius = size.x
				capsule.height = size.y * 2
				shape = capsule
			"box":
				var box = BoxShape3D.new()
				box.size = size
				shape = box

		collision_shape.shape = shape
		physical_bone.add_child(collision_shape)
		collision_shape.owner = skeleton.get_tree().edited_scene_root if Engine.is_editor_hint() else skeleton

		# Add to skeleton
		skeleton.add_child(physical_bone)
		physical_bone.owner = skeleton.get_tree().edited_scene_root if Engine.is_editor_hint() else skeleton

	return simulator
