extends Node
## 维度切换控制器 - 管理 2D↔3D 切换

signal dimension_changed(new_dimension: Dimension)
signal dimension_switch_failed(reason: String)

enum Dimension { MODE_2D, MODE_3D }

const PIXEL_SCALE := 50.0  # 50px = 1m
const SWITCH_COOLDOWN := 1.5
const TRANSITION_DURATION := 0.5

var current_dimension: Dimension = Dimension.MODE_2D
var is_transitioning := false
var can_switch := true

var _world_2d: Node2D
var _world_3d: Node3D
var _player_2d: CharacterBody2D
var _player_3d: CharacterBody3D
var _ui_layer: CanvasLayer
var _cooldown_timer := 0.0
var _last_z_position := 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			can_switch = true


func initialize(world_2d: Node2D, world_3d: Node3D, player_2d: CharacterBody2D, player_3d: CharacterBody3D, ui: CanvasLayer) -> void:
	_world_2d = world_2d
	_world_3d = world_3d
	_player_2d = player_2d
	_player_3d = player_3d
	_ui_layer = ui
	set_process(true)
	_apply_dimension(Dimension.MODE_2D)


func request_switch() -> bool:
	if is_transitioning or not can_switch:
		dimension_switch_failed.emit("冷却中")
		return false

	var target := Dimension.MODE_3D if current_dimension == Dimension.MODE_2D else Dimension.MODE_2D
	_execute_switch(target)
	return true


func _execute_switch(target: Dimension) -> void:
	is_transitioning = true
	can_switch = false

	# Freeze input
	if _player_2d.has_method("set_input_enabled"):
		_player_2d.set_input_enabled(false)
	if _player_3d.has_method("set_input_enabled"):
		_player_3d.set_input_enabled(false)

	# Sync position
	if target == Dimension.MODE_3D:
		var pos_2d := _player_2d.global_position
		_last_z_position = clampf(_last_z_position, -10.0, 10.0)
		_player_3d.global_position = Vector3(
			pos_2d.x / PIXEL_SCALE,
			-pos_2d.y / PIXEL_SCALE,
			_last_z_position
		)
		_player_3d.velocity = Vector3(
			_player_2d.velocity.x / PIXEL_SCALE,
			-_player_2d.velocity.y / PIXEL_SCALE,
			0.0
		)
	else:
		_last_z_position = _player_3d.global_position.z
		_player_2d.global_position = Vector2(
			_player_3d.global_position.x * PIXEL_SCALE,
			-_player_3d.global_position.y * PIXEL_SCALE
		)
		_player_2d.velocity = Vector2(
			_player_3d.velocity.x * PIXEL_SCALE,
			-_player_3d.velocity.y * PIXEL_SCALE
		)

	# Simple fade transition
	await _do_transition()

	_apply_dimension(target)
	current_dimension = target

	# Unfreeze
	if target == Dimension.MODE_2D and _player_2d.has_method("set_input_enabled"):
		_player_2d.set_input_enabled(true)
	elif target == Dimension.MODE_3D and _player_3d.has_method("set_input_enabled"):
		_player_3d.set_input_enabled(true)

	is_transitioning = false
	_cooldown_timer = SWITCH_COOLDOWN
	dimension_changed.emit(target)


func _apply_dimension(dim: Dimension) -> void:
	if dim == Dimension.MODE_2D:
		_world_2d.visible = true
		_world_2d.process_mode = Node.PROCESS_MODE_INHERIT
		_world_3d.visible = false
		_world_3d.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		_world_2d.visible = false
		_world_2d.process_mode = Node.PROCESS_MODE_DISABLED
		_world_3d.visible = true
		_world_3d.process_mode = Node.PROCESS_MODE_INHERIT


func _do_transition() -> void:
	# Find or create a fade overlay in the UI layer
	if not _ui_layer:
		return
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.anchors_preset = Control.PRESET_FULL_RECT
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, TRANSITION_DURATION * 0.5)
	tween.tween_property(fade, "color:a", 0.0, TRANSITION_DURATION * 0.5)
	await tween.finished
	fade.queue_free()
