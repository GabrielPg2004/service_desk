extends Control
## Tela de fim de expediente com o resumo do dia.

signal _confirmado

var _pronto := false
var _conteudo: Control


func _ready() -> void:
	Jogo.tela_cheia(self)
	visible = false


func mostrar(r: Dictionary) -> void:
	if _conteudo:
		_conteudo.queue_free()
	_conteudo = Control.new()
	add_child(_conteudo)
	var fundo := ColorRect.new()
	fundo.color = Color(0.1, 0.05, 0.08, 0.6)
	fundo.size = Vector2(480, 270)
	_conteudo.add_child(fundo)
	var p := Jogo.painel()
	p.size = Vector2(300, 196)
	p.position = Vector2(90, 34)
	_conteudo.add_child(p)

	var titulo := Jogo.rotulo("FIM DO EXPEDIENTE", 14, Jogo.COR_TEXTO, true)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.size = Vector2(300, 18)
	titulo.position = Vector2(0, 12)
	p.add_child(titulo)
	var sub := Jogo.rotulo("%s · Dia %d de %d" % [Jogo.DIAS[int(r["dia"])], int(r["dia"]), Jogo.TOTAL_DIAS], 9,
		Jogo.COR_TEXTO_SUAVE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(300, 12)
	sub.position = Vector2(0, 32)
	p.add_child(sub)

	var atendidos := int(r["atendidos"])
	var media := float(r["estrelas"]) / atendidos if atendidos > 0 else 0.0
	var linhas := [
		["Chamados resolvidos", "%d de %d" % [atendidos, int(r["total"])]],
		["Avaliação média", ""],
		["Resolvidos de primeira", "%d" % int(r["perfeitos"])],
		["Conversas com a equipe", "%d de %d" % [int(r["conversas"]), Jogo.COLEGAS.size()]],
		["Corações conquistados", "+%d" % int(r["coracoes"])],
	]
	for i in linhas.size():
		var y := 56.0 + i * 20.0
		var a := Jogo.rotulo(linhas[i][0], 10)
		a.position = Vector2(26, y)
		p.add_child(a)
		var b := Jogo.rotulo(linhas[i][1], 10, Jogo.COR_DESTAQUE)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.size = Vector2(100, 12)
		b.position = Vector2(174, y)
		p.add_child(b)
		if i == 1:
			for e in 3:
				var est := TextureRect.new()
				est.texture = Jogo.textura("ui/estrela" if media >= e + 0.5 else "ui/estrela_vazia")
				est.position = Vector2(238 + e * 13, y + 1)
				p.add_child(est)
		var linha := ColorRect.new()
		linha.color = Color(0.55, 0.39, 0.32, 0.25)
		linha.position = Vector2(24, y + 15)
		linha.size = Vector2(252, 1)
		p.add_child(linha)

	var dica := Jogo.rotulo("Espaço: continuar", 9, Jogo.COR_TEXTO_SUAVE)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.size = Vector2(300, 12)
	dica.position = Vector2(0, 172)
	p.add_child(dica)

	visible = true
	_conteudo.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_conteudo, "modulate:a", 1.0, 0.4)
	_pronto = false
	await get_tree().create_timer(0.8).timeout
	_pronto = true
	await _confirmado
	Som.tocar("confirmar")
	visible = false


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		if _pronto:
			_pronto = false
			_confirmado.emit()
