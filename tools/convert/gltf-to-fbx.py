# A glTF from ew-to-gltf.ts, as FBX for XCOM 2's editor, with a picture of it to
# check by eye: Blender, without a window.
#
#   blender -b -P tools/convert/gltf-to-fbx.py -- in.glb out.fbx [preview.png [animation [frame]]]
#
# LWX2_ANIMS (a comma-separated list) keeps only those animations: the editor's
# import of all of them at once crashed (an assertion in its threading code).
#
# The FBX keeps Unreal's units (1 Blender unit = 1 Unreal unit, scale 1, no unit
# conversion), Z up and X forward as Unreal has them, the skeleton without an
# armature root bone of Blender's own ("Armature" nodes are not written as bones).
import sys, math, bpy, mathutils

args = sys.argv[sys.argv.index('--') + 1:]
src, dst = args[0], args[1]
preview = args[2] if len(args) > 2 else None
anim = args[3] if len(args) > 3 else None
frame = int(args[4]) if len(args) > 4 else 10

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
# The unit's mesh: the largest (the importer adds small shapes for showing bones).
mesh = max((o for o in bpy.data.objects if o.type == 'MESH'), key=lambda o: len(o.data.vertices))
for o in [o for o in bpy.data.objects if o.type == 'MESH' and o is not mesh]:
    bpy.data.objects.remove(o)
print('armature', arm.name, len(arm.data.bones), 'bones; mesh', mesh.name, len(mesh.data.vertices), 'vertices; actions', len(bpy.data.actions))
# The glTF importer names each action "<animation>_<mesh>": back to EW's own names
# ("AC_NO_IdleA"), which XCOM 2's sequences will be called.
suffix = '_' + mesh.name.split('.')[0]
for act in bpy.data.actions:
    if act.name.endswith(suffix):
        act.name = act.name[:-len(suffix)]
import os
keep = [a for a in os.environ.get('LWX2_ANIMS', '').split(',') if a]
if keep:
    for act in [a for a in bpy.data.actions if a.name not in keep]:
        bpy.data.actions.remove(act)
    print('animations kept:', sorted(a.name for a in bpy.data.actions))

if anim and arm.animation_data is not None:
    act = bpy.data.actions.get(anim) or next((a for a in bpy.data.actions if a.name.startswith(anim)), None)
    if act:
        arm.animation_data.action = act
        bpy.context.scene.frame_set(frame)
        print('posed in', act.name, 'frame', frame)
else:
    if arm.animation_data is not None:
        arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = mathutils.Matrix.Identity(4)

if preview:
    scene = bpy.context.scene
    lo = [min((mesh.matrix_world @ mathutils.Vector(c))[k] for c in mesh.bound_box) for k in range(3)]
    hi = [max((mesh.matrix_world @ mathutils.Vector(c))[k] for c in mesh.bound_box) for k in range(3)]
    centre = mathutils.Vector([(a + b) / 2 for a, b in zip(lo, hi)])
    size = max(b - a for a, b in zip(lo, hi))
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    scene.collection.objects.link(cam)
    cam.location = centre + mathutils.Vector((size * 1.2, -size * 1.6, size * 0.5))
    cam.rotation_euler = (centre - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 45
    scene.camera = cam
    sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
    sun.data.energy = 3
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(30))
    scene.collection.objects.link(sun)
    scene.world = bpy.data.worlds.new('w')
    scene.world.color = (0.25, 0.25, 0.28)
    # Cycles on the CPU: no GPU needed.
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 24
    scene.cycles.use_denoising = False
    scene.render.resolution_x, scene.render.resolution_y = 900, 900
    scene.render.filepath = preview
    bpy.ops.render.render(write_still=True)

# Unreal reads FBX in centimetres and Blender writes metres: 1 glTF unit (an Unreal unit, read
# by Blender as a metre) would arrive as 100. Scaled back by 0.01 (seen in the editor: the
# pelvis at 9264 instead of 92.6).
# The armature object is named Root and exported as a root node: with the name of a bone EW's
# skeletons do not have, it does not clash with RigRoot.
arm.name = 'Root'
# Blender names each FBX take "<object>|<action>": the action's name alone.
import io_scene_fbx.export_fbx_bin as fbx_bin
_name = fbx_bin.get_blenderID_name
fbx_bin.get_blenderID_name = lambda bid: bid[1].name if isinstance(bid, tuple) and len(bid) == 2 and isinstance(bid[1], bpy.types.Action) else _name(bid)
bpy.ops.export_scene.fbx(
    filepath=dst,
    apply_unit_scale=False,
    global_scale=0.01,
    axis_forward='X',
    axis_up='Z',
    add_leaf_bones=False,
    primary_bone_axis='X',
    secondary_bone_axis='Y',
    bake_anim=True,
    bake_anim_use_all_actions=True,
    bake_anim_use_nla_strips=False,
    mesh_smooth_type='FACE',
    use_armature_deform_only=True,
    armature_nodetype='NULL',
    # The textures inside the FBX, for the editor to import with the mesh.
    path_mode='COPY',
    embed_textures=True,
)
print('wrote', dst)
