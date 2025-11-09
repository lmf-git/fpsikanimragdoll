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

func equip(character: Node3D, hand_attachment: Node3D = null):
	"""Equip this weapon to a character's hand attachment node"""
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

	# Detach from current parent
	if get_parent():
		get_parent().remove_child(self)

	# Parent to hand attachment if provided, otherwise to character
	var attach_to = hand_attachment if hand_attachment else character
	attach_to.add_child(self)

	# Set local transform relative to hand
	# If we have a main_grip, offset the weapon so grip aligns with hand bone origin
	if main_grip:
		# Get grip offset in local space
		var grip_local_pos = main_grip.position

		# Apply rotation offset first (e.g., rotate pistol to point forward)
		var rotation_offset = Basis()
		rotation_offset = rotation_offset.rotated(Vector3.RIGHT, deg_to_rad(-90))  # Pitch
		transform.basis = rotation_offset

		# Position weapon so grip point is at hand origin (0,0,0 in hand local space)
		# This means weapon position = -grip_offset rotated by weapon basis
		var grip_offset_rotated = transform.basis * grip_local_pos
		transform.origin = -grip_offset_rotated

		print("Weapon ", weapon_name, " equipped with grip offset: ", transform.origin)
	else:
		# No grip point - just place at hand origin with rotation offset
		transform.origin = Vector3.ZERO
		transform.basis = Basis().rotated(Vector3.RIGHT, deg_to_rad(-90))
		print("Weapon ", weapon_name, " equipped at hand origin (no grip point)")

	print("Weapon ", weapon_name, " equipped successfully, parented to: ", attach_to.name)
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
