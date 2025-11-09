@tool
extends EditorScript

# Helper script to automatically set up physical bones for ragdoll
# Run this from the editor: File -> Run -> setup_physical_bones.gd

func _run():
	var scene_root = get_scene()
	if not scene_root:
		print("No scene open")
		return

	# Find character node
	var character = scene_root.get_node_or_null("Character")
	if not character:
		print("Character node not found")
		return

	# Find skeleton
	var skeleton = find_skeleton(character)
	if not skeleton:
		print("Skeleton3D not found")
		return

	# Remove existing physical bones
	for child in skeleton.get_children():
		if child is PhysicalBone3D or child is PhysicalBoneSimulator3D:
			child.queue_free()

	print("Creating physical bones...")

	# Create physical bone simulator first
	var simulator = PhysicalBoneSimulator3D.new()
	simulator.name = "PhysicalBoneSimulator3D"
	skeleton.add_child(simulator, true)
	simulator.owner = get_scene()

	# Define bone configurations
	var bone_configs = [
		# [bone_name, shape_type, size, mass, joint_type]
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
			print("Bone not found: " + bone_name)
			continue

		# Create physical bone
		var physical_bone = PhysicalBone3D.new()
		physical_bone.name = bone_name.replace("characters3d.com___", "PhysicalBone_")
		physical_bone.bone_name = bone_name
		physical_bone.mass = mass
		physical_bone.friction = 0.6
		physical_bone.bounce = 0.0
		physical_bone.joint_type = joint_type

		# Configure joint limits based on type
		if joint_type == PhysicalBone3D.JOINT_TYPE_CONE:
			physical_bone.joint_constraints.set("angular_limit_enabled", true)
			physical_bone.joint_constraints.set("swing_span", deg_to_rad(45))
			physical_bone.joint_constraints.set("twist_span", deg_to_rad(30))
		elif joint_type == PhysicalBone3D.JOINT_TYPE_HINGE:
			physical_bone.joint_constraints.set("angular_limit_enabled", true)
			physical_bone.joint_constraints.set("angular_limit_lower", deg_to_rad(-120))
			physical_bone.joint_constraints.set("angular_limit_upper", deg_to_rad(0))

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
				# Rotate capsule to align with bone
				collision_shape.rotation_degrees = Vector3(0, 0, 90)
			"box":
				var box = BoxShape3D.new()
				box.size = size * 2
				shape = box

		collision_shape.shape = shape
		physical_bone.add_child(collision_shape, true)
		collision_shape.owner = get_scene()

		# Add to skeleton
		skeleton.add_child(physical_bone, true)
		physical_bone.owner = get_scene()

		created_count += 1
		print("Created physical bone: " + physical_bone.name)

	print("Physical bones setup complete! Created " + str(created_count) + " bones.")
	print("PhysicalBoneSimulator3D added.")

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = find_skeleton(child)
		if result:
			return result
	return null
