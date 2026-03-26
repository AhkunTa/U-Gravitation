extends Node
## 演示关卡构建器 - 运行时构建 2D/3D 双世界
## 布局：左侧出生点，右侧终点，中间有间隙
## 2D 中间隙不可跨越，3D 中有 Z 轴隐藏走廊可绕行

const PX_SCALE := 50.0  # 50px = 1 meter

var world_2d: Node2D
var world_3d: Node3D
var player_2d: CharacterBody2D
var player_3d: CharacterBody3D
var ui_layer: CanvasLayer
var dimension_label: Label
var hint_label: Label


func _ready() -> void:
	_build_world_2d()
	_build_world_3d()
	_build_ui()
	_setup_managers()


# ============================================================
# 2D World
# ============================================================
func _build_world_2d() -> void:
	world_2d = Node2D.new()
	world_2d.name = "World2D"
	add_child(world_2d)

	# Floor
	_add_static_rect_2d(world_2d, Vector2(0, 300), Vector2(1200, 32), Color(0.35, 0.35, 0.4))

	# Left platform (spawn area)
	_add_static_rect_2d(world_2d, Vector2(-300, 180), Vector2(300, 16), Color(0.3, 0.5, 0.3))

	# Right platform (goal area)
	_add_static_rect_2d(world_2d, Vector2(300, 180), Vector2(300, 16), Color(0.3, 0.5, 0.3))

	# Walls (left and right boundaries)
	_add_static_rect_2d(world_2d, Vector2(-616, 0), Vector2(32, 700), Color(0.3, 0.3, 0.35))
	_add_static_rect_2d(world_2d, Vector2(616, 0), Vector2(32, 700), Color(0.3, 0.3, 0.35))

	# Ceiling
	_add_static_rect_2d(world_2d, Vector2(0, -320), Vector2(1200, 32), Color(0.35, 0.35, 0.4))

	# Gap indicator - a small sign
	var gap_label := Label.new()
	gap_label.text = "?"
	gap_label.position = Vector2(-20, 220)
	gap_label.add_theme_font_size_override("font_size", 40)
	gap_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 0.5))
	world_2d.add_child(gap_label)

	# Player 2D
	player_2d = CharacterBody2D.new()
	player_2d.name = "Player2D"
	player_2d.position = Vector2(-350, 140)
	player_2d.set_script(load("res://scripts/player/player_2d.gd"))

	var col_2d := CollisionShape2D.new()
	var shape_2d := RectangleShape2D.new()
	shape_2d.size = Vector2(24, 32)
	col_2d.shape = shape_2d
	player_2d.add_child(col_2d)

	var sprite_2d := ColorRect.new()
	sprite_2d.size = Vector2(24, 32)
	sprite_2d.position = Vector2(-12, -16)
	sprite_2d.color = Color(0.2, 0.6, 1.0)
	player_2d.add_child(sprite_2d)

	var camera_2d := Camera2D.new()
	camera_2d.name = "Camera2D"
	camera_2d.zoom = Vector2(1.0, 1.0)
	player_2d.add_child(camera_2d)

	world_2d.add_child(player_2d)

	# Goal 2D
	var goal_2d := Area2D.new()
	goal_2d.name = "Goal2D"
	goal_2d.position = Vector2(450, 150)
	var goal_col := CollisionShape2D.new()
	var goal_shape := RectangleShape2D.new()
	goal_shape.size = Vector2(40, 40)
	goal_col.shape = goal_shape
	goal_2d.add_child(goal_col)
	var goal_visual := ColorRect.new()
	goal_visual.size = Vector2(40, 40)
	goal_visual.position = Vector2(-20, -20)
	goal_visual.color = Color(1.0, 0.85, 0.0, 0.8)
	goal_2d.add_child(goal_visual)
	goal_2d.body_entered.connect(_on_goal_reached)
	goal_2d.collision_layer = 0
	goal_2d.collision_mask = 2  # detect player
	world_2d.add_child(goal_2d)


func _add_static_rect_2d(parent: Node2D, pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2.0
	visual.color = color
	body.add_child(visual)
	parent.add_child(body)
	return body


# ============================================================
# 3D World
# ============================================================
func _build_world_3d() -> void:
	world_3d = Node3D.new()
	world_3d.name = "World3D"
	world_3d.visible = false
	add_child(world_3d)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.5)
	env.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world_3d.add_child(world_env)

	# Directional light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	world_3d.add_child(light)

	# Floor (extends to cover Z-axis corridor)
	_add_static_box_3d(world_3d, Vector3(0, -6.32, -2), Vector3(24, 0.64, 12), Color(0.35, 0.35, 0.4))

	# Left platform (Z=0)
	_add_static_box_3d(world_3d, Vector3(-6, -3.28, 0), Vector3(6, 0.32, 3), Color(0.3, 0.5, 0.3))

	# Right platform (Z=0)
	_add_static_box_3d(world_3d, Vector3(6, -3.28, 0), Vector3(6, 0.32, 3), Color(0.3, 0.5, 0.3))

	# Hidden Z-axis corridor (the secret path!)
	# Connector from left platform (Z=0) into Z axis
	_add_static_box_3d(world_3d, Vector3(-5, -3.28, -2), Vector3(3, 0.32, 2.5), Color(0.45, 0.35, 0.6))
	# Bridge from left going deeper into Z
	_add_static_box_3d(world_3d, Vector3(-4, -3.28, -4.5), Vector3(3, 0.32, 3), Color(0.4, 0.3, 0.6))
	# Middle corridor at Z=-4.5
	_add_static_box_3d(world_3d, Vector3(0, -3.28, -4.5), Vector3(5, 0.32, 3), Color(0.4, 0.3, 0.6))
	# Bridge from corridor back toward right platform
	_add_static_box_3d(world_3d, Vector3(4, -3.28, -4.5), Vector3(3, 0.32, 3), Color(0.4, 0.3, 0.6))
	# Connector from Z axis back to right platform (Z=0)
	_add_static_box_3d(world_3d, Vector3(5, -3.28, -2), Vector3(3, 0.32, 2.5), Color(0.45, 0.35, 0.6))

	# Walls
	_add_static_box_3d(world_3d, Vector3(-12.32, 0, -2), Vector3(0.64, 14, 12), Color(0.3, 0.3, 0.35))
	_add_static_box_3d(world_3d, Vector3(12.32, 0, -2), Vector3(0.64, 14, 12), Color(0.3, 0.3, 0.35))

	# Ceiling
	_add_static_box_3d(world_3d, Vector3(0, 6.72, -2), Vector3(24, 0.64, 12), Color(0.35, 0.35, 0.4))

	# Player 3D
	player_3d = CharacterBody3D.new()
	player_3d.name = "Player3D"
	player_3d.position = Vector3(-7, -2.5, 0)
	player_3d.set_script(load("res://scripts/player/player_3d.gd"))

	var col_3d := CollisionShape3D.new()
	var shape_3d := BoxShape3D.new()
	shape_3d.size = Vector3(0.48, 0.64, 0.48)
	col_3d.shape = shape_3d
	player_3d.add_child(col_3d)

	var mesh_3d := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.48, 0.64, 0.48)
	mesh_3d.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 1.0)
	mesh_3d.material_override = mat
	player_3d.add_child(mesh_3d)

	# Camera 3D - isometric-ish view
	var cam_pivot := Node3D.new()
	cam_pivot.name = "CameraPivot"
	var camera_3d := Camera3D.new()
	camera_3d.name = "Camera3D"
	camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera_3d.fov = 50.0
	camera_3d.position = Vector3(0, 12, 16)
	camera_3d.rotation_degrees = Vector3(-35, 0, 0)
	cam_pivot.add_child(camera_3d)
	player_3d.add_child(cam_pivot)

	world_3d.add_child(player_3d)

	# Goal 3D
	var goal_3d := Area3D.new()
	goal_3d.name = "Goal3D"
	goal_3d.position = Vector3(9, -2.8, 0)
	var goal_col_3d := CollisionShape3D.new()
	var goal_shape_3d := BoxShape3D.new()
	goal_shape_3d.size = Vector3(0.8, 0.8, 0.8)
	goal_col_3d.shape = goal_shape_3d
	goal_3d.add_child(goal_col_3d)
	var goal_mesh := MeshInstance3D.new()
	var goal_box := BoxMesh.new()
	goal_box.size = Vector3(0.8, 0.8, 0.8)
	goal_mesh.mesh = goal_box
	var goal_mat := StandardMaterial3D.new()
	goal_mat.albedo_color = Color(1.0, 0.85, 0.0)
	goal_mat.emission_enabled = true
	goal_mat.emission = Color(1.0, 0.85, 0.0)
	goal_mat.emission_energy_multiplier = 0.5
	goal_mesh.material_override = goal_mat
	goal_3d.add_child(goal_mesh)
	goal_3d.body_entered.connect(_on_goal_reached)
	goal_3d.collision_layer = 0
	goal_3d.collision_mask = 2
	world_3d.add_child(goal_3d)


func _add_static_box_3d(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	parent.add_child(body)
	return body


# ============================================================
# UI
# ============================================================
func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	ui_layer.layer = 10
	add_child(ui_layer)

	# Dimension label (top-right)
	dimension_label = Label.new()
	dimension_label.name = "DimensionLabel"
	dimension_label.text = "2D"
	dimension_label.add_theme_font_size_override("font_size", 28)
	dimension_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	dimension_label.anchors_preset = Control.PRESET_TOP_RIGHT
	dimension_label.offset_left = -80
	dimension_label.offset_top = 16
	dimension_label.offset_right = -16
	dimension_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_layer.add_child(dimension_label)

	# Hint label (center-bottom)
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "A/D 移动  |  Space 跳跃  |  Tab 切换维度  |  R 重置"
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
	hint_label.offset_top = -60
	hint_label.offset_bottom = -30
	hint_label.offset_left = -250
	hint_label.offset_right = 250
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(hint_label)

	# Level label (top-left)
	var level_label := Label.new()
	level_label.text = "Demo Level"
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	level_label.position = Vector2(16, 16)
	ui_layer.add_child(level_label)


# ============================================================
# Managers & Logic
# ============================================================
func _setup_managers() -> void:
	GravityManager.current_direction = GravityManager.GravityDir.DOWN
	DimensionManager.initialize(world_2d, world_3d, player_2d, player_3d, ui_layer)
	DimensionManager.dimension_changed.connect(_on_dimension_changed)

	# Set player 2D collision layer
	player_2d.collision_layer = 2
	player_2d.collision_mask = 1

	# Set player 3D collision layer
	player_3d.collision_layer = 2
	player_3d.collision_mask = 1


func _on_dimension_changed(_new_dim) -> void:
	if DimensionManager.current_dimension == DimensionManager.Dimension.MODE_2D:
		dimension_label.text = "2D"
	else:
		dimension_label.text = "3D"


func _on_goal_reached(_body: Node) -> void:
	# Simple win feedback
	dimension_label.text = "CLEAR!"
	dimension_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	hint_label.text = "按 R 重新开始"
	hint_label.modulate.a = 1.0
	hint_label.visible = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_level"):
		get_tree().reload_current_scene()
