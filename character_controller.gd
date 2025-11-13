extends CharacterBody3D
class_name CharacterController

# Movement
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var prone_speed: float = 1.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

# Stance system
enum Stance { STANDING, CROUCHING, PRONE }
var current_stance: Stance = Stance.STANDING
var target_stance: Stance = Stance.STANDING
@export var stance_transition_speed: float = 8.0

# Capsule dimensions for different stances
@export var standing_height: float = 1.8
@export var crouching_height: float = 1.0
@export var prone_height: float = 0.5
var capsule_shape: CapsuleShape3D
var collision_shape: CollisionShape3D

# Jump state
var is_jumping: bool = false
var jump_time: float = 0.0
@export var max_jump_time: float = 0.3  # Time to blend IK during jump

# Walk/run animation state
var walk_cycle_time: float = 0.0  # Time accumulator for walk cycle
@export var walk_cycle_speed: float = 4.0  # Speed of walk cycle (steps per second)
@export var run_cycle_speed: float = 6.0  # Speed of run cycle (faster)
@export var walk_foot_lift: float = 0.15  # How high feet lift when walking
@export var run_foot_lift: float = 0.25  # How high feet lift when running
var is_moving: bool = false
var is_running: bool = false

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
var is_aim_toggled: bool = false  # Toggle aim mode (Ctrl+Right-Click)

# Weapon positioning - skeleton-relative offsets
@export var aim_weapon_offset: Vector3 = Vector3(0.15, 0.25, -1.5)  # Offset when aiming down sights (lowered for better hand position)
@export var ready_weapon_offset: Vector3 = Vector3(0.25, 0.0, -1.4)  # Offset when ready/moving (lowered to chest level)
@export var sheathed_weapon_offset: Vector3 = Vector3(0.5, -0.6, 0.2)  # Offset when sheathed at side
@export var weapon_transition_speed: float = 8.0  # Speed of state transitions

# Weapon sway
@export var sway_amount: float = 0.05  # Amount of sway
@export var sway_speed: float = 5.0  # Speed of sway oscillation
@export var movement_sway_multiplier: float = 2.0  # Extra sway when moving
var sway_time: float = 0.0  # Time accumulator for sway
var current_sway: Vector3 = Vector3.ZERO  # Current sway offset

# Weapon recoil
@export var recoil_rotation: Vector3 = Vector3(5.0, 0.0, 0.0)  # Rotation recoil in degrees (pitch, yaw, roll)
@export var recoil_position: Vector3 = Vector3(0.0, 0.0, 0.05)  # Position recoil (backward push)
@export var recoil_recovery_speed: float = 10.0  # How fast recoil returns to normal
var current_recoil_rotation: Vector3 = Vector3.ZERO  # Current recoil rotation offset
var current_recoil_position: Vector3 = Vector3.ZERO  # Current recoil position offset

# Hand IK recoil
@export var hand_recoil_offset: Vector3 = Vector3(0.0, -0.05, 0.08)  # Hand kicks back and down when shooting
var current_hand_recoil: Vector3 = Vector3.ZERO  # Current hand recoil offset

# Muzzle flash
var muzzle_flash_light: OmniLight3D = null
var muzzle_flash_timer: float = 0.0
const MUZZLE_FLASH_DURATION: float = 0.05  # 50ms flash

# Gunshot audio
var gunshot_audio: AudioStreamPlayer3D = null

# Crosshair UI
var crosshair_ui: Control = null
var crosshair_lines: Array[ColorRect] = []  # 4 lines for COD-style cross
@export var crosshair_gap: float = 8.0  # Gap from center
@export var crosshair_length: float = 12.0  # Length of each line
@export var crosshair_thickness: float = 2.0  # Thickness of lines
@export var crosshair_color: Color = Color(1.0, 1.0, 1.0, 0.8)  # White with slight transparency

# Dynamic crosshair spread
var current_spread: float = 0.0  # Current spread amount
var base_spread: float = 0.0  # Base spread (min)
@export var max_spread: float = 40.0  # Maximum spread expansion
@export var spread_increase_per_shot: float = 8.0  # How much spread increases per shot
@export var spread_recovery_rate: float = 30.0  # How fast spread recovers per second

# Weapon firing
var is_firing: bool = false  # Holding fire button
var last_shot_time: float = 0.0

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
var spine_bone_id: int = -1  # For spine aiming
var upper_chest_bone_id: int = -1  # For spine aiming
var right_hand_bone_id: int = -1
var left_hand_bone_id: int = -1
var right_hand_attachment: BoneAttachment3D = null  # For attaching weapons to hand
var original_head_pose: Transform3D
var original_neck_pose: Transform3D
var mesh_instance: MeshInstance3D

# Spine IK aiming parameters
@export_group("Weapon Aiming")
@export var aim_ik_enabled: bool = true
@export var aim_ik_iterations: int = 3
@export_range(0.0, 1.0) var aim_ik_weight: float = 1.0
@export var aim_angle_limit: float = 90.0  # Maximum aim angle in degrees
@export var max_spine_pitch_up: float = 45.0  # Maximum spine pitch up in degrees
@export var max_spine_pitch_down: float = 45.0  # Maximum spine pitch down in degrees
@export var aim_distance_limit: float = 1.5  # Minimum aim distance
@export var aim_target_offset: Vector3 = Vector3(0.0, 1.36, 0.0)  # Offset to aim at (e.g., chest height)

# Per-bone weights for spine aiming
var spine_bone_weights: Dictionary = {
	"Spine": 1.0,  # Only rotate Spine bone
	"Chest": 0.0,  # Don't rotate - Chest is parent of upper_chest/neck/head hierarchy
	"Upper_Chest": 0.0  # Not used - upper_chest is parent of neck/head, rotating it displaces head
}

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

		# Find spine bones for aiming IK
		spine_bone_id = skeleton.find_bone("characters3d.com___Spine")
		upper_chest_bone_id = skeleton.find_bone("characters3d.com___Upper_Chest")

		if head_bone_id >= 0:
			original_head_pose = skeleton.get_bone_pose(head_bone_id)
		if neck_bone_id >= 0:
			original_neck_pose = skeleton.get_bone_pose(neck_bone_id)

		# Find mesh instance for visibility control
		mesh_instance = find_mesh_instance(skeleton)

		# Create BoneAttachment3D for right hand (for weapon attachment)
		if right_hand_bone_id >= 0:
			right_hand_attachment = BoneAttachment3D.new()
			right_hand_attachment.name = "RightHandAttachment"
			# Add to skeleton first, then set bone properties
			skeleton.add_child(right_hand_attachment)
			right_hand_attachment.owner = self
			# Set bone name after adding to tree - this is important!
			right_hand_attachment.bone_name = right_hand_bone_name
			right_hand_attachment.bone_idx = right_hand_bone_id
			# Ensure it follows the bone, not override it
			right_hand_attachment.override_pose = false
			print("Created BoneAttachment3D for right hand: ", right_hand_bone_name, " (bone_idx: ", right_hand_bone_id, ")")
			print("  Skeleton: ", skeleton.name, ", Bone global pose: ", skeleton.get_bone_global_pose(right_hand_bone_id).origin)

	# Find collision shape for stance adjustments
	for child in get_children():
		if child is CollisionShape3D:
			collision_shape = child
			if collision_shape.shape is CapsuleShape3D:
				capsule_shape = collision_shape.shape
				standing_height = capsule_shape.height
				print("Found capsule shape, standing height: ", standing_height)
			break

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

	# Create crosshair UI
	_create_crosshair_ui()

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

func _create_crosshair_ui():
	"""Create COD-style crosshair UI with 4 expanding lines"""
	# Create a CanvasLayer to hold the UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "CrosshairLayer"
	add_child(canvas_layer)

	# Create a Control node as container
	crosshair_ui = Control.new()
	crosshair_ui.name = "CrosshairUI"
	crosshair_ui.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill entire screen
	crosshair_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't intercept mouse events
	canvas_layer.add_child(crosshair_ui)

	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0

	# Create 4 lines for COD-style crosshair (top, bottom, left, right)
	# Top line
	var top_line = ColorRect.new()
	top_line.color = crosshair_color
	top_line.size = Vector2(crosshair_thickness, crosshair_length)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_ui.add_child(top_line)
	crosshair_lines.append(top_line)

	# Bottom line
	var bottom_line = ColorRect.new()
	bottom_line.color = crosshair_color
	bottom_line.size = Vector2(crosshair_thickness, crosshair_length)
	bottom_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_ui.add_child(bottom_line)
	crosshair_lines.append(bottom_line)

	# Left line
	var left_line = ColorRect.new()
	left_line.color = crosshair_color
	left_line.size = Vector2(crosshair_length, crosshair_thickness)
	left_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_ui.add_child(left_line)
	crosshair_lines.append(left_line)

	# Right line
	var right_line = ColorRect.new()
	right_line.color = crosshair_color
	right_line.size = Vector2(crosshair_length, crosshair_thickness)
	right_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_ui.add_child(right_line)
	crosshair_lines.append(right_line)

	# Position lines at center with gap
	_update_crosshair_positions(center, base_spread)

	print("COD-style crosshair UI created")

func _update_crosshair_positions(center: Vector2, spread: float):
	"""Update crosshair line positions based on spread"""
	if crosshair_lines.size() < 4:
		return

	var gap_with_spread = crosshair_gap + spread

	# Top line (index 0)
	crosshair_lines[0].position = Vector2(center.x - crosshair_thickness / 2.0, center.y - gap_with_spread - crosshair_length)

	# Bottom line (index 1)
	crosshair_lines[1].position = Vector2(center.x - crosshair_thickness / 2.0, center.y + gap_with_spread)

	# Left line (index 2)
	crosshair_lines[2].position = Vector2(center.x - gap_with_spread - crosshair_length, center.y - crosshair_thickness / 2.0)

	# Right line (index 3)
	crosshair_lines[3].position = Vector2(center.x + gap_with_spread, center.y - crosshair_thickness / 2.0)

func _update_crosshair(delta: float):
	"""Update crosshair spread and visibility"""
	if crosshair_lines.size() == 0:
		return

	# Hide crosshair when no weapon equipped
	if not equipped_weapon:
		for line in crosshair_lines:
			line.visible = false
		return

	# Show crosshair when weapon is equipped
	for line in crosshair_lines:
		line.visible = true

	# Recover spread over time
	if current_spread > base_spread:
		current_spread -= spread_recovery_rate * delta
		current_spread = max(current_spread, base_spread)

	# Update crosshair positions with current spread
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0
	_update_crosshair_positions(center, current_spread)

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

	# Create elbow pole targets for better IK solving
	var left_elbow_pole = Node3D.new()
	left_elbow_pole.name = "LeftElbowPole"
	ik_targets_node.add_child(left_elbow_pole)
	left_elbow_pole.position = Vector3(-0.3, 1.0, 0.5)  # To the left, forward of body

	var right_elbow_pole = Node3D.new()
	right_elbow_pole.name = "RightElbowPole"
	ik_targets_node.add_child(right_elbow_pole)
	right_elbow_pole.position = Vector3(0.3, 1.0, 0.5)  # To the right, forward of body

	# Create wrist pole targets for refined hand/wrist positioning
	var left_wrist_pole = Node3D.new()
	left_wrist_pole.name = "LeftWristPole"
	ik_targets_node.add_child(left_wrist_pole)
	left_wrist_pole.position = Vector3(-0.2, 1.0, 0.3)  # Closer to body than elbow

	var right_wrist_pole = Node3D.new()
	right_wrist_pole.name = "RightWristPole"
	ik_targets_node.add_child(right_wrist_pole)
	right_wrist_pole.position = Vector3(0.2, 1.0, 0.3)  # Closer to body than elbow

	# Create LeftHandIK
	if left_hand_target:
		left_hand_ik = SkeletonIK3D.new()
		left_hand_ik.name = "LeftHandIK"
		left_hand_ik.root_bone = "characters3d.com___L_Shoulder"
		left_hand_ik.tip_bone = "characters3d.com___L_Hand"
		left_hand_ik.interpolation = 1.0  # Instant IK solving for responsive weapon movement
		left_hand_ik.max_iterations = 20  # More iterations for better accuracy
		left_hand_ik.use_magnet = true  # Enable pole target
		skeleton.add_child(left_hand_ik)
		left_hand_ik.set_target_node(left_hand_target.get_path())
		left_hand_ik.set_magnet_position(left_elbow_pole.global_position)
		print("Created LeftHandIK with elbow pole")

	# Create RightHandIK
	if right_hand_target:
		right_hand_ik = SkeletonIK3D.new()
		right_hand_ik.name = "RightHandIK"
		right_hand_ik.root_bone = "characters3d.com___R_Shoulder"
		right_hand_ik.tip_bone = "characters3d.com___R_Hand"
		right_hand_ik.interpolation = 1.0  # Instant IK solving for responsive weapon movement
		right_hand_ik.max_iterations = 20  # More iterations for better accuracy
		right_hand_ik.use_magnet = true  # Enable pole target
		skeleton.add_child(right_hand_ik)
		right_hand_ik.set_target_node(right_hand_target.get_path())
		right_hand_ik.set_magnet_position(right_elbow_pole.global_position)
		print("Created RightHandIK with elbow pole")

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
	# 2. HINGE joints for single-axis rotation on torso/spine/neck/head to prevent multi-axis spinning
	# 3. HINGE joints for single-axis movement (knees, elbows, ankles, wrists)
	# 4. Tight collision shapes (small radius) to prevent excess leverage
	# 5. Maximum constraint enforcement (ERP=1.0, CFM=0.0) for core bones
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
		var bone_collision_shape = CollisionShape3D.new()
		bone_collision_shape.shape = shape

		# Adjust collision shape position for specific bones
		if bone_suffix in ["Head"]:
			# Move head collider up slightly
			bone_collision_shape.position = Vector3(0, 0.05, 0)

		physical_bone.add_child(bone_collision_shape)
		bone_collision_shape.owner = physical_bone

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

			bone_collision_shape.add_child(debug_mesh)
			debug_mesh.owner = physical_bone

		# CRITICAL: Configure joint to connect to parent bone
		# Use HINGE only for knees, elbows, ankles, wrists (one-axis joints)
		# Use CONE for torso/shoulders/hips to allow natural twisting and bending
		var use_hinge = bone_suffix in ["Lower_Leg", "L_Lower_Leg", "R_Lower_Leg", "Lower_Arm", "L_Lower_Arm", "R_Lower_Arm", "Foot", "L_Foot", "R_Foot", "Hand", "L_Hand", "R_Hand"]

		if use_hinge:
			physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_HINGE
		else:
			physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_CONE

		physical_bone.joint_offset = Transform3D()  # No offset from bone

		# Joint limits - Realistic human body ranges of motion
		var swing_limit = deg_to_rad(30)   # Default moderate flexibility
		var twist_limit = deg_to_rad(20)   # Default twist
		var damping = 0.5   # Moderate damping for natural movement
		var bias = 0.5      # Moderate bias

		# Realistic human joint ranges
		if bone_suffix in ["Hips"]:
			# Hips/pelvis - allow natural bending and twisting
			swing_limit = deg_to_rad(45)   # Natural hip flexion/extension
			twist_limit = deg_to_rad(30)   # Hip rotation
			damping = 0.6
			bias = 0.6
		elif bone_suffix in ["Spine"]:
			# Lower spine - flexible for bending
			swing_limit = deg_to_rad(50)   # Good forward/back range
			twist_limit = deg_to_rad(40)   # Can twist well
			damping = 0.5
			bias = 0.5
		elif bone_suffix in ["Chest", "Upper_Chest"]:
			# Upper torso - moderate flexibility
			swing_limit = deg_to_rad(40)   # Natural chest bending
			twist_limit = deg_to_rad(35)   # Torso rotation
			damping = 0.55
			bias = 0.55
		elif bone_suffix in ["Neck"]:
			# Neck - good range of motion
			swing_limit = deg_to_rad(60)   # Can look up/down/side
			twist_limit = deg_to_rad(45)   # Can turn head
			damping = 0.4
			bias = 0.4
		elif bone_suffix in ["Head"]:
			# Head - natural movement
			swing_limit = deg_to_rad(70)   # Full head movement
			twist_limit = deg_to_rad(50)   # Head rotation
			damping = 0.4
			bias = 0.4
		elif "Shoulder" in bone_suffix:
			# Shoulders - allow natural shoulder movement
			swing_limit = deg_to_rad(30)   # Shoulder can move
			twist_limit = deg_to_rad(20)   # Some rotation
			damping = 0.6
			bias = 0.6
		elif bone_suffix in ["Upper_Leg", "L_Upper_Leg", "R_Upper_Leg"]:
			# Upper legs - natural hip movement
			swing_limit = deg_to_rad(90)   # Can swing forward/back naturally
			twist_limit = deg_to_rad(45)   # Hip rotation
			damping = 0.5
			bias = 0.5
		elif bone_suffix in ["Lower_Leg", "L_Lower_Leg", "R_Lower_Leg"]:
			# HINGE: Lower legs (knees) - one direction only
			swing_limit = deg_to_rad(130)  # Can bend fully
			twist_limit = deg_to_rad(0)    # No twist on hinge
			damping = 0.5
			bias = 0.5
		elif bone_suffix in ["Foot", "L_Foot", "R_Foot"]:
			# HINGE: Feet/ankles - natural ankle flex
			swing_limit = deg_to_rad(45)   # Natural ankle flexion
			twist_limit = deg_to_rad(0)    # No twist on hinge
			damping = 0.5
			bias = 0.5
		elif bone_suffix in ["Toes", "L_Toes", "R_Toes"]:
			# Toes - can flex
			swing_limit = deg_to_rad(30)
			twist_limit = deg_to_rad(10)
			damping = 0.6
			bias = 0.6
		elif bone_suffix in ["Upper_Arm", "L_Upper_Arm", "R_Upper_Arm"]:
			# Upper arms - full shoulder range
			swing_limit = deg_to_rad(90)   # Full arm swing
			twist_limit = deg_to_rad(45)   # Arm rotation
			damping = 0.4
			bias = 0.4
		elif bone_suffix in ["Lower_Arm", "L_Lower_Arm", "R_Lower_Arm"]:
			# HINGE: Lower arms (elbows) - one direction only
			swing_limit = deg_to_rad(145)  # Full elbow bend
			twist_limit = deg_to_rad(0)    # No twist on hinge
			damping = 0.5
			bias = 0.5
		elif bone_suffix in ["Hand", "L_Hand", "R_Hand"]:
			# HINGE: Hands/wrists - realistic wrist movement
			swing_limit = deg_to_rad(80)   # Wrist flexion
			twist_limit = deg_to_rad(0)    # No twist on hinge
			damping = 0.5
			bias = 0.5
		elif "Finger" in bone_suffix or "Thumb" in bone_suffix or "Index" in bone_suffix or "Middle" in bone_suffix or "Ring" in bone_suffix or "Little" in bone_suffix:
			# Fingers - natural finger bending
			swing_limit = deg_to_rad(70)
			twist_limit = deg_to_rad(10)
			damping = 0.6
			bias = 0.6

		# Apply limits based on joint type
		if use_hinge:
			# Hinge joints for knees/elbows/ankles/wrists - one direction only
			# Prevent hyperextension by limiting to forward bend only
			physical_bone.set("joint_constraints/angular_limit_lower", 0)  # Prevent hyperextension
			physical_bone.set("joint_constraints/angular_limit_upper", swing_limit)  # Allow forward bend
			physical_bone.set("joint_constraints/angular_limit_enabled", true)
		else:
			# Cone joints for torso, shoulders, hips - allow multi-axis movement
			physical_bone.set("joint_constraints/swing_span", swing_limit)
			physical_bone.set("joint_constraints/twist_span", twist_limit)

		# Apply constraint parameters for natural movement
		physical_bone.set("joint_constraints/bias", bias)
		physical_bone.set("joint_constraints/damping", damping)
		physical_bone.set("joint_constraints/softness", 0.1)  # Slight softness for natural feel
		physical_bone.set("joint_constraints/relaxation", 0.8)

		# Physics properties - realistic masses
		if bone_suffix in ["Hips", "Spine", "Chest", "Upper_Chest"]:
			physical_bone.mass = 3.0  # Torso segments
		elif bone_suffix in ["Head"]:
			physical_bone.mass = 2.5  # Head weight
		elif bone_suffix in ["Neck"]:
			physical_bone.mass = 1.0  # Neck
		elif bone_suffix in ["Upper_Leg", "L_Upper_Leg", "R_Upper_Leg"]:
			physical_bone.mass = 2.0  # Thighs are heavy
		elif bone_suffix in ["Upper_Arm", "L_Upper_Arm", "R_Upper_Arm"]:
			physical_bone.mass = 1.5  # Upper arms
		else:
			physical_bone.mass = 0.8  # Lighter limbs

		physical_bone.friction = 0.8
		physical_bone.bounce = 0.0

		# Moderate damping for natural movement
		physical_bone.linear_damp = 0.3   # Allow movement
		physical_bone.angular_damp = 0.5  # Moderate rotation resistance

		# No axis locks needed - joint limits and damping provide control

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

	# Left click for shooting (press and hold for automatic fire)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and equipped_weapon:
				is_firing = true
				# Fire immediately on first press
				_shoot_weapon()
			elif not event.pressed:
				is_firing = false

	# Right click for weapon aim
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and equipped_weapon and not is_weapon_sheathed:
			# Ctrl+Right-Click to toggle aim (sticky aim)
			if event.ctrl_pressed:
				is_aim_toggled = !is_aim_toggled
				weapon_state = WeaponState.AIMING if is_aim_toggled else (WeaponState.SHEATHED if is_weapon_sheathed else WeaponState.READY)
				print("Aim toggled: ", "ON" if is_aim_toggled else "OFF")
			# Regular Right-Click for temporary aim (hold to aim)
			else:
				if not is_aim_toggled:  # Only allow temporary aim if not toggled on
					weapon_state = WeaponState.AIMING
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			# Release right-click: return to ready unless aim is toggled on
			if not is_aim_toggled:
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

func _handle_stance_input():
	"""Handle stance change inputs"""
	# Toggle crouch with C key
	if Input.is_action_just_pressed("ui_page_down"):  # C key (will map in project settings)
		if current_stance == Stance.STANDING:
			target_stance = Stance.CROUCHING
		elif current_stance == Stance.CROUCHING:
			target_stance = Stance.STANDING

	# Toggle prone with Z key
	if Input.is_action_just_pressed("ui_end"):  # Z key (will map in project settings)
		if current_stance == Stance.STANDING or current_stance == Stance.CROUCHING:
			target_stance = Stance.PRONE
		elif current_stance == Stance.PRONE:
			target_stance = Stance.STANDING

func _update_stance(delta):
	"""Update current stance with smooth transitions"""
	if not capsule_shape or not collision_shape:
		return

	# Transition stance
	if current_stance != target_stance:
		current_stance = target_stance

	# Get target height and rotation based on stance
	var target_height = standing_height
	var target_pitch = 0.0  # Character pitch rotation (for prone)

	match current_stance:
		Stance.STANDING:
			target_height = standing_height
			target_pitch = 0.0
		Stance.CROUCHING:
			target_height = crouching_height
			target_pitch = 0.0
		Stance.PRONE:
			target_height = prone_height
			target_pitch = deg_to_rad(85)  # Almost horizontal

	# Smoothly interpolate capsule height
	capsule_shape.height = lerp(capsule_shape.height, target_height, stance_transition_speed * delta)

	# Smoothly interpolate character pitch for prone
	var current_pitch = rotation.x
	rotation.x = lerp_angle(current_pitch, target_pitch, stance_transition_speed * delta)

	# Adjust collision shape position (capsule center moves down when shorter)
	var height_diff = standing_height - capsule_shape.height
	collision_shape.position.y = (standing_height / 2.0) - (height_diff / 2.0)

	# Update IK targets based on stance
	_update_ik_for_stance(delta)

func _update_ik_for_stance(delta):
	"""Adjust IK target positions based on current stance and jump state"""
	if not ik_enabled:
		return

	var ik_targets_node = get_node_or_null("IKTargets")
	if not ik_targets_node:
		return

	var left_foot_target = ik_targets_node.get_node_or_null("LeftFootTarget")
	var right_foot_target = ik_targets_node.get_node_or_null("RightFootTarget")
	var left_hand_target = ik_targets_node.get_node_or_null("LeftHandTarget")
	var right_hand_target = ik_targets_node.get_node_or_null("RightHandTarget")

	# Update movement state
	is_moving = velocity.length() > 0.1
	is_running = is_moving and Input.is_action_pressed("sprint")  # Assuming sprint action exists

	# Update walk cycle time
	if is_moving and not is_jumping:
		var cycle_speed = run_cycle_speed if is_running else walk_cycle_speed
		walk_cycle_time += delta * cycle_speed
	else:
		walk_cycle_time = 0.0

	# Adjust feet based on stance, jump, and movement
	if left_foot_target and right_foot_target and skeleton:
		var base_foot_height = -0.9  # Default standing foot position
		var left_foot_offset = 0.0
		var right_foot_offset = 0.0

		if is_jumping:
			# During jump, bring feet up
			var jump_blend = min(jump_time / max_jump_time, 1.0)
			base_foot_height = lerp(-0.9, -0.3, jump_blend)  # Feet come up during jump
		elif is_moving and current_stance == Stance.STANDING:
			# Procedural walk/run animation
			var foot_lift = run_foot_lift if is_running else walk_foot_lift

			# Create alternating foot stepping pattern using sine wave
			# Left foot and right foot are 180 degrees out of phase
			left_foot_offset = sin(walk_cycle_time * PI) * foot_lift
			right_foot_offset = sin((walk_cycle_time + 1.0) * PI) * foot_lift

			# Ensure only positive lift (feet don't go below ground)
			left_foot_offset = max(0.0, left_foot_offset)
			right_foot_offset = max(0.0, right_foot_offset)
		else:
			# Adjust feet based on stance when not moving
			match current_stance:
				Stance.STANDING:
					base_foot_height = -0.9
				Stance.CROUCHING:
					base_foot_height = -0.5  # Feet closer to body when crouching
				Stance.PRONE:
					base_foot_height = 0.0  # Feet level with body when prone

		# Set foot positions (local to character)
		var target_left_height = base_foot_height + left_foot_offset
		var target_right_height = base_foot_height + right_foot_offset
		left_foot_target.position.y = lerp(left_foot_target.position.y, target_left_height, stance_transition_speed * delta)
		right_foot_target.position.y = lerp(right_foot_target.position.y, target_right_height, stance_transition_speed * delta)

	# Adjust hands based on stance (when not holding weapon)
	if not equipped_weapon and left_hand_target and right_hand_target:
		var hand_height = 0.3  # Default hand position

		match current_stance:
			Stance.STANDING:
				hand_height = 0.3
			Stance.CROUCHING:
				hand_height = 0.1  # Hands lower when crouching
			Stance.PRONE:
				hand_height = -0.2  # Hands supporting body when prone

		left_hand_target.position.y = lerp(left_hand_target.position.y, hand_height, stance_transition_speed * delta)
		right_hand_target.position.y = lerp(right_hand_target.position.y, hand_height, stance_transition_speed * delta)

func _physics_process(delta):
	if ragdoll_enabled:
		return

	# Handle automatic fire for full-auto weapons
	if is_firing and equipped_weapon and equipped_weapon.can_shoot:
		var current_time = Time.get_ticks_msec() / 1000.0
		# Check if weapon is full-auto (rifle) or semi-auto (pistol)
		var is_automatic = equipped_weapon.weapon_type == Weapon.WeaponType.RIFLE

		if is_automatic and (current_time - last_shot_time) >= equipped_weapon.fire_rate:
			_shoot_weapon()
			last_shot_time = current_time

	# Handle stance changes
	_handle_stance_input()
	_update_stance(delta)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Reset jump state when landing
		if is_jumping:
			is_jumping = false
			jump_time = 0.0

	# Handle jump - only when standing or crouching
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if current_stance != Stance.PRONE:
			velocity.y = jump_velocity
			is_jumping = true
			jump_time = 0.0

	# Update jump time for IK blending
	if is_jumping:
		jump_time += delta

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

	# Apply movement - speed depends on stance
	var current_speed = walk_speed
	match current_stance:
		Stance.STANDING:
			current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
		Stance.CROUCHING:
			current_speed = crouch_speed
		Stance.PRONE:
			current_speed = prone_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Head rotation moved to _process after spine aiming to avoid conflicts

	# Update recoil recovery
	_update_recoil(delta)

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

	# When aiming: spine handles yaw (horizontal rotation), head only pitches (vertical)
	# When not aiming: head handles both yaw and pitch normally
	var pitch_multiplier = 1.0
	var yaw_multiplier = 1.0

	if equipped_weapon and weapon_state == WeaponState.AIMING:
		# Spine rotates horizontally to keep gun centered
		# Disable head yaw to prevent double rotation
		yaw_multiplier = 0.0
		# Keep pitch enabled for looking up/down
		pitch_multiplier = 1.0

	# Apply rotation to neck (contributes to yaw and some pitch)
	if neck_bone_id >= 0:
		var neck_pose = skeleton.get_bone_pose(neck_bone_id)
		var neck_target = Basis()
		# Neck contributes 40% of the yaw rotation
		neck_target = neck_target.rotated(Vector3.UP, head_yaw * 0.4 * yaw_multiplier)
		# Neck contributes 30% of pitch (negated due to 180° model rotation)
		neck_target = neck_target.rotated(neck_target.x, -head_pitch * 0.3 * pitch_multiplier)
		neck_target = neck_target * original_neck_pose.basis

		neck_pose.basis = neck_pose.basis.slerp(neck_target, head_rotation_speed * delta)
		skeleton.set_bone_pose(neck_bone_id, neck_pose)

	# Apply rotation to head (remaining rotation)
	var head_pose = skeleton.get_bone_pose(head_bone_id)
	var head_target = Basis()
	# Head contributes 60% of yaw rotation
	head_target = head_target.rotated(Vector3.UP, head_yaw * 0.6 * yaw_multiplier)
	# Head contributes 70% of pitch (negated due to 180° model rotation)
	head_target = head_target.rotated(head_target.x, -head_pitch * 0.7 * pitch_multiplier)
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

	# Remove weapon from character (BoneAttachment3D)
	if equipped_weapon.get_parent():
		equipped_weapon.get_parent().remove_child(equipped_weapon)

	# Add weapon as child of physical hand bone
	physical_hand_bone.add_child(equipped_weapon)

	# Position weapon relative to hand bone (using grip alignment)
	if equipped_weapon.main_grip:
		var grip_local_pos = equipped_weapon.main_grip.position
		# Apply rotation offset for proper weapon orientation
		var rotation_offset = Basis().rotated(Vector3.RIGHT, deg_to_rad(-90))
		equipped_weapon.transform.basis = rotation_offset
		# Position so grip aligns with hand bone origin
		var grip_offset_rotated = equipped_weapon.transform.basis * grip_local_pos
		equipped_weapon.position = -grip_offset_rotated

		# Add weapon-specific offset (same as normal equip)
		# In local space: X- = left, Z+ = forward
		var weapon_offset = Vector3.ZERO
		if equipped_weapon.weapon_type == Weapon.WeaponType.PISTOL:
			weapon_offset = Vector3(-0.03, 0.0, 0.08)  # 3cm left, 8cm forward
		elif equipped_weapon.weapon_type == Weapon.WeaponType.RIFLE:
			weapon_offset = Vector3(-0.02, 0.0, 0.12)  # 2cm left, 12cm forward
		equipped_weapon.position += weapon_offset
	else:
		equipped_weapon.position = Vector3(-0.03, 0.0, 0.08)  # Default pistol offset (forward and left)
		equipped_weapon.rotation = Vector3.ZERO

	# Enable weapon ragdoll mode - stays in hand until collision
	equipped_weapon.enter_ragdoll_mode()

	print("Weapon attached to ragdoll hand and will drop on collision")

func _detach_weapon_from_ragdoll_hand():
	"""Restore weapon to normal attachment after ragdoll"""
	if not equipped_weapon:
		return

	# Check if weapon was dropped during ragdoll
	if not equipped_weapon.is_equipped:
		print("Weapon was dropped during ragdoll, not restoring")
		equipped_weapon = null
		return

	print("Detaching weapon from ragdoll hand")

	# Exit weapon ragdoll mode
	equipped_weapon.exit_ragdoll_mode()

	# Remove from physical bone
	if equipped_weapon.get_parent():
		equipped_weapon.get_parent().remove_child(equipped_weapon)

	# Re-add to hand attachment (BoneAttachment3D)
	if right_hand_attachment:
		right_hand_attachment.add_child(equipped_weapon)

		# Restore grip-aligned transform
		if equipped_weapon.main_grip:
			var grip_local_pos = equipped_weapon.main_grip.position
			var rotation_offset = Basis().rotated(Vector3.RIGHT, deg_to_rad(-90))
			equipped_weapon.transform.basis = rotation_offset
			var grip_offset_rotated = equipped_weapon.transform.basis * grip_local_pos
			equipped_weapon.transform.origin = -grip_offset_rotated

			# Apply weapon-specific offset
			# In local space: X- = left, Z+ = forward
			var weapon_offset = Vector3.ZERO
			if equipped_weapon.weapon_type == Weapon.WeaponType.PISTOL:
				weapon_offset = Vector3(-0.03, 0.0, 0.08)  # 3cm left, 8cm forward
			elif equipped_weapon.weapon_type == Weapon.WeaponType.RIFLE:
				weapon_offset = Vector3(-0.02, 0.0, 0.12)  # 2cm left, 12cm forward
			equipped_weapon.transform.origin += weapon_offset
		else:
			equipped_weapon.transform.origin = Vector3(-0.03, 0.0, 0.08)  # Default pistol offset (forward and left)
			equipped_weapon.transform.basis = Basis().rotated(Vector3.RIGHT, deg_to_rad(-90))

	print("Weapon restored to normal attachment")

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

	# Equip the weapon - parent to right hand attachment so it follows IK automatically
	if weapon.equip(self, right_hand_attachment):
		equipped_weapon = weapon
		nearby_weapon = null

		# Weapon is now parented to hand bone and will automatically follow IK transforms

func _shoot_weapon():
	"""Shoot the currently equipped weapon"""
	if not equipped_weapon:
		return

	# Get shoot direction from camera
	var camera = fps_camera if camera_mode == 0 else tps_camera
	if not camera:
		return

	var shoot_direction = -camera.global_transform.basis.z  # Forward direction

	# Apply weapon spread based on weapon state
	var spread_angle = 0.0
	if weapon_state == WeaponState.AIMING:
		spread_angle = deg_to_rad(0.5)  # Very tight spread when aiming down sights
	else:  # READY or SHEATHED (hip fire)
		spread_angle = deg_to_rad(3.0)  # Wide spread when hip firing

	# Add random spread to direction
	var spread_x = randf_range(-spread_angle, spread_angle)
	var spread_y = randf_range(-spread_angle, spread_angle)

	# Apply spread by rotating the shoot direction
	var spread_basis = Basis()
	spread_basis = spread_basis.rotated(camera.global_transform.basis.x, spread_y)  # Pitch
	spread_basis = spread_basis.rotated(camera.global_transform.basis.y, spread_x)  # Yaw
	shoot_direction = spread_basis * shoot_direction

	# Shoot from camera position
	var shoot_from = camera.global_position

	# Call weapon shoot function
	var hit_result = equipped_weapon.shoot(shoot_from, shoot_direction)

	# Trigger muzzle flash
	_trigger_muzzle_flash()

	# Play gunshot sound
	_play_gunshot_sound()

	# Apply recoil
	_apply_recoil()

	# Increase crosshair spread
	current_spread += spread_increase_per_shot
	current_spread = min(current_spread, max_spread)

	# Update last shot time
	last_shot_time = Time.get_ticks_msec() / 1000.0

	# Handle hit result
	if hit_result.hit:
		var hit_node = hit_result.collider

		# Create impact particle effect
		_create_impact_effect(hit_result.position, hit_result.normal)

		# Check if we hit a character with a skeleton (for partial ragdoll)
		if hit_node is PhysicalBone3D:
			var target_character = _find_parent_character(hit_node)
			if target_character and target_character != self:
				# Apply partial ragdoll to the hit bone
				target_character._apply_partial_ragdoll(hit_result.bone_name, hit_result.direction * hit_result.knockback_force)

func _find_parent_character(node: Node) -> Node:
	"""Find the parent CharacterController if it exists"""
	var current = node.get_parent()
	while current:
		if current is CharacterController:
			return current
		current = current.get_parent()
	return null

func _trigger_muzzle_flash():
	"""Create and trigger muzzle flash effect at weapon muzzle"""
	if not equipped_weapon:
		return

	# Get flash position - use muzzle_point if available, otherwise weapon position
	var flash_position = equipped_weapon.global_position
	if equipped_weapon.muzzle_point:
		flash_position = equipped_weapon.muzzle_point.global_position

	# Create bright muzzle flash light
	var flash = OmniLight3D.new()
	get_tree().root.add_child(flash)
	flash.global_position = flash_position
	flash.light_color = Color(1.0, 0.9, 0.6)
	flash.light_energy = 50.0  # Very bright
	flash.omni_range = 5.0
	flash.shadow_enabled = false

	# Quick flash using tween
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "light_energy", 0.0, 0.05)
	flash_tween.tween_callback(flash.queue_free)

	print("Muzzle flash at ", flash_position)

func _play_gunshot_sound():
	"""Play explosive gunshot sound with heavy bass"""
	if not equipped_weapon:
		return

	# Create audio player if it doesn't exist
	if not gunshot_audio:
		gunshot_audio = AudioStreamPlayer3D.new()
		gunshot_audio.max_distance = 100.0  # Louder, travels further
		gunshot_audio.unit_size = 15.0  # Much louder
		gunshot_audio.volume_db = 5.0  # Boost volume
		add_child(gunshot_audio)

	# Create explosive gunshot using AudioStreamGenerator
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 16000.0  # Lower for deeper bass
	generator.buffer_length = 0.3  # Longer for more boom

	gunshot_audio.stream = generator
	gunshot_audio.global_position = equipped_weapon.global_position
	gunshot_audio.play()

	# Fill buffer in next frame
	_fill_gunshot_buffer.call_deferred()

func _fill_gunshot_buffer():
	"""Fill the audio buffer with explosive gunshot sound"""
	if not gunshot_audio:
		return

	var playback = gunshot_audio.get_stream_playback()
	if not playback:
		return

	# Generate explosive gunshot: 0.25s at 16000Hz
	var samples = 4000
	var mix_rate = 16000.0

	# Filter states for bass layers
	var bass_filter = 0.0
	var sub_bass_filter = 0.0

	for i in range(samples):
		var t = float(i) / float(samples)
		var time_seconds = float(i) / mix_rate

		# Multi-stage envelope for explosive sound
		var attack_env = 1.0 - exp(-t * 200.0)  # Very fast attack
		var decay_env = exp(-t * 8.0)  # Slower decay for more boom
		var sustain_env = exp(-t * 3.5)  # Even slower sub-bass rumble

		# LAYER 1: Sub-bass explosion (very low frequency)
		var sub_bass_freq = 40.0 + (60.0 * exp(-t * 15.0))  # 40-100Hz sweep down
		var sub_bass = sin(time_seconds * sub_bass_freq * TAU) * sustain_env * 0.6

		# LAYER 2: Bass thump (low frequency)
		var bass_freq = 80.0 + (120.0 * exp(-t * 12.0))  # 80-200Hz sweep down
		var bass_thump = sin(time_seconds * bass_freq * TAU) * decay_env * 0.5

		# LAYER 3: Mid crack (sharp attack)
		var noise = (randf() * 2.0 - 1.0)
		var crack = 0.0
		if t < 0.08:  # First 8%
			crack = noise * (1.0 - t / 0.08) * attack_env * 0.7

		# LAYER 4: Bass noise (filtered white noise)
		bass_filter = 0.15 * noise + 0.85 * bass_filter  # Heavy low-pass
		var bass_noise = bass_filter * decay_env * 0.4

		# LAYER 5: Sub-bass noise (even more filtered)
		sub_bass_filter = 0.05 * noise + 0.95 * sub_bass_filter  # Extreme low-pass
		var sub_noise = sub_bass_filter * sustain_env * 0.3

		# Mix all layers with emphasis on bass
		var sample = sub_bass + bass_thump + crack + bass_noise + sub_noise

		# Soft clipping for natural distortion (like real gunshot)
		sample = tanh(sample * 1.5)  # Overdrive for punch
		sample = clamp(sample, -1.0, 1.0)

		playback.push_frame(Vector2(sample, sample))

	print("Gunshot sound: BOOM!")

func _apply_recoil():
	"""Apply recoil to camera and weapon"""
	# Add recoil rotation (camera kick up)
	current_recoil_rotation += recoil_rotation

	# Add recoil position (weapon pushes back)
	current_recoil_position += recoil_position

	# Add hand IK recoil (hands kick back)
	current_hand_recoil += hand_recoil_offset

	# Randomize recoil slightly for more natural feel
	var random_yaw = randf_range(-1.0, 1.0)
	current_recoil_rotation.y += random_yaw

func _create_impact_effect(impact_pos: Vector3, normal: Vector3):
	"""Create bullet hole decal and smoke effect at impact point"""

	# 1. CREATE BULLET HOLE DECAL
	var decal = Decal.new()
	get_tree().root.add_child(decal)
	decal.global_position = impact_pos + normal * 0.01  # Slightly offset from surface

	# Orient decal to face along surface normal
	var up_vector = Vector3.UP
	if abs(normal.dot(Vector3.UP)) > 0.99:  # Nearly parallel
		up_vector = Vector3.RIGHT
	decal.look_at(impact_pos + normal * 2.0, up_vector)

	# Decal size and properties
	decal.size = Vector3(0.2, 0.2, 0.5)  # Width, height, depth
	decal.cull_mask = 0xFFFFF  # Render on all layers

	# Create bullet hole texture procedurally
	var decal_material = StandardMaterial3D.new()
	decal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	decal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	decal_material.albedo_color = Color(0.1, 0.1, 0.1, 0.8)  # Dark bullet hole
	decal_material.blend_mode = BaseMaterial3D.BLEND_MODE_MUL  # Multiply blending for darkening
	decal.texture_albedo = _create_bullet_hole_texture()

	# Make decal permanent (or fade after time)
	var decal_timer = get_tree().create_timer(30.0)  # Stay for 30 seconds
	decal_timer.timeout.connect(func(): decal.queue_free())

	# 2. CREATE SIMPLE VISIBLE SMOKE PUFF
	var smoke = OmniLight3D.new()
	get_tree().root.add_child(smoke)
	smoke.global_position = impact_pos + normal * 0.1
	smoke.light_color = Color(0.6, 0.6, 0.6)  # Gray light
	smoke.light_energy = 2.0
	smoke.omni_range = 1.0

	# Fade out smoke light over time
	var smoke_tween = create_tween()
	smoke_tween.tween_property(smoke, "light_energy", 0.0, 0.5)
	smoke_tween.tween_callback(smoke.queue_free)

	# 3. CREATE BRIGHT IMPACT FLASH
	var flash = OmniLight3D.new()
	get_tree().root.add_child(flash)
	flash.global_position = impact_pos + normal * 0.05
	flash.light_color = Color(1.0, 0.9, 0.7)  # Bright yellow-white
	flash.light_energy = 10.0
	flash.omni_range = 2.0

	# Quick flash
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "light_energy", 0.0, 0.1)
	flash_tween.tween_callback(flash.queue_free)

	print("Created bullet hole, smoke puff, and impact flash at ", impact_pos)

func _create_bullet_hole_texture() -> ImageTexture:
	"""Create a simple circular bullet hole texture"""
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.5

	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)

			if dist < radius:
				# Create gradient from center (black) to edge (transparent)
				var alpha = 1.0 - (dist / radius)
				alpha = clamp(alpha * 1.5, 0.0, 1.0)
				image.set_pixel(x, y, Color(0, 0, 0, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)

func _update_recoil(delta: float):
	"""Update recoil recovery in _process"""
	# Recover from recoil smoothly
	current_recoil_rotation = current_recoil_rotation.lerp(Vector3.ZERO, recoil_recovery_speed * delta)
	current_recoil_position = current_recoil_position.lerp(Vector3.ZERO, recoil_recovery_speed * delta)
	current_hand_recoil = current_hand_recoil.lerp(Vector3.ZERO, recoil_recovery_speed * delta)

	# Apply recoil to camera rotation
	if fps_camera or tps_camera:
		# Apply recoil as additional rotation on top of normal camera rotation
		camera_rotation.x += deg_to_rad(current_recoil_rotation.x) * delta * 2.0  # Gradual camera kick
		camera_rotation.y += deg_to_rad(current_recoil_rotation.y) * delta * 2.0

	# Update muzzle flash timer
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
		if muzzle_flash_timer <= 0.0 and muzzle_flash_light:
			muzzle_flash_light.visible = false

func _apply_partial_ragdoll(bone_name: String, impulse: Vector3):
	"""Apply partial ragdoll effect to a specific bone"""
	if not skeleton:
		return

	print("Applying partial ragdoll to bone: ", bone_name, " with impulse: ", impulse)

	# Find the physical bone
	var physical_bone: PhysicalBone3D = null
	for child in skeleton.get_children():
		if child is PhysicalBone3D and child.bone_name == bone_name:
			physical_bone = child
			break

	if not physical_bone:
		print("  Physical bone not found!")
		return

	# Enable physics simulation on this bone temporarily
	physical_bone.set_simulate_physics(true)

	# Apply impulse
	physical_bone.apply_central_impulse(impulse)

	# Schedule recovery (return to normal after delay)
	var recover_timer = get_tree().create_timer(1.5)
	recover_timer.timeout.connect(func(): _recover_bone(physical_bone))

	print("  Partial ragdoll applied, will recover in 1.5s")

func _recover_bone(physical_bone: PhysicalBone3D):
	"""Recover a bone from ragdoll state"""
	if physical_bone and is_instance_valid(physical_bone):
		physical_bone.set_simulate_physics(false)
		print("Recovered bone: ", physical_bone.bone_name)

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

func _calculate_weapon_sway(delta: float, moving: bool) -> Vector3:
	"""Calculate procedural weapon sway based on movement and time"""
	sway_time += delta * sway_speed

	# Base sway using sine waves for smooth oscillation
	var sway_x = sin(sway_time) * sway_amount
	var sway_y = cos(sway_time * 0.8) * sway_amount * 0.5

	# Extra sway when moving
	if moving:
		sway_x *= movement_sway_multiplier
		sway_y *= movement_sway_multiplier
		# Add bob effect when moving
		sway_y += sin(sway_time * 2.0) * sway_amount * movement_sway_multiplier * 0.3

	# Reduce sway when aiming
	if weapon_state == WeaponState.AIMING:
		sway_x *= 0.3
		sway_y *= 0.3

	return Vector3(sway_x, sway_y, 0)

func _update_weapon_ik_targets():
	"""Set IK target positions for weapon holding (called BEFORE IK is applied)"""
	if not equipped_weapon or not skeleton or right_hand_bone_id < 0:
		return

	var ik_targets_node = get_node_or_null("IKTargets")
	if not ik_targets_node:
		return

	# Get camera rotation for IK target positioning
	var active_camera = fps_camera if camera_mode == 0 else tps_camera
	if not active_camera:
		return

	# Check if character is moving for sway calculation
	var character_moving = velocity.length() > 0.1
	current_sway = _calculate_weapon_sway(get_process_delta_time(), character_moving)

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

	# Use camera-relative positioning ONLY when actively aiming for precise aim
	# When weapon ready but not aiming, use body-relative for natural pose
	var use_camera_relative = (weapon_state == WeaponState.AIMING)

	var positioning_basis: Basis
	if use_camera_relative:
		# Camera-relative: Gun points exactly where you're looking
		positioning_basis = active_camera.global_transform.basis
	else:
		# Body-relative: Gun follows body rotation
		positioning_basis = Basis(Vector3.UP, body_rotation_y)

	# Position right hand IK target relative to body
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

		# Apply hand recoil to offset
		var final_offset = base_offset + current_hand_recoil
		var target_pos = anchor_transform.origin + positioning_basis * final_offset

		right_hand_target.global_position = target_pos

	# Update left hand IK target ONLY for two-handed weapons (rifles)
	var left_hand_target = ik_targets_node.get_node_or_null("LeftHandTarget")
	if left_hand_target:
		if equipped_weapon.is_two_handed:
			# Two-handed weapon (rifle/assault rifle): Position left hand for foregrip
			# Left hand should be higher and further forward than right hand
			if equipped_weapon.secondary_grip:
				# If weapon has a secondary grip node, use it as base
				left_hand_target.global_position = equipped_weapon.secondary_grip.global_position
			else:
				# No secondary grip - calculate position relative to right hand
				# Position left hand forward and slightly up from right hand
				# Start from right hand target position
				var right_hand_pos: Vector3 = right_hand_target.global_position if right_hand_target else global_position

				# Offset for assault rifle foregrip:
				# - Forward (along weapon barrel): 0.35m in front of right hand
				# - Up: 0.05m higher than right hand
				# - No left/right offset (centerline)
				var foregrip_offset = Vector3(0.0, 0.05, -0.35)  # Higher and forward

				# Apply positioning basis offset (camera-relative in FPS/ADS)
				var left_hand_pos = right_hand_pos + positioning_basis * foregrip_offset
				left_hand_target.global_position = left_hand_pos
		else:
			# Pistol (one-handed): Left hand only supports when aiming, not during hip fire
			# Left hand should be below and slightly forward of right hand for proper pistol grip
			if weapon_state == WeaponState.AIMING:
				var right_hand_pos: Vector3 = right_hand_target.global_position if right_hand_target else global_position

				# Offset for pistol support grip:
				# - Down: 0.08m below right hand
				# - Forward: 0.05m forward to wrap under trigger guard
				# - Right: 0.03m to the right (crosses under) to create elbow bend
				var support_grip_offset = Vector3(0.03, -0.08, -0.05)  # Right, down, forward

				var left_hand_pos = right_hand_pos + positioning_basis * support_grip_offset
				left_hand_target.global_position = left_hand_pos
			else:
				# When hip firing (READY) or sheathed, left hand goes to rest position (one-handed grip)
				var l_hand_id = skeleton.find_bone("characters3d.com___L_Hand")
				if l_hand_id >= 0:
					var left_hand_rest = skeleton.global_transform * skeleton.get_bone_rest(l_hand_id).origin
					left_hand_target.global_position = left_hand_rest

	# Update elbow pole positions to guide arm bending
	var left_elbow_pole = ik_targets_node.get_node_or_null("LeftElbowPole")
	var right_elbow_pole = ik_targets_node.get_node_or_null("RightElbowPole")

	if right_hand_target and right_elbow_pole:
		# Position right elbow pole to guide elbow to bend outward
		# Place it to the right and slightly forward of the hand target
		var elbow_offset = Vector3(0.2, 0.0, -0.2)  # Right and forward
		right_elbow_pole.global_position = right_hand_target.global_position + positioning_basis * elbow_offset

	if left_hand_target and left_elbow_pole:
		# Position left elbow pole to guide elbow to bend outward
		# Place it to the left and slightly forward of the hand target
		var elbow_offset = Vector3(-0.2, 0.0, -0.2)  # Left and forward
		left_elbow_pole.global_position = left_hand_target.global_position + positioning_basis * elbow_offset

	# Update wrist pole positions for refined hand/wrist control
	var left_wrist_pole = ik_targets_node.get_node_or_null("LeftWristPole")
	var right_wrist_pole = ik_targets_node.get_node_or_null("RightWristPole")

	if right_hand_target and right_wrist_pole:
		# Position right wrist pole closer to hand, slightly down and outward
		# This helps guide the wrist orientation for proper weapon grip
		var wrist_offset = Vector3(0.1, -0.05, -0.1)  # Slightly right, down, and forward
		right_wrist_pole.global_position = right_hand_target.global_position + positioning_basis * wrist_offset

	if left_hand_target and left_wrist_pole:
		# Position left wrist pole for support hand positioning
		var wrist_offset = Vector3(-0.1, -0.05, -0.1)  # Slightly left, down, and forward
		left_wrist_pole.global_position = left_hand_target.global_position + positioning_basis * wrist_offset

func _update_weapon_to_hand():
	"""Position weapon to follow IK-transformed hand bone (called AFTER IK is applied)"""
	if not equipped_weapon:
		return
	if not skeleton:
		return
	if right_hand_bone_id < 0:
		return

	# Get the IK-transformed hand bone transform
	var right_hand_transform = skeleton.global_transform * skeleton.get_bone_global_pose(right_hand_bone_id)

	# STEP 1: Position weapon so grip point aligns with hand bone origin
	# This must be done FIRST, before applying any rotation offsets
	if equipped_weapon.main_grip:
		# Calculate where weapon should be placed so grip aligns with hand
		var grip_local_pos = equipped_weapon.main_grip.position

		# First, match hand rotation directly (no offset yet)
		equipped_weapon.global_transform.basis = right_hand_transform.basis

		# Calculate grip offset in world space
		var grip_world_offset = equipped_weapon.global_transform.basis * grip_local_pos

		# Position weapon so grip point is at hand bone origin
		equipped_weapon.global_position = right_hand_transform.origin - grip_world_offset

		# STEP 2: Apply weapon-specific rotation offset AFTER positioning
		# This rotates the weapon around the grip point (hand bone origin)
		# Adjust these values to orient the weapon correctly in hand
		var rotation_offset = Basis()
		rotation_offset = rotation_offset.rotated(Vector3.RIGHT, deg_to_rad(-90))  # Pitch
		# Add more rotations here if needed:
		# rotation_offset = rotation_offset.rotated(Vector3.UP, deg_to_rad(X))     # Yaw
		# rotation_offset = rotation_offset.rotated(Vector3.FORWARD, deg_to_rad(X)) # Roll

		equipped_weapon.global_transform.basis = right_hand_transform.basis * rotation_offset

		# Recalculate position after rotation (rotation happens around grip point)
		grip_world_offset = equipped_weapon.global_transform.basis * grip_local_pos
		equipped_weapon.global_position = right_hand_transform.origin - grip_world_offset
	else:
		# Fallback: if no grip point, just match hand transform
		equipped_weapon.global_transform = right_hand_transform

func _get_constrained_aim_target() -> Vector3:
	"""Calculate aim target position with angle and distance constraints"""
	if not equipped_weapon:
		return global_position + global_transform.basis * Vector3(0, 0, -10)

	var camera = fps_camera if camera_mode == 0 else tps_camera
	if not camera:
		return global_position + global_transform.basis * Vector3(0, 0, -10)

	# Get aim origin (weapon raycast position)
	var aim_origin = global_position + Vector3(0, 1.5, 0)  # Approximate chest height
	if equipped_weapon.muzzle_point:
		aim_origin = equipped_weapon.muzzle_point.global_position

	# Get raw target position (where camera is looking)
	var camera_forward = -camera.global_transform.basis.z
	var target_position = camera.global_position + camera_forward * 100.0

	# Add offset to target (e.g., aim at chest instead of feet)
	target_position += aim_target_offset

	# Calculate direction and distance to target
	var target_direction = (target_position - aim_origin).normalized()
	var target_distance = aim_origin.distance_to(target_position)
	var aim_forward = -global_transform.basis.z

	# Calculate blend amount for constraints
	var blend_out = 0.0

	# Constraint 1: Angle limit
	var angle_to_target = rad_to_deg(acos(aim_forward.dot(target_direction)))
	if angle_to_target > aim_angle_limit:
		blend_out = max(blend_out, (angle_to_target - aim_angle_limit) / aim_angle_limit)

	# Constraint 2: Distance limit
	if target_distance < aim_distance_limit:
		blend_out = max(blend_out, (aim_distance_limit - target_distance) / aim_distance_limit)

	# Blend between target direction and forward direction
	blend_out = clamp(blend_out, 0.0, 1.0)
	var final_direction = target_direction.lerp(aim_forward, blend_out).normalized()

	# Return final target position
	return aim_origin + final_direction * max(target_distance, aim_distance_limit)

func _aim_bone_toward_direction(bone_id: int, aim_direction: Vector3, bone_weight: float):
	"""Rotate bone toward aim direction (avoids circular dependency)"""
	if bone_id < 0 or not skeleton:
		return

	# Get bone's current global pose (includes all parent transformations)
	var bone_global_pose = skeleton.get_bone_global_pose(bone_id)
	var bone_global_transform = skeleton.global_transform * bone_global_pose

	# Get bone's current forward direction (in global space)
	# Spine bones typically point upward, so we use +Y as their "forward"
	var bone_forward = bone_global_transform.basis.y

	# Calculate rotation needed to align bone forward with aim direction
	var rotation_axis = bone_forward.cross(aim_direction)
	if rotation_axis.length_squared() < 0.0001:
		return  # Already aligned or opposite directions

	rotation_axis = rotation_axis.normalized()
	var rotation_angle = acos(clamp(bone_forward.dot(aim_direction), -1.0, 1.0))

	# Apply bone weight to rotation
	rotation_angle *= bone_weight * aim_ik_weight

	# Create delta rotation
	var delta_rotation = Basis(rotation_axis, rotation_angle)

	# Apply rotation to bone in global space
	var new_basis = delta_rotation * bone_global_transform.basis

	# Convert back to bone local space
	var parent_id = skeleton.get_bone_parent(bone_id)
	if parent_id >= 0:
		var parent_global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(parent_id)
		var parent_inv = parent_global_transform.affine_inverse()
		var local_transform = parent_inv * Transform3D(new_basis, bone_global_transform.origin)
		skeleton.set_bone_pose_rotation(bone_id, local_transform.basis.get_rotation_quaternion())
	else:
		# No parent, use skeleton inverse
		var skeleton_inv = skeleton.global_transform.affine_inverse()
		var local_transform = skeleton_inv * Transform3D(new_basis, bone_global_transform.origin)
		skeleton.set_bone_pose_rotation(bone_id, local_transform.basis.get_rotation_quaternion())

func _rotate_hand_to_grip_weapon():
	"""Rotate right hand bone to grip weapon with palm facing inward"""
	if not equipped_weapon or not skeleton or right_hand_bone_id < 0:
		return

	var camera = fps_camera if camera_mode == 0 else tps_camera
	if not camera:
		return

	# Get camera's forward direction (where weapon should point)
	var camera_forward = -camera.global_transform.basis.z
	var camera_up = camera.global_transform.basis.y

	# Get current hand bone global pose (after IK)
	var hand_global_pose = skeleton.get_bone_global_pose(right_hand_bone_id)
	var hand_global_transform = skeleton.global_transform * hand_global_pose

	# Create target rotation for hand to grip weapon
	# For proper gun grip (right hand):
	# - Fingers wrap around grip (pointing down/forward)
	# - Palm faces LEFT (inward toward body)
	# - Thumb points UP along the side of the weapon

	# Build weapon-aligned basis
	var weapon_forward = camera_forward  # Weapon points where camera looks
	var weapon_up = camera_up
	var weapon_right = weapon_up.cross(weapon_forward).normalized()
	weapon_up = weapon_forward.cross(weapon_right).normalized()

	# For right hand gripping gun:
	# - Hand forward (fingers direction) should point along weapon forward
	# - Palm should face LEFT (weapon_left = -weapon_right)
	# - Thumb should point UP (weapon_up)
	var target_basis = Basis()
	target_basis.z = -weapon_forward  # Hand -Z points forward (Godot convention)
	target_basis.x = -weapon_right    # Hand +X (palm side) faces LEFT (inward)
	target_basis.y = weapon_up        # Hand +Y (thumb side) points UP

	# Convert to bone local space
	var parent_id = skeleton.get_bone_parent(right_hand_bone_id)
	if parent_id >= 0:
		var parent_global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(parent_id)
		var parent_inv = parent_global_transform.affine_inverse()
		var local_transform = parent_inv * Transform3D(target_basis, hand_global_transform.origin)
		skeleton.set_bone_pose_rotation(right_hand_bone_id, local_transform.basis.get_rotation_quaternion())

func _apply_spine_aiming():
	"""Apply spine bone rotations to aim upper body toward camera direction"""
	if not aim_ik_enabled or not equipped_weapon or not skeleton:
		return

	var camera = fps_camera if camera_mode == 0 else tps_camera
	if not camera:
		return

	# Get camera's forward direction (where it's looking)
	var camera_forward = -camera.global_transform.basis.z

	# Apply angle constraint - don't aim too far back or to sides
	var body_forward = -global_transform.basis.z

	var angle_to_camera = rad_to_deg(acos(clamp(body_forward.dot(camera_forward), -1.0, 1.0)))

	# Blend toward body forward if exceeding angle limit
	var blend_weight = 1.0
	if angle_to_camera > aim_angle_limit:
		blend_weight = 1.0 - ((angle_to_camera - aim_angle_limit) / aim_angle_limit)
		blend_weight = clamp(blend_weight, 0.0, 1.0)

	# Calculate aim direction with horizontal constraint
	var aim_direction = camera_forward.lerp(body_forward, 1.0 - blend_weight).normalized()

	# Apply vertical pitch constraints to prevent spine flipping
	# Get the pitch (vertical angle) of the aim direction
	var horizontal_forward = Vector3(aim_direction.x, 0, aim_direction.z).normalized()
	if horizontal_forward.length_squared() > 0.01:  # Avoid division by zero
		var current_pitch = rad_to_deg(atan2(-aim_direction.y, horizontal_forward.length()))

		# Clamp pitch to limits
		var clamped_pitch = clamp(current_pitch, -max_spine_pitch_down, max_spine_pitch_up)

		# Reconstruct aim direction with clamped pitch
		var pitch_radians = deg_to_rad(clamped_pitch)
		var horizontal_length = cos(pitch_radians)
		aim_direction = Vector3(
			horizontal_forward.x * horizontal_length,
			-sin(pitch_radians),
			horizontal_forward.z * horizontal_length
		).normalized()

	# Only rotate spine bone - chest/upper_chest are parents of neck/head
	if spine_bone_id >= 0:
		# Apply rotation only once (not multiple iterations)
		# Multiple iterations are for IK solving, not needed for direct bone rotation
		_aim_bone_toward_direction(spine_bone_id, aim_direction, spine_bone_weights["Spine"])

func _apply_spine_aiming_horizontal_only():
	"""Apply spine rotation ONLY horizontally (yaw) to keep gun centered, NO vertical rotation"""
	if not aim_ik_enabled or not equipped_weapon or not skeleton or spine_bone_id < 0:
		return

	var camera = fps_camera if camera_mode == 0 else tps_camera
	if not camera:
		return

	# Get camera and body forward directions (horizontal plane only)
	var camera_forward = -camera.global_transform.basis.z
	var body_forward = -global_transform.basis.z

	# Project onto horizontal plane (remove Y component for horizontal-only rotation)
	var camera_forward_horizontal = Vector3(camera_forward.x, 0, camera_forward.z).normalized()
	var body_forward_horizontal = Vector3(body_forward.x, 0, body_forward.z).normalized()

	if camera_forward_horizontal.length_squared() < 0.01:
		return  # Avoid division by zero when looking straight up/down

	# Calculate yaw angle between body and camera (horizontal angle only)
	var yaw_angle = atan2(camera_forward_horizontal.x, camera_forward_horizontal.z) - atan2(body_forward_horizontal.x, body_forward_horizontal.z)

	# Normalize angle to [-PI, PI]
	while yaw_angle > PI:
		yaw_angle -= 2.0 * PI
	while yaw_angle < -PI:
		yaw_angle += 2.0 * PI

	# Apply angle constraint to prevent rotating too far back
	var max_yaw = deg_to_rad(aim_angle_limit)
	yaw_angle = clamp(yaw_angle, -max_yaw, max_yaw)

	# Apply yaw rotation to spine bone (rotation around Y axis only)
	# This rotates upper body left/right to face camera direction
	# But does NOT tilt forward/back, so head stays at shoulder level
	var spine_rotation = Quaternion(Vector3.UP, yaw_angle * spine_bone_weights["Spine"] * aim_ik_weight)

	# Get current spine pose and apply rotation
	var current_pose = skeleton.get_bone_pose(spine_bone_id)
	var new_rotation = spine_rotation * current_pose.basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(spine_bone_id, new_rotation)

func _process(_delta):
	# WEAPON UPDATE ORDER - CRITICAL for proper IK-based positioning:
	# 1. Set IK targets (where hands should go based on weapon state/aiming)
	# 2. Apply IK (moves bones to targets)
	# 3. Weapon automatically follows hand bone (no manual update needed - it's parented to BoneAttachment3D)

	# STEP 1: Set IK targets for weapon holding
	if equipped_weapon:
		_update_weapon_ik_targets()

	# STEP 2: Apply IK - start() moves bones to targets
	# Update elbow pole magnet positions before applying IK
	var ik_targets_node = get_node_or_null("IKTargets")
	if ik_targets_node:
		var left_elbow_pole = ik_targets_node.get_node_or_null("LeftElbowPole")
		var right_elbow_pole = ik_targets_node.get_node_or_null("RightElbowPole")

		if right_hand_ik and right_elbow_pole:
			right_hand_ik.set_magnet_position(right_elbow_pole.global_position)
		if left_hand_ik and left_elbow_pole:
			left_hand_ik.set_magnet_position(left_elbow_pole.global_position)

	if ik_enabled:
		# IK enabled - apply foot IK always
		if left_foot_ik:
			left_foot_ik.start()
		if right_foot_ik:
			right_foot_ik.start()

		# Hand IK depends on weapon equipped state
		if equipped_weapon:
			# Weapon equipped - always use right hand IK to hold weapon
			if right_hand_ik:
				right_hand_ik.start()
			# Left hand IK when AIMING for two-handed grip
			if weapon_state == WeaponState.AIMING:
				if left_hand_ik:
					left_hand_ik.start()
			else:
				# Not aiming - disable left hand IK for relaxed pose
				if left_hand_ik:
					left_hand_ik.stop()
		else:
			# No weapon - use default animation for hands
			if left_hand_ik:
				left_hand_ik.stop()
			if right_hand_ik:
				right_hand_ik.stop()
	else:
		# IK disabled - but keep hand IK active if weapon equipped
		if equipped_weapon:
			# Keep right hand IK active to hold weapon
			if right_hand_ik:
				right_hand_ik.start()
			# Left hand IK only when aiming
			if weapon_state == WeaponState.AIMING and left_hand_ik:
				left_hand_ik.start()
			else:
				if left_hand_ik:
					left_hand_ik.stop()
			# Disable foot IK when IK is toggled off
			if left_foot_ik:
				left_foot_ik.stop()
			if right_foot_ik:
				right_foot_ik.stop()
		else:
			# No weapon - stop all IK
			if left_hand_ik:
				left_hand_ik.stop()
			if right_hand_ik:
				right_hand_ik.stop()
			if left_foot_ik:
				left_foot_ik.stop()
			if right_foot_ik:
				right_foot_ik.stop()

	# STEP 3: Apply head rotation BEFORE spine aiming
	if head_look_enabled and skeleton and head_bone_id >= 0:
		_update_head_look(get_process_delta_time())

	# STEP 4: Weapon automatically follows hand bone (parented to BoneAttachment3D)
	# Apply spine aiming when actively aiming to keep gun centered and aligned
	# HORIZONTAL ONLY: Rotate left/right to keep gun centered in view
	# NO VERTICAL: Don't rotate up/down to prevent head displacement
	var should_aim_spine = equipped_weapon and weapon_state == WeaponState.AIMING

	if should_aim_spine:
		_apply_spine_aiming_horizontal_only()
		_rotate_hand_to_grip_weapon()
	else:
		# Reset spine bone rotation when not aiming
		if spine_bone_id >= 0 and skeleton:
			skeleton.set_bone_pose_rotation(spine_bone_id, Quaternion.IDENTITY)

	# STEP 5: Update crosshair spread and position
	_update_crosshair(_delta)
