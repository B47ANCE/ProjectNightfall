"""Original UV-bulb source geometry; never writes runtime or frozen packages."""
from pathlib import Path
import math
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'models'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

def lathe(name, profile, color):
    segments = 32
    vertices = [(radius*math.cos(i*math.tau/segments),
                 radius*math.sin(i*math.tau/segments),z)
                for radius,z in profile for i in range(segments)]
    faces = []
    for ring in range(len(profile)-1):
        for i in range(segments):
            j=(i+1)%segments
            faces.append((ring*segments+i,ring*segments+j,
                          (ring+1)*segments+j,(ring+1)*segments+i))
    faces.extend([tuple(reversed(range(segments))),
                  tuple((len(profile)-1)*segments+i for i in range(segments))])
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    material=bpy.data.materials.new(name+' material')
    material.use_nodes=True
    material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=color
    obj.data.materials.append(material)
    for polygon in mesh.polygons:
        polygon.use_smooth=len(polygon.vertices)==4
    return obj

# Editable visual proportions, not a socket compatibility or power contract.
lathe('Contact',[(.004,0),(.004,.002)],(.12,.12,.12,1))
lathe('Insulator',[(.004,.002),(.011,.005)],(.025,.025,.025,1))
profile=[(.011,.005)]
for turn in range(5):
    z=.005+turn*.0035
    profile.extend([(.012,z+.0005),(.013,z+.0015),(.012,z+.003)])
profile.append((.011,.024))
lathe('Metal base',profile,(.5,.52,.55,1))
envelope=lathe('UV envelope',[(.010,.024),(.011,.032),(.019,.042),
                    (.027,.053),(.030,.065),(.028,.077),
                    (.022,.087),(.012,.093),(.001,.096)],(.025,.025,.32,1))
# Refine the envelope's coarse lathed silhouette before exporting; smoothing
# normals alone cannot remove the visible corners between profile rings.
bpy.context.view_layer.objects.active=envelope
smooth=envelope.modifiers.new('Envelope curvature','SUBSURF')
smooth.levels=1
bpy.ops.object.modifier_apply(modifier=smooth.name)
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
bpy.ops.object.join()
obj=bpy.context.object
obj.name='PN_UVBulb_Source'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=.03)
bpy.ops.object.mode_set(mode='OBJECT')
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=16
atlas=bpy.data.images.new('PN_UVBulb_Albedo',width=256,height=256,alpha=True)
for material in obj.data.materials:
    node=material.node_tree.nodes.new('ShaderNodeTexImage')
    node.image=atlas
    material.node_tree.nodes.active=node
scene.render.bake.use_pass_direct=False
scene.render.bake.use_pass_indirect=False
scene.render.bake.use_pass_color=True
scene.render.bake.margin=4
bpy.ops.object.bake(type='DIFFUSE')
atlas.filepath_raw=str(OUT/'UVBulb-albedo.png')
atlas.file_format='PNG'
atlas.save()
material=bpy.data.materials.new('PN_UVBulb_Atlas')
material.use_nodes=True
texture=material.node_tree.nodes.new('ShaderNodeTexImage')
texture.image=atlas
shader=material.node_tree.nodes.get('Principled BSDF')
material.node_tree.links.new(texture.outputs['Color'],shader.inputs['Base Color'])
obj.data.materials.clear()
obj.data.materials.append(material)
for polygon in obj.data.polygons:
    polygon.material_index=0
expected=len(obj.data.vertices)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'UVBulb-v1.blend'))
bpy.ops.export_scene.fbx(filepath=str(OUT/'UVBulb-v1.fbx'),use_selection=True,
                        object_types={'MESH'},bake_anim=False,add_leaf_bones=False)
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.fbx(filepath=str(OUT/'UVBulb-v1.fbx'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(meshes)==1
obj=meshes[0]
assert len(obj.data.vertices)==expected
assert len(obj.data.uv_layers)==1
assert all(abs(v)<1e-6 for v in obj.location)
floor=min((obj.matrix_world @ Vector(c)).z for c in obj.bound_box)
assert abs(floor)<1e-6
assert len(obj.data.materials)==1
material=obj.data.materials[0]
nodes=[n for n in material.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
assert any(Path(bpy.path.abspath(n.image.filepath)).resolve()==(OUT/'UVBulb-albedo.png').resolve()
           and tuple(n.image.size)==(256,256) for n in nodes)
shader=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
assert shader.inputs['Base Color'].is_linked
print(f'PASS UV bulb source round trip: {expected} vertices; UV, atlas reference and floor origin preserved; native rendering UNVERIFIED')
