extends Node2D
## Personagem não jogável: colegas (ficam na mesa) e clientes (vão e voltam do balcão).

const Visual := preload("res://scripts/personagem.gd")

var id := ""
var visual
var _balao: Sprite2D
var _marcador: Sprite2D
var _balao_fixo_ate := 0.0
var _t := 0.0
var _proxima_virada := 4.0
var _colega := false


func configurar(novo_id: String, colega: bool) -> void:
	id = novo_id
	_colega = colega
	visual = Visual.new()
	add_child(visual)
	visual.configurar(id)
	_balao = Sprite2D.new()
	_balao.position = Vector2(0, -42)
	_balao.visible = false
	add_child(_balao)
	_marcador = Sprite2D.new()
	_marcador.texture = Jogo.textura("ui/marcador")
	_marcador.position = Vector2(0, -42)
	_marcador.visible = false
	add_child(_marcador)
	if colega:
		var corpo := StaticBody2D.new()
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = Vector2(10, 6)
		forma.shape = ret
		forma.position = Vector2(0, -3)
		corpo.add_child(forma)
		add_child(corpo)
		_proxima_virada = randf_range(2.0, 6.0)


func mostrar_balao(tipo: String) -> void:
	if _t < _balao_fixo_ate:
		return
	_balao.visible = tipo != ""
	if tipo != "":
		_balao.texture = Jogo.textura("ui/balao_" + tipo)


func mostrar_balao_temporario(tipo: String, duracao := 1.8) -> void:
	_balao_fixo_ate = 0.0
	mostrar_balao(tipo)
	_marcador.visible = false
	_balao_fixo_ate = _t + duracao


func mostrar_marcador(visivel: bool) -> void:
	_marcador.visible = visivel and _t >= _balao_fixo_ate


func olhar_para(ponto: Vector2) -> void:
	visual.olhar_vetor(ponto - global_position)
	_proxima_virada = 6.0


func andar(pontos: Array, velocidade := 52.0) -> void:
	visual.andando = true
	for p in pontos:
		var destino: Vector2 = p
		var distancia := destino.distance_to(position)
		if distancia < 0.5:
			continue
		visual.olhar_vetor(destino - position)
		var t := create_tween()
		t.tween_property(self, "position", destino, distancia / velocidade)
		await t.finished
	visual.andando = false


func _process(delta: float) -> void:
	_t += delta
	_balao.offset.y = roundf(sin(_t * 4.0) * 1.5)
	_marcador.offset.y = roundf(sin(_t * 5.0) * 2.0)
	if _colega and not visual.andando:
		_proxima_virada -= delta
		if _proxima_virada <= 0.0:
			_proxima_virada = randf_range(3.0, 7.0)
			visual.direcao = ["baixo", "baixo", "baixo", "esq", "dir"].pick_random()
