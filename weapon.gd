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

# Shooting properties
@export var damage: float = 25.0
@export var max_range: float = 100.0
@export var knockback_force: float = 5.0
@export var fire_rate: float = 0.2  # Seconds between shots
@export var muzzle_point: Node3D  # Where bullets come from

# Shooting state
var can_shoot: bool = true
var shoot_cooldown_timer: float = 0.0

# State
var is_equipped: bool = false
var holder: Node3D = null
var is_in_ragdoll_mode: bool = false  # Tracking if holder is ragdolled
var should_monitor_collisions: bool = false  # Whether to check for drop on collision

func _ready():
	# Make weapon physics-enabled when not equipped
	if not is_equipped:
		freeze = false
		gravity_scale = 1.0

	# Ensure grip points are found (in case NodePath wasn't auto-resolved)
	if not main_grip:
		main_grip = get_node_or_null("MainGrip")
		if main_grip:
			print("Found MainGrip node in _ready(): ", main_grip)

	if not secondary_grip:
		secondary_grip = get_node_or_null("SecondaryGrip")

	if not muzzle_point:
		muzzle_point = get_node_or_null("MuzzlePoint")

	print("Weapon _ready - main_grip: ", main_grip, ", secondary_grip: ", secondary_grip, ", muzzle_point: ", muzzle_point)

	# Connect to collision signal for ragdoll drop detection
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Update shoot cooldown
	if not can_shoot:
		shoot_cooldown_timer -= delta
		if shoot_cooldown_timer <= 0.0:
			can_shoot = true

func shoot(from_position: Vector3, direction: Vector3) -> Dictionary:
	"""
	Shoot the weapon using raycast
	Returns dictionary with hit info: {hit: bool, position: Vector3, normal: Vector3, collider: Node3D, bone_name: String}
	"""
	if not can_shoot:
		return {"hit": false}

	# Start cooldown
	can_shoot = false
	shoot_cooldown_timer = fire_rate

	# Use muzzle point if available, otherwise use from_position
	var ray_origin = from_position
	if muzzle_point:
		ray_origin = muzzle_point.global_position

	# Perform raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + direction * max_range)
	query.exclude = [holder] if holder else []  # Don't hit the holder
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	if result:
		print("Shot hit: ", result.collider.name, " at ", result.position)

		# Check if we hit a PhysicalBone3D (for partial ragdoll)
		var bone_name = ""
		if result.collider is PhysicalBone3D:
			bone_name = result.collider.bone_name
			print("  Hit bone: ", bone_name)

		# Return hit info
		return {
			"hit": true,
			"position": result.position,
			"normal": result.normal,
			"collider": result.collider,
			"bone_name": bone_name,
			"damage": damage,
			"knockback_force": knockback_force,
			"direction": direction
		}

	return {"hit": false}

func equip(character: Node3D, hand_attachment: Node3D = null):
	"""Equip this weapon to a character's hand attachment node"""
	if is_equipped:
		print("Weapon ", weapon_name, " already equipped!")
		return false

	print("Equipping weapon ", weapon_name, " to character")
	is_equipped = true
	holder = character

	# Disable physics when equipped - CRITICAL: set freeze_mode to KINEMATIC
	# This allows the weapon to follow its parent (BoneAttachment3D) while physics is disabled
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC  # Allow parent-driven movement
	freeze = false  # Must be false to follow parent transform
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
	print("DEBUG: main_grip = ", main_grip)
	if main_grip:
		print("DEBUG: main_grip exists, position = ", main_grip.position)
		# Get grip offset in local space
		var grip_local_pos = main_grip.position

		# Apply rotation offset first (e.g., rotate pistol to point forward)
		# Pistol barrel points -Z by default, so rotate 180° around Y to point +Z (forward)
		var rotation_offset = Basis()
		rotation_offset = rotation_offset.rotated(Vector3.UP, deg_to_rad(180))  # Flip 180 degrees to point forward
		transform.basis = rotation_offset

		# Position weapon so grip point is at hand origin (0,0,0 in hand local space)
		# This means weapon position = -grip_offset rotated by weapon basis
		var grip_offset_rotated = transform.basis * grip_local_pos
		transform.origin = -grip_offset_rotated

		# Add weapon-specific positioning offset for better feel
		# After -90° pitch rotation, weapon points forward along Z-
		# In weapon's local space: X+ = right, X- = left, Z+ = forward (toward barrel), Z- = backward
		var weapon_offset = Vector3.ZERO
		if weapon_type == WeaponType.PISTOL:
			# Move pistol forward and to the left in local space
			weapon_offset = Vector3(-0.03, 0.0, 0.08)  # 3cm left, 8cm forward
		elif weapon_type == WeaponType.RIFLE:
			# Rifles need more forward offset
			weapon_offset = Vector3(-0.02, 0.0, 0.12)  # 2cm left, 12cm forward

		# Apply offset in local space
		transform.origin += weapon_offset

		print("Weapon ", weapon_name, " equipped with grip offset: ", transform.origin, " (type offset applied)")
	else:
		# No grip point - just place at hand origin with rotation offset
		transform.origin = Vector3(-0.03, 0.0, 0.08)  # Default pistol offset (forward and left)
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
	gravity_scale = 2.0  # Use stronger gravity for dropped weapons
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

func enter_ragdoll_mode():
	"""Enable ragdoll mode - weapon stays in hand but monitors for collisions to drop"""
	if not is_equipped:
		return

	is_in_ragdoll_mode = true
	should_monitor_collisions = true

	# Enable physics but keep parented to hand
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = false  # Allow movement
	gravity_scale = 0.0  # No gravity while in hand

	# Enable collision detection but don't collide with holder's bones
	collision_layer = 4  # Weapon layer
	collision_mask = 1   # Only collide with world (not character bones on layer 2)

	print("Weapon ", weapon_name, " entered ragdoll mode - will drop on collision")

func exit_ragdoll_mode():
	"""Exit ragdoll mode - return to normal equipped state"""
	if not is_equipped:
		return

	is_in_ragdoll_mode = false
	should_monitor_collisions = false

	# Return to normal equipped state
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	gravity_scale = 0.0
	collision_layer = 0  # No collisions when equipped normally
	collision_mask = 0

	print("Weapon ", weapon_name, " exited ragdoll mode")

func _on_body_entered(body: Node):
	"""Handle collision detection for ragdoll drop"""
	# Only process if we're in ragdoll mode and monitoring collisions
	if not should_monitor_collisions or not is_in_ragdoll_mode:
		return

	# Don't drop if we hit the holder's bones (PhysicalBone3D)
	if body is PhysicalBone3D:
		# Check if this is our holder's bone
		if holder and _is_part_of_character(body, holder):
			return  # Ignore collision with our own character's bones

	# Hit something else (world, other objects) - drop the weapon!
	print("Weapon ", weapon_name, " collided with ", body.name, " - dropping!")
	_drop_from_ragdoll()

func _is_part_of_character(bone: PhysicalBone3D, character: Node) -> bool:
	"""Check if a PhysicalBone3D belongs to the character"""
	var current = bone.get_parent()
	while current:
		if current == character:
			return true
		current = current.get_parent()
	return false

func _drop_from_ragdoll():
	"""Drop weapon from hand during ragdoll"""
	should_monitor_collisions = false  # Stop checking collisions
	is_in_ragdoll_mode = false

	# Store world transform before unparenting
	var world_pos = global_position
	var world_rot = global_rotation
	var world_vel = linear_velocity  # Preserve velocity

	# Detach from hand
	if get_parent():
		get_parent().remove_child(self)

	# Add to world root
	if holder and holder.get_tree():
		holder.get_tree().root.add_child(self)

	# Restore world transform
	global_position = world_pos
	global_rotation = world_rot

	# Enable full physics with stronger gravity for realistic fall
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = false
	gravity_scale = 2.0  # Stronger gravity for more realistic weapon drop
	collision_layer = 4  # Weapon layer
	collision_mask = 1   # Collide with world

	# Apply some bounce/friction properties for realistic impact
	physics_material_override = PhysicsMaterial.new() if not physics_material_override else physics_material_override
	if physics_material_override:
		physics_material_override.bounce = 0.2  # Slight bounce
		physics_material_override.friction = 0.6  # Moderate friction

	# Apply velocity to continue motion
	linear_velocity = world_vel

	# Mark as unequipped
	is_equipped = false
	holder = null

	print("Weapon ", weapon_name, " dropped from ragdoll at ", global_position)
