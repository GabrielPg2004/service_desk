extends Node2D
## Visual de um personagem: sombra + sprite da folha 4x4 (baixo, cima, esq, dir) com caminhada.
## A origem do nó fica nos pés.

const LINHAS := {"baixo": 0, "cima": 1, "esq": 2, "dir": 3}

var direcao := "baixo"
var andando := false
var _sprite: Sprite2D
var _tempo := 0.0


func configurar(id: String) -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = Jogo.folha(id)
	_sprite.hframes = 4
	_sprite.vframes = 4
	_sprite.centered = false
	_sprite.offset = Vector2(-8, -31)
	add_child(_sprite)
	_atualizar()


func _draw() -> void:
	draw_set_transform(Vector2(0, -0.5), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0.18, 0.08, 0.14, 0.25))


func _process(delta: float) -> void:
	_tempo = _tempo + delta if andando else 0.0
	_atualizar()


func _atualizar() -> void:
	if _sprite == null:
		return
	var quadro := int(_tempo * 8.0) % 4 if andando else 0
	_sprite.frame = LINHAS[direcao] * 4 + quadro


func olhar_vetor(v: Vector2) -> void:
	if v == Vector2.ZERO:
		return
	if absf(v.x) > absf(v.y):
		direcao = "dir" if v.x > 0 else "esq"
	else:
		direcao = "baixo" if v.y > 0 else "cima"


func vetor_frente() -> Vector2:
	return {"baixo": Vector2.DOWN, "cima": Vector2.UP, "esq": Vector2.LEFT, "dir": Vector2.RIGHT}[direcao]
