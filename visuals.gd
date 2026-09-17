extends RefCounted
class_name FrontierVisuals

static var materials: Dictionary = {}

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key := str(color) + str(glow)
	if materials.has(key): return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.5
	materials[key] = mat
	return mat

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(node)
	node.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	node.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		node.add_child(collision)
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0 else top
	shape.height = height
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

static func label(parent: Node3D, text: String, pos: Vector3, color: Color = Color.WHITE, size: int = 32) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = size
	node.pixel_size = 0.015
	node.outline_size = 6
	node.modulate = color
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(node)
	node.position = pos
	return node

static func person(parent: Node3D, color: Color, kind: String = "civilian", variation: int = 0) -> Node3D:
	var model := Node3D.new()
	parent.add_child(model)
	var skin := Color(["#f5cba1", "#c48d66", "#8c5d48", "#dfad87"][variation % 4])
	var hair := Color(["#67483e", "#b96342", "#e2c18a", "#dfd9c6"][variation % 4])
	model.scale = Vector3(0.92 + (variation % 3) * 0.08, 0.94 + (variation % 4) * 0.04, 1)
	if kind == "zombie": skin = Color("#b4d791")
	if kind == "monster": skin = Color("#d5b7f4")
	box(model, Vector3(0, 0.92, 0), Vector3(0.68, 0.68, 0.4), color)
	for side in [-1.0, 1.0]:
		box(model, Vector3(side * 0.19, 0.29, 0), Vector3(0.25, 0.58, 0.3), Color("#59657b"))
		var arm := Node3D.new()
		model.add_child(arm)
		arm.name = "LeftArm" if side < 0 else "RightArm"
		arm.position = Vector3(side * 0.44, 1.16, 0)
		box(arm, Vector3(0, -0.13, 0), Vector3(0.23, 0.35, 0.25), color)
		box(arm, Vector3(0, -0.37, 0), Vector3(0.19, 0.2, 0.23), skin)
		box(model, Vector3(side * 0.19, 0.1, -0.08), Vector3(0.29, 0.2, 0.43), Color("#71544d"))
	box(model, Vector3(0, 1.55, 0), Vector3(0.57, 0.55, 0.52), skin)
	box(model, Vector3(0, 1.76, 0.06), Vector3(0.6, 0.16, 0.48), hair)
	box(model, Vector3(0, 1.52, -0.29), Vector3(0.1, 0.12, 0.1), skin.darkened(0.08))
	box(model, Vector3(0, 0.67, -0.015), Vector3(0.71, 0.09, 0.43), Color("#72534d"))
	box(model, Vector3(0, 0.67, -0.24), Vector3(0.13, 0.12, 0.04), Color("#efd184"))
	if variation % 3 == 1:
		box(model, Vector3(0, 1.46, -0.3), Vector3(0.24, 0.06, 0.025), hair)
	if variation % 3 == 2:
		for side in [-1, 1]:
			box(model, Vector3(side * 0.28, 1.53, 0.05), Vector3(0.14, 0.5, 0.36), hair)
	if variation % 5 == 2:
		box(model, Vector3(0, 0.92, -0.225), Vector3(0.48, 0.57, 0.04), Color("#f1dec0"))
	for side in [-1.0, 1.0]:
		box(model, Vector3(side * 0.13, 1.58, -0.269), Vector3(0.055, 0.085, 0.02), Color("#433f4b"))
	box(model, Vector3(0, 1.42, -0.269), Vector3(0.14, 0.035, 0.02), Color("#a96d67"))
	if kind in ["civilian", "bandit", "deputy"]:
		var hat := Color("#684e50") if kind == "bandit" else Color(["#dfac68", "#789f98", "#f4dfb6", "#a97c88"][variation % 4])
		cylinder(model, Vector3(0, 1.87, 0), 0.40 + (variation % 3) * 0.07, 0.1, hat)
		cylinder(model, Vector3(0, 2.02, 0), 0.29, 0.23 + (variation % 3) * 0.06, hat, 0.25)
		cylinder(model, Vector3(0, 1.93, 0), 0.3, 0.07, color.darkened(0.3))
		box(model, Vector3(0, 1.24, -0.22), Vector3(0.3, 0.15, 0.035), Color("#c76f70") if kind == "bandit" else Color("#f3d778"))
	if kind == "deputy":
		box(model, Vector3(-0.18, 1.05, -0.22), Vector3(0.14, 0.14, 0.04), Color("#ffe197")).rotation.z = PI / 4
	if kind == "monster":
		for side in [-1.0, 1.0]:
			cylinder(model, Vector3(side * 0.27, 1.95, 0), 0.13, 0.4, Color("#fff1cc"), 0.0)
		model.scale = Vector3.ONE * 1.45
	batch_static(model, [model.get_node_or_null("LeftArm"), model.get_node_or_null("RightArm")])
	return model

# Bake rigid primitive geometry by material, retaining collision/interaction nodes.
# This avoids thousands of separate draw calls on the Web renderer.
static func batch_static(root: Node3D, excluded: Array = []) -> void:
	var groups: Dictionary = {}
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node in excluded: continue
		for child in node.get_children(): pending.append(child)
		if not node is MeshInstance3D: continue
		var mesh_node := node as MeshInstance3D
		var material_id := mesh_node.material_override.get_instance_id()
		if not groups.has(material_id):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[material_id] = {"surface": surface, "material": mesh_node.material_override}
		var local := Transform3D.IDENTITY
		var ancestor: Node3D = mesh_node
		while ancestor != root:
			local = ancestor.transform * local
			ancestor = ancestor.get_parent() as Node3D
		groups[material_id].surface.append_from(mesh_node.mesh, 0, local)
		mesh_node.hide()
		mesh_node.queue_free()
	for group in groups.values():
		var instance := MeshInstance3D.new()
		instance.mesh = group.surface.commit()
		instance.material_override = group.material
		root.add_child(instance)
