extends Camera3D
class_name FPSCamera

# This camera follows the character's head bone for authentic FPS view
@export var skeleton: Skeleton3D
@export var head_bone_name: String = "characters3d.com___Head"
@export var head_offset: Vector3 = Vector3(0, 0.1, 0.15)  # Offset from head bone (eyes position, forward from face)

var head_bone_id: int = -1
var skeleton_mesh: Node3D

func _ready():
	# Find skeleton if not assigned
	if not skeleton:
		skeleton = _find_skeleton(get_parent())

	if skeleton:
		head_bone_id = skeleton.find_bone(head_bone_name)
		skeleton_mesh = skeleton.get_parent() if skeleton.get_parent() else skeleton

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null

func _physics_process(_delta):
	var controller = get_parent()
	if not controller:
		return

	var cam_rotation = controller.get("camera_rotation")
	if not cam_rotation:
		return

	# Position at head bone if available (so camera moves with head)
	if skeleton and head_bone_id >= 0:
		# Get the global transform of the head bone
		var head_global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(head_bone_id)
		# Position camera at head bone with offset
		global_transform.origin = head_global_transform.origin + head_global_transform.basis * head_offset
	else:
		# Fallback: position relative to controller
		global_transform.origin = controller.global_position + Vector3(0, 1.6, 0)

	# Apply camera rotation (head tracking rotates the bones, camera rotation controls view)
	var camera_transform = Transform3D()
	camera_transform = camera_transform.rotated(Vector3.UP, cam_rotation.y)
	camera_transform = camera_transform.rotated(camera_transform.basis.x, cam_rotation.x)
	global_transform.basis = camera_transform.basis
