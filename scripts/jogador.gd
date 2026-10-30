extends CharacterBody2D
## Gabriel: anda com as setas (ou WASD). A origem fica nos pés.

const Visual := preload("res://scripts/personagem.gd")
const VELOCIDADE := 82.0

var visual
var pode_mover := true
var camera: Camera2D
var _passo := 0.0


func configurar(limites: Rect2) -> void:
	visual = Visual.new()
	add_child(visual)
	visual.configurar("gabriel")
	visual.direcao = "cima"
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(10, 6)
	forma.shape = ret
	forma.position = Vector2(0, -3)
	add_child(forma)
	camera = Camera2D.new()
	camera.position = Vector2(0, -12)
	camera.limit_left = int(limites.position.x)
	camera.limit_top = int(limites.position.y)
	camera.limit_right = int(limites.end.x)
	camera.limit_bottom = int(limites.end.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	camera.make_current()


func vetor_frente() -> Vector2:
	return visual.vetor_frente()


func _physics_process(delta: float) -> void:
	var entrada := Vector2.ZERO
	if pode_mover:
		entrada = Input.get_vector("mover_esq", "mover_dir", "mover_cima", "mover_baixo")
	velocity = entrada * VELOCIDADE
	move_and_slide()
	visual.andando = entrada != Vector2.ZERO
	if entrada != Vector2.ZERO:
		visual.olhar_vetor(entrada)
		_passo += delta
		if _passo >= 0.32:
			_passo = 0.0
			Som.tocar("passo", -10.0, randf_range(0.85, 1.15))
	else:
		_passo = 0.25
