extends Area3D
class_name IKTarget

# Interactive IK target - clickable and draggable at runtime
@export var target_color: Color = Color.RED
@export var target_size: float = 0.1
@export var show_in_game: bool = false

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var is_being_dragged: bool = false
var camera: Camera3D
var drag_plane: Plane
var drag_offset: Vector3

func _ready():
	# Set up collision for interaction
	collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = target_size
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

	# Create visual indicator
	if not Engine.is_editor_hint() and not show_in_game:
		return

	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = target_size
	sphere.height = target_size * 2

	mesh_instance.mesh = sphere

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = target_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	mesh_instance.material_override = material
	add_child(mesh_instance)

	# Enable mouse interaction
	input_ray_pickable = true
	connect("input_event", _on_input_event)

	# Find camera
	camera = get_viewport().get_camera_3d()

func _on_input_event(_camera: Node, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				is_being_dragged = true
				drag_offset = global_position - _click_position

				# Create a plane parallel to camera for dragging
				if camera:
					var camera_forward = -camera.global_transform.basis.z
					drag_plane = Plane(camera_forward, global_position)
			else:
				# Stop dragging
				is_being_dragged = false

func _process(_delta):
	# Only show in editor or if show_in_game is true
	if mesh_instance:
		mesh_instance.visible = Engine.is_editor_hint() or show_in_game

	# Handle dragging
	if is_being_dragged and camera:
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000

		var intersection = drag_plane.intersects_ray(from, to - from)
		if intersection:
			global_position = intersection
