# Setup Instructions for FPS/TPS Character Controller

## Current Status

The character controller is fully functional with automatic setup!

### What's Working
- ✅ FPS camera with head tracking
- ✅ TPS camera with collision detection
- ✅ Character movement (WASD)
- ✅ Camera toggle (O key)
- ✅ Mouse look
- ✅ Head/neck bone tracking
- ✅ **Ragdoll physics (auto-created at runtime)**

### What Needs Setup
- ⚠️ SkeletonIK3D nodes (for IK functionality) - optional
- ⚠️ Finger bones for ragdoll (waiting for bone names from user)

## Quick Setup with Editor Script

### Option 1: Automatic Setup (Recommended)

1. Open `character.tscn` in Godot
2. Select the script `setup_character_complete.gd` in the FileSystem
3. Run it (File → Run or Ctrl+Shift+X)
4. Save the scene (Ctrl+S)
5. Test the game!

### Option 2: Manual Setup

#### Setting up Physical Bones (Ragdoll)

1. Open `character.tscn`
2. Navigate to: Character → Model → Skeleton3D
3. **Right-click** on "Skeleton3D"
4. Select **"Create Physical Skeleton"**
5. Godot will create all PhysicalBone3D nodes automatically
6. Save the scene

**Test:** Press R key in-game to toggle ragdoll

#### Setting up Inverse Kinematics (IK)

The IK system requires SkeletonIK3D nodes to be children of the Skeleton3D node.

1. Open `character.tscn`
2. Navigate to: Character → Model → Skeleton3D
3. For each limb, add a SkeletonIK3D node:
   - Right-click Skeleton3D → Add Child Node → SkeletonIK3D

4. Configure each SkeletonIK3D node:

**Left Hand IK:**
- Name: `LeftHandIK`
- Root Bone: `characters3d.com___Left_arm`
- Tip Bone: `characters3d.com___Left_hand`
- Target: `../../IKTargets/LeftHandTarget`

**Right Hand IK:**
- Name: `RightHandIK`
- Root Bone: `characters3d.com___Right_arm`
- Tip Bone: `characters3d.com___Right_hand`
- Target: `../../IKTargets/RightHandTarget`

**Left Foot IK:**
- Name: `LeftFootIK`
- Root Bone: `characters3d.com___Left_leg`
- Tip Bone: `characters3d.com___Left_foot`
- Target: `../../IKTargets/LeftFootTarget`

**Right Foot IK:**
- Name: `RightFootIK`
- Root Bone: `characters3d.com___Right_leg`
- Tip Bone: `characters3d.com___Right_foot`
- Target: `../../IKTargets/RightFootTarget`

5. In the Character node (root), set the IK references:
   - left_hand_ik: `Model/Skeleton3D/LeftHandIK`
   - right_hand_ik: `Model/Skeleton3D/RightHandIK`
   - left_foot_ik: `Model/Skeleton3D/LeftFootIK`
   - right_foot_ik: `Model/Skeleton3D/RightFootIK`

6. Save the scene

**Test:** Press I key in-game to toggle IK

## Debug Output

When you run the game, the console will show:
- All skeleton bones (with IDs)
- Camera setup status
- Toggle states for camera/IK/ragdoll

Check the console for any errors or missing references.

## Controls

- **WASD** - Move
- **Space** - Jump
- **Shift** - Sprint
- **Mouse** - Look around
- **O** - Toggle FPS/TPS camera
- **I** - Toggle IK
- **R** - Toggle ragdoll
- **Escape** - Release/capture mouse

## Common Issues

### Camera toggle doesn't work
- Check console for "ERROR: One or both cameras are null!"
- Make sure fps_camera and tps_camera are set in Character node

### Ragdoll doesn't activate
- Check console for "Found 0 physical bones"
- Use "Create Physical Skeleton" in Skeleton3D context menu
- Or run the setup script

### IK doesn't work
- Check console for IK node references (will be null if not set)
- Make sure SkeletonIK3D nodes are created and configured
- Verify bone names match exactly (use debug output)

## Bone Names Reference

The debug output will list all bones. Common important bones:
- Head: `characters3d.com___Head`
- Neck: `characters3d.com___Neck`
- Arms: `characters3d.com___Left_arm`, `characters3d.com___Right_arm`
- Hands: `characters3d.com___Left_hand`, `characters3d.com___Right_hand`
- Legs: `characters3d.com___Left_leg`, `characters3d.com___Right_leg`
- Feet: `characters3d.com___Left_foot`, `characters3d.com___Right_foot`

**Note:** Bone names may vary. Check the debug console output for the exact names in your skeleton.
