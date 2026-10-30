extends Control
## Caixa de diálogo: retrato, nome, texto com efeito de digitação e escolhas.
## Uso: await falar(["linha", "@rafa: outra linha"], "celia")  /  var i = await escolher(pergunta, opcoes)

signal _avancou
signal _escolheu(indice: int)

const LETRAS_POR_SEGUNDO := 65.0
const LARGURA_TEXTO_RETRATO := 340.0
const LARGURA_TEXTO_CHEIA := 436.0
const LARGURA_OPCAO := 420.0

var em_ligacao := ""

var _caixa: NinePatchRect
var _texto: Label
var _placa: NinePatchRect
var _nome: Label
var _cargo: Label
var _moldura: NinePatchRect
var _fundo_retrato: ColorRect
var _retrato: TextureRect
var _seta: TextureRect
var _painel_opcoes: NinePatchRect
var _pergunta: Label
var _destaque: ColorRect
var _cursor: TextureRect
var _rotulos_opcoes: Array[Label] = []

var _digitando := false
var _esperando := false
var _escolhendo := false
var _selecionado := 0
var _progresso := 0.0
var _bloqueio := 0.0
var _t := 0.0
var _tom_voz := 1.0
var _voz_ativa := true


func _ready() -> void:
	Jogo.tela_cheia(self)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

	_caixa = Jogo.painel()
	_caixa.position = Vector2(8, 172)
	_caixa.size = Vector2(464, 94)
	add_child(_caixa)

	_texto = Jogo.rotulo("", 10)
	_texto.custom_minimum_size = Vector2(0, 74)
	_texto.position = Vector2(22, 183)
	_texto.size = Vector2(LARGURA_TEXTO_RETRATO, 74)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_constant_override("line_spacing", 1)
	add_child(_texto)

	_moldura = Jogo.painel()
	_moldura.position = Vector2(372, 176)
	_moldura.size = Vector2(92, 86)
	add_child(_moldura)
	_fundo_retrato = ColorRect.new()
	_fundo_retrato.color = Color("f3d9a6")
	_fundo_retrato.position = Vector2(376, 180)
	_fundo_retrato.size = Vector2(84, 78)
	add_child(_fundo_retrato)
	_retrato = TextureRect.new()
	_retrato.position = Vector2(378, 178)
	_retrato.size = Vector2(80, 80)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_retrato)

	_placa = Jogo.painel("ui/painel", 5)
	_placa.position = Vector2(16, 157)
	_placa.size = Vector2(120, 19)
	add_child(_placa)
	_nome = Jogo.rotulo("", 10, Jogo.COR_CLARA, true)
	_nome.position = Vector2(24, 159)
	_placa.add_child(_nome)
	_nome.position = Vector2(8, 1)
	_cargo = Jogo.rotulo("", 8, Color("e0c49a"))
	_placa.add_child(_cargo)

	_seta = TextureRect.new()
	_seta.texture = Jogo.textura("ui/cursor")
	_seta.rotation = PI / 2
	_seta.position = Vector2(364, 252)
	add_child(_seta)

	_painel_opcoes = Jogo.painel()
	_painel_opcoes.visible = false
	add_child(_painel_opcoes)
	_destaque = ColorRect.new()
	_destaque.color = Color(0.98, 0.84, 0.55, 0.75)
	_painel_opcoes.add_child(_destaque)
	_pergunta = Jogo.rotulo("", 9, Jogo.COR_TEXTO_SUAVE, true)
	_pergunta.position = Vector2(14, 8)
	_painel_opcoes.add_child(_pergunta)
	for i in 3:
		var l: Label = Jogo.rotulo("", 10)
		l.custom_minimum_size = Vector2(LARGURA_OPCAO, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_constant_override("line_spacing", 0)
		_painel_opcoes.add_child(l)
		_rotulos_opcoes.append(l)
	_cursor = TextureRect.new()
	_cursor.texture = Jogo.textura("ui/cursor")
	_painel_opcoes.add_child(_cursor)


func falar(linhas: Array, falante_padrao := "narrador") -> void:
	for linha in linhas:
		var falante := falante_padrao
		var texto := str(linha)
		if texto.begins_with("@"):
			var p := texto.find(":")
			falante = texto.substr(1, p - 1)
			texto = texto.substr(p + 1).strip_edges()
		await _mostrar_linha(falante, texto)


func escolher(pergunta: String, opcoes: Array) -> int:
	visible = true
	_seta.visible = false
	_pergunta.text = pergunta
	var y := 8.0
	if pergunta != "":
		y += 14.0
	for i in 3:
		var l := _rotulos_opcoes[i]
		l.visible = i < opcoes.size()
		if not l.visible:
			continue
		l.text = str(opcoes[i])
		l.position = Vector2(28, y)
		l.size = Vector2(LARGURA_OPCAO, 0)
		y += l.size.y + 5.0
	var altura_painel := y + 5.0
	_painel_opcoes.size = Vector2(464, altura_painel)
	_painel_opcoes.position = Vector2(8, 152 - altura_painel)
	_painel_opcoes.visible = true
	_selecionado = 0
	_escolhendo = true
	_bloqueio = 0.2
	_atualizar_selecao()
	var indice: int = await _escolheu
	_escolhendo = false
	_painel_opcoes.visible = false
	return indice


func fechar() -> void:
	visible = false
	_painel_opcoes.visible = false
	_digitando = false
	_esperando = false
	_escolhendo = false


func ocupado() -> bool:
	return visible


func _mostrar_linha(falante: String, texto: String) -> void:
	visible = true
	_painel_opcoes.visible = false
	_configurar_falante(falante)
	_texto.text = texto
	_texto.visible_characters = 0
	_progresso = 0.0
	_digitando = true
	_esperando = false
	_bloqueio = 0.12
	await _avancou
	_esperando = false


func _configurar_falante(falante: String) -> void:
	var narrador := falante == "narrador" or falante == ""
	_moldura.visible = not narrador
	_fundo_retrato.visible = not narrador
	_retrato.visible = not narrador
	_placa.visible = not narrador
	_voz_ativa = not narrador
	_texto.size.x = LARGURA_TEXTO_CHEIA if narrador else LARGURA_TEXTO_RETRATO
	_texto.add_theme_color_override("font_color", Jogo.COR_TEXTO_SUAVE if narrador else Jogo.COR_TEXTO)
	if narrador:
		return
	_retrato.texture = Jogo.retrato(falante)
	_nome.text = Jogo.nome(falante)
	var cargo := Jogo.cargo(falante)
	if falante == em_ligacao:
		cargo += " · ao telefone"
	_cargo.text = cargo
	var largura_nome := _nome.get_minimum_size().x
	var largura_cargo := _cargo.get_minimum_size().x
	_cargo.position = Vector2(14 + largura_nome, 1)
	_placa.size.x = 22 + largura_nome + largura_cargo
	_tom_voz = 0.85 + float(absi(hash(falante)) % 30) / 100.0


func _atualizar_selecao() -> void:
	for i in _rotulos_opcoes.size():
		var l := _rotulos_opcoes[i]
		l.add_theme_color_override("font_color", Jogo.COR_DESTAQUE if i == _selecionado else Jogo.COR_TEXTO)
	var atual := _rotulos_opcoes[_selecionado]
	_destaque.position = Vector2(10, atual.position.y - 2)
	_destaque.size = Vector2(444, atual.size.y + 3)
	_cursor.position = Vector2(16, atual.position.y + 3)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_bloqueio = maxf(_bloqueio - delta, 0.0)
	if _digitando:
		var antes := int(_progresso)
		_progresso += delta * LETRAS_POR_SEGUNDO
		var agora := int(_progresso)
		_texto.visible_characters = agora
		if _voz_ativa and agora != antes and agora % 3 == 0:
			Som.tocar("texto", -8.0, _tom_voz)
		if agora >= _texto.get_total_character_count():
			_digitando = false
			_esperando = true
			_texto.visible_characters = -1
	_seta.visible = _esperando and not _escolhendo and int(_t * 3.0) % 2 == 0
	if _escolhendo:
		_cursor.position.x = 15 + roundf(sin(_t * 8.0))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _escolhendo:
		var total := 0
		for l in _rotulos_opcoes:
			if l.visible:
				total += 1
		if event.is_action_pressed("mover_cima"):
			_selecionado = (_selecionado - 1 + total) % total
			Som.tocar("cursor")
			_atualizar_selecao()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("mover_baixo"):
			_selecionado = (_selecionado + 1) % total
			Som.tocar("cursor")
			_atualizar_selecao()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interagir"):
			get_viewport().set_input_as_handled()
			if _bloqueio <= 0.0:
				Som.tocar("confirmar")
				_escolheu.emit(_selecionado)
		return
	if event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		if _bloqueio > 0.0:
			return
		if _digitando:
			_digitando = false
			_esperando = true
			_texto.visible_characters = -1
			_bloqueio = 0.08
		elif _esperando:
			_esperando = false
			_avancou.emit()
