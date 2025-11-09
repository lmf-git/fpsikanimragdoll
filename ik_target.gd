extends Node3D
class_name IKTarget

# Helper script for IK targets - makes them visible in editor and easy to position
@export var target_color: Color = Color.RED
@export var target_size: float = 0.1
@export var show_in_game: bool = false

var mesh_instance: MeshInstance3D

func _ready():
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

func _process(_delta):
	# Only show in editor or if show_in_game is true
	if mesh_instance:
		mesh_instance.visible = Engine.is_editor_hint() or show_in_game
