extends CharacterBody3D
class_name CharacterController

# Movement
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

# Camera
@export var fps_camera: Camera3D
@export var tps_camera: Camera3D
@export var camera_mode: int = 0  # 0 = FPS, 1 = TPS
@export var max_camera_pitch_up: float = 70.0  # Maximum degrees to look up
@export var max_camera_pitch_down: float = 80.0  # Maximum degrees to look down

# Character parts
@export var skeleton: Skeleton3D
@export var head_bone_name: String = "characters3d.com___Head"
@export var neck_bone_name: String = "characters3d.com___Neck"
@export var right_hand_bone_name: String = "characters3d.com___R_Hand"
@export var left_hand_bone_name: String = "characters3d.com___L_Hand"

# Head look and free look
@export var head_look_enabled: bool = true
@export var max_head_rotation_x: float = 60.0  # degrees (pitch)
@export var max_head_rotation_y: float = 70.0  # degrees (yaw before body turns)
@export var head_rotation_speed: float = 10.0
@export var body_rotation_speed: float = 8.0  # How fast body catches up to camera
@export var free_look_threshold: float = 45.0  # Degrees of head turn before body follows

# IK System
@export var ik_enabled: bool = true
@export var left_hand_ik: SkeletonIK3D
@export var right_hand_ik: SkeletonIK3D
@export var left_foot_ik: SkeletonIK3D
@export var right_foot_ik: SkeletonIK3D

# Ragdoll
@export var ragdoll_enabled: bool = false
@export var auto_create_ragdoll: bool = true  # Automatically create physical bones at runtime
@export var debug_show_colliders: bool = true  # Show collision shapes for debugging

# Weapon system
@export var pickup_range: float = 2.0
var equipped_weapon: Weapon = null
var nearby_weapon: Weapon = null

# Ragdoll bone configuration - bones that will have physics
const RAGDOLL_BONES = [
	# Torso
	"Hips", "Spine", "Chest", "Upper_Chest", "Neck", "Head",
	# Left arm
	"L_Shoulder", "L_Upper_Arm", "L_Lower_Arm", "L_Hand",
	# Left fingers
	"L_Thumb_Proximal", "L_Thumb_Intermediate", "L_Thumb_Distal",
	"L_Index_Proximal", "L_Index_Intermediate", "L_Index_Distal",
	"L_Middle_Proximal", "L_Middle_Intermediate", "L_Middle_Distal",
	"L_Ring_Proximal", "L_Ring_Intermediate", "L_Ring_Distal",
	"L_Little_Proximal", "L_Little_Intermediate", "L_Little_Distal",
	# Right arm
	"R_Shoulder", "R_Upper_Arm", "R_Lower_Arm", "R_Hand",
	# Right fingers
	"R_Thumb_Proximal", "R_Thumb_Intermediate", "R_Thumb_Distal",
	"R_Index_Proximal", "R_Index_Intermediate", "R_Index_Distal",
	"R_Middle_Proximal", "R_Middle_Intermediate", "R_Middle_Distal",
	"R_Ring_Proximal", "R_Ring_Intermediate", "R_Ring_Distal",
	"R_Little_Proximal", "R_Little_Intermediate", "R_Little_Distal",
	# Legs
	"L_Upper_Leg", "L_Lower_Leg", "L_Foot", "L_Toes",
	"R_Upper_Leg", "R_Lower_Leg", "R_Foot", "R_Toes"
]

# Internal variables
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_rotation: Vector2 = Vector2.ZERO  # Camera/head target rotation
var body_rotation_y: float = 0.0  # Actual body Y rotation
var head_bone_id: int = -1
var neck_bone_id: int = -1
var right_hand_bone_id: int = -1
var left_hand_bone_id: int = -1
var original_head_pose: Transform3D
var original_neck_pose: Transform3D
var mesh_instance: MeshInstance3D

func _ready():
	print("\n=== Character Controller Ready ===")
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Find skeleton if not set
	if not skeleton:
		skeleton = find_skeleton(self)

	print("Skeleton found: ", skeleton)

	if skeleton:
		print("Skeleton bone count: ", skeleton.get_bone_count())
		print("Looking for head bone: ", head_bone_name)
		print("Looking for neck bone: ", neck_bone_name)
		print("Looking for right hand bone: ", right_hand_bone_name)
		print("Looking for left hand bone: ", left_hand_bone_name)

		head_bone_id = skeleton.find_bone(head_bone_name)
		neck_bone_id = skeleton.find_bone(neck_bone_name)
		right_hand_bone_id = skeleton.find_bone(right_hand_bone_name)
		left_hand_bone_id = skeleton.find_bone(left_hand_bone_name)

		print("Head bone ID: ", head_bone_id)
		print("Neck bone ID: ", neck_bone_id)
		print("Right hand bone ID: ", right_hand_bone_id)
		print("Left hand bone ID: ", left_hand_bone_id)

		if head_bone_id >= 0:
			original_head_pose = skeleton.get_bone_pose(head_bone_id)
		if neck_bone_id >= 0:
			original_neck_pose = skeleton.get_bone_pose(neck_bone_id)

		# Find mesh instance for visibility control
		mesh_instance = find_mesh_instance(skeleton)
		print("Mesh instance: ", mesh_instance)

		# Debug: List all bones
		print("\n=== All Skeleton Bones ===")
		for i in range(skeleton.get_bone_count()):
			print("  [", i, "] ", skeleton.get_bone_name(i))
		print("=== End Bone List ===\n")

	# Find cameras if not set (they should be children of this node)
	if not fps_camera:
		fps_camera = get_node_or_null("FPSCamera")
	if not tps_camera:
		tps_camera = get_node_or_null("TPSCamera")

	print("FPS Camera: ", fps_camera)
	print("TPS Camera: ", tps_camera)
	print("Initial camera mode: ", camera_mode)

	# Auto-create ragdoll if enabled
	if auto_create_ragdoll and skeleton:
		_create_ragdoll_bones()

	# Set initial camera
	_switch_camera(camera_mode)
	print("=== End Character Controller Ready ===\n")

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = find_skeleton(child)
		if result:
			return result
	return null

func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	return null

func _create_ragdoll_bones():
	print("\n=== Creating Ragdoll Bones at Runtime ===")

	# Check if bones already exist
	var existing_bones = 0
	for child in skeleton.get_children():
		if child is PhysicalBone3D:
			existing_bones += 1

	if existing_bones > 0:
		print("Physical bones already exist (", existing_bones, "), skipping creation")
		return

	var bones_created = 0

	# Create physical bones for ragdoll
	for bone_suffix in RAGDOLL_BONES:
		# Find the bone ID - try different naming conventions
		var bone_id = -1
		var bone_name = ""

		# Try different prefixes common in character models
		var prefixes = ["characters3d.com___", "", "mixamorig:", "Armature_"]
		for prefix in prefixes:
			var test_name = prefix + bone_suffix
			bone_id = skeleton.find_bone(test_name)
			if bone_id >= 0:
				bone_name = test_name
				break

		if bone_id < 0:
			print("  WARNING: Could not find bone: ", bone_suffix)
			continue

		# Create physical bone
		var physical_bone = PhysicalBone3D.new()
		physical_bone.name = "PhysicalBone_" + bone_suffix
		physical_bone.bone_name = bone_name

		# Get bone size to create appropriately sized collision shape
		var bone_parent_id = skeleton.get_bone_parent(bone_id)
		var bone_length = 0.2  # default

		# Calculate bone length from rest pose if possible
		if bone_parent_id >= 0:
			var bone_rest = skeleton.get_bone_rest(bone_id)
			bone_length = bone_rest.origin.length()
			if bone_length < 0.05:
				bone_length = 0.2

		# Determine shape size based on bone type
		var radius = 0.05
		var height = bone_length

		# Larger shapes for major bones
		if bone_suffix in ["Hips", "Spine", "Chest", "Upper_Chest"]:
			radius = 0.18
			height = 0.35
		elif bone_suffix in ["Head"]:
			radius = 0.15
			height = 0.25
		elif bone_suffix in ["Upper_Arm", "Lower_Arm", "Upper_Leg", "Lower_Leg"]:
			radius = 0.06
			height = max(bone_length, 0.2)
		elif "Hand" in bone_suffix or "Foot" in bone_suffix:
			radius = 0.05
			height = 0.15
		elif "Finger" in bone_suffix or "Thumb" in bone_suffix or "Index" in bone_suffix or "Middle" in bone_suffix or "Ring" in bone_suffix or "Little" in bone_suffix or "Toes" in bone_suffix:
			radius = 0.02
			height = 0.05

		# Create collision shape
		var shape = CapsuleShape3D.new()
		shape.radius = radius
		shape.height = height

		# Add collision shape
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = shape

		# Adjust collision shape position for specific bones
		if bone_suffix in ["Head"]:
			# Move head collider up slightly
			collision_shape.position = Vector3(0, 0.05, 0)

		physical_bone.add_child(collision_shape)
		collision_shape.owner = physical_bone

		# Add debug visualization mesh
		if debug_show_colliders:
			var debug_mesh = MeshInstance3D.new()
			var capsule_mesh = CapsuleMesh.new()
			capsule_mesh.radius = radius
			capsule_mesh.height = height
			debug_mesh.mesh = capsule_mesh

			# Create semi-transparent material for debug view
			var debug_material = StandardMaterial3D.new()
			debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			debug_material.albedo_color = Color(0, 1, 0, 0.3)  # Green semi-transparent
			debug_mesh.material_override = debug_material

			collision_shape.add_child(debug_mesh)
			debug_mesh.owner = physical_bone

		# CRITICAL: Configure joint to connect to parent bone
		# Use HINGE joints for knees and elbows, CONE for everything else
		var use_hinge = bone_suffix in ["Lower_Leg", "L_Lower_Leg", "R_Lower_Leg", "Lower_Arm", "L_Lower_Arm", "R_Lower_Arm"]

		if use_hinge:
			physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_HINGE
		else:
			physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_CONE

		physical_bone.joint_offset = Transform3D()  # No offset from bone

		# Joint limits - EXTREMELY tight constraints, near-rigid skeleton
		var swing_limit = deg_to_rad(5)   # Default almost rigid
		var twist_limit = deg_to_rad(2)   # Almost no twist
		var damping = 0.95  # Very high damping = very stiff
		var bias = 0.95     # Very high bias = rigid response

		# Ultra-specific constraints - EXTREMELY tight, near-rigid!
		if bone_suffix in ["Hips"]:
			# Hips/pelvis - COMPLETELY LOCKED (no rotation at all)
			swing_limit = deg_to_rad(0.01)
			twist_limit = deg_to_rad(0.01)
			damping = 0.99999
			bias = 0.99999
		elif bone_suffix in ["Spine", "Chest", "Upper_Chest"]:
			# Spine/torso - COMPLETELY LOCKED (no rotation at all)
			swing_limit = deg_to_rad(0.01)
			twist_limit = deg_to_rad(0.01)
			damping = 0.99999
			bias = 0.99999
		elif bone_suffix in ["Neck"]:
			# Neck - COMPLETELY LOCKED (no rotation at all)
			swing_limit = deg_to_rad(0.01)
			twist_limit = deg_to_rad(0.01)
			damping = 0.99999
			bias = 0.99999
		elif bone_suffix in ["Head"]:
			# Head - COMPLETELY LOCKED (no rotation at all)
			swing_limit = deg_to_rad(0.01)
			twist_limit = deg_to_rad(0.01)
			damping = 0.99999
			bias = 0.99999
		elif "Shoulder" in bone_suffix:
			# Shoulders - COMPLETELY LOCKED (no rotation at all)
			swing_limit = deg_to_rad(0.01)
			twist_limit = deg_to_rad(0.01)
			damping = 0.99999
			bias = 0.99999
		elif bone_suffix in ["Upper_Leg", "L_Upper_Leg", "R_Upper_Leg"]:
			# Upper legs - very restricted hip
			swing_limit = deg_to_rad(3)
			twist_limit = deg_to_rad(0.5)
			damping = 0.98
			bias = 0.98
		elif bone_suffix in ["Lower_Leg", "L_Lower_Leg", "R_Lower_Leg"]:
			# HINGE: Lower legs (knees) - one direction only
			# For hinge joints, only swing matters
			swing_limit = deg_to_rad(120)  # Can bend backward
			twist_limit = deg_to_rad(0)    # No twist on hinge
			damping = 0.95
			bias = 0.95
		elif bone_suffix in ["Foot", "L_Foot", "R_Foot"]:
			# Feet/ankles - extremely restricted
			swing_limit = deg_to_rad(0.5)
			twist_limit = deg_to_rad(0.2)
			damping = 0.998
			bias = 0.998
		elif bone_suffix in ["Toes", "L_Toes", "R_Toes"]:
			# Toes - almost locked
			swing_limit = deg_to_rad(1)
			twist_limit = deg_to_rad(0.1)
			damping = 0.998
			bias = 0.998
		elif bone_suffix in ["Upper_Arm", "L_Upper_Arm", "R_Upper_Arm"]:
			# Upper arms - very restricted shoulder movement
			swing_limit = deg_to_rad(3)
			twist_limit = deg_to_rad(1)
			damping = 0.98
			bias = 0.98
		elif bone_suffix in ["Lower_Arm", "L_Lower_Arm", "R_Lower_Arm"]:
			# HINGE: Lower arms (elbows) - one direction only
			swing_limit = deg_to_rad(140)  # Can bend
			twist_limit = deg_to_rad(0)    # No twist on hinge
			damping = 0.95
			bias = 0.95
		elif bone_suffix in ["Hand", "L_Hand", "R_Hand"]:
			# Hands/wrists - extremely restricted
			swing_limit = deg_to_rad(0.5)
			twist_limit = deg_to_rad(0.2)
			damping = 0.998
			bias = 0.998
		elif "Finger" in bone_suffix or "Thumb" in bone_suffix or "Index" in bone_suffix or "Middle" in bone_suffix or "Ring" in bone_suffix or "Little" in bone_suffix:
			# Fingers - almost locked
			swing_limit = deg_to_rad(2)
			twist_limit = deg_to_rad(0.1)
			damping = 0.998
			bias = 0.998

		# Apply limits based on joint type
		if use_hinge:
			# Hinge joints use different constraint properties
			physical_bone.set("joint_constraints/angular_limit_lower", -swing_limit)
			physical_bone.set("joint_constraints/angular_limit_upper", 0)  # Only bend one way
			physical_bone.set("joint_constraints/angular_limit_enabled", true)
		else:
			# Cone joints
			physical_bone.set("joint_constraints/swing_span", swing_limit)
			physical_bone.set("joint_constraints/twist_span", twist_limit)

		# EXTREMELY stiff joints - nearly rigid skeleton
		physical_bone.set("joint_constraints/bias", bias)
		physical_bone.set("joint_constraints/damping", damping)
		physical_bone.set("joint_constraints/softness", 0.001)  # Extremely rigid, not springy
		physical_bone.set("joint_constraints/relaxation", 0.999)  # Very high stability

		# Physics properties - add damping to resist all motion
		physical_bone.mass = 1.0
		physical_bone.friction = 1.0  # Maximum friction
		physical_bone.bounce = 0.0
		physical_bone.linear_damp = 0.8  # Strong resistance to linear movement
		physical_bone.angular_damp = 0.99  # Extremely heavy resistance to rotation

		# CRITICAL: Set collision layers and masks for proper physics
		physical_bone.collision_layer = 2  # Layer 2 for ragdoll parts
		physical_bone.collision_mask = 1   # Collide with layer 1 (world/ground)

		# Add to skeleton
		skeleton.add_child(physical_bone)
		physical_bone.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		bones_created += 1
		print("  Created: ", physical_bone.name, " (radius: ", radius, ", height: ", height, ")")

	# Set up collision exceptions between all physical bones (prevent self-collision)
	var all_physical_bones = []
	for child in skeleton.get_children():
		if child is PhysicalBone3D:
			all_physical_bones.append(child)

	print("Setting up collision exceptions between ", all_physical_bones.size(), " bones...")
	for i in range(all_physical_bones.size()):
		for j in range(i + 1, all_physical_bones.size()):
			all_physical_bones[i].add_collision_exception_with(all_physical_bones[j])

	print("Created ", bones_created, " physical bones")
	print("=== Ragdoll Creation Complete ===\n")

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.x -= event.relative.y * mouse_sensitivity
		camera_rotation.y -= event.relative.x * mouse_sensitivity
		# Clamp pitch (x rotation) with configurable limits
		camera_rotation.x = clamp(camera_rotation.x, deg_to_rad(-max_camera_pitch_up), deg_to_rad(max_camera_pitch_down))

	if event.is_action_pressed("toggle_camera"):
		print("\n=== TOGGLE CAMERA PRESSED ===")
		print("Current camera_mode: ", camera_mode)
		camera_mode = (camera_mode + 1) % 2
		print("New camera_mode: ", camera_mode)
		_switch_camera(camera_mode)
		print("Camera mode: ", "FPS" if camera_mode == 0 else "TPS")
		print("=== END TOGGLE ===\n")

	if event.is_action_pressed("toggle_ik"):
		print("\n=== TOGGLE IK PRESSED ===")
		ik_enabled = !ik_enabled
		print("IK enabled: ", ik_enabled)
		print("Left hand IK: ", left_hand_ik)
		print("Right hand IK: ", right_hand_ik)
		print("Left foot IK: ", left_foot_ik)
		print("Right foot IK: ", right_foot_ik)
		print("=== END IK TOGGLE ===\n")

	if event.is_action_pressed("toggle_ragdoll"):
		toggle_ragdoll()

	# E key for weapon pickup/drop
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		print("E key pressed - equipped_weapon: ", equipped_weapon, ", nearby_weapon: ", nearby_weapon)
		if equipped_weapon:
			drop_weapon()
		elif nearby_weapon:
			pickup_weapon(nearby_weapon)

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _switch_camera(mode: int):
	print("\n=== _switch_camera called ===")
	print("Mode: ", mode, " (", "FPS" if mode == 0 else "TPS", ")")
	print("fps_camera exists: ", fps_camera != null)
	print("tps_camera exists: ", tps_camera != null)

	if fps_camera and tps_camera:
		if mode == 0:  # FPS
			print("Setting FPS camera as current")
			fps_camera.current = true
			tps_camera.current = false
			# Use camera cull mask to hide character body in FPS
			# Layer 1 = default, Layer 2 = character body
			if mesh_instance:
				# Move mesh to layer 2
				mesh_instance.layers = 2
				print("Mesh moved to layer 2")
			# FPS camera only sees layer 1 (not character body)
			fps_camera.cull_mask = 1
		else:  # TPS
			print("Setting TPS camera as current")
			fps_camera.current = false
			tps_camera.current = true
			if mesh_instance:
				# Move mesh back to layer 1
				mesh_instance.layers = 1
				print("Mesh moved to layer 1")
			# TPS camera sees all layers
			tps_camera.cull_mask = 0xFFFFF
	else:
		print("ERROR: One or both cameras are null!")
		print("fps_camera: ", fps_camera)
		print("tps_camera: ", tps_camera)
	print("=== End _switch_camera ===\n")

func _physics_process(delta):
	if ragdoll_enabled:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Update body rotation - smoothly follow camera or snap when moving
	var head_yaw_difference = angle_difference(body_rotation_y, camera_rotation.y)

	# If moving, body faces movement direction immediately
	# If standing still, body turns when head exceeds threshold
	if input_dir.length() > 0.1:
		# When moving, body follows camera direction
		body_rotation_y = lerp_angle(body_rotation_y, camera_rotation.y, body_rotation_speed * delta)
	else:
		# When standing still, only turn body if head turned too far
		if abs(head_yaw_difference) > deg_to_rad(free_look_threshold):
			body_rotation_y = lerp_angle(body_rotation_y, camera_rotation.y, body_rotation_speed * delta * 0.5)

	# Apply body rotation
	rotation.y = body_rotation_y

	# Calculate movement direction based on body rotation
	var direction = Vector3.ZERO
	if input_dir.length() > 0.1:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement
	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Update head rotation for aiming
	if head_look_enabled and skeleton and head_bone_id >= 0:
		_update_head_look(delta)

	# Detect nearby weapons for pickup
	_detect_nearby_weapon()

func _update_head_look(delta):
	# Calculate head rotation relative to body
	var head_yaw_offset = angle_difference(body_rotation_y, camera_rotation.y)

	# Clamp head rotations to limits
	var head_pitch = clamp(camera_rotation.x,
		deg_to_rad(-max_head_rotation_x),
		deg_to_rad(max_head_rotation_x))

	var head_yaw = clamp(head_yaw_offset,
		deg_to_rad(-max_head_rotation_y),
		deg_to_rad(max_head_rotation_y))

	# Apply rotation to neck (contributes to yaw and some pitch)
	if neck_bone_id >= 0:
		var neck_pose = skeleton.get_bone_pose(neck_bone_id)
		var neck_target = Basis()
		# Neck contributes 40% of the yaw rotation
		neck_target = neck_target.rotated(Vector3.UP, head_yaw * 0.4)
		# Neck contributes 30% of pitch (negated due to 180° model rotation)
		neck_target = neck_target.rotated(neck_target.x, -head_pitch * 0.3)
		neck_target = neck_target * original_neck_pose.basis

		neck_pose.basis = neck_pose.basis.slerp(neck_target, head_rotation_speed * delta)
		skeleton.set_bone_pose(neck_bone_id, neck_pose)

	# Apply rotation to head (remaining rotation)
	var head_pose = skeleton.get_bone_pose(head_bone_id)
	var head_target = Basis()
	# Head contributes 60% of yaw rotation
	head_target = head_target.rotated(Vector3.UP, head_yaw * 0.6)
	# Head contributes 70% of pitch (negated due to 180° model rotation)
	head_target = head_target.rotated(head_target.x, -head_pitch * 0.7)
	head_target = head_target * original_head_pose.basis

	head_pose.basis = head_pose.basis.slerp(head_target, head_rotation_speed * delta)
	skeleton.set_bone_pose(head_bone_id, head_pose)

func toggle_ragdoll():
	print("=== Ragdoll Toggle Debug ===")

	if not skeleton:
		print("ERROR: No skeleton found!")
		return

	# Count physical bones
	var physical_bones = []
	for child in skeleton.get_children():
		if child is PhysicalBone3D:
			physical_bones.append(child)

	print("Found ", physical_bones.size(), " physical bones")

	if physical_bones.size() == 0:
		print("ERROR: No PhysicalBone3D nodes found!")
		print("Please run setup_physical_bones.gd editor script to create physical bones.")
		print("Or use Skeleton3D -> Create Physical Skeleton in the editor")
		ragdoll_enabled = false
		return

	ragdoll_enabled = !ragdoll_enabled

	if ragdoll_enabled:
		print("ENABLING RAGDOLL - Starting physics simulation")
		# Use skeleton's built-in ragdoll methods (no PhysicalBoneSimulator3D needed)
		skeleton.physical_bones_start_simulation()
		# Disable character collision and control
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)

		# Make mesh visible on all layers for ragdoll (so it's visible in FPS mode too)
		if mesh_instance:
			mesh_instance.layers = 1
			print("Mesh made visible for ragdoll")
	else:
		print("DISABLING RAGDOLL - Stopping physics simulation")
		skeleton.physical_bones_stop_simulation()
		collision_layer = 1
		collision_mask = 1
		set_physics_process(true)

		# Restore mesh visibility based on camera mode
		if mesh_instance:
			if camera_mode == 0:  # FPS mode
				mesh_instance.layers = 2  # Hide from FPS camera
			else:  # TPS mode
				mesh_instance.layers = 1  # Visible
			print("Mesh visibility restored based on camera mode")

	print("Ragdoll enabled: ", ragdoll_enabled)

func _detect_nearby_weapon():
	"""Detect weapons within pickup range"""
	nearby_weapon = null

	# Find all weapons in the scene
	var weapons = get_tree().get_nodes_in_group("weapons")
	if weapons.is_empty():
		# If no weapons in group, search for Weapon nodes
		weapons = []
		_find_weapons_recursive(get_tree().root, weapons)

	# Find closest weapon within range
	var closest_distance = pickup_range
	for weapon in weapons:
		if weapon is Weapon and not weapon.is_equipped:
			var distance = global_position.distance_to(weapon.global_position)
			if distance < closest_distance:
				nearby_weapon = weapon
				closest_distance = distance


func _find_weapons_recursive(node: Node, weapons: Array):
	"""Recursively find all Weapon nodes"""
	if node is Weapon:
		weapons.append(node)
	for child in node.get_children():
		_find_weapons_recursive(child, weapons)

func pickup_weapon(weapon: Weapon):
	"""Pick up a weapon"""
	if not weapon or weapon.is_equipped:
		return

	print("Picking up weapon: ", weapon.weapon_name)

	# Equip the weapon
	if weapon.equip(self):
		equipped_weapon = weapon
		nearby_weapon = null

		# Position weapon at right hand
		_update_weapon_position()

func drop_weapon():
	"""Drop the currently equipped weapon"""
	if not equipped_weapon:
		return

	print("Dropping weapon: ", equipped_weapon.weapon_name)

	equipped_weapon.unequip()
	equipped_weapon = null

func _update_weapon_position():
	"""Update weapon position to follow hand bones with IK"""
	if not equipped_weapon or not skeleton or right_hand_bone_id < 0:
		return

	# Get right hand bone global transform
	var right_hand_transform = skeleton.global_transform * skeleton.get_bone_global_pose(right_hand_bone_id)

	# Position weapon at right hand with offset
	var weapon_offset = Vector3(0, 0, 0)  # Weapon grip offset from hand center
	var weapon_rotation_offset = Vector3(deg_to_rad(-90), 0, 0)  # Rotate weapon to grip orientation

	# Apply offsets based on weapon type
	if equipped_weapon.weapon_type == Weapon.WeaponType.PISTOL:
		weapon_offset = Vector3(0, -0.05, 0.1)
	elif equipped_weapon.weapon_type == Weapon.WeaponType.RIFLE:
		weapon_offset = Vector3(0, -0.05, 0.15)

	# Set weapon position and rotation
	equipped_weapon.global_position = right_hand_transform.origin + right_hand_transform.basis * weapon_offset

	# Align weapon with hand rotation plus offset
	var weapon_basis = right_hand_transform.basis
	weapon_basis = weapon_basis.rotated(weapon_basis.x, weapon_rotation_offset.x)
	weapon_basis = weapon_basis.rotated(weapon_basis.y, weapon_rotation_offset.y)
	weapon_basis = weapon_basis.rotated(weapon_basis.z, weapon_rotation_offset.z)
	equipped_weapon.global_transform.basis = weapon_basis

	# For two-handed weapons, position left hand at secondary grip
	if equipped_weapon.is_two_handed and left_hand_bone_id >= 0 and equipped_weapon.secondary_grip:
		var secondary_grip_pos = equipped_weapon.secondary_grip.global_position

		# Get left hand current pose
		var left_hand_pose = skeleton.get_bone_pose(left_hand_bone_id)

		# Calculate target position for left hand (simplified IK - just point towards grip)
		var left_hand_global = skeleton.global_transform * skeleton.get_bone_global_pose(left_hand_bone_id)
		var direction_to_grip = (secondary_grip_pos - left_hand_global.origin).normalized()

		# Rotate left hand to point at grip (basic aim IK)
		var target_basis = left_hand_pose.basis.looking_at(direction_to_grip, Vector3.UP)
		left_hand_pose.basis = left_hand_pose.basis.slerp(target_basis, 0.5)
		skeleton.set_bone_pose(left_hand_bone_id, left_hand_pose)

func _process(_delta):
	# Update weapon position to follow hand
	if equipped_weapon:
		_update_weapon_position()

	# Update IK targets if enabled
	if ik_enabled:
		if left_hand_ik and left_hand_ik.is_running():
			left_hand_ik.start()
		if right_hand_ik and right_hand_ik.is_running():
			right_hand_ik.start()
		if left_foot_ik and left_foot_ik.is_running():
			left_foot_ik.start()
		if right_foot_ik and right_foot_ik.is_running():
			right_foot_ik.start()
