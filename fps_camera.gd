extends Camera3D
class_name FPSCamera

# This camera follows the character's head bone for authentic FPS view
@export var skeleton: Skeleton3D
@export var head_bone_name: String = "characters3d.com___Head"
@export var head_offset: Vector3 = Vector3(0, 0.1, 0)  # Offset from head bone (eyes position)

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

func _process(_delta):
	if skeleton and head_bone_id >= 0:
		# Get the global transform of the head bone
		var head_global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(head_bone_id)

		# Get camera rotation from parent controller
		var controller = get_parent()
		if controller and controller.has_method("get"):
			var cam_rotation = controller.get("camera_rotation")
			if cam_rotation:
				# Position camera at head bone with offset
				global_transform.origin = head_global_transform.origin + head_global_transform.basis * head_offset

				# Apply camera rotation (pitch and yaw)
				# Reset rotation first to avoid accumulation
				global_transform.basis = Basis()
				# Apply yaw (Y rotation) then pitch (X rotation)
				global_transform.basis = global_transform.basis.rotated(Vector3.UP, cam_rotation.y)
				global_transform.basis = global_transform.basis.rotated(global_transform.basis.x, cam_rotation.x)
