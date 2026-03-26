extends Node
## 全局重力控制器 - 管理当前重力方向和强度

signal gravity_changed(old_direction: Vector2, new_direction: Vector2)

enum GravityDir { DOWN, UP, LEFT, RIGHT }

const DIR_VECTORS_2D := {
	GravityDir.DOWN:  Vector2(0, 1),
	GravityDir.UP:    Vector2(0, -1),
	GravityDir.LEFT:  Vector2(-1, 0),
	GravityDir.RIGHT: Vector2(1, 0),
}

const DIR_VECTORS_3D := {
	GravityDir.DOWN:  Vector3(0, -1, 0),
	GravityDir.UP:    Vector3(0, 1, 0),
	GravityDir.LEFT:  Vector3(-1, 0, 0),
	GravityDir.RIGHT: Vector3(1, 0, 0),
}

var current_direction: GravityDir = GravityDir.DOWN
var gravity_strength: float = 980.0


func get_gravity_vector_2d() -> Vector2:
	return DIR_VECTORS_2D[current_direction] * gravity_strength


func get_gravity_vector_3d() -> Vector3:
	return DIR_VECTORS_3D[current_direction] * (gravity_strength / 100.0)


func set_direction(new_dir: GravityDir) -> void:
	if new_dir == current_direction:
		return
	var old_vec := DIR_VECTORS_2D[current_direction]
	current_direction = new_dir
	var new_vec := DIR_VECTORS_2D[current_direction]
	gravity_changed.emit(old_vec, new_vec)
