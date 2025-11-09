@tool
extends EditorScript

# Improved physical bones setup script
# This will find the skeleton automatically and create all physical bones

func _run():
	print("\n=== Physical Bones Setup Starting ===\n")

	var scene_root = get_scene()
	if not scene_root:
		print("ERROR: No scene open! Please open character.tscn first")
		return

	print("Scene root: ", scene_root.name)

	# Find skeleton recursively
	var skeleton = find_skeleton_recursive(scene_root)

	if not skeleton:
		print("ERROR: No Skeleton3D found in scene!")
		print("Make sure character.tscn is open")
		return

	print("Found skeleton: ", skeleton.name)
	print("Skeleton has ", skeleton.get_bone_count(), " bones")

	# Remove existing physical bones and simulator
	print("\nRemoving old physical bones...")
	var to_remove = []
	for child in skeleton.get_children():
		if child is PhysicalBone3D or child is PhysicalBoneSimulator3D:
			print("  Removing: ", child.name)
			to_remove.append(child)

	# Remove them
	for node in to_remove:
		skeleton.remove_child(node)
		node.queue_free()

	print("\nCreating PhysicalBoneSimulator3D...")
	var simulator = PhysicalBoneSimulator3D.new()
	simulator.name = "PhysicalBoneSimulator3D"
	skeleton.add_child(simulator, true)
	simulator.owner = scene_root
	print("  Created: ", simulator.name)

	print("\nCreating physical bones...")

	# Define bone configurations: [bone_name, shape_type, size, mass, joint_type]
	var bone_configs = [
		# Torso
		["characters3d.com___Hips", "capsule", Vector3(0.3, 0.2, 0.3), 3.0, PhysicalBone3D.JOINT_TYPE_NONE],
		["characters3d.com___Spine", "capsule", Vector3(0.25, 0.15, 0.25), 2.0, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___Chest", "capsule", Vector3(0.3, 0.15, 0.3), 2.5, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___Upper_Chest", "capsule", Vector3(0.28, 0.15, 0.28), 2.0, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___Neck", "capsule", Vector3(0.08, 0.08, 0.08), 0.4, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___Head", "sphere", Vector3(0.15, 0.15, 0.15), 1.5, PhysicalBone3D.JOINT_TYPE_CONE],

		# Left Arm
		["characters3d.com___L_Shoulder", "sphere", Vector3(0.1, 0.1, 0.1), 0.4, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___L_Upper_Arm", "capsule", Vector3(0.08, 0.25, 0.08), 0.6, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___L_Lower_Arm", "capsule", Vector3(0.06, 0.25, 0.06), 0.5, PhysicalBone3D.JOINT_TYPE_HINGE],
		["characters3d.com___L_Hand", "box", Vector3(0.05, 0.15, 0.08), 0.3, PhysicalBone3D.JOINT_TYPE_CONE],

		# Right Arm
		["characters3d.com___R_Shoulder", "sphere", Vector3(0.1, 0.1, 0.1), 0.4, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___R_Upper_Arm", "capsule", Vector3(0.08, 0.25, 0.08), 0.6, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___R_Lower_Arm", "capsule", Vector3(0.06, 0.25, 0.06), 0.5, PhysicalBone3D.JOINT_TYPE_HINGE],
		["characters3d.com___R_Hand", "box", Vector3(0.05, 0.15, 0.08), 0.3, PhysicalBone3D.JOINT_TYPE_CONE],

		# Left Leg
		["characters3d.com___L_Upper_Leg", "capsule", Vector3(0.1, 0.4, 0.1), 2.0, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___L_Lower_Leg", "capsule", Vector3(0.08, 0.4, 0.08), 1.5, PhysicalBone3D.JOINT_TYPE_HINGE],
		["characters3d.com___L_Foot", "box", Vector3(0.08, 0.05, 0.18), 0.5, PhysicalBone3D.JOINT_TYPE_CONE],

		# Right Leg
		["characters3d.com___R_Upper_Leg", "capsule", Vector3(0.1, 0.4, 0.1), 2.0, PhysicalBone3D.JOINT_TYPE_CONE],
		["characters3d.com___R_Lower_Leg", "capsule", Vector3(0.08, 0.4, 0.08), 1.5, PhysicalBone3D.JOINT_TYPE_HINGE],
		["characters3d.com___R_Foot", "box", Vector3(0.08, 0.05, 0.18), 0.5, PhysicalBone3D.JOINT_TYPE_CONE],
	]

	var created_count = 0

	for config in bone_configs:
		var bone_name = config[0]
		var shape_type = config[1]
		var size = config[2]
		var mass = config[3]
		var joint_type = config[4]

		var bone_id = skeleton.find_bone(bone_name)
		if bone_id < 0:
			print("  WARNING: Bone not found: ", bone_name)
			continue

		# Create physical bone
		var physical_bone = PhysicalBone3D.new()
		physical_bone.name = bone_name.replace("characters3d.com___", "PhysicalBone_")
		physical_bone.bone_name = bone_name
		physical_bone.mass = mass
		physical_bone.friction = 0.6
		physical_bone.bounce = 0.0
		physical_bone.joint_type = joint_type

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
				collision_shape.rotation_degrees = Vector3(0, 0, 90)
			"box":
				var box = BoxShape3D.new()
				box.size = size * 2
				shape = box

		collision_shape.shape = shape
		physical_bone.add_child(collision_shape, true)
		collision_shape.owner = scene_root

		# Add to skeleton
		skeleton.add_child(physical_bone, true)
		physical_bone.owner = scene_root

		created_count += 1
		print("  Created: ", physical_bone.name)

	print("\n=== Setup Complete! ===")
	print("Created ", created_count, " physical bones")
	print("Created PhysicalBoneSimulator3D")
	print("\nNow save the scene (Ctrl+S) and test ragdoll with R key!")

func find_skeleton_recursive(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node

	for child in node.get_children():
		var result = find_skeleton_recursive(child)
		if result:
			return result

	return null
