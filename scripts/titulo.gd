extends Node2D
## Tela de título: o escritório ao fundo com a câmera passeando, logo e menu.

const Mundo := preload("res://scripts/mundo.gd")
const Npc := preload("res://scripts/npc.gd")

const AJUDA := """Setas ou WASD: andar
Espaço, Enter ou Z: interagir e avançar o diálogo
Cima / Baixo: escolher a resposta
Esc: pausa, equipe e música

Atenda os usuários no balcão e o telefone da sua mesa.
Em cada atendimento, escolha a resposta certa entre três.
Balão amarelo: alguém da equipe quer conversar.
Cada boa conversa vale um coração de amizade.

Cinco dias de trabalho, cerca de uma hora de jogo."""

var _opcoes: Array = []
var _rotulos: Array[Label] = []
var _cursor: TextureRect
var _menu: Control
var _ajuda: Control
var _camera: Camera2D
var _selecionado := 0
var _t := 0.0
var _bloqueio := 0.4


func _ready() -> void:
	get_tree().paused = false
	Som.tocar_musica("musica_escritorio")
	var mundo = Mundo.new()
	add_child(mundo)
	mundo.construir()
	for id in Jogo.COLEGAS:
		var npc = Npc.new()
		mundo.ysort.add_child(npc)
		npc.position = Mundo.POS_COLEGAS[id]
		npc.configurar(id, true)
	var luz := CanvasModulate.new()
	luz.color = Color(1.0, 0.95, 0.88)
	add_child(luz)
	_camera = Camera2D.new()
	_camera.position = Vector2(512, 150)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(mundo.limites().end.x)
	_camera.limit_bottom = int(mundo.limites().end.y)
	add_child(_camera)
	_camera.make_current()

	var camada := CanvasLayer.new()
	add_child(camada)
	var raiz := Control.new()
	Jogo.tela_cheia(raiz)
	raiz.theme = Jogo.tema
	camada.add_child(raiz)
	var veu := ColorRect.new()
	veu.color = Color(0.16, 0.1, 0.13, 0.35)
	Jogo.tela_cheia(veu)
	raiz.add_child(veu)

	var logo := Jogo.painel()
	logo.position = Vector2(62, 26)
	logo.size = Vector2(356, 74)
	raiz.add_child(logo)
	var titulo := Jogo.rotulo("Chamado Aberto", 30, Jogo.COR_DESTAQUE, true)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.size = Vector2(356, 36)
	titulo.position = Vector2(0, 10)
	logo.add_child(titulo)
	var sub := Jogo.rotulo("Uma semana no Service Desk da Goestalpine IT-Group", 9, Jogo.COR_TEXTO_SUAVE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(356, 14)
	sub.position = Vector2(0, 48)
	logo.add_child(sub)

	_menu = Jogo.painel()
	_menu.position = Vector2(170, 124)
	raiz.add_child(_menu)
	var dia_salvo := Jogo.dia_salvo()
	if dia_salvo > 0:
		_opcoes.append(["Continuar (%s)" % Jogo.DIAS[dia_salvo], "continuar"])
	_opcoes.append(["Novo jogo", "novo"])
	_opcoes.append(["Como jogar", "ajuda"])
	for i in _opcoes.size():
		var l := Jogo.rotulo(_opcoes[i][0], 11)
		l.position = Vector2(26, 10 + i * 18)
		_menu.add_child(l)
		_rotulos.append(l)
	_menu.size = Vector2(140, 16 + _opcoes.size() * 18)
	_cursor = TextureRect.new()
	_cursor.texture = Jogo.textura("ui/cursor")
	_menu.add_child(_cursor)

	var rodape := Jogo.rotulo("Setas: escolher   Espaço / Enter: confirmar", 8, Jogo.COR_CLARA)
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.size = Vector2(480, 12)
	rodape.position = Vector2(0, 252)
	raiz.add_child(rodape)

	_ajuda = Jogo.painel()
	_ajuda.position = Vector2(60, 34)
	_ajuda.size = Vector2(360, 202)
	_ajuda.visible = false
	raiz.add_child(_ajuda)
	var texto := Jogo.rotulo("", 10)
	texto.custom_minimum_size = Vector2(324, 0)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.text = AJUDA
	texto.position = Vector2(18, 14)
	_ajuda.add_child(texto)
	_atualizar()


func _atualizar() -> void:
	for i in _rotulos.size():
		_rotulos[i].add_theme_color_override("font_color", Jogo.COR_DESTAQUE if i == _selecionado else Jogo.COR_TEXTO)
	_cursor.position = Vector2(12, 14 + _selecionado * 18)


func _process(delta: float) -> void:
	_t += delta
	_bloqueio = maxf(_bloqueio - delta, 0.0)
	_camera.position.x = 512.0 + sin(_t * 0.07) * 272.0
	_cursor.position.x = 12.0 + roundf(sin(_t * 6.0))


func _unhandled_input(event: InputEvent) -> void:
	if _bloqueio > 0.0:
		return
	if _ajuda.visible:
		if event.is_action_pressed("interagir") or event.is_action_pressed("menu"):
			_ajuda.visible = false
			_menu.visible = true
			Som.tocar("cancelar")
		return
	if event.is_action_pressed("mover_cima"):
		_selecionado = (_selecionado - 1 + _opcoes.size()) % _opcoes.size()
		Som.tocar("cursor")
		_atualizar()
	elif event.is_action_pressed("mover_baixo"):
		_selecionado = (_selecionado + 1) % _opcoes.size()
		Som.tocar("cursor")
		_atualizar()
	elif event.is_action_pressed("interagir"):
		Som.tocar("confirmar")
		match _opcoes[_selecionado][1]:
			"continuar":
				Jogo.carregar()
				get_tree().change_scene_to_file("res://cenas/escritorio.tscn")
			"novo":
				Jogo.novo_jogo()
				Jogo.apagar_save()
				get_tree().change_scene_to_file("res://cenas/escritorio.tscn")
			"ajuda":
				_ajuda.visible = true
				_menu.visible = false
