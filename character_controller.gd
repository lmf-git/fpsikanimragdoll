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

# Character parts
@export var skeleton: Skeleton3D
@export var head_bone_name: String = "characters3d.com___Head"
@export var neck_bone_name: String = "characters3d.com___Neck"

# Head look
@export var head_look_enabled: bool = true
@export var max_head_rotation_x: float = 60.0  # degrees
@export var max_head_rotation_y: float = 70.0  # degrees
@export var head_rotation_speed: float = 5.0

# IK System
@export var ik_enabled: bool = true
@export var left_hand_ik: SkeletonIK3D
@export var right_hand_ik: SkeletonIK3D
@export var left_foot_ik: SkeletonIK3D
@export var right_foot_ik: SkeletonIK3D

# Ragdoll
@export var ragdoll_enabled: bool = false
@export var physical_skeleton: PhysicalBoneSimulator3D

# Internal variables
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_rotation: Vector2 = Vector2.ZERO
var head_bone_id: int = -1
var neck_bone_id: int = -1
var original_head_pose: Transform3D
var mesh_instance: MeshInstance3D

func _ready():
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Find skeleton if not set
	if not skeleton:
		skeleton = find_skeleton(self)

	if skeleton:
		head_bone_id = skeleton.find_bone(head_bone_name)
		neck_bone_id = skeleton.find_bone(neck_bone_name)
		if head_bone_id >= 0:
			original_head_pose = skeleton.get_bone_pose(head_bone_id)

	# Set initial camera
	_switch_camera(camera_mode)

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = find_skeleton(child)
		if result:
			return result
	return null

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.x -= event.relative.y * mouse_sensitivity
		camera_rotation.y -= event.relative.x * mouse_sensitivity
		camera_rotation.x = clamp(camera_rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event.is_action_pressed("toggle_camera"):
		camera_mode = (camera_mode + 1) % 2
		_switch_camera(camera_mode)

	if event.is_action_pressed("toggle_ragdoll"):
		toggle_ragdoll()

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _switch_camera(mode: int):
	if fps_camera and tps_camera:
		if mode == 0:  # FPS
			fps_camera.current = true
			tps_camera.current = false
			if mesh_instance:
				mesh_instance.visible = false
		else:  # TPS
			fps_camera.current = false
			tps_camera.current = true
			if mesh_instance:
				mesh_instance.visible = true

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

	# Calculate movement direction
	var direction = Vector3.ZERO
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Rotate character with camera (Y axis only for body)
	rotation.y = camera_rotation.y

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

func _update_head_look(delta):
	# Get the camera pitch rotation
	var head_rotation_x = clamp(camera_rotation.x,
		deg_to_rad(-max_head_rotation_x),
		deg_to_rad(max_head_rotation_x))

	# Create rotation for head bone
	var head_rotation = Quaternion(Vector3.RIGHT, head_rotation_x)

	# Get current pose and apply rotation
	var current_pose = skeleton.get_bone_pose(head_bone_id)
	var target_rotation = Basis(head_rotation)

	# Smoothly interpolate
	current_pose.basis = current_pose.basis.slerp(target_rotation * original_head_pose.basis, head_rotation_speed * delta)

	skeleton.set_bone_pose(head_bone_id, current_pose)

func toggle_ragdoll():
	ragdoll_enabled = !ragdoll_enabled

	if physical_skeleton:
		if ragdoll_enabled:
			physical_skeleton.physical_bones_start_simulation()
			# Disable character collision
			set_physics_process(false)
		else:
			physical_skeleton.physical_bones_stop_simulation()
			set_physics_process(true)

func _process(_delta):
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
