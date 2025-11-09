# Godot 4.5 FPS/TPS Character Controller with IK and Ragdoll

A complete character controller system for Godot 4.5 featuring:
- First-person and third-person cameras
- Head tracking/aiming system
- IK (Inverse Kinematics) for limbs
- Ragdoll physics system

## Features

### 1. Dual Camera System
- **FPS Camera**: Positioned at the character's head bone with realistic head movement
- **TPS Camera**: Third-person camera with collision detection and smooth following
- Toggle between cameras with `V` key

### 2. Head Aiming System
- Head bone rotates based on camera pitch for realistic aiming
- Configurable rotation limits (±60° pitch, ±70° yaw by default)
- Smooth interpolation for natural movement

### 3. IK System
- Ready-to-use IK targets for:
  - Left Hand (Red)
  - Right Hand (Green)
  - Left Foot (Blue)
  - Right Foot (Yellow)
- Targets can be positioned in the editor or via code
- Useful for weapon holding, grabbing objects, procedural foot placement, etc.

### 4. Ragdoll Physics
- Physical bones for realistic ragdoll simulation
- Toggle ragdoll mode with `R` key
- Configured for all major body parts:
  - Spine, chest, neck, head
  - Arms and hands
  - Legs and feet

## Controls

| Key/Input | Action |
|-----------|--------|
| W/A/S/D | Move |
| Space | Jump |
| Shift | Sprint |
| Mouse | Look around |
| V | Toggle Camera (FPS/TPS) |
| R | Toggle Ragdoll |
| ESC | Release/Capture mouse |

## Project Structure

```
fpsikanimragdoll/
├── character.gltf           # Character model
├── buffer.bin               # Model data
├── project.godot            # Godot project configuration
├── character_controller.gd  # Main character controller
├── fps_camera.gd            # First-person camera
├── tps_camera.gd            # Third-person camera
├── ik_target.gd             # IK target helper
├── ragdoll_setup.gd         # Ragdoll setup helper
├── character.tscn           # Character scene
└── world.tscn               # Test world scene
```

## Character Skeleton

The character uses a standard humanoid skeleton with bones:
- Hips, Spine, Chest, Upper_Chest, Neck, Head
- L/R Shoulder, Upper_Arm, Lower_Arm, Hand
- L/R Upper_Leg, Lower_Leg, Foot, Toes
- Full finger bones for detailed hand animation

## Setup Instructions

### Using in Godot Editor

1. Open the project in Godot 4.5
2. The main scene is `world.tscn`
3. Run the project to test the character

### Customizing IK Targets

1. Open `character.tscn`
2. Expand the `IKTargets` node
3. Position the target nodes as needed
4. The character controller will automatically use them

### Adding IK to Skeleton

To enable IK on the skeleton:

1. Select the Model node in the character scene
2. Find the Skeleton3D node
3. Add SkeletonIK3D nodes as children:
   - Name them: LeftHandIK, RightHandIK, LeftFootIK, RightFootIK
4. Configure each SkeletonIK3D:
   - Set Root Bone (e.g., "characters3d.com___L_Shoulder")
   - Set Tip Bone (e.g., "characters3d.com___L_Hand")
   - Set Target Node to the corresponding IK target
5. Link them in the character controller's exported variables

### Enabling Ragdoll

The `ragdoll_setup.gd` script provides a helper function to automatically create PhysicalBone3D nodes:

```gdscript
# In editor or at runtime:
var skeleton = $Model/Skeleton3D
var simulator = RagdollSetup.setup_ragdoll(skeleton)
```

Or manually:
1. Select the Skeleton3D node
2. Right-click → "Create Physical Skeleton"
3. Adjust collision shapes as needed
4. Add a PhysicalBoneSimulator3D node as a child of Skeleton3D

## Customization

### Movement Settings

Edit `character_controller.gd` exports:
- `walk_speed`: Default walking speed (5.0)
- `sprint_speed`: Sprint speed (8.0)
- `jump_velocity`: Jump strength (4.5)
- `mouse_sensitivity`: Mouse look sensitivity (0.003)

### Camera Settings

**FPS Camera** (`fps_camera.gd`):
- `head_offset`: Offset from head bone for eye position
- `fov`: Field of view (90°)

**TPS Camera** (`tps_camera.gd`):
- `follow_distance`: Distance from character (3.0)
- `follow_height`: Height above character (1.5)
- `camera_smoothness`: Camera movement smoothness (10.0)

### Head Look Settings

In `character_controller.gd`:
- `max_head_rotation_x`: Max pitch rotation (60°)
- `max_head_rotation_y`: Max yaw rotation (70°)
- `head_rotation_speed`: Rotation interpolation speed (5.0)

## Technical Details

### FPS Camera Implementation
- Attached to character head bone in world space
- Follows head bone global transform
- Uses bone global pose for accurate positioning
- Independent rotation control for aiming

### Head Aiming
- Modifies head bone pose in real-time
- Uses quaternion interpolation for smooth rotation
- Clamped to prevent unnatural head positions
- Works in both FPS and TPS modes

### TPS Camera
- Raycasts to prevent wall clipping
- Smooth distance adjustment on collision
- Always looks at character position
- Collision margin prevents camera popping

### Ragdoll System
- Uses PhysicalBone3D for each major bone
- Capsule shapes for limbs, sphere for joints
- Realistic mass distribution
- Toggleable at runtime

## License

This project uses a character model from Characters3D.com.
Scripts are provided as-is for educational and commercial use.

## Troubleshooting

**Camera not following head:**
- Ensure skeleton reference is set in FPS camera
- Check bone name matches: "characters3d.com___Head"

**Ragdoll not working:**
- Ensure PhysicalBone3D nodes are created on skeleton
- Check that PhysicalBoneSimulator3D exists
- Verify collision shapes are properly configured

**IK not affecting limbs:**
- Create SkeletonIK3D nodes on the skeleton
- Set correct root and tip bones
- Link targets to SkeletonIK3D nodes
- Call `start()` on SkeletonIK3D nodes

**Character falling through floor:**
- Ensure ground has StaticBody3D with CollisionShape3D
- Check character CollisionShape3D is configured
- Verify character is CharacterBody3D type
