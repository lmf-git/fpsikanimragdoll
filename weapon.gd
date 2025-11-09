extends RigidBody3D
class_name Weapon

# Weapon types
enum WeaponType { PISTOL, RIFLE }

# Weapon properties
@export var weapon_type: WeaponType = WeaponType.PISTOL
@export var weapon_name: String = "Weapon"
@export var is_two_handed: bool = false

# Grip points for IK
@export var main_grip: Node3D  # Primary grip (right hand for pistol, dominant hand for rifle)
@export var secondary_grip: Node3D  # Secondary grip (left hand foregrip for rifle)

# Pickup settings
@export var pickup_range: float = 2.0
@export var can_be_picked_up: bool = true

# State
var is_equipped: bool = false
var holder: Node3D = null

func _ready():
	# Make weapon physics-enabled when not equipped
	if not is_equipped:
		freeze = false
		gravity_scale = 1.0

func equip(character: Node3D):
	"""Equip this weapon to a character"""
	if is_equipped:
		print("Weapon ", weapon_name, " already equipped!")
		return false

	print("Equipping weapon ", weapon_name, " to character")
	is_equipped = true
	holder = character

	# Disable physics when equipped - CRITICAL: set freeze_mode to KINEMATIC
	# This allows us to move the weapon programmatically while physics is disabled
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC  # Allow programmatic movement
	freeze = true
	gravity_scale = 0.0
	collision_layer = 0
	collision_mask = 0

	# Attach to character
	if get_parent():
		get_parent().remove_child(self)
	character.add_child(self)

	# Position weapon at character's hand
	global_position = character.global_position
	global_rotation = character.global_rotation

	print("Weapon ", weapon_name, " equipped successfully (freeze_mode=KINEMATIC)")
	return true

func unequip():
	"""Drop/unequip this weapon"""
	if not is_equipped:
		return

	is_equipped = false
	var old_holder = holder
	holder = null

	# Re-enable physics
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC  # Reset to default
	freeze = false
	gravity_scale = 1.0
	collision_layer = 4  # Weapon layer
	collision_mask = 1   # Collide with world

	# Detach from character and add to world
	if get_parent():
		var world_pos = global_position
		var world_rot = global_rotation
		get_parent().remove_child(self)

		# Add to world root
		old_holder.get_tree().root.add_child(self)
		global_position = world_pos
		global_rotation = world_rot

	print("Weapon ", weapon_name, " unequipped and dropped at ", global_position)

func get_grip_position(grip_type: String) -> Vector3:
	"""Get the global position of a grip point"""
	if grip_type == "main" and main_grip:
		return main_grip.global_position
	elif grip_type == "secondary" and secondary_grip:
		return secondary_grip.global_position
	return global_position

func get_grip_rotation(grip_type: String) -> Basis:
	"""Get the global rotation of a grip point"""
	if grip_type == "main" and main_grip:
		return main_grip.global_transform.basis
	elif grip_type == "secondary" and secondary_grip:
		return secondary_grip.global_transform.basis
	return global_transform.basis
