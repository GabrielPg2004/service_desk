extends Node
## Teste de mapa: a partir da entrada, percorre (BFS) todas as posições livres para o jogador
## e confere se cada objeto interativo, colega e vaga do balcão está ao alcance de alguma delas.
## Ativação: godot --headless --path . -- --teste-mapa

const PASSO := 4.0

var _quadros := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().change_scene_to_file.call_deferred("res://cenas/escritorio.tscn")


func _physics_process(_delta: float) -> void:
	var cena := get_tree().current_scene
	if cena == null or cena.name != "Escritorio":
		return
	_quadros += 1
	if _quadros == 5:
		_testar(cena)


func _testar(e) -> void:
	var espaco: PhysicsDirectSpaceState2D = e.get_world_2d().direct_space_state
	var forma := RectangleShape2D.new()
	forma.size = Vector2(10, 6)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.exclude = [e.jogador.get_rid()]
	var limites: Rect2 = e.mundo.limites()

	var livre := func(p: Vector2) -> bool:
		consulta.transform = Transform2D(0.0, p + Vector2(0, -3))
		return espaco.intersect_shape(consulta, 1).is_empty()

	var inicio: Vector2 = e.jogador.position
	var visitados := {inicio: true}
	var fila: Array = [inicio]
	while not fila.is_empty():
		var p: Vector2 = fila.pop_front()
		for d in [Vector2(PASSO, 0), Vector2(-PASSO, 0), Vector2(0, PASSO), Vector2(0, -PASSO)]:
			var q: Vector2 = p + d
			if visitados.has(q) or not limites.has_point(q):
				continue
			if livre.call(q):
				visitados[q] = true
				fila.append(q)
	var alcancaveis: Array = visitados.keys()
	print("TESTE-MAPA: %d posições livres alcançáveis" % alcancaveis.size())

	var alvos: Array = []
	for it in e.mundo.interativos:
		alvos.append(["objeto " + it["id"], it["rect"], float(it["alcance"])])
	for id in e._colegas:
		var pos: Vector2 = e._colegas[id].position
		alvos.append(["colega " + id, Rect2(pos - Vector2(6, 6), Vector2(12, 8)), 14.0])
	for vaga in e.mundo.VAGAS_BALCAO:
		alvos.append(["vaga do balcão " + str(vaga), Rect2(vaga - Vector2(6, 6), Vector2(12, 8)), 40.0])

	var falhas := 0
	for a in alvos:
		var r: Rect2 = a[1]
		var melhor := INF
		var posicao := Vector2.ZERO
		for p in alcancaveis:
			var ponto := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
			var d := ponto.distance_to(p)
			if d < melhor:
				melhor = d
				posicao = p
		if melhor > a[2] - 1.0:
			falhas += 1
			print("TESTE-MAPA: FALHA - %s fora de alcance (mais perto: %.1f px, alcance %.0f)" % [a[0], melhor, a[2]])
			continue
		if a[0].begins_with("vaga"):
			continue
		# do ponto mais próximo, olhando para o alvo, a interação escolhe exatamente esse alvo?
		e.jogador.position = posicao
		var ponto := Vector2(clampf(posicao.x, r.position.x, r.end.x), clampf(posicao.y, r.position.y, r.end.y))
		e.jogador.visual.olhar_vetor(ponto - posicao if ponto != posicao else r.get_center() - posicao)
		var escolhido = e._alvo_interacao()
		var esperado: String = a[0].split(" ")[1]
		if escolhido == null or escolhido["id"] != esperado:
			falhas += 1
			print("TESTE-MAPA: FALHA - perto de %s a interação escolhe %s" % [a[0],
				"nada" if escolhido == null else escolhido["id"]])
	# o caminho dos clientes (entrada -> corredor -> balcão) não pode atravessar móveis
	var entrada: Vector2 = e.mundo.ENTRADA
	for vaga in e.mundo.VAGAS_BALCAO:
		var pontos := [entrada, Vector2(entrada.x, e.mundo.CORREDOR_Y), Vector2(vaga.x, e.mundo.CORREDOR_Y), vaga]
		for i in range(1, pontos.size()):
			var a: Vector2 = pontos[i - 1]
			var b: Vector2 = pontos[i]
			for k in 11:
				var p := a.lerp(b, k / 10.0)
				if p.y < (e.mundo.ALTURA - 1) * e.mundo.T and not livre.call(p):
					falhas += 1
					print("TESTE-MAPA: FALHA - caminho do cliente bloqueado em ", p)
					break
	print("TESTE-MAPA: %d alvos verificados, %d falha(s)" % [alvos.size(), falhas])
	get_tree().quit(1 if falhas > 0 else 0)
