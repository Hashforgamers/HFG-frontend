"""HASH RUSH asset pipeline.

Generates every original 3D model the game ships with and exports them as GLB:

    blender --background --python tools/build_assets.py            # models
    blender --background --python tools/build_assets.py -- --preview  # + PNG contact sheets

Each character is a handful of rigid *parts* (torso, head, armL, ...). A part's
object origin is its joint pivot, so the game can animate it by rotating the
part: on the GPU for the instanced crowds, per node for the bosses. Colours are
plain Principled materials; the loader bakes them into vertex colours so a whole
crowd is one draw call.

Blender is Z-up and the models face -Y; the glTF exporter converts that to
Y-up, facing +Z.
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "public", "models")
PREVIEW = os.path.join(ROOT, "tools", "preview")

LOD = 0  # 0 = full detail, 1 = low (set per export)

# name: (base colour, metallic, roughness, emission strength)
MATERIALS = {
    "blue": ((0.07, 0.33, 0.95), 0.55, 0.38, 0.0),
    "blue_dark": ((0.03, 0.10, 0.36), 0.6, 0.45, 0.0),
    "blue_light": ((0.42, 0.68, 1.0), 0.4, 0.35, 0.0),
    "white": ((0.90, 0.94, 1.0), 0.2, 0.4, 0.0),
    "cyan_emit": ((0.25, 0.95, 1.0), 0.0, 0.3, 3.0),
    "red": ((0.86, 0.10, 0.10), 0.5, 0.42, 0.0),
    "red_dark": ((0.34, 0.03, 0.05), 0.6, 0.5, 0.0),
    "black": ((0.035, 0.035, 0.05), 0.6, 0.4, 0.0),
    "steel": ((0.36, 0.39, 0.45), 0.85, 0.35, 0.0),
    "steel_dark": ((0.13, 0.14, 0.18), 0.85, 0.45, 0.0),
    "red_emit": ((1.0, 0.16, 0.10), 0.0, 0.3, 3.0),
    "orange_emit": ((1.0, 0.50, 0.08), 0.0, 0.3, 3.5),
    "purple": ((0.27, 0.10, 0.52), 0.65, 0.32, 0.0),
    "purple_dark": ((0.08, 0.04, 0.18), 0.7, 0.4, 0.0),
    "violet_emit": ((0.72, 0.35, 1.0), 0.0, 0.3, 3.5),
    "gold": ((0.95, 0.68, 0.18), 0.9, 0.3, 0.0),
    "yellow": ((0.98, 0.78, 0.10), 0.3, 0.5, 0.0),
}


def material(name):
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    color, metallic, rough, emit = MATERIALS[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = rough
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit
    return mat


# --- shape helpers: each returns (bmesh, material name) ----------------------


def _place(bm, loc, rot, scale=(1, 1, 1)):
    m = Matrix.Translation(Vector(loc)) @ Euler(rot).to_matrix().to_4x4() @ Matrix.Diagonal((*scale, 1.0))
    bm.transform(m)
    return bm


def box(mat, size, loc, rot=(0, 0, 0), bevel=0.0, taper=1.0, taper_y=None):
    """Rounded box. `taper` scales the top face in X (and Y unless taper_y)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    ty = taper if taper_y is None else taper_y
    for v in bm.verts:
        if v.co.z > 0:
            v.co.x *= taper
            v.co.y *= ty
    bm.transform(Matrix.Diagonal((*size, 1.0)))
    if bevel > 0 and LOD == 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=1, affect="EDGES", profile=0.5)
    return _place(bm, loc, rot), mat


def sphere(mat, radius, loc, scale=(1, 1, 1), rot=(0, 0, 0), seg=12, rings=8):
    bm = bmesh.new()
    if LOD:
        seg, rings = max(6, seg // 2), max(4, rings // 2)
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=radius)
    return _place(bm, loc, rot, scale), mat


def cyl(mat, r1, r2, depth, loc, rot=(0, 0, 0), seg=12):
    """Cylinder / cone along local Z (r1 at the bottom, r2 at the top)."""
    bm = bmesh.new()
    if LOD:
        seg = max(6, seg // 2)
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r1, radius2=max(r2, 0.0005), depth=depth)
    return _place(bm, loc, rot), mat


def torus(mat, major, minor, loc, rot=(0, 0, 0), seg=20, tube=6):
    bm = bmesh.new()
    if LOD:
        seg, tube = seg // 2, 4
    for i in range(seg):
        a = 2 * math.pi * i / seg
        for j in range(tube):
            b = 2 * math.pi * j / tube
            r = major + minor * math.cos(b)
            bm.verts.new((r * math.cos(a), r * math.sin(a), minor * math.sin(b)))
    bm.verts.ensure_lookup_table()
    for i in range(seg):
        for j in range(tube):
            a, b = i * tube + j, i * tube + (j + 1) % tube
            c, d = ((i + 1) % seg) * tube + (j + 1) % tube, ((i + 1) % seg) * tube + j
            bm.faces.new((bm.verts[a], bm.verts[d], bm.verts[c], bm.verts[b]))
    return _place(bm, loc, rot), mat


def mirror(pieces):
    """Pieces mirrored across X (for the opposite limb)."""
    out = []
    for bm, mat in pieces:
        c = bm.copy()
        c.transform(Matrix.Diagonal((-1, 1, 1, 1)))
        bmesh.ops.reverse_faces(c, faces=list(c.faces))
        out.append((c, mat))
    return out


def part(name, pivot, pieces):
    """Join pieces into one object whose origin is the joint `pivot`."""
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    slots = {}
    out = bmesh.new()
    for bm, mat in pieces:
        if mat not in slots:
            slots[mat] = len(slots)
            mesh.materials.append(material(mat))
        tmp = bpy.data.meshes.new("tmp")
        for f in bm.faces:
            f.material_index = slots[mat]
        bm.to_mesh(tmp)  # pieces stay alive: mirror() may reuse them
        out.from_mesh(tmp)
        # from_mesh keeps material_index of the source faces
        bpy.data.meshes.remove(tmp)
    out.transform(Matrix.Translation(-Vector(pivot)))
    bmesh.ops.recalc_face_normals(out, faces=list(out.faces))
    # smooth shading with hard creases above ~38 degrees
    for f in out.faces:
        f.smooth = True
    for e in out.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(38):
            e.smooth = False
    out.to_mesh(mesh)
    out.free()
    obj.location = pivot
    return obj


def X(a):  # rotation that lays a Z-cylinder along X
    return (0, math.radians(90), 0)


def Y(a=90):  # rotation that lays a Z-cylinder along Y
    return (math.radians(a), 0, 0)


# --- characters ---------------------------------------------------------------


def blue_bot():
    """Hashling: the player's unit. ~1.2 m tall, oversized helmet, cyan visor."""
    leg = [
        box("blue_dark", (0.13, 0.15, 0.22), (0.14, 0, 0.20), bevel=0.03),
        box("white", (0.16, 0.24, 0.09), (0.14, -0.035, 0.045), bevel=0.03),
    ]
    arm = [
        sphere("blue_light", 0.085, (0.285, 0, 0.58)),
        box("blue", (0.10, 0.11, 0.22), (0.30, 0, 0.44), bevel=0.03),
        sphere("white", 0.075, (0.30, 0, 0.31)),
    ]
    part("legR", (0.14, 0, 0.30), leg)
    part("legL", (-0.14, 0, 0.30), mirror(leg))
    part("armR", (0.285, 0, 0.58), arm)
    part("armL", (-0.285, 0, 0.58), mirror(arm))
    part("torso", (0, 0, 0.30), [
        box("blue", (0.44, 0.32, 0.36), (0, 0, 0.47), bevel=0.07, taper=0.86),
        box("cyan_emit", (0.18, 0.03, 0.07), (0, -0.155, 0.50)),
        box("blue_dark", (0.28, 0.12, 0.24), (0, 0.19, 0.48), bevel=0.03),
        box("blue_dark", (0.30, 0.24, 0.06), (0, 0, 0.30), bevel=0.02),
    ])
    part("head", (0, 0, 0.66), [
        sphere("blue", 0.29, (0, 0, 0.90), scale=(1.06, 1.0, 0.92), seg=14, rings=9),
        sphere("cyan_emit", 0.21, (0, -0.19, 0.885), scale=(1.1, 0.62, 0.50)),
        box("blue_light", (0.07, 0.40, 0.06), (0, 0.02, 1.155), bevel=0.02),
        cyl("blue_dark", 0.085, 0.085, 0.06, (0.305, 0, 0.89), rot=X(0)),
        cyl("blue_dark", 0.085, 0.085, 0.06, (-0.305, 0, 0.89), rot=X(0)),
        cyl("white", 0.012, 0.012, 0.16, (0.19, 0.05, 1.20), seg=6),
        sphere("cyan_emit", 0.032, (0.19, 0.05, 1.29), seg=6, rings=4),
    ])


def red_grunt():
    """Basic enemy: angular helmet, dark faceplate, slanted red eyes."""
    leg = [
        box("red_dark", (0.13, 0.15, 0.22), (0.14, 0, 0.20), bevel=0.02),
        box("black", (0.17, 0.25, 0.09), (0.14, -0.04, 0.045), bevel=0.02, taper=0.8),
    ]
    arm = [
        cyl("red", 0.13, 0.0, 0.20, (0.31, 0, 0.64), rot=(0, math.radians(35), 0), seg=6),
        box("red_dark", (0.10, 0.11, 0.22), (0.31, 0, 0.44), bevel=0.02),
        box("black", (0.13, 0.14, 0.10), (0.31, -0.01, 0.30), bevel=0.02),
    ]
    part("legR", (0.14, 0, 0.30), leg)
    part("legL", (-0.14, 0, 0.30), mirror(leg))
    part("armR", (0.29, 0, 0.58), arm)
    part("armL", (-0.29, 0, 0.58), mirror(arm))
    part("torso", (0, 0, 0.30), [
        box("red", (0.36, 0.30, 0.38), (0, 0, 0.48), bevel=0.04, taper=1.32),
        box("black", (0.20, 0.03, 0.14), (0, -0.165, 0.50), taper=1.3),
        box("red_emit", (0.08, 0.03, 0.05), (0, -0.175, 0.51)),
        box("red_dark", (0.26, 0.22, 0.07), (0, 0, 0.30), bevel=0.02),
    ])
    horn = [cyl("black", 0.055, 0.0, 0.26, (0.22, 0.02, 1.06), rot=(0, math.radians(28), 0), seg=6)]
    part("head", (0, 0, 0.67), [
        box("red", (0.44, 0.40, 0.34), (0, 0, 0.86), bevel=0.05, taper=0.72),
        box("black", (0.36, 0.05, 0.17), (0, -0.19, 0.84), taper=0.85),
        box("red_emit", (0.11, 0.03, 0.035), (0.085, -0.215, 0.855), rot=(0, math.radians(-16), 0)),
        box("red_emit", (0.11, 0.03, 0.035), (-0.085, -0.215, 0.855), rot=(0, math.radians(16), 0)),
        box("red_dark", (0.07, 0.44, 0.08), (0, 0.0, 1.03), bevel=0.02, taper_y=0.6, taper=1.0),
        *horn, *mirror(horn),
    ])


def red_brute():
    """Heavy enemy: wide armoured shoulders, tiny head, big fists. Scaled up for giants."""
    leg = [
        box("red_dark", (0.17, 0.19, 0.22), (0.17, 0, 0.19), bevel=0.03),
        box("black", (0.22, 0.30, 0.10), (0.17, -0.04, 0.05), bevel=0.03, taper=0.8),
    ]
    arm = [
        box("red", (0.26, 0.30, 0.20), (0.44, 0, 0.70), bevel=0.04, taper=0.7),
        cyl("black", 0.05, 0.0, 0.16, (0.46, 0, 0.86), seg=6),
        box("red_dark", (0.14, 0.15, 0.24), (0.45, 0, 0.50), bevel=0.03),
        box("black", (0.21, 0.22, 0.19), (0.45, -0.01, 0.31), bevel=0.04),
    ]
    part("legR", (0.17, 0, 0.30), leg)
    part("legL", (-0.17, 0, 0.30), mirror(leg))
    part("armR", (0.40, 0, 0.66), arm)
    part("armL", (-0.40, 0, 0.66), mirror(arm))
    part("torso", (0, 0, 0.30), [
        box("red", (0.50, 0.38, 0.44), (0, 0, 0.52), bevel=0.05, taper=1.42),
        box("black", (0.30, 0.04, 0.20), (0, -0.20, 0.54), taper=1.3),
        box("red_emit", (0.20, 0.03, 0.04), (0, -0.225, 0.59)),
        box("red_emit", (0.14, 0.03, 0.04), (0, -0.225, 0.51)),
        box("red_dark", (0.36, 0.28, 0.08), (0, 0, 0.30), bevel=0.02),
        box("steel_dark", (0.30, 0.14, 0.26), (0, 0.24, 0.56), bevel=0.03),
    ])
    part("head", (0, 0, 0.76), [
        box("red_dark", (0.30, 0.30, 0.24), (0, -0.02, 0.87), bevel=0.04, taper=0.8),
        box("black", (0.25, 0.04, 0.10), (0, -0.165, 0.87)),
        box("red_emit", (0.20, 0.03, 0.03), (0, -0.185, 0.875)),
        cyl("black", 0.06, 0.0, 0.24, (0, 0.02, 1.08), seg=6),
    ])


# --- bosses (modelled at game scale, ~7 m) -----------------------------------


def boss_titan():
    """Iron Titan: armoured giant with heavy fists."""
    leg = [
        box("steel", (1.0, 1.1, 1.5), (0.95, 0, 1.75), bevel=0.12, taper=0.8),
        cyl("steel_dark", 0.5, 0.5, 0.9, (0.95, 0, 1.1), rot=X(0)),
        box("steel_dark", (0.9, 1.0, 0.8), (0.95, 0, 0.75), bevel=0.1),
        box("steel", (1.2, 1.7, 0.45), (0.95, -0.25, 0.23), bevel=0.1, taper=0.82),
        box("red_emit", (0.7, 0.06, 0.12), (0.95, -0.56, 1.75)),
    ]
    arm = [
        sphere("steel_dark", 0.85, (2.25, 0, 5.0), seg=14, rings=8),
        box("steel", (1.5, 1.6, 0.6), (2.35, 0, 5.55), bevel=0.12, taper=0.7),
        box("red_dark", (0.75, 0.8, 1.5), (2.45, 0, 3.95), bevel=0.1),
        cyl("steel_dark", 0.42, 0.42, 0.9, (2.45, 0, 3.15), rot=X(0)),
        box("steel", (1.25, 1.35, 1.5), (2.5, -0.05, 2.25), bevel=0.2),
        box("steel_dark", (1.35, 0.5, 0.35), (2.5, -0.55, 1.75), bevel=0.06),
        box("red_emit", (0.9, 0.08, 0.16), (2.5, -0.74, 2.5)),
    ]
    part("legR", (0.95, 0, 2.5), leg)
    part("legL", (-0.95, 0, 2.5), mirror(leg))
    part("armR", (2.25, 0, 5.0), arm)
    part("armL", (-2.25, 0, 5.0), mirror(arm))
    part("torso", (0, 0, 2.5), [
        box("steel_dark", (2.3, 1.5, 0.9), (0, 0, 2.75), bevel=0.15),
        box("steel", (2.6, 1.9, 2.6), (0, 0, 4.4), bevel=0.2, taper=1.38),
        box("red_dark", (1.7, 0.2, 1.3), (0, -1.05, 4.5), bevel=0.05, taper=1.3),
        cyl("orange_emit", 0.42, 0.42, 0.12, (0, -1.18, 4.6), rot=Y()),
        torus("steel_dark", 0.5, 0.09, (0, -1.18, 4.6), rot=Y()),
        box("steel_dark", (1.9, 0.9, 1.9), (0, 1.15, 4.5), bevel=0.12),
        cyl("steel_dark", 0.22, 0.22, 1.4, (0.6, 1.3, 5.9)),
        cyl("steel_dark", 0.22, 0.22, 1.1, (-0.6, 1.3, 5.75)),
    ])
    part("head", (0, 0, 5.75), [
        box("steel", (1.25, 1.25, 1.05), (0, -0.1, 6.3), bevel=0.14, taper=0.78),
        box("black", (1.05, 0.14, 0.34), (0, -0.72, 6.3)),
        box("red_emit", (0.82, 0.08, 0.13), (0, -0.79, 6.32)),
        box("red_dark", (0.3, 1.3, 0.3), (0, -0.05, 6.9), bevel=0.06, taper_y=0.6),
        box("steel_dark", (1.05, 0.5, 0.36), (0, -0.52, 5.88), bevel=0.06, taper=0.8),
    ])


def boss_inferno():
    """Inferno Guardian: hunched mechanical beast with glowing heat vents."""
    leg = [
        box("red_dark", (0.95, 1.5, 1.3), (1.35, 0.5, 1.9), bevel=0.12, rot=(math.radians(-18), 0, 0)),
        box("black", (0.7, 0.8, 1.2), (1.35, 0.15, 0.95), bevel=0.1, rot=(math.radians(14), 0, 0)),
        box("red", (1.1, 1.8, 0.42), (1.35, -0.2, 0.21), bevel=0.1, taper=0.8),
        cyl("black", 0.16, 0.0, 0.6, (1.05, -1.25, 0.2), rot=Y(), seg=6),
        cyl("black", 0.16, 0.0, 0.6, (1.65, -1.25, 0.2), rot=Y(), seg=6),
    ]
    arm = [
        sphere("red", 0.9, (2.3, -0.6, 4.2), scale=(1, 1.1, 0.9), seg=14, rings=8),
        cyl("black", 0.22, 0.0, 0.9, (2.5, -0.6, 5.2), seg=6),
        cyl("black", 0.18, 0.0, 0.7, (2.9, -0.6, 4.75), rot=(0, math.radians(40), 0), seg=6),
        box("red_dark", (0.7, 0.75, 1.6), (2.5, -0.8, 3.0), bevel=0.1),
        box("red", (1.15, 1.25, 1.2), (2.55, -1.0, 1.75), bevel=0.16),
        cyl("orange_emit", 0.32, 0.32, 0.1, (2.55, -1.66, 1.8), rot=Y()),
        cyl("black", 0.13, 0.0, 0.8, (2.2, -1.25, 0.85), rot=(math.radians(200), 0, 0), seg=6),
        cyl("black", 0.13, 0.0, 0.8, (2.55, -1.3, 0.85), rot=(math.radians(200), 0, 0), seg=6),
        cyl("black", 0.13, 0.0, 0.8, (2.9, -1.25, 0.85), rot=(math.radians(200), 0, 0), seg=6),
    ]
    vents = []
    for i, (x, y, z) in enumerate([(-0.9, 1.2, 5.0), (0.9, 1.2, 5.0), (-1.3, 0.3, 5.25), (1.3, 0.3, 5.25), (0, 0.7, 5.5)]):
        vents.append(cyl("steel_dark", 0.36, 0.3, 1.1, (x, y, z), rot=(math.radians(-12), 0, 0), seg=10))
        vents.append(cyl("orange_emit", 0.25, 0.25, 0.08, (x, y + 0.12, z + 0.56), rot=(math.radians(-12), 0, 0), seg=10))
    part("legR", (1.35, 0.5, 2.4), leg)
    part("legL", (-1.35, 0.5, 2.4), mirror(leg))
    part("armR", (2.3, -0.6, 4.2), arm)
    part("armL", (-2.3, -0.6, 4.2), mirror(arm))
    part("torso", (0, 0.4, 2.4), [
        sphere("red", 2.1, (0, 0.3, 3.9), scale=(1.15, 1.15, 0.85), seg=18, rings=10),
        box("red_dark", (2.4, 1.6, 1.3), (0, 0.5, 2.6), bevel=0.2),
        box("black", (2.0, 0.3, 1.2), (0, -1.9, 3.5), bevel=0.08, rot=(math.radians(-14), 0, 0)),
        box("orange_emit", (0.22, 0.1, 0.9), (-0.55, -2.07, 3.5), rot=(math.radians(-14), 0, 0)),
        box("orange_emit", (0.22, 0.1, 0.9), (0, -2.07, 3.5), rot=(math.radians(-14), 0, 0)),
        box("orange_emit", (0.22, 0.1, 0.9), (0.55, -2.07, 3.5), rot=(math.radians(-14), 0, 0)),
        *vents,
    ])
    horn = [
        cyl("black", 0.26, 0.0, 1.5, (0.75, -1.9, 5.2), rot=(math.radians(-25), math.radians(38), 0), seg=8),
        box("orange_emit", (0.34, 0.08, 0.16), (0.36, -3.06, 4.38), rot=(0, math.radians(-18), 0)),
    ]
    part("head", (0, -1.7, 4.3), [
        box("red", (1.5, 1.7, 1.0), (0, -2.3, 4.45), bevel=0.14, taper=0.75),
        box("black", (1.2, 1.1, 0.4), (0, -2.75, 3.8), bevel=0.08, taper=0.85),
        box("orange_emit", (0.9, 0.5, 0.1), (0, -2.9, 4.02)),
        *horn, *mirror(horn),
    ])


def boss_void():
    """Void Commander: floating robotic commander with an energy core."""
    arm = [
        sphere("purple", 0.62, (1.85, 0, 5.1), scale=(1.1, 1, 0.8), seg=12, rings=8),
        box("gold", (0.9, 0.9, 0.16), (1.95, 0, 5.5), bevel=0.05, taper=0.6),
        box("purple_dark", (0.42, 0.46, 1.5), (2.05, 0, 4.1), bevel=0.08),
        box("purple", (0.56, 0.6, 1.3), (2.1, -0.05, 2.9), bevel=0.1, taper=1.25),
        sphere("violet_emit", 0.36, (2.1, -0.1, 2.05), seg=10, rings=6),
        box("gold", (0.66, 0.7, 0.12), (2.1, -0.05, 2.38), bevel=0.03),
    ]
    part("armR", (1.85, 0, 5.1), arm)
    part("armL", (-1.85, 0, 5.1), mirror(arm))
    plates = []
    for i in range(6):
        a = i * math.pi / 3
        plates.append(box("purple_dark", (0.75, 0.14, 2.2),
                          (math.sin(a) * 0.95, math.cos(a) * 0.8, 2.3),
                          rot=(math.radians(14) * math.cos(a), math.radians(-14) * math.sin(a), -a),
                          bevel=0.04, taper=1.5))
    part("torso", (0, 0, 3.4), [
        box("purple", (2.3, 1.5, 2.0), (0, 0, 4.5), bevel=0.2, taper=1.3),
        box("purple_dark", (1.3, 1.1, 1.0), (0, 0, 3.4), bevel=0.14, taper=1.4),
        box("gold", (1.9, 0.12, 0.2), (0, -0.82, 5.2), bevel=0.03),
        box("gold", (0.2, 0.12, 1.4), (0, -0.86, 4.5), bevel=0.03),
        cyl("purple_dark", 0.5, 0.05, 1.5, (0, 0, 1.6), rot=(math.radians(180), 0, 0), seg=8),
        *plates,
    ])
    part("core", (0, -0.86, 4.5), [
        sphere("violet_emit", 0.42, (0, -0.86, 4.5), scale=(1, 0.5, 1), seg=12, rings=8),
    ])
    spike = [
        box("gold", (0.16, 0.16, 1.1), (0.52, 0.1, 7.0), bevel=0.03, taper=0.15, rot=(0, math.radians(18), 0)),
    ]
    part("head", (0, 0, 5.6), [
        box("purple_dark", (1.0, 1.05, 1.15), (0, -0.05, 6.25), bevel=0.14, taper=0.72),
        box("black", (0.8, 0.12, 0.5), (0, -0.56, 6.3), taper=0.8),
        box("violet_emit", (0.56, 0.06, 0.10), (0, -0.625, 6.38)),
        box("violet_emit", (0.10, 0.06, 0.26), (0, -0.625, 6.2)),
        box("gold", (0.16, 0.16, 1.4), (0, 0.1, 7.15), bevel=0.03, taper=0.15),
        *spike, *mirror(spike),
    ])
    part("ring", (0, 0, 6.3), [
        torus("gold", 1.75, 0.07, (0, 0.35, 6.3), rot=(math.radians(72), 0, 0), seg=28),
        sphere("violet_emit", 0.16, (1.75, 0.35, 6.3), seg=8, rings=5),
        sphere("violet_emit", 0.16, (-1.75, 0.35, 6.3), seg=8, rings=5),
    ])


# --- props ---------------------------------------------------------------------


def cannon():
    """The player's hover cannon. `barrel` recoils, `turret` is the housing."""
    fin = [
        box("blue", (0.34, 1.7, 0.30), (0.86, 0.05, 0.36), bevel=0.08, taper=0.7),
        box("cyan_emit", (0.05, 1.3, 0.07), (1.035, 0.05, 0.34)),
        cyl("blue_dark", 0.22, 0.22, 0.12, (0.86, 0.55, 0.16)),
        cyl("cyan_emit", 0.16, 0.16, 0.04, (0.86, 0.55, 0.09)),
        cyl("blue_dark", 0.22, 0.22, 0.12, (0.86, -0.45, 0.16)),
        cyl("cyan_emit", 0.16, 0.16, 0.04, (0.86, -0.45, 0.09)),
    ]
    part("base", (0, 0, 0), [
        box("blue_dark", (1.5, 1.9, 0.34), (0, 0.05, 0.42), bevel=0.1, taper=0.86),
        box("white", (1.0, 1.3, 0.10), (0, 0.1, 0.62), bevel=0.03),
        box("steel_dark", (0.9, 0.5, 0.4), (0, 0.85, 0.7), bevel=0.06),
        cyl("orange_emit", 0.14, 0.14, 0.06, (-0.24, 1.11, 0.7), rot=Y()),
        cyl("orange_emit", 0.14, 0.14, 0.06, (0.24, 1.11, 0.7), rot=Y()),
        *fin, *mirror(fin),
    ])
    part("turret", (0, 0.1, 0.66), [
        sphere("blue", 0.62, (0, 0.1, 0.76), scale=(1, 1.05, 0.72), seg=16, rings=9),
        box("blue_light", (0.3, 0.9, 0.2), (0, 0.2, 1.2), bevel=0.05),
        box("cyan_emit", (0.12, 0.5, 0.05), (0, 0.2, 1.31)),
    ])
    part("barrel", (0, -0.2, 0.95), [
        cyl("blue_dark", 0.30, 0.34, 0.5, (0, -0.55, 0.95), rot=Y(), seg=14),
        cyl("white", 0.25, 0.25, 1.0, (0, -1.1, 0.95), rot=Y(), seg=14),
        cyl("blue", 0.33, 0.33, 0.24, (0, -1.62, 0.95), rot=Y(), seg=14),
        torus("cyan_emit", 0.30, 0.05, (0, -1.76, 0.95), rot=Y(), seg=16, tube=6),
        cyl("black", 0.21, 0.21, 0.04, (0, -1.75, 0.95), rot=Y(), seg=14),
        box("blue_dark", (0.12, 0.7, 0.14), (0, -1.05, 1.23), bevel=0.03),
    ])


def turret():
    """Enemy gun emplacement (static)."""
    part("torso", (0, 0, 0), [
        cyl("steel_dark", 0.75, 0.55, 0.5, (0, 0, 0.25), seg=8),
        cyl("red_dark", 0.4, 0.4, 0.5, (0, 0, 0.7), seg=10),
        sphere("red", 0.6, (0, 0, 1.2), scale=(1, 1.1, 0.8), seg=12, rings=8),
        box("black", (0.5, 0.2, 0.2), (0, -0.55, 1.25)),
        box("red_emit", (0.36, 0.06, 0.08), (0, -0.66, 1.26)),
        cyl("steel_dark", 0.11, 0.11, 0.9, (0.26, -0.85, 1.1), rot=Y(), seg=8),
        cyl("steel_dark", 0.11, 0.11, 0.9, (-0.26, -0.85, 1.1), rot=Y(), seg=8),
        cyl("red_emit", 0.08, 0.08, 0.04, (0.26, -1.31, 1.1), rot=Y(), seg=8),
        cyl("red_emit", 0.08, 0.08, 0.04, (-0.26, -1.31, 1.1), rot=Y(), seg=8),
        cyl("black", 0.07, 0.0, 0.4, (0, 0.1, 1.85), seg=6),
    ])


def barrel():
    part("torso", (0, 0, 0), [
        cyl("red", 0.5, 0.5, 1.1, (0, 0, 0.55), seg=12),
        torus("steel_dark", 0.5, 0.05, (0, 0, 0.2), seg=12, tube=5),
        torus("steel_dark", 0.5, 0.05, (0, 0, 0.9), seg=12, tube=5),
        cyl("yellow", 0.51, 0.51, 0.26, (0, 0, 0.55), seg=12),
        cyl("steel_dark", 0.12, 0.12, 0.1, (0.2, 0, 1.14), seg=8),
        box("orange_emit", (0.2, 0.03, 0.14), (0, -0.51, 0.55)),
    ])


MODELS = {
    "blue_bot": (blue_bot, True),
    "red_grunt": (red_grunt, True),
    "red_brute": (red_brute, True),
    "boss_titan": (boss_titan, False),
    "boss_inferno": (boss_inferno, False),
    "boss_void": (boss_void, False),
    "cannon": (cannon, False),
    "turret": (turret, False),
    "barrel": (barrel, False),
}


def clear():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)


def tri_count():
    return sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" for p in o.data.polygons)


def export(name):
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_animations=False, export_cameras=False, export_lights=False)
    print(f"[assets] {name}.glb  {tri_count()} tris  {os.path.getsize(path) / 1024:.1f} KB")


def render_preview(name, height):
    """Three-quarter beauty shot, used to eyeball the models (not shipped)."""
    scene = bpy.context.scene
    cam_data = bpy.data.cameras.new("cam")
    cam_data.lens = 60
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    d = height * 2.9
    cam.location = (d * 0.55, -d * 0.8, height * 0.95)
    look = Vector((0, 0, height * 0.5)) - cam.location
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    extra = [cam]
    for loc, energy in (((4, -5, 8), 4.0), ((-6, -2, 3), 1.6), ((0, 6, 5), 2.5)):
        ld = bpy.data.lights.new("l", "SUN")
        ld.energy = energy
        lo = bpy.data.objects.new("l", ld)
        lo.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(lo)
        extra.append(lo)
    world = scene.world or bpy.data.worlds.new("w")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.10, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "BLENDER_WORKBENCH"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x = scene.render.resolution_y = 512
    scene.render.filepath = os.path.join(PREVIEW, name + ".png")
    bpy.ops.render.render(write_still=True)
    for o in extra:
        bpy.data.objects.remove(o, do_unlink=True)


def main():
    global LOD
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    os.makedirs(OUT, exist_ok=True)
    for name, (build, has_lod) in MODELS.items():
        for lod in ((0, 1) if has_lod else (0,)):
            LOD = lod
            clear()
            build()
            export(name + ("_lo" if lod else ""))
            if "--preview" in argv and lod == 0:
                os.makedirs(PREVIEW, exist_ok=True)
                height = max((o.matrix_world @ Vector(c)).z for o in bpy.data.objects if o.type == "MESH" for c in o.bound_box)
                render_preview(name, height)


main()
