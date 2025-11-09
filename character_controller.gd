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
var last_nearby_weapon: Weapon = null  # Track changes for debug logging

# Weapon states
enum WeaponState { SHEATHED, READY, AIMING }
var weapon_state: WeaponState = WeaponState.READY
var is_weapon_sheathed: bool = false  # Toggle for sheathed state

# Weapon positioning - skeleton-relative offsets
@export var aim_weapon_offset: Vector3 = Vector3(0.25, 0.2, -0.5)  # Offset when aiming down sights (high in front of face)
@export var ready_weapon_offset: Vector3 = Vector3(0.35, -0.15, -0.4)  # Offset when ready/moving (more up and forward)
@export var sheathed_weapon_offset: Vector3 = Vector3(0.5, -0.6, 0.2)  # Offset when sheathed at side
@export var weapon_transition_speed: float = 8.0  # Speed of state transitions

# Weapon sway
@export var sway_amount: float = 0.05  # Amount of sway
@export var sway_speed: float = 5.0  # Speed of sway oscillation
@export var movement_sway_multiplier: float = 2.0  # Extra sway when moving
var sway_time: float = 0.0  # Time accumulator for sway
var current_sway: Vector3 = Vector3.ZERO  # Current sway offset

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
var chest_bone_id: int = -1  # For weapon positioning anchor
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

	if skeleton:
		head_bone_id = skeleton.find_bone(head_bone_name)
		neck_bone_id = skeleton.find_bone(neck_bone_name)
		right_hand_bone_id = skeleton.find_bone(right_hand_bone_name)
		left_hand_bone_id = skeleton.find_bone(left_hand_bone_name)

		# Find chest bone for weapon positioning anchor
		chest_bone_id = skeleton.find_bone("characters3d.com___Upper_Chest")
		if chest_bone_id < 0:
			chest_bone_id = skeleton.find_bone("characters3d.com___Chest")

		if head_bone_id >= 0:
			original_head_pose = skeleton.get_bone_pose(head_bone_id)
		if neck_bone_id >= 0:
			original_neck_pose = skeleton.get_bone_pose(neck_bone_id)

		# Find mesh instance for visibility control
		mesh_instance = find_mesh_instance(skeleton)

	# Find cameras if not set (they should be children of this node)
	if not fps_camera:
		fps_camera = get_node_or_null("FPSCamera")
	if not tps_camera:
		tps_camera = get_node_or_null("TPSCamera")

	# Create IK system at runtime
	if skeleton:
		_create_ik_system()

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

func _create_ik_system():
	"""Create SkeletonIK3D nodes at runtime and link them to targets"""
	print("\n=== Creating IK System ===")

	# Find IK target nodes
	var ik_targets_node = get_node_or_null("IKTargets")
	if not ik_targets_node:
		print("ERROR: IKTargets node not found!")
		return

	var left_hand_target = ik_targets_node.get_node_or_null("LeftHandTarget")
	var right_hand_target = ik_targets_node.get_node_or_null("RightHandTarget")
	var left_foot_target = ik_targets_node.get_node_or_null("LeftFootTarget")
	var right_foot_target = ik_targets_node.get_node_or_null("RightFootTarget")

	print("Found targets - LH: ", left_hand_target, ", RH: ", right_hand_target,
	      ", LF: ", left_foot_target, ", RF: ", right_foot_target)

	# Create LeftHandIK
	if left_hand_target:
		left_hand_ik = SkeletonIK3D.new()
		left_hand_ik.name = "LeftHandIK"
		left_hand_ik.root_bone = "characters3d.com___L_Shoulder"
		left_hand_ik.tip_bone = "characters3d.com___L_Hand"
		left_hand_ik.interpolation = 0.5
		left_hand_ik.max_iterations = 10
		skeleton.add_child(left_hand_ik)
		left_hand_ik.set_target_node(left_hand_target.get_path())
		print("Created LeftHandIK")

	# Create RightHandIK
	if right_hand_target:
		right_hand_ik = SkeletonIK3D.new()
		right_hand_ik.name = "RightHandIK"
		right_hand_ik.root_bone = "characters3d.com___R_Shoulder"
		right_hand_ik.tip_bone = "characters3d.com___R_Hand"
		right_hand_ik.interpolation = 0.5
		right_hand_ik.max_iterations = 10
		skeleton.add_child(right_hand_ik)
		right_hand_ik.set_target_node(right_hand_target.get_path())
		print("Created RightHandIK")

	# Create LeftFootIK
	if left_foot_target:
		left_foot_ik = SkeletonIK3D.new()
		left_foot_ik.name = "LeftFootIK"
		left_foot_ik.root_bone = "characters3d.com___L_Upper_Leg"
		left_foot_ik.tip_bone = "characters3d.com___L_Foot"
		left_foot_ik.interpolation = 0.5
		left_foot_ik.max_iterations = 10
		skeleton.add_child(left_foot_ik)
		left_foot_ik.set_target_node(left_foot_target.get_path())
		print("Created LeftFootIK")

	# Create RightFootIK
	if right_foot_target:
		right_foot_ik = SkeletonIK3D.new()
		right_foot_ik.name = "RightFootIK"
		right_foot_ik.root_bone = "characters3d.com___R_Upper_Leg"
		right_foot_ik.tip_bone = "characters3d.com___R_Foot"
		right_foot_ik.interpolation = 0.5
		right_foot_ik.max_iterations = 10
		skeleton.add_child(right_foot_ik)
		right_foot_ik.set_target_node(right_foot_target.get_path())
		print("Created RightFootIK")

	print("=== IK System Created ===\n")

func _create_ragdoll_bones():
	print("\n=== Creating Ragdoll Bones at Runtime ===")

	# RAGDOLL BEST PRACTICES IMPLEMENTED:
	# 1. Heavy torso/head mass (10kg/5kg/3kg) acts as anchor to prevent spinning
	# 2. Locked torso joints (0° swing/twist + axis locks) for rigid upper body
	# 3. HINGE joints for single-axis movement (knees, elbows, ankles, wrists)
	# 4. Tight collision shapes (small radius) to prevent excess leverage
	# 5. Maximum constraint enforcement (ERP=1.0, CFM=0.0) for locked bones
	# 6. High angular damping (5.0) on core bones to prevent rotation
	# 7. Self-collision disabled between all physical bones
	# 8. Proper collision layers: ragdoll on layer 2, world on layer 1

	# Delete any existing physical bones to ensure we use latest settings
	var existing_bones = []
	for child in skeleton.get_children():
		if child is PhysicalBone3D:
			existing_bones.append(child)

	if existing_bones.size() > 0:
		print("Deleting ", existing_bones.size(), " existing physical bones to recreate with new settings...")
		for bone in existing_bones:
			skeleton.remove_child(bone)
			bone.queue_free()

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

		# Larger shapes for major bones - keep tight to prevent excess movement
		if bone_suffix in ["Hips", "Spine", "Chest", "Upper_Chest"]:
			radius = 0.08  # Much smaller radius for tighter control
			height = 0.15  # Shorter segments for less leverage
		elif "Shoulder" in bone_suffix:
			radius = 0.05  # Very small for shoulders - they're locked anyway
			height = 0.08
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
		# Use HINGE for knees/elbows/ankles/wrists - single axis rotation only
		# Don't use NONE - it disconnects bones completely!
		var use_hinge = bone_suffix in ["Lower_Leg", "L_Lower_Leg", "R_Lower_Leg", "Lower_Arm", "L_Lower_Arm", "R_Lower_Arm", "Foot", "L_Foot", "R_Foot", "Hand", "L_Hand", "R_Hand"]

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

		# Ultra-specific constraints - COMPLETELY RIGID UPPER BODY!
		if bone_suffix in ["Hips"]:
			# Hips/pelvis - ZERO MOVEMENT (completely locked)
			swing_limit = 0.0
			twist_limit = 0.0
			damping = 1.0
			bias = 1.0
		elif bone_suffix in ["Spine", "Chest", "Upper_Chest"]:
			# Spine/torso - ZERO MOVEMENT (completely locked)
			swing_limit = 0.0
			twist_limit = 0.0
			damping = 1.0
			bias = 1.0
		elif bone_suffix in ["Neck"]:
			# Neck - ZERO MOVEMENT (completely locked)
			swing_limit = 0.0
			twist_limit = 0.0
			damping = 1.0
			bias = 1.0
		elif bone_suffix in ["Head"]:
			# Head - ZERO MOVEMENT (completely locked)
			swing_limit = 0.0
			twist_limit = 0.0
			damping = 1.0
			bias = 1.0
		elif "Shoulder" in bone_suffix:
			# Shoulders - ZERO MOVEMENT (completely locked)
			swing_limit = 0.0
			twist_limit = 0.0
			damping = 1.0
			bias = 1.0
		elif bone_suffix in ["Upper_Leg", "L_Upper_Leg", "R_Upper_Leg"]:
			# Upper legs - EXTREMELY restricted hip to prevent body spinning
			swing_limit = deg_to_rad(0.5)  # Almost locked
			twist_limit = deg_to_rad(0)    # No twist at all
			damping = 1.0
			bias = 1.0
		elif bone_suffix in ["Lower_Leg", "L_Lower_Leg", "R_Lower_Leg"]:
			# HINGE: Lower legs (knees) - one direction only
			# For hinge joints, only swing matters
			swing_limit = deg_to_rad(120)  # Can bend backward
			twist_limit = deg_to_rad(0)    # No twist on hinge
			damping = 0.95
			bias = 0.95
		elif bone_suffix in ["Foot", "L_Foot", "R_Foot"]:
			# HINGE: Feet/ankles - VERY tight to prevent body rotation
			swing_limit = deg_to_rad(5)  # Minimal flex only
			twist_limit = deg_to_rad(0)  # No twist on hinge
			damping = 1.0
			bias = 1.0
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
			# HINGE: Hands/wrists - only bend up/down realistically
			swing_limit = deg_to_rad(70)  # Can flex at wrist
			twist_limit = deg_to_rad(0)   # No twist on hinge
			damping = 0.95
			bias = 0.95
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
		# For torso, upper body, and leg bones, apply maximum constraint enforcement
		if bone_suffix in ["Hips", "Spine", "Chest", "Upper_Chest", "Neck", "Head", "Shoulder", "L_Shoulder", "R_Shoulder", "Upper_Arm", "L_Upper_Arm", "R_Upper_Arm", "Upper_Leg", "L_Upper_Leg", "R_Upper_Leg", "Foot", "L_Foot", "R_Foot"]:
			# Maximum constraint enforcement - absolutely no give
			physical_bone.set("joint_constraints/bias", 1.0)
			physical_bone.set("joint_constraints/damping", 1.0)
			physical_bone.set("joint_constraints/softness", 0.0)
			physical_bone.set("joint_constraints/relaxation", 1.0)
			physical_bone.set("joint_constraints/erp", 1.0)  # Error reduction parameter - maximum
			physical_bone.set("joint_constraints/cfm", 0.0)  # Constraint force mixing - zero (rigid)
		else:
			# Standard stiffness for other bones
			physical_bone.set("joint_constraints/bias", bias)
			physical_bone.set("joint_constraints/damping", damping)
			physical_bone.set("joint_constraints/softness", 0.0)
			physical_bone.set("joint_constraints/relaxation", 1.0)

		# Physics properties - add damping to resist all motion
		# Make torso/head MUCH heavier to act as anchor and resist spinning
		if bone_suffix in ["Hips", "Spine", "Chest", "Upper_Chest"]:
			physical_bone.mass = 10.0  # Very heavy torso to prevent spinning
		elif bone_suffix in ["Head"]:
			physical_bone.mass = 5.0  # Heavy head to prevent spinning
		elif bone_suffix in ["Neck"]:
			physical_bone.mass = 3.0  # Heavy neck to prevent spinning
		else:
			physical_bone.mass = 1.0  # Normal mass for limbs

		physical_bone.friction = 1.0  # Maximum friction
		physical_bone.bounce = 0.0

		# Apply extreme damping for upper body and legs to prevent any rotation
		if bone_suffix in ["Hips", "Spine", "Chest", "Upper_Chest", "Neck", "Head", "Shoulder", "L_Shoulder", "R_Shoulder", "Upper_Arm", "L_Upper_Arm", "R_Upper_Arm", "Upper_Leg", "L_Upper_Leg", "R_Upper_Leg", "Foot", "L_Foot", "R_Foot"]:
			physical_bone.linear_damp = 2.0  # Extreme resistance to movement
			physical_bone.angular_damp = 5.0  # Extreme resistance to rotation (prevents spinning)
		else:
			physical_bone.linear_damp = 0.8  # Strong resistance to linear movement
			physical_bone.angular_damp = 0.99  # Extremely heavy resistance to rotation

		# Lock rotation axes for torso/head/neck to completely prevent spinning
		if bone_suffix in ["Hips", "Spine", "Chest", "Upper_Chest", "Neck", "Head"]:
			physical_bone.axis_lock_angular_x = true
			physical_bone.axis_lock_angular_y = true
			physical_bone.axis_lock_angular_z = true

		# CRITICAL: Set collision layers and masks for proper physics
		physical_bone.collision_layer = 2  # Layer 2 for ragdoll parts
		physical_bone.collision_mask = 1   # Collide with layer 1 (world/ground)

		# Add to skeleton
		skeleton.add_child(physical_bone)
		physical_bone.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		bones_created += 1
		# Removed verbose logging for each bone

	# Set up collision exceptions between all physical bones (prevent self-collision)
	var all_physical_bones = []
	for child in skeleton.get_children():
		if child is PhysicalBone3D:
			all_physical_bones.append(child)

	for i in range(all_physical_bones.size()):
		for j in range(i + 1, all_physical_bones.size()):
			all_physical_bones[i].add_collision_exception_with(all_physical_bones[j])

	print("Created ", bones_created, " ragdoll bones")

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

	# Right click for weapon aim
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and equipped_weapon and not is_weapon_sheathed:
				weapon_state = WeaponState.AIMING
			else:
				# Return to ready or sheathed based on sheathed flag
				weapon_state = WeaponState.SHEATHED if is_weapon_sheathed else WeaponState.READY

	# H key to toggle weapon sheathed/ready
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		if equipped_weapon:
			is_weapon_sheathed = !is_weapon_sheathed
			weapon_state = WeaponState.SHEATHED if is_weapon_sheathed else WeaponState.READY
			print("Weapon ", "sheathed" if is_weapon_sheathed else "ready")

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

		# Attach weapon to physical hand bone if equipped
		if equipped_weapon:
			_attach_weapon_to_ragdoll_hand()

		# Attach FPS camera to physical head bone
		_attach_camera_to_ragdoll_head()
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

		# Restore weapon to normal attachment if equipped
		if equipped_weapon:
			_detach_weapon_from_ragdoll_hand()

		# Restore FPS camera to character
		_detach_camera_from_ragdoll_head()

	print("Ragdoll enabled: ", ragdoll_enabled)

func _attach_weapon_to_ragdoll_hand():
	"""Attach weapon to physical hand bone during ragdoll"""
	if not equipped_weapon or not skeleton:
		return

	# Find the physical bone for the right hand
	var hand_bone_name = skeleton.get_bone_name(right_hand_bone_id)
	var physical_hand_bone = null

	for child in skeleton.get_children():
		if child is PhysicalBone3D and child.bone_name == hand_bone_name:
			physical_hand_bone = child
			break

	if not physical_hand_bone:
		print("WARNING: Could not find physical bone for right hand")
		return

	print("Attaching weapon to ragdoll hand: ", physical_hand_bone.name)

	# Remove weapon from character
	if equipped_weapon.get_parent():
		equipped_weapon.get_parent().remove_child(equipped_weapon)

	# Add weapon as child of physical hand bone
	physical_hand_bone.add_child(equipped_weapon)

	# Position weapon relative to hand bone (using grip alignment)
	if equipped_weapon.main_grip:
		var grip_local_pos = equipped_weapon.main_grip.position
		equipped_weapon.position = -grip_local_pos
		equipped_weapon.rotation = Vector3.ZERO
	else:
		equipped_weapon.position = Vector3(0, -0.05, 0.1)
		equipped_weapon.rotation = Vector3.ZERO

	# Enable physics on weapon but don't let it fall
	equipped_weapon.freeze = false
	equipped_weapon.gravity_scale = 0.0  # No gravity while held
	equipped_weapon.collision_layer = 4  # Weapon layer
	equipped_weapon.collision_mask = 1 | 2  # Collide with world and ragdoll

	# Connect to collision signal to release on impact
	if not equipped_weapon.body_entered.is_connected(_on_ragdoll_weapon_collision):
		equipped_weapon.body_entered.connect(_on_ragdoll_weapon_collision)

	print("Weapon attached to ragdoll hand")

func _detach_weapon_from_ragdoll_hand():
	"""Restore weapon to normal attachment after ragdoll"""
	if not equipped_weapon:
		return

	print("Detaching weapon from ragdoll hand")

	# Disconnect collision signal
	if equipped_weapon.body_entered.is_connected(_on_ragdoll_weapon_collision):
		equipped_weapon.body_entered.disconnect(_on_ragdoll_weapon_collision)

	# Remove from physical bone
	if equipped_weapon.get_parent():
		equipped_weapon.get_parent().remove_child(equipped_weapon)

	# Re-add to character
	add_child(equipped_weapon)

	# Restore normal weapon state
	equipped_weapon.freeze = true
	equipped_weapon.gravity_scale = 0.0
	equipped_weapon.collision_layer = 0
	equipped_weapon.collision_mask = 0

	print("Weapon restored to normal attachment")

func _on_ragdoll_weapon_collision(body: Node):
	"""Release weapon when it collides with something during ragdoll"""
	if not ragdoll_enabled or not equipped_weapon:
		return

	# Ignore collisions with own ragdoll parts
	if body is PhysicalBone3D and body.get_parent() == skeleton:
		return

	print("Weapon collision during ragdoll with: ", body.name, " - Releasing weapon")

	# Disconnect signal
	if equipped_weapon.body_entered.is_connected(_on_ragdoll_weapon_collision):
		equipped_weapon.body_entered.disconnect(_on_ragdoll_weapon_collision)

	# Drop the weapon
	drop_weapon()

func _attach_camera_to_ragdoll_head():
	"""Attach FPS camera to physical head bone during ragdoll"""
	if not fps_camera or not skeleton or head_bone_id < 0:
		return

	# Find the physical bone for the head
	var bone_name = skeleton.get_bone_name(head_bone_id)
	var physical_head_bone = null

	for child in skeleton.get_children():
		if child is PhysicalBone3D and child.bone_name == bone_name:
			physical_head_bone = child
			break

	if not physical_head_bone:
		print("WARNING: Could not find physical bone for head")
		return

	print("Attaching FPS camera to ragdoll head: ", physical_head_bone.name)

	# Store camera's current rotation to preserve it
	var camera_global_basis = fps_camera.global_transform.basis

	# Remove camera from character
	if fps_camera.get_parent():
		fps_camera.get_parent().remove_child(fps_camera)

	# Add camera as child of physical head bone
	physical_head_bone.add_child(fps_camera)

	# Set camera position at eye level but preserve current rotation
	fps_camera.position = Vector3(0, 0.1, 0.15)  # Eye offset
	# Preserve the camera's rotation by converting global basis to local relative to head bone
	fps_camera.global_transform.basis = camera_global_basis

	print("FPS camera attached to ragdoll head")

func _detach_camera_from_ragdoll_head():
	"""Restore FPS camera to character after ragdoll"""
	if not fps_camera:
		return

	print("Detaching FPS camera from ragdoll head")

	# Remove from physical bone
	if fps_camera.get_parent():
		fps_camera.get_parent().remove_child(fps_camera)

	# Re-add to character
	add_child(fps_camera)

	# Restore normal camera position
	fps_camera.position = Vector3(0, 1.6, 0)
	fps_camera.rotation = Vector3.ZERO

	print("FPS camera restored to character")

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

	# Only log when nearby weapon changes
	if nearby_weapon != last_nearby_weapon:
		# Removed spam - users can see weapon highlight instead
		last_nearby_weapon = nearby_weapon


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

	# Restore IK targets to default positions
	var ik_targets_node = get_node_or_null("IKTargets")
	if ik_targets_node:
		# Reset left hand to default
		var left_hand_target = ik_targets_node.get_node_or_null("LeftHandTarget")
		if left_hand_target:
			left_hand_target.global_position = global_position + Vector3(-0.5, 1.2, 0.3)

		# Reset right hand to default
		var right_hand_target = ik_targets_node.get_node_or_null("RightHandTarget")
		if right_hand_target:
			right_hand_target.global_position = global_position + Vector3(0.5, 1.2, 0.3)

	equipped_weapon.unequip()
	equipped_weapon = null

func _calculate_weapon_sway(delta: float, is_moving: bool) -> Vector3:
	"""Calculate procedural weapon sway based on movement and time"""
	sway_time += delta * sway_speed

	# Base sway using sine waves for smooth oscillation
	var sway_x = sin(sway_time) * sway_amount
	var sway_y = cos(sway_time * 0.8) * sway_amount * 0.5

	# Extra sway when moving
	if is_moving:
		sway_x *= movement_sway_multiplier
		sway_y *= movement_sway_multiplier
		# Add bob effect when moving
		sway_y += sin(sway_time * 2.0) * sway_amount * movement_sway_multiplier * 0.3

	# Reduce sway when aiming
	if weapon_state == WeaponState.AIMING:
		sway_x *= 0.3
		sway_y *= 0.3

	return Vector3(sway_x, sway_y, 0)

func _update_weapon_position():
	"""Update weapon position and rotation to follow hand bones (skeleton-based, not camera-based)"""
	if not equipped_weapon or not skeleton or right_hand_bone_id < 0:
		return

	var ik_targets_node = get_node_or_null("IKTargets")
	if not ik_targets_node:
		return

	# Get camera rotation for IK target positioning (skeleton-based with camera aim direction)
	var active_camera = fps_camera if camera_mode == 0 else tps_camera
	if not active_camera:
		return

	var camera_transform = active_camera.global_transform

	# Check if character is moving for sway calculation
	var is_moving = velocity.length() > 0.1
	current_sway = _calculate_weapon_sway(get_process_delta_time(), is_moving)

	# Determine IK target offset based on weapon state
	var target_offset = ready_weapon_offset
	match weapon_state:
		WeaponState.SHEATHED:
			target_offset = sheathed_weapon_offset
			current_sway *= 0.2  # Reduce sway when sheathed
		WeaponState.READY:
			target_offset = ready_weapon_offset
		WeaponState.AIMING:
			target_offset = aim_weapon_offset

	# STEP 1: Position right hand IK target relative to BODY (chest bone), not camera
	var right_hand_target = ik_targets_node.get_node_or_null("RightHandTarget")
	if right_hand_target:
		var base_offset = target_offset + current_sway

		# Use chest bone as anchor point for body-relative positioning
		var anchor_transform: Transform3D
		if chest_bone_id >= 0:
			anchor_transform = skeleton.global_transform * skeleton.get_bone_global_pose(chest_bone_id)
		else:
			# Fallback to character position if no chest bone
			anchor_transform = global_transform

		# Position hand relative to body/chest, but rotate offset by camera yaw for aiming
		# This keeps the weapon near the body but lets it follow camera look direction
		var body_basis = Basis(Vector3.UP, camera_rotation.y)  # Only yaw, not pitch
		var target_pos = anchor_transform.origin + body_basis * base_offset
		right_hand_target.global_position = target_pos

	# STEP 2: Weapon follows right hand bone (after IK has been applied)
	var right_hand_transform = skeleton.global_transform * skeleton.get_bone_global_pose(right_hand_bone_id)

	# Weapon rotation follows RIGHT HAND bone, not camera (fully skeleton-based)
	equipped_weapon.global_transform.basis = right_hand_transform.basis

	# Position weapon so its grip aligns with the right hand bone
	if equipped_weapon.main_grip:
		var grip_local_pos = equipped_weapon.main_grip.position
		var grip_world_offset = equipped_weapon.global_transform.basis * grip_local_pos
		equipped_weapon.global_position = right_hand_transform.origin - grip_world_offset
	else:
		# Fallback: if no grip point defined, use simple offset
		equipped_weapon.global_position = right_hand_transform.origin

	# STEP 3: Update left hand IK target ONLY for two-handed weapons (rifles)
	var left_hand_target = ik_targets_node.get_node_or_null("LeftHandTarget")
	if left_hand_target:
		if equipped_weapon.is_two_handed and equipped_weapon.secondary_grip:
			# Two-handed weapon (rifle): left hand to foregrip
			left_hand_target.global_position = equipped_weapon.secondary_grip.global_position
		else:
			# Pistol: disable left hand IK by moving target to default position
			# This allows left hand to use idle animation instead
			var l_hand_id = skeleton.find_bone("characters3d.com___L_Hand")
			if l_hand_id >= 0:
				var left_hand_rest = skeleton.global_transform * skeleton.get_bone_rest(l_hand_id).origin
				left_hand_target.global_position = left_hand_rest

func _process(_delta):
	# Update IK - start() applies the IK each frame
	# IMPORTANT: IK must be applied BEFORE weapon position update so hand bone is in correct position
	if ik_enabled:
		if left_hand_ik:
			left_hand_ik.start()
		if right_hand_ik:
			right_hand_ik.start()
		if left_foot_ik:
			left_foot_ik.start()
		if right_foot_ik:
			right_foot_ik.start()
	else:
		# Stop IK when disabled
		if left_hand_ik:
			left_hand_ik.stop()
		if right_hand_ik:
			right_hand_ik.stop()
		if left_foot_ik:
			left_foot_ik.stop()
		if right_foot_ik:
			right_foot_ik.stop()

	# Update weapon position AFTER IK to follow hand bone
	if equipped_weapon:
		_update_weapon_position()
