extends CharacterBody2D
## 2D 角色控制器

const MOVE_SPEED := 300.0
const JUMP_VELOCITY := -400.0
const MAX_FALL_SPEED := 800.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.1

var _input_enabled := true
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := false


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


func _physics_process(delta: float) -> void:
	var gravity_vec := GravityManager.get_gravity_vector_2d()

	# Apply gravity
	velocity += gravity_vec * delta
	# Clamp fall speed along gravity direction
	var grav_dir := gravity_vec.normalized()
	var fall_component := velocity.dot(grav_dir)
	if fall_component > MAX_FALL_SPEED:
		velocity = velocity - grav_dir * (fall_component - MAX_FALL_SPEED)

	# Update coyote time
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_was_on_floor = true
	elif _was_on_floor:
		_was_on_floor = false
	if _coyote_timer > 0.0:
		_coyote_timer -= delta

	# Jump buffer
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	if not _input_enabled:
		# Set up_direction for floor detection even when input disabled
		up_direction = -grav_dir
		move_and_slide()
		return

	# Input
	var move_dir := 0.0
	if Input.is_action_pressed("move_left"):
		move_dir -= 1.0
	if Input.is_action_pressed("move_right"):
		move_dir += 1.0

	# Movement perpendicular to gravity
	var right_vec := Vector2(-grav_dir.y, grav_dir.x)
	var move_component := right_vec * move_dir * MOVE_SPEED
	# Remove existing movement along right_vec, replace with input
	var grav_component := grav_dir * velocity.dot(grav_dir)
	velocity = grav_component + move_component

	# Jump
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity = velocity - grav_dir * velocity.dot(grav_dir)  # zero out gravity component
		velocity += -grav_dir * abs(JUMP_VELOCITY)
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

	# Dimension switch
	if Input.is_action_just_pressed("dimension_switch"):
		DimensionManager.request_switch()

	up_direction = -grav_dir
	move_and_slide()
