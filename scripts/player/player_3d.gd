extends CharacterBody3D
## 3D 角色控制器

const MOVE_SPEED := 6.0
const JUMP_VELOCITY := 8.0
const MAX_FALL_SPEED := 16.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.1

var _input_enabled := false  # Starts disabled (2D is default)
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := false


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


func _physics_process(delta: float) -> void:
	var gravity_vec := GravityManager.get_gravity_vector_3d()

	# Apply gravity
	velocity += gravity_vec * delta
	# Clamp fall speed
	var grav_dir := gravity_vec.normalized()
	var fall_component := velocity.dot(grav_dir)
	if fall_component > MAX_FALL_SPEED:
		velocity = velocity - grav_dir * (fall_component - MAX_FALL_SPEED)

	# Coyote time
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_was_on_floor = true
	elif _was_on_floor:
		_was_on_floor = false
	if _coyote_timer > 0.0:
		_coyote_timer -= delta

	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	if not _input_enabled:
		up_direction = -grav_dir
		move_and_slide()
		return

	# Input - horizontal plane movement
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1.0
	input_dir = input_dir.normalized()

	# Build movement vector on the plane perpendicular to gravity
	var move_vec := Vector3(input_dir.x, 0.0, input_dir.y) * MOVE_SPEED
	# Keep gravity component of velocity, replace horizontal
	var grav_component := grav_dir * velocity.dot(grav_dir)
	velocity = grav_component + move_vec

	# Jump
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity = velocity - grav_dir * velocity.dot(grav_dir)
		velocity += -grav_dir * JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

	# Dimension switch
	if Input.is_action_just_pressed("dimension_switch"):
		DimensionManager.request_switch()

	up_direction = -grav_dir
	move_and_slide()
