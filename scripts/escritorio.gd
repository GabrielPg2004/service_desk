extends Node2D
## Um dia de trabalho no Service Desk: relógio, chamados, colegas, telefone, almoço e fim do expediente.

const Mundo := preload("res://scripts/mundo.gd")
const Jogador := preload("res://scripts/jogador.gd")
const Npc := preload("res://scripts/npc.gd")
const Dialogo := preload("res://scripts/ui/dialogo.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const Minigame := preload("res://scripts/ui/minigame.gd")
const Pausa := preload("res://scripts/ui/pausa.gd")
const Resumo := preload("res://scripts/ui/resumo.gd")
const Final := preload("res://scripts/ui/final.gd")
const Transicao := preload("res://scripts/ui/transicao.gd")

const INICIO := 8 * 60
const ALMOCO := 12 * 60
const VOLTA_ALMOCO := 13 * 60
const FIM := 17 * 60
const SEG_POR_MINUTO := 0.75
const SEG_POR_MINUTO_RAPIDO := 0.12
const CORES_DO_DIA := [[480, Color(0.92, 0.94, 1.0)], [660, Color(1, 1, 1)], [900, Color(1, 0.97, 0.92)],
	[1020, Color(1.0, 0.88, 0.78)]]
const NOMES_OBJETOS := {
	"impressora": "Impressora PA-IMP-01", "cafeteira": "Tomar um café", "bebedouro": "Beber água",
	"estoque": "Almoxarifado", "rack_rede": "Patch panel", "rack": "Servidores", "quadro_branco": "Ler o quadro",
	"planta": "Olhar a planta", "porta": "Porta de entrada", "tv_painel": "Painel de monitoramento",
	"poster": "Pôster", "bancada": "Bancada de ferramentas", "mesa_reuniao": "Mesa de reunião",
}

var mundo
var jogador
var dialogo
var hud
var minigame
var pausa
var resumo
var tela_final
var transicao
var luz: CanvasModulate

var minutos := INICIO
var ocupado := true
var _acumulador := 0.0
var _almoco_feito := false
var _encerrado := false
var _rapido := false
var _pendentes: Array = []
var ativos: Array = []
var _concluidos: Array = []
var _total_do_dia := 0
var _colegas: Dictionary = {}
var _vagas: Array = [null, null, null]
var _fila_balcao: Array = []
var _incidente := false
var _coracoes_hoje := 0
var _conversas_hoje := 0
var _alvo = null
var _tempo_toque := 0.0
var _tempo_marcadores := 0.0


func _ready() -> void:
	mundo = Mundo.new()
	add_child(mundo)
	mundo.construir()
	luz = CanvasModulate.new()
	add_child(luz)

	jogador = Jogador.new()
	mundo.ysort.add_child(jogador)
	jogador.position = Mundo.INICIO_JOGADOR
	jogador.configurar(mundo.limites())

	for id in Jogo.COLEGAS:
		var npc = Npc.new()
		mundo.ysort.add_child(npc)
		npc.position = Mundo.POS_COLEGAS[id]
		npc.configurar(id, true)
		_colegas[id] = npc

	var camada := CanvasLayer.new()
	add_child(camada)
	var raiz := Control.new()
	Jogo.tela_cheia(raiz)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = Jogo.tema
	camada.add_child(raiz)
	hud = Hud.new()
	raiz.add_child(hud)
	dialogo = Dialogo.new()
	raiz.add_child(dialogo)
	minigame = Minigame.new()
	raiz.add_child(minigame)
	resumo = Resumo.new()
	raiz.add_child(resumo)
	tela_final = Final.new()
	raiz.add_child(tela_final)
	transicao = Transicao.new()
	raiz.add_child(transicao)
	pausa = Pausa.new()
	raiz.add_child(pausa)

	_pendentes = Jogo.chamados_do_dia(Jogo.dia)
	_total_do_dia = _pendentes.size()
	_atualizar_luz()
	hud.atualizar_relogio(Jogo.dia, minutos, false)
	_atualizar_hud_chamados()
	Som.tocar_musica("musica_escritorio")
	_iniciar_dia()


func _iniciar_dia() -> void:
	ocupado = true
	jogador.pode_mover = false
	transicao.modulate.a = 1.0
	await transicao.cartao(Jogo.DIAS[Jogo.dia], "Dia %d de %d" % [Jogo.dia, Jogo.TOTAL_DIAS])
	await transicao.clarear()
	await dialogo.falar(Jogo.falas["inicio_dia"][str(Jogo.dia)], "narrador")
	dialogo.fechar()
	hud.mostrar_ajuda(Jogo.dia == 1)
	_liberar()


func _liberar() -> void:
	ocupado = false
	jogador.pode_mover = true


# ---------------------------------------------------------------------------
# Relógio
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	_tempo_marcadores -= delta
	if _tempo_marcadores <= 0.0:
		_tempo_marcadores = 0.2
		_atualizar_marcadores()
	_tocar_telefone(delta)
	if ocupado or _encerrado:
		hud.mostrar_dica("")
		return
	_alvo = _alvo_interacao()
	hud.mostrar_dica(_texto_dica(_alvo) if _alvo else "")
	_rapido = not _tem_algo_a_fazer()
	var seg := SEG_POR_MINUTO_RAPIDO if _rapido else SEG_POR_MINUTO
	_acumulador += delta
	while _acumulador >= seg and not ocupado:
		_acumulador -= seg
		_passar_minuto()


func _passar_minuto() -> void:
	minutos += 1
	hud.atualizar_relogio(Jogo.dia, minutos, _rapido)
	_atualizar_luz()
	if Jogo.dia == 1 and minutos == 10 * 60:
		hud.mostrar_ajuda(false)
	while not _pendentes.is_empty() and Jogo.minutos_de(_pendentes[0]["hora"]) <= minutos:
		_chegar_chamado(_pendentes.pop_front())
	if minutos == 16 * 60 + 30:
		hud.aviso("Faltam 30 minutos para as 17h")
	if minutos >= ALMOCO and not _almoco_feito:
		_almoco()
	elif minutos >= FIM:
		_encerrar_dia()


func _atualizar_luz() -> void:
	var cor: Color = CORES_DO_DIA[0][1]
	for i in range(1, CORES_DO_DIA.size()):
		var a: Array = CORES_DO_DIA[i - 1]
		var b: Array = CORES_DO_DIA[i]
		if minutos >= a[0] and minutos <= b[0]:
			cor = a[1].lerp(b[1], float(minutos - a[0]) / float(b[0] - a[0]))
		elif minutos > b[0]:
			cor = b[1]
	luz.color = cor


func _tem_algo_a_fazer() -> bool:
	if not ativos.is_empty() or not _fila_balcao.is_empty():
		return true
	for id in Jogo.COLEGAS:
		if _cena_disponivel(id) != null:
			return true
	return false


func _almoco() -> void:
	_almoco_feito = true
	ocupado = true
	jogador.pode_mover = false
	await transicao.escurecer()
	await dialogo.falar(Jogo.falas["almoco"][str(Jogo.dia)], "narrador")
	dialogo.fechar()
	minutos = VOLTA_ALMOCO
	hud.atualizar_relogio(Jogo.dia, minutos, false)
	_atualizar_luz()
	await transicao.clarear()
	_liberar()


func _encerrar_dia() -> void:
	_encerrado = true
	ocupado = true
	jogador.pode_mover = false
	Som.tocar("fim_dia")
	await dialogo.falar(Jogo.falas["fim_dia"][str(Jogo.dia)], "narrador")
	dialogo.fechar()
	var estrelas := 0
	var perfeitos := 0
	for c in _concluidos:
		estrelas += int(c["estrelas"])
		if int(c["estrelas"]) == 3:
			perfeitos += 1
	var r := {"dia": Jogo.dia, "atendidos": _concluidos.size(), "total": _total_do_dia, "estrelas": estrelas,
		"perfeitos": perfeitos, "conversas": _conversas_hoje, "coracoes": _coracoes_hoje}
	Jogo.historico.append(r)
	await resumo.mostrar(r)
	if Jogo.dia < Jogo.TOTAL_DIAS:
		Jogo.dia += 1
		Jogo.salvar()
		await transicao.escurecer()
		get_tree().reload_current_scene()
		return
	await dialogo.falar(Jogo.falas["final_abertura"], "celia")
	dialogo.fechar()
	await transicao.escurecer()
	transicao.modulate.a = 0.0
	await tela_final.mostrar()
	Jogo.apagar_save()
	get_tree().change_scene_to_file("res://cenas/titulo.tscn")


# ---------------------------------------------------------------------------
# Chegada de chamados
# ---------------------------------------------------------------------------
func _chegar_chamado(dados: Dictionary) -> void:
	var c := {"dados": dados, "estado": "aguardando", "tarefa": 0, "erros": 0, "npc": null, "chegou": false,
		"vaga": -1}
	ativos.append(c)
	var canal: String = dados["canal"]
	var cliente := Jogo.nome(dados["cliente"])
	match canal:
		"balcao":
			hud.aviso("Chamado #%d: %s no balcão" % [dados["numero"], cliente], "ui/icone_balcao")
			_trazer_cliente(c)
		"telefone":
			hud.aviso("Chamado #%d: telefone tocando!" % dados["numero"], "ui/icone_telefone")
			c["chegou"] = true
		"incidente":
			_incidente = true
			c["chegou"] = true
			Som.tocar("alarme")
			Som.tocar_musica("musica_incidente")
			hud.aviso("INCIDENTE: rede fora do ar!", "ui/icone_alerta", -1, Jogo.COR_OURO)
			hud.aviso("Fale com a Dona Célia", "ui/icone_equipe")
		_:
			c["chegou"] = true
			hud.aviso("%s precisa de você" % cliente, "ui/icone_equipe")
	_atualizar_hud_chamados()


func _trazer_cliente(c: Dictionary) -> void:
	var vaga := _vagas.find(null)
	if vaga < 0:
		_fila_balcao.append(c)
		return
	_vagas[vaga] = c
	c["vaga"] = vaga
	var npc = Npc.new()
	mundo.ysort.add_child(npc)
	npc.position = Mundo.ENTRADA
	npc.configurar(c["dados"]["cliente"], false)
	c["npc"] = npc
	Som.tocar("porta", -4.0)
	var alvo: Vector2 = Mundo.VAGAS_BALCAO[vaga]
	await npc.andar([Vector2(Mundo.ENTRADA.x, Mundo.CORREDOR_Y), Vector2(alvo.x, Mundo.CORREDOR_Y), alvo])
	if not is_instance_valid(npc):
		return
	npc.visual.direcao = "cima"
	c["chegou"] = true
	Som.tocar("campainha", -6.0)


func _dispensar_cliente(c: Dictionary) -> void:
	var npc = c["npc"]
	c["npc"] = null
	if c["vaga"] >= 0:
		_vagas[c["vaga"]] = null
		c["vaga"] = -1
	if npc == null:
		return
	npc.mostrar_balao("")
	npc.mostrar_marcador(false)
	await npc.andar([Vector2(npc.position.x, Mundo.CORREDOR_Y), Vector2(Mundo.ENTRADA.x, Mundo.CORREDOR_Y),
		Mundo.ENTRADA + Vector2(0, 12)])
	npc.queue_free()
	if not _fila_balcao.is_empty():
		_trazer_cliente(_fila_balcao.pop_front())


# ---------------------------------------------------------------------------
# Interação
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and not pausa.visible and not _encerrado:
		get_viewport().set_input_as_handled()
		pausa.abrir()
		return
	if ocupado or _encerrado:
		return
	if event.is_action_pressed("interagir") and _alvo != null:
		get_viewport().set_input_as_handled()
		_interagir(_alvo)


func _alvo_interacao():
	var pe: Vector2 = jogador.position
	var frente: Vector2 = jogador.vetor_frente()
	var candidatos: Array = mundo.interativos.duplicate()
	for id in _colegas:
		var npc = _colegas[id]
		candidatos.append({"tipo": "npc", "id": id, "rect": Rect2(npc.position - Vector2(6, 6), Vector2(12, 8)),
			"alcance": 14.0})
	for c in ativos:
		var npc = c["npc"]
		if npc != null and c["chegou"]:
			candidatos.append({"tipo": "cliente", "id": c["dados"]["cliente"], "chamado": c,
				"rect": Rect2(npc.position - Vector2(6, 6), Vector2(12, 8)), "alcance": 40.0})
	var melhor = null
	var melhor_nota := INF
	for it in candidatos:
		var r: Rect2 = it["rect"]
		var ponto := Vector2(clampf(pe.x, r.position.x, r.end.x), clampf(pe.y, r.position.y, r.end.y))
		var v := ponto - pe
		var d := v.length()
		if d > float(it["alcance"]):
			continue
		var alinhamento := 1.0 if d < 1.0 else v.normalized().dot(frente)
		if alinhamento < 0.35:
			continue
		var nota := d - alinhamento * 12.0
		if nota < melhor_nota:
			melhor_nota = nota
			melhor = it
	return melhor


func _texto_dica(alvo: Dictionary) -> String:
	match alvo["tipo"]:
		"npc":
			return "Falar com " + Jogo.nome(alvo["id"])
		"cliente":
			return "Atender " + Jogo.nome(alvo["id"])
	if alvo["id"] == "mesa_gabriel":
		return "Atender o telefone" if _telefone_aguardando() != null else "Sua mesa"
	return NOMES_OBJETOS.get(alvo["id"], "Interagir")


func _interagir(alvo: Dictionary) -> void:
	ocupado = true
	jogador.pode_mover = false
	hud.mostrar_dica("")
	match alvo["tipo"]:
		"npc":
			await _falar_com_colega(alvo["id"])
		"cliente":
			await _atender_cliente(alvo["chamado"])
		"obj":
			await _usar_objeto(alvo["id"])
	dialogo.fechar()
	_atualizar_hud_chamados()
	if not _encerrado:
		_liberar()


func _falar_com_colega(id: String) -> void:
	var npc = _colegas[id]
	npc.olhar_para(jogador.position)
	var c = _chamado_com_tarefa("npc:" + id)
	if c != null:
		await _executar_tarefa(c)
		return
	c = _chamado_de_colega(id)
	if c != null:
		await _executar_etapas(c)
		return
	var cena = _cena_disponivel(id)
	if cena != null:
		await _executar_cena(id, cena)
		return
	await dialogo.falar([Jogo.falas["falas_soltas"][id].pick_random()], id)


func _atender_cliente(c: Dictionary) -> void:
	var npc = c["npc"]
	if npc:
		npc.olhar_para(jogador.position)
	if c["estado"] == "aguardando":
		await _executar_etapas(c)
	elif _tarefa_atual(c).get("alvo", "") == "cliente":
		await _executar_tarefa(c)
	else:
		await dialogo.falar([Jogo.falas["espera"].pick_random()], c["dados"]["cliente"])


func _usar_objeto(id: String) -> void:
	if id == "mesa_gabriel":
		var tel = _telefone_aguardando()
		if tel != null:
			Som.tocar("confirmar")
			dialogo.em_ligacao = tel["dados"]["cliente"]
			await _executar_etapas(tel)
			dialogo.em_ligacao = ""
		elif _incidente:
			await dialogo.falar(Jogo.falas["objetos"]["telefone_incidente"])
		else:
			var fila := ativos.size()
			await dialogo.falar(["@narrador: Sistema de chamados: %d resolvido(s) hoje, %d em aberto." %
				[_concluidos.size(), fila], Jogo.falas["objetos"]["telefone_mudo"][0]])
		return
	var c = _chamado_com_tarefa("obj:" + id)
	if c != null:
		await _executar_tarefa(c)
		return
	if id == "cafeteira":
		Som.tocar("cafe")
	var linhas: Array = Jogo.falas["objetos"].get(id, ["@narrador: Nada de especial aqui."])
	await dialogo.falar([linhas.pick_random()])


# ---------------------------------------------------------------------------
# Fluxo de um chamado
# ---------------------------------------------------------------------------
func _executar_etapas(c: Dictionary) -> void:
	var d: Dictionary = c["dados"]
	var falante: String = d["cliente"]
	c["estado"] = "em_atendimento"
	await dialogo.falar(d["abertura"], falante)
	for etapa in d["etapas"]:
		await _rodar_etapa(c, etapa, falante)
	c["estado"] = "tarefa"
	c["tarefa"] = 0
	var tarefas: Array = d.get("tarefas", [])
	if tarefas.is_empty():
		await _concluir(c, falante)
		return
	var cliente_espera := false
	for t in tarefas:
		if t["alvo"] == "cliente":
			cliente_espera = true
	if d["canal"] == "balcao" and not cliente_espera:
		await dialogo.falar(Jogo.falas["cliente_sai"], falante)
		dialogo.fechar()
		_dispensar_cliente(c)
	hud.aviso("Objetivo: " + tarefas[0]["objetivo"])


func _rodar_etapa(c: Dictionary, etapa: Dictionary, falante: String) -> void:
	var opcoes: Array = etapa["opcoes"].duplicate()
	opcoes.shuffle()
	while true:
		var textos: Array = []
		for o in opcoes:
			textos.append(o["t"])
		var i: int = await dialogo.escolher(etapa.get("pergunta", ""), textos)
		var escolha: Dictionary = opcoes[i]
		if escolha.get("ok", false):
			Som.tocar("acerto")
			await dialogo.falar(escolha.get("r", []), falante)
			return
		c["erros"] += 1
		Som.tocar("erro")
		await dialogo.falar(escolha.get("r", []), falante)
		opcoes.remove_at(i)


func _tarefa_atual(c: Dictionary) -> Dictionary:
	var tarefas: Array = c["dados"].get("tarefas", [])
	if c["estado"] != "tarefa" or c["tarefa"] >= tarefas.size():
		return {}
	return tarefas[c["tarefa"]]


func _executar_tarefa(c: Dictionary) -> void:
	var t := _tarefa_atual(c)
	var alvo: String = t["alvo"]
	var falante := "narrador"
	if alvo.begins_with("npc:"):
		falante = alvo.substr(4)
	elif alvo == "cliente":
		falante = c["dados"]["cliente"]
	await dialogo.falar(t.get("falas", []), falante)
	if t.has("etapa"):
		await _rodar_etapa(c, t["etapa"], falante)
	if t.has("minigame"):
		dialogo.fechar()
		await minigame.jogar(t["minigame"]["titulo"], int(t["minigame"]["setas"]))
	await dialogo.falar(t.get("depois", []), falante)
	c["tarefa"] += 1
	var tarefas: Array = c["dados"]["tarefas"]
	if c["tarefa"] >= tarefas.size():
		await _concluir(c, falante)
	else:
		hud.aviso("Objetivo: " + tarefas[c["tarefa"]]["objetivo"])


func _concluir(c: Dictionary, falante: String) -> void:
	var d: Dictionary = c["dados"]
	await dialogo.falar(d["conclusao"], falante)
	dialogo.fechar()
	c["estado"] = "concluido"
	ativos.erase(c)
	var estrelas := maxi(1, 3 - int(c["erros"]))
	_concluidos.append({"id": d["id"], "estrelas": estrelas})
	Som.tocar("fim_dia", -6.0)
	hud.aviso("#%d encerrado" % d["numero"], "", estrelas)
	if c["npc"] != null:
		c["npc"].mostrar_balao_temporario("coracao", 1.5)
		_dispensar_cliente(c)
	if d["canal"] == "incidente":
		_incidente = false
		Som.tocar_musica("musica_escritorio")
		hud.aviso("Incidente encerrado. A equipe quer conversar.", "ui/icone_equipe")


# ---------------------------------------------------------------------------
# Histórias da equipe
# ---------------------------------------------------------------------------
func _cena_disponivel(id: String):
	for cena in Jogo.historias.get(id, []):
		if int(cena["dia"]) != Jogo.dia:
			continue
		if Jogo.cenas_vistas.has("%s_%d" % [id, Jogo.dia]):
			return null
		if minutos < Jogo.minutos_de(cena["hora"]):
			return null
		if cena.has("apos") and not _foi_concluido(cena["apos"]):
			return null
		return cena
	return null


func _executar_cena(id: String, cena: Dictionary) -> void:
	await dialogo.falar(cena["falas"], id)
	var opcoes: Array = cena["opcoes"].duplicate()
	opcoes.shuffle()
	var textos: Array = []
	for o in opcoes:
		textos.append(o["t"])
	var i: int = await dialogo.escolher(cena.get("pergunta", "O que você diz?"), textos)
	var escolha: Dictionary = opcoes[i]
	Jogo.cenas_vistas["%s_%d" % [id, Jogo.dia]] = true
	_conversas_hoje += 1
	if escolha.get("ok", false):
		Jogo.dar_coracao(id)
		_coracoes_hoje += 1
		Som.tocar("coracao")
		_colegas[id].mostrar_balao_temporario("coracao", 2.0)
	await dialogo.falar(escolha.get("r", []), id)
	await dialogo.falar(cena.get("fim", []), id)
	dialogo.fechar()
	if escolha.get("ok", false):
		hud.aviso("%s: amizade %d/%d" % [Jogo.nome(id), int(Jogo.amizade[id]), Jogo.MAX_CORACOES],
			"ui/coracao")


# ---------------------------------------------------------------------------
# Consultas
# ---------------------------------------------------------------------------
func _foi_concluido(id_chamado: String) -> bool:
	for c in _concluidos:
		if c["id"] == id_chamado:
			return true
	return false


func _chamado_com_tarefa(alvo: String):
	for c in ativos:
		if _tarefa_atual(c).get("alvo", "") == alvo:
			return c
	return null


func _chamado_de_colega(id: String):
	for c in ativos:
		if c["estado"] == "aguardando" and c["dados"]["canal"] in ["colega", "incidente"] \
				and c["dados"]["cliente"] == id:
			return c
	return null


func _telefone_aguardando():
	for c in ativos:
		if c["estado"] == "aguardando" and c["dados"]["canal"] == "telefone":
			return c
	return null


func _tocar_telefone(delta: float) -> void:
	var tocando: bool = (_telefone_aguardando() != null or _incidente) and not _encerrado
	mundo.tocando = tocando and dialogo.em_ligacao == ""
	if not mundo.tocando:
		_tempo_toque = 0.0
		return
	_tempo_toque -= delta
	if _tempo_toque <= 0.0:
		_tempo_toque = 2.4
		Som.tocar("telefone", -8.0)


func _atualizar_marcadores() -> void:
	for id in _colegas:
		var npc = _colegas[id]
		var tem_tarefa: bool = _chamado_com_tarefa("npc:" + id) != null
		npc.mostrar_marcador(tem_tarefa)
		if tem_tarefa:
			npc.mostrar_balao("")
		elif _chamado_de_colega(id) != null:
			npc.mostrar_balao("chamado")
		elif _cena_disponivel(id) != null:
			npc.mostrar_balao("historia")
		else:
			npc.mostrar_balao("")
	for c in ativos:
		var npc = c["npc"]
		if npc == null or not c["chegou"]:
			continue
		var volta: bool = _tarefa_atual(c).get("alvo", "") == "cliente"
		npc.mostrar_marcador(volta)
		if c["estado"] == "aguardando":
			npc.mostrar_balao("chamado")
		elif volta:
			npc.mostrar_balao("")
		else:
			npc.mostrar_balao("espera")
	for id in mundo.marcadores:
		var visivel: bool = _chamado_com_tarefa("obj:" + id) != null
		if id == "mesa_gabriel":
			visivel = _telefone_aguardando() != null
		mundo.mostrar_marcador(id, visivel)


func _atualizar_hud_chamados() -> void:
	var itens: Array = []
	for c in ativos:
		var d: Dictionary = c["dados"]
		var status := ""
		var t := _tarefa_atual(c)
		if not t.is_empty():
			status = t["objetivo"]
		elif c["estado"] == "aguardando":
			match d["canal"]:
				"balcao":
					status = "Aguardando no balcão" if c["chegou"] else "Chegando ao balcão"
				"telefone":
					status = "Telefone tocando na sua mesa!"
				_:
					status = "Fale com " + Jogo.nome(d["cliente"])
		else:
			status = "Em atendimento"
		itens.append({"icone": d["canal"], "titulo": "#%d %s" % [d["numero"], d["titulo"]], "status": status,
			"urgente": d["canal"] == "incidente"})
	hud.atualizar_chamados(itens)
