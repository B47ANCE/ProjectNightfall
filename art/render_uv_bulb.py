"""Offline preview of original exported geometry, not a game screenshot."""
from pathlib import Path
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT/'models/UVBulb-v1.fbx'))
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=32
scene.render.resolution_x=512
scene.render.resolution_y=512
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.image_settings.color_mode='RGBA'
scene.render.film_transparent=True
obj=next(o for o in scene.objects if o.type=='MESH')
center=sum((obj.matrix_world @ Vector(c) for c in obj.bound_box),Vector())/8
size=max(obj.dimensions)
bpy.ops.object.camera_add(location=center+Vector((2,-3,2))*size)
camera=bpy.context.object
camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO'
camera.data.ortho_scale=size*1.4
camera.data.clip_start=.0001
scene.camera=camera
for offset,energy in [((2,-3,4),.4),((-2,1,2),.2)]:
    bpy.ops.object.light_add(type='AREA',location=center+Vector(offset)*size)
    lamp=bpy.context.object
    lamp.data.energy=energy
    lamp.data.size=size*3
    lamp.rotation_euler=(center-lamp.location).to_track_quat('-Z','Y').to_euler()
scene.world=bpy.data.worlds.new('Preview world')
scene.world.color=(.25,.25,.25)
scene.render.filepath=str(ROOT/'models/UVBulb-preview.png')
bpy.ops.render.render(write_still=True)
