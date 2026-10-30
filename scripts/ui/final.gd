extends Control
## Encerramento da semana: epílogo de cada colega, título conquistado e créditos.

signal _confirmado

var _pronto := false
var _pagina: Control


func _ready() -> void:
	Jogo.tela_cheia(self)
	visible = false


func mostrar() -> void:
	visible = true
	var fundo := ColorRect.new()
	fundo.color = Color("2a1b23")
	Jogo.tela_cheia(fundo)
	add_child(fundo)
	for id in Jogo.COLEGAS:
		await _pagina_colega(id)
	await _pagina_titulo()
	await _pagina_creditos()


func _nova_pagina() -> NinePatchRect:
	if _pagina:
		_pagina.queue_free()
	_pagina = Control.new()
	add_child(_pagina)
	var p := Jogo.painel()
	p.size = Vector2(400, 200)
	p.position = Vector2(40, 35)
	_pagina.add_child(p)
	_pagina.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_pagina, "modulate:a", 1.0, 0.4)
	return p


func _esperar() -> void:
	var dica := Jogo.rotulo("Espaço: continuar", 8, Jogo.COR_TEXTO_SUAVE)
	dica.position = Vector2(400, 246)
	_pagina.add_child(dica)
	dica.add_theme_color_override("font_color", Color("e0c49a"))
	_pronto = false
	await get_tree().create_timer(0.7).timeout
	_pronto = true
	await _confirmado
	Som.tocar("cursor")


func _pagina_colega(id: String) -> void:
	var p := _nova_pagina()
	var coracoes := int(Jogo.amizade.get(id, 0))
	var tipo := "bom" if coracoes >= 3 else "neutro"
	var moldura := ColorRect.new()
	moldura.color = Color("f3d9a6")
	moldura.position = Vector2(18, 18)
	moldura.size = Vector2(84, 84)
	p.add_child(moldura)
	var ret := TextureRect.new()
	ret.texture = Jogo.retrato(id)
	ret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ret.stretch_mode = TextureRect.STRETCH_SCALE
	ret.size = Vector2(80, 80)
	ret.position = Vector2(20, 20)
	p.add_child(ret)
	var nome := Jogo.rotulo(Jogo.nome(id), 14, Jogo.COR_TEXTO, true)
	nome.position = Vector2(116, 20)
	p.add_child(nome)
	var cargo := Jogo.rotulo(Jogo.cargo(id), 9, Jogo.COR_TEXTO_SUAVE)
	cargo.position = Vector2(116, 38)
	p.add_child(cargo)
	for c in Jogo.MAX_CORACOES:
		var cor := TextureRect.new()
		cor.texture = Jogo.textura("ui/coracao" if c < coracoes else "ui/coracao_vazio")
		cor.position = Vector2(116 + c * 14, 54)
		p.add_child(cor)
	var texto := Jogo.rotulo("", 10)
	texto.custom_minimum_size = Vector2(360, 0)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.text = Jogo.falas["epilogos"][id][tipo]
	texto.position = Vector2(20, 112)
	texto.size = Vector2(360, 70)
	p.add_child(texto)
	if tipo == "bom":
		Som.tocar("coracao")
	await _esperar()


func _pagina_titulo() -> void:
	var p := _nova_pagina()
	Som.tocar("fim_dia")
	var a := Jogo.rotulo("SUA SEMANA NO SERVICE DESK", 10, Jogo.COR_TEXTO_SUAVE, true)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a.size = Vector2(400, 14)
	a.position = Vector2(0, 18)
	p.add_child(a)
	var titulo := Jogo.rotulo(Jogo.titulo_final(), 16, Jogo.COR_DESTAQUE, true)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.size = Vector2(400, 22)
	titulo.position = Vector2(0, 40)
	p.add_child(titulo)
	var atendidos := 0
	var total := 0
	var perfeitos := 0
	for r in Jogo.historico:
		atendidos += int(r.get("atendidos", 0))
		total += int(r.get("total", 0))
		perfeitos += int(r.get("perfeitos", 0))
	var media := Jogo.media_estrelas_semana()
	var linhas := [
		"Chamados resolvidos: %d de %d" % [atendidos, total],
		"Resolvidos de primeira: %d" % perfeitos,
		"Avaliação média: %.1f estrelas" % media,
		"Corações da equipe: %d de %d" % [Jogo.total_coracoes(), Jogo.COLEGAS.size() * Jogo.MAX_CORACOES],
	]
	for i in linhas.size():
		var l := Jogo.rotulo(linhas[i], 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(400, 14)
		l.position = Vector2(0, 80 + i * 18)
		p.add_child(l)
	await _esperar()


func _pagina_creditos() -> void:
	var p := _nova_pagina()
	var linhas := [
		["Obrigado por jogar!", 14, true],
		["Chamado Aberto", 10, true],
		["Uma semana no Service Desk da Goestalpine IT-Group", 9, false],
		["", 6, false],
		["Feito em Godot 4. Arte em pixel e sons gerados por código.", 9, false],
		["Fontes Jersey 10 e Pixelify Sans (SIL Open Font License).", 9, false],
		["Personagens e situações são ficcionais.", 9, false],
	]
	var y := 30.0
	for item in linhas:
		var l := Jogo.rotulo(item[0], item[1], Jogo.COR_DESTAQUE if item[2] else Jogo.COR_TEXTO, item[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(400, item[1] + 4)
		l.position = Vector2(0, y)
		p.add_child(l)
		y += item[1] + 10
	await _esperar()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		if _pronto:
			_pronto = false
			_confirmado.emit()
