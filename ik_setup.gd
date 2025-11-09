@tool
extends EditorScript

# Helper script to automatically set up IK nodes on the skeleton
# Run this from the editor: File -> Run -> ik_setup.gd

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

	# Find IK targets
	var ik_targets = character.get_node_or_null("IKTargets")
	if not ik_targets:
		print("IKTargets node not found")
		return

	# Setup IK for each limb
	setup_limb_ik(skeleton, ik_targets, "LeftHand",
		"characters3d.com___L_Shoulder",
		"characters3d.com___L_Hand")

	setup_limb_ik(skeleton, ik_targets, "RightHand",
		"characters3d.com___R_Shoulder",
		"characters3d.com___R_Hand")

	setup_limb_ik(skeleton, ik_targets, "LeftFoot",
		"characters3d.com___L_Upper_Leg",
		"characters3d.com___L_Foot")

	setup_limb_ik(skeleton, ik_targets, "RightFoot",
		"characters3d.com___R_Upper_Leg",
		"characters3d.com___R_Foot")

	print("IK setup complete!")

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = find_skeleton(child)
		if result:
			return result
	return null

func setup_limb_ik(skeleton: Skeleton3D, ik_targets: Node3D, limb_name: String, root_bone: String, tip_bone: String):
	var ik_node_name = limb_name + "IK"

	# Check if already exists
	var existing = skeleton.get_node_or_null(ik_node_name)
	if existing:
		print("IK node already exists: " + ik_node_name)
		existing.queue_free()

	# Create new SkeletonIK3D
	var ik = SkeletonIK3D.new()
	ik.name = ik_node_name
	ik.root_bone = root_bone
	ik.tip_bone = tip_bone

	# Find target node
	var target = ik_targets.get_node_or_null(limb_name + "Target")
	if target:
		ik.target_node = ik.get_path_to(target)
		ik.use_magnet = true
		ik.magnet = Vector3(0, 0, -0.5)  # Pull slightly back

	# Add to skeleton
	skeleton.add_child(ik, true)
	ik.owner = get_scene()

	print("Created IK: " + ik_node_name)
