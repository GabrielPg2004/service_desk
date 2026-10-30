extends Control
## Menu de pausa: continuar, ver a equipe (corações), ligar/desligar música, voltar ao título.

var _painel: NinePatchRect
var _rotulos: Array[Label] = []
var _cursor: TextureRect
var _equipe: Control
var _selecionado := 0
var _vendo_equipe := false
var _selecionado_equipe := 0
var _destaque_equipe: ColorRect
var _descricao: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Jogo.tela_cheia(self)
	visible = false
	var fundo := ColorRect.new()
	fundo.color = Color(0.1, 0.05, 0.08, 0.55)
	Jogo.tela_cheia(fundo)
	add_child(fundo)

	_painel = Jogo.painel()
	_painel.size = Vector2(170, 120)
	_painel.position = Vector2(155, 60)
	add_child(_painel)
	var titulo := Jogo.rotulo("PAUSA", 12, Jogo.COR_TEXTO, true)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.size = Vector2(170, 16)
	titulo.position = Vector2(0, 10)
	_painel.add_child(titulo)
	for i in 4:
		var l := Jogo.rotulo("", 10)
		l.position = Vector2(34, 32 + i * 18)
		_painel.add_child(l)
		_rotulos.append(l)
	_cursor = TextureRect.new()
	_cursor.texture = Jogo.textura("ui/cursor")
	_painel.add_child(_cursor)

	_equipe = Control.new()
	_equipe.visible = false
	add_child(_equipe)


func abrir() -> void:
	get_tree().paused = true
	visible = true
	_vendo_equipe = false
	_equipe.visible = false
	_painel.visible = true
	_selecionado = 0
	_atualizar()
	Som.tocar("confirmar")


func fechar() -> void:
	visible = false
	get_tree().paused = false
	Som.tocar("cancelar")


func _atualizar() -> void:
	var textos := ["Continuar", "Equipe", "Música: " + ("ligada" if Som.musica_ligada else "desligada"),
		"Voltar ao título"]
	for i in _rotulos.size():
		_rotulos[i].text = textos[i]
		_rotulos[i].add_theme_color_override("font_color", Jogo.COR_DESTAQUE if i == _selecionado else Jogo.COR_TEXTO)
	_cursor.position = Vector2(22, 36 + _selecionado * 18)


func _montar_equipe() -> void:
	for filho in _equipe.get_children():
		filho.queue_free()
	var painel := Jogo.painel()
	painel.size = Vector2(452, 246)
	painel.position = Vector2(14, 12)
	_equipe.add_child(painel)
	var titulo := Jogo.rotulo("SUA EQUIPE", 12, Jogo.COR_TEXTO, true)
	titulo.position = Vector2(16, 10)
	painel.add_child(titulo)
	var voltar := Jogo.rotulo("Setas: escolher   Esc: voltar", 8, Jogo.COR_TEXTO_SUAVE)
	voltar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	voltar.size = Vector2(200, 12)
	voltar.position = Vector2(236, 10)
	painel.add_child(voltar)
	_destaque_equipe = ColorRect.new()
	_destaque_equipe.color = Color(0.98, 0.84, 0.55, 0.8)
	_destaque_equipe.size = Vector2(212, 50)
	painel.add_child(_destaque_equipe)
	for i in Jogo.COLEGAS.size():
		var id: String = Jogo.COLEGAS[i]
		var x := 12.0 + (i % 2) * 216.0
		var y := 30.0 + (i / 2) * 52.0
		var ret := TextureRect.new()
		ret.texture = Jogo.retrato(id)
		ret.position = Vector2(x + 4, y + 5)
		painel.add_child(ret)
		var nome := Jogo.rotulo(Jogo.nome(id), 10, Jogo.COR_TEXTO, true)
		nome.position = Vector2(x + 50, y + 4)
		painel.add_child(nome)
		var cargo := Jogo.rotulo(Jogo.cargo(id), 7, Jogo.COR_TEXTO_SUAVE)
		cargo.position = Vector2(x + 50, y + 16)
		painel.add_child(cargo)
		for c in Jogo.MAX_CORACOES:
			var cor := TextureRect.new()
			cor.texture = Jogo.textura("ui/coracao" if c < int(Jogo.amizade.get(id, 0)) else "ui/coracao_vazio")
			cor.position = Vector2(x + 50 + c * 13, y + 33)
			painel.add_child(cor)
	var linha := ColorRect.new()
	linha.color = Color(0.55, 0.39, 0.32, 0.35)
	linha.position = Vector2(14, 190)
	linha.size = Vector2(424, 1)
	painel.add_child(linha)
	_descricao = Jogo.rotulo("", 9, Jogo.COR_TEXTO)
	_descricao.custom_minimum_size = Vector2(420, 0)
	_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descricao.position = Vector2(16, 196)
	painel.add_child(_descricao)
	_atualizar_equipe()


func _atualizar_equipe() -> void:
	var i := _selecionado_equipe
	_destaque_equipe.position = Vector2(12.0 + (i % 2) * 216.0, 30.0 + (i / 2) * 52.0)
	_descricao.text = Jogo.descricao(Jogo.COLEGAS[i])


func _input(event: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if _vendo_equipe:
		var passo := 0
		if event.is_action_pressed("mover_esq"):
			passo = -1
		elif event.is_action_pressed("mover_dir"):
			passo = 1
		elif event.is_action_pressed("mover_cima"):
			passo = -2
		elif event.is_action_pressed("mover_baixo"):
			passo = 2
		if passo != 0:
			_selecionado_equipe = (_selecionado_equipe + passo + Jogo.COLEGAS.size()) % Jogo.COLEGAS.size()
			Som.tocar("cursor")
			_atualizar_equipe()
		elif event.is_action_pressed("interagir") or event.is_action_pressed("menu"):
			_vendo_equipe = false
			_equipe.visible = false
			_painel.visible = true
			Som.tocar("cancelar")
		return
	if event.is_action_pressed("menu"):
		fechar()
	elif event.is_action_pressed("mover_cima"):
		_selecionado = (_selecionado + 3) % 4
		Som.tocar("cursor")
		_atualizar()
	elif event.is_action_pressed("mover_baixo"):
		_selecionado = (_selecionado + 1) % 4
		Som.tocar("cursor")
		_atualizar()
	elif event.is_action_pressed("interagir"):
		match _selecionado:
			0:
				fechar()
			1:
				_montar_equipe()
				_vendo_equipe = true
				_equipe.visible = true
				_painel.visible = false
				Som.tocar("confirmar")
			2:
				Som.alternar_musica()
				Som.tocar("confirmar")
				_atualizar()
			3:
				get_tree().paused = false
				get_tree().change_scene_to_file("res://cenas/titulo.tscn")
