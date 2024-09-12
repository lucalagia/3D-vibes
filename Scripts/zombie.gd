extends CharacterBody3D


var player = null
var state_machine
var health = 6

const SPEED = 1
const ATTACK_RANGE = 1.5

@export var player_path := "/root/World/Map/SubViewportContainer/SubViewport/Player"

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree

func _ready():
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")

func _process(delta):
	velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"Walking":
			# Navigation
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10)
		"Attack":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	# Conditions
	anim_tree.set("parameters/conditions/Attack", _target_in_range(0.0))
	anim_tree.set("parameters/conditions/Walking", !_target_in_range(0.0))
	
	move_and_slide()

func _target_in_range(margin):
	return global_position.distance_to(player.global_position) < ATTACK_RANGE + margin

func _hit_finished():
	if _target_in_range(1.0):
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)


func _on_area_3d_body_part_hit(dam: Variant) -> void:
	health -= dam
	if health <= 0:
		anim_tree.set("parameters/conditions/die", true)
		await get_tree().create_timer(4.0).timeout
		queue_free()
