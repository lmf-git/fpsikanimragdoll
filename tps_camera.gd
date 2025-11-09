extends Camera3D
class_name TPSCamera

# Third-person camera with collision detection
@export var target: Node3D  # Character to follow
@export var follow_distance: float = 3.0
@export var follow_height: float = 1.5
@export var camera_smoothness: float = 10.0
@export var collision_margin: float = 0.2
@export var min_distance: float = 0.5  # Minimum distance to prevent excessive zoom

var current_distance: float = 0.0

func _ready():
	if not target:
		target = get_parent()
	current_distance = follow_distance

func _physics_process(delta):
	if not target:
		return

	# Get camera rotation from parent controller
	var controller = get_parent()
	if not controller or not controller.has_method("get"):
		return

	var cam_rotation = controller.get("camera_rotation")
	if not cam_rotation:
		return

	# Calculate desired camera position
	var target_pos = target.global_transform.origin + Vector3(0, follow_height, 0)

	# Calculate camera offset based on rotation (negative Z for behind character)
	var offset = Vector3(0, 0, -follow_distance)
	var rotation_transform = Transform3D()
	rotation_transform = rotation_transform.rotated(Vector3.UP, cam_rotation.y)
	rotation_transform = rotation_transform.rotated(rotation_transform.basis.x, cam_rotation.x)
	offset = rotation_transform.basis * offset

	var desired_pos = target_pos + offset

	# Perform raycast for collision detection
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(target_pos, desired_pos)
	query.exclude = [target]

	var result = space_state.intersect_ray(query)

	var final_pos: Vector3
	if result:
		# Hit something, move camera closer
		var hit_distance = target_pos.distance_to(result.position)
		# Clamp to minimum distance to prevent excessive zoom
		var target_distance = max(hit_distance - collision_margin, min_distance)
		current_distance = lerp(current_distance, target_distance, camera_smoothness * delta)
		var adjusted_offset = offset.normalized() * current_distance
		final_pos = target_pos + adjusted_offset
	else:
		# No collision, use full distance
		current_distance = lerp(current_distance, follow_distance, camera_smoothness * delta)
		final_pos = desired_pos

	# Smoothly move camera to position
	global_transform.origin = global_transform.origin.lerp(final_pos, camera_smoothness * delta)

	# Look at target
	look_at(target_pos, Vector3.UP)
