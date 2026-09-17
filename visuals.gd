extends RefCounted
class_name FrontierVisuals

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.5
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

static func person(parent: Node3D, color: Color, kind: String = "civilian") -> Node3D:
	var model := Node3D.new()
	parent.add_child(model)
	var skin := Color("#f5cba1")
	if kind == "zombie": skin = Color("#b4d791")
	if kind == "monster": skin = Color("#d5b7f4")
	box(model, Vector3(0, 0.92, 0), Vector3(0.68, 0.68, 0.4), color)
	for side in [-1.0, 1.0]:
		box(model, Vector3(side * 0.19, 0.29, 0), Vector3(0.25, 0.58, 0.3), Color("#59657b"))
		box(model, Vector3(side * 0.46, 0.94, 0), Vector3(0.2, 0.58, 0.24), skin)
		box(model, Vector3(side * 0.19, 0.1, -0.08), Vector3(0.29, 0.2, 0.43), Color("#71544d"))
	box(model, Vector3(0, 1.55, 0), Vector3(0.57, 0.55, 0.52), skin)
	for side in [-1.0, 1.0]:
		box(model, Vector3(side * 0.13, 1.58, -0.269), Vector3(0.055, 0.085, 0.02), Color("#433f4b"))
	box(model, Vector3(0, 1.42, -0.269), Vector3(0.14, 0.035, 0.02), Color("#a96d67"))
	if kind in ["civilian", "bandit", "deputy"]:
		var hat := Color("#684e50") if kind == "bandit" else Color("#dfac68")
		cylinder(model, Vector3(0, 1.87, 0), 0.49, 0.1, hat)
		cylinder(model, Vector3(0, 2.04, 0), 0.3, 0.3, hat, 0.26)
		box(model, Vector3(0, 1.24, -0.22), Vector3(0.3, 0.15, 0.035), Color("#c76f70") if kind == "bandit" else Color("#f3d778"))
	if kind == "deputy":
		box(model, Vector3(-0.18, 1.05, -0.22), Vector3(0.14, 0.14, 0.04), Color("#ffe197")).rotation.z = PI / 4
	if kind == "monster":
		for side in [-1.0, 1.0]:
			cylinder(model, Vector3(side * 0.27, 1.95, 0), 0.13, 0.4, Color("#fff1cc"), 0.0)
		model.scale = Vector3.ONE * 1.45
	return model
