extends Control
## Minigame de sequência de setas: aperte as setas na ordem mostrada.
## Erros não reiniciam a sequência (o jogo é tranquilo), mas são contados.

signal _concluido

const ACOES := ["mover_cima", "mover_dir", "mover_baixo", "mover_esq"]
const ROTACAO := {"mover_cima": 0.0, "mover_dir": PI / 2, "mover_baixo": PI, "mover_esq": -PI / 2}

var _painel: NinePatchRect
var _titulo: Label
var _dica: Label
var _barra: ColorRect
var _teclas: Array[TextureRect] = []
var _sequencia: Array = []
var _indice := 0
var _erros := 0
var _ativo := false
var _t := 0.0


func _ready() -> void:
	Jogo.tela_cheia(self)
	visible = false
	var fundo := ColorRect.new()
	fundo.color = Color(0.1, 0.05, 0.08, 0.45)
	Jogo.tela_cheia(fundo)
	add_child(fundo)
	_painel = Jogo.painel()
	_painel.size = Vector2(320, 118)
	_painel.position = Vector2(80, 62)
	add_child(_painel)
	_titulo = Jogo.rotulo("", 12, Jogo.COR_TEXTO)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.size = Vector2(320, 16)
	_titulo.position = Vector2(0, 12)
	_painel.add_child(_titulo)
	_dica = Jogo.rotulo("Aperte as setas na ordem mostrada", 9, Jogo.COR_TEXTO_SUAVE)
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.size = Vector2(320, 12)
	_dica.position = Vector2(0, 90)
	_painel.add_child(_dica)
	var trilho := ColorRect.new()
	trilho.color = Color("d8bf94")
	trilho.position = Vector2(40, 80)
	trilho.size = Vector2(240, 4)
	_painel.add_child(trilho)
	_barra = ColorRect.new()
	_barra.color = Color("6fbf73")
	_barra.position = Vector2(40, 80)
	_barra.size = Vector2(0, 4)
	_painel.add_child(_barra)


## Retorna a quantidade de erros.
func jogar(titulo: String, quantidade: int) -> int:
	_titulo.text = titulo
	for t in _teclas:
		t.queue_free()
	_teclas.clear()
	_sequencia.clear()
	for i in quantidade:
		var acao: String = ACOES.pick_random()
		while i >= 2 and acao == _sequencia[i - 1] and acao == _sequencia[i - 2]:
			acao = ACOES.pick_random()
		_sequencia.append(acao)
	var espaco := 26.0
	var x0 := 160.0 - (quantidade * espaco) / 2.0 + 3.0
	for i in quantidade:
		var tecla := TextureRect.new()
		tecla.texture = Jogo.textura("ui/tecla")
		tecla.size = Vector2(20, 20)
		tecla.pivot_offset = Vector2(10, 9)
		tecla.rotation = ROTACAO[_sequencia[i]]
		tecla.position = Vector2(x0 + i * espaco, 44)
		_painel.add_child(tecla)
		_teclas.append(tecla)
	_indice = 0
	_erros = 0
	_barra.size.x = 0
	_dica.text = "Aperte as setas na ordem mostrada"
	visible = true
	_ativo = true
	_atualizar()
	await _concluido
	_dica.text = "Pronto!"
	Som.tocar("acerto")
	await get_tree().create_timer(0.7).timeout
	visible = false
	return _erros


func _atualizar() -> void:
	for i in _teclas.size():
		var tecla := _teclas[i]
		if i < _indice:
			tecla.texture = Jogo.textura("ui/tecla_ok")
			tecla.modulate = Color(1, 1, 1, 1)
			tecla.scale = Vector2.ONE
		elif i == _indice:
			tecla.texture = Jogo.textura("ui/tecla")
			tecla.modulate = Color(1, 1, 1, 1)
			tecla.scale = Vector2(1.2, 1.2)
		else:
			tecla.texture = Jogo.textura("ui/tecla")
			tecla.modulate = Color(1, 1, 1, 0.55)
			tecla.scale = Vector2.ONE
	_barra.size.x = 240.0 * _indice / maxf(_sequencia.size(), 1)


func _process(delta: float) -> void:
	_t += delta
	if _ativo and _indice < _teclas.size():
		_teclas[_indice].position.y = 44 + roundf(sin(_t * 8.0) * 1.5)


func _input(event: InputEvent) -> void:
	if not _ativo:
		return
	for acao in ACOES:
		if event.is_action_pressed(acao):
			get_viewport().set_input_as_handled()
			_apertar(acao)
			return
	if event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()


func _apertar(acao: String) -> void:
	var tecla := _teclas[_indice]
	if acao == _sequencia[_indice]:
		Som.tocar("mini_ok", 0.0, 1.0 + _indice * 0.06)
		tecla.position.y = 44
		_indice += 1
		_atualizar()
		if _indice >= _sequencia.size():
			_ativo = false
			_concluido.emit()
	else:
		_erros += 1
		Som.tocar("mini_erro")
		tecla.texture = Jogo.textura("ui/tecla_erro")
		_dica.text = "Ops! Essa não. Tente de novo."
		var t := create_tween()
		var x := tecla.position.x
		t.tween_property(tecla, "position:x", x + 3, 0.04)
		t.tween_property(tecla, "position:x", x - 3, 0.08)
		t.tween_property(tecla, "position:x", x, 0.04)
		t.tween_callback(func():
			if _ativo:
				_atualizar())
