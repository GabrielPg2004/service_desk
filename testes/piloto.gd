extends Node
## Piloto automático para testes: joga a semana inteira sozinho, a jato.
## Ativação: godot --path . -- --piloto [--capturas=pasta] [--dia=N] [--erra]
## Escreve "PILOTO: ..." no console e encerra com código 0 ao terminar a semana.

var _capturas := ""
var _erra := false
var _escritorio = null
var _ultima_acao := 0.0
var _relogio := 0.0
var _fotos_tiradas: Dictionary = {}
var _dia_visto := 0
var _dia_inicial := 1
var _jogou := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capturas="):
			_capturas = arg.substr(11)
			DirAccess.make_dir_recursive_absolute(_capturas)
		elif arg == "--erra":
			_erra = true
		elif arg.begins_with("--dia="):
			_dia_inicial = int(arg.substr(6))
	Jogo.apagar_save()
	Engine.time_scale = 3.0 if _capturas != "" else 8.0
	print("PILOTO: iniciado")


func _process(delta: float) -> void:
	_relogio += delta
	var cena := get_tree().current_scene
	if cena == null:
		return
	if cena.name == "Titulo":
		if _jogou:
			print("PILOTO: semana concluída. Título: ", Jogo.titulo_final(), " | corações: ", Jogo.total_coracoes())
			get_tree().quit(0)
			return
		if _relogio > 1.5 and not _fotos_tiradas.has("00_titulo"):
			_foto_uma_vez("00_titulo")
		if _relogio > 2.5:
			_relogio = -100.0
			Jogo.novo_jogo()
			Jogo.dia = _dia_inicial
			get_tree().change_scene_to_file("res://cenas/escritorio.tscn")
		return
	if cena.name != "Escritorio":
		return
	_escritorio = cena
	_jogou = true
	if Jogo.dia != _dia_visto:
		_dia_visto = Jogo.dia
		print("PILOTO: começou o dia ", Jogo.dia)
	_ultima_acao -= delta
	if _ultima_acao > 0.0:
		return
	_ultima_acao = 0.12 if _capturas == "" else 0.35
	_agir()


func _agir() -> void:
	var e = _escritorio
	if e.minigame._ativo:
		_foto_uma_vez("minigame")
		_apertar(e.minigame._sequencia[e.minigame._indice])
		return
	if e.resumo.visible:
		if not _fotos_tiradas.has("resumo_dia%d" % Jogo.dia):
			print("PILOTO: resumo ", Jogo.historico[-1])
		_foto_uma_vez("resumo_dia%d" % Jogo.dia)
		_apertar("interagir")
		return
	if e.tela_final.visible:
		_foto_uma_vez("final_%d" % int(_relogio))
		_apertar("interagir")
		return
	if e.dialogo.visible:
		if e.dialogo._escolhendo:
			_foto_uma_vez("escolha_dia%d" % Jogo.dia)
			var total := 0
			for l in e.dialogo._rotulos_opcoes:
				if l.visible:
					total += 1
			# escolhe a opção certa (ou erra de propósito com --erra, para testar o fluxo de erro)
			var alvo := randi() % total if _erra else _indice_certo(e)
			for i in (alvo - e.dialogo._selecionado + total) % total:
				_apertar("mover_baixo")
			_apertar("interagir")
		else:
			if e.dialogo._placa.visible:
				_foto_uma_vez("dialogo_dia%d" % Jogo.dia)
			_apertar("interagir")
		return
	if e.ocupado:
		return
	if _capturas != "" and not _fotos_tiradas.has("equipe") and e.minutos >= 9 * 60:
		e.pausa.abrir()
		e.pausa._montar_equipe()
		e.pausa._vendo_equipe = true
		e.pausa._equipe.visible = true
		e.pausa._painel.visible = false
		await _foto_uma_vez("equipe")
		e.pausa.fechar()
		return
	_foto_uma_vez("escritorio_dia%d_%02dh" % [Jogo.dia, e.minutos / 60])
	var alvo = _proximo_alvo(e)
	if alvo != null:
		e.jogador.position = alvo["perto"]
		e._interagir(alvo)


func _indice_certo(e) -> int:
	# encontra o texto da opção certa no conteúdo carregado
	var textos: Array = []
	for l in e.dialogo._rotulos_opcoes:
		if l.visible:
			textos.append(l.text)
	for fonte in [Jogo.chamados, Jogo.historias.values()]:
		for item in fonte:
			var lista: Array = item if item is Array else [item]
			for x in lista:
				for etapa in _etapas_de(x):
					for o in etapa.get("opcoes", []):
						if o.get("ok", false) and o["t"] in textos:
							return textos.find(o["t"])
	return 0


func _etapas_de(x: Dictionary) -> Array:
	var etapas: Array = x.get("etapas", []).duplicate()
	if x.has("opcoes"):
		etapas.append(x)
	for t in x.get("tarefas", []):
		if t.has("etapa"):
			etapas.append(t["etapa"])
	return etapas


func _proximo_alvo(e):
	var mundo = e.mundo
	var tel = e._telefone_aguardando()
	if tel != null:
		return {"tipo": "obj", "id": "mesa_gabriel", "perto": Vector2(420, 100)}
	for c in e.ativos:
		var t: Dictionary = e._tarefa_atual(c)
		if t.is_empty():
			continue
		var a: String = t["alvo"]
		if a.begins_with("npc:"):
			var id := a.substr(4)
			return {"tipo": "npc", "id": id, "perto": e._colegas[id].position + Vector2(-12, 0)}
		if a.begins_with("obj:"):
			var id := a.substr(4)
			for it in mundo.interativos:
				if it["id"] == id:
					return {"tipo": "obj", "id": id, "perto": it["rect"].get_center() + Vector2(0, 14)}
		if a == "cliente" and c["npc"] != null and c["chegou"]:
			return {"tipo": "cliente", "id": c["dados"]["cliente"], "chamado": c,
				"perto": c["npc"].position + Vector2(0, -36)}
	for c in e.ativos:
		if c["estado"] != "aguardando" or not c["chegou"]:
			continue
		if c["npc"] != null:
			return {"tipo": "cliente", "id": c["dados"]["cliente"], "chamado": c,
				"perto": c["npc"].position + Vector2(0, -36)}
		if c["dados"]["canal"] in ["colega", "incidente"]:
			var id: String = c["dados"]["cliente"]
			return {"tipo": "npc", "id": id, "perto": e._colegas[id].position + Vector2(-12, 0)}
	for id in Jogo.COLEGAS:
		if e._cena_disponivel(id) != null:
			return {"tipo": "npc", "id": id, "perto": e._colegas[id].position + Vector2(-12, 0)}
	return null


func _apertar(acao: String) -> void:
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = true
	Input.parse_input_event(ev)
	var solta := InputEventAction.new()
	solta.action = acao
	solta.pressed = false
	Input.parse_input_event(solta)


func _foto_uma_vez(nome: String) -> void:
	if _fotos_tiradas.has(nome):
		return
	_fotos_tiradas[nome] = true
	await _foto(nome)


func _foto(nome: String) -> void:
	if _capturas == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png("%s/%s.png" % [_capturas, nome])
