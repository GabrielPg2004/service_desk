extends Node2D
## Monta o andar do escritório: Backoffice | Primeiro Atendimento | Telecom.
## Piso e paredes são desenhados a partir de tiles.png; móveis viram sprites com colisão.

const T := 16
const LARGURA := 64
const ALTURA := 18
const PORTA_ENTRADA := [30, 31, 32]
const LINHAS_PORTAS_INTERNAS := [9, 10]
const PAREDES_INTERNAS := [19, 44]

const POS_COLEGAS := {
	"celia": Vector2(380, 88), "rafa": Vector2(522, 90), "bia": Vector2(586, 90),
	"otavio": Vector2(204, 98), "luana": Vector2(780, 106), "davi": Vector2(780, 202),
}
const VAGAS_BALCAO := [Vector2(444, 206), Vector2(482, 206), Vector2(520, 206)]
const ENTRADA := Vector2(504, 270)
const CORREDOR_Y := 234.0
const INICIO_JOGADOR := Vector2(504, 252)

var ysort: Node2D
var interativos: Array = []
var marcadores: Dictionary = {}
var telefone: Sprite2D
var tocando := false

var _piso: Node2D
var _decor_piso: Node2D
var _decor_parede: Node2D
var _corpo: StaticBody2D
var _racks: Array[Sprite2D] = []
var _janelas: Array[float] = []
var _t := 0.0


class Piso extends Node2D:
	var mundo

	func _draw() -> void:
		var tiles: Texture2D = Jogo.textura("tiles")
		for y in mundo.ALTURA:
			for x in mundo.LARGURA:
				var tipo: String = mundo.tipo(x, y)
				var pos := Vector2(x * mundo.T, y * mundo.T)
				var area := Rect2(pos, Vector2(mundo.T, mundo.T))
				match tipo:
					"piso":
						draw_texture_rect_region(tiles, area, mundo.regiao_piso(x, y))
					"soleira", "porta":
						draw_texture_rect_region(tiles, area, Rect2(128, 0, 16, 16))
					"parede":
						draw_texture_rect_region(tiles, area, Rect2(mundo.mascara_parede(x, y) * 16, 16, 16, 16))
					"frente":
						if y == 1:
							var col: int = {"pa": 0, "bo": 2, "tc": 4}[mundo.sala(x)] + x % 2
							draw_texture_rect_region(tiles, Rect2(pos, Vector2(16, 32)), Rect2(col * 16, 32, 16, 32))
		# sombra projetada pelas paredes
		var sombra := Color(0.18, 0.08, 0.14, 0.22)
		draw_rect(Rect2(mundo.T, 3 * mundo.T, (mundo.LARGURA - 2) * mundo.T, 4), sombra)
		for px in mundo.PAREDES_INTERNAS:
			for faixa in [[3, 8], [11, 16]]:
				draw_rect(Rect2((px + 1) * mundo.T, faixa[0] * mundo.T, 3, (faixa[1] - faixa[0] + 1) * mundo.T), sombra)
		draw_rect(Rect2(mundo.T, 3 * mundo.T, 3, 14 * mundo.T), sombra)
		# luz que entra pelas janelas
		for jx in mundo._janelas:
			var luz := PackedVector2Array([Vector2(jx + 3, 48), Vector2(jx + 27, 48), Vector2(jx + 41, 96),
				Vector2(jx + 17, 96)])
			draw_colored_polygon(luz, Color(1.0, 0.95, 0.72, 0.13))


func tipo(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= LARGURA or y >= ALTURA:
		return "parede"
	if y == ALTURA - 1:
		return "porta" if x in PORTA_ENTRADA else "parede"
	if y == 0 or x == 0 or x == LARGURA - 1:
		return "parede"
	if x in PAREDES_INTERNAS:
		return "soleira" if y in LINHAS_PORTAS_INTERNAS else "parede"
	if y <= 2:
		return "frente"
	return "piso"


func sala(x: int) -> String:
	if x < PAREDES_INTERNAS[0]:
		return "bo"
	if x > PAREDES_INTERNAS[1]:
		return "tc"
	return "pa"


func regiao_piso(x: int, y: int) -> Rect2:
	match sala(x):
		"bo":
			return Rect2(32, 0, 16, 16)
		"tc":
			return Rect2(80 if (x * 7 + y * 3) % 11 == 0 else 64, 0, 16, 16)
	if y >= 12:
		return Rect2(96 + 16 * ((x + y) % 2), 0, 16, 16)
	return Rect2(16 * ((x * 3 + y * 5) % 2), 0, 16, 16)


func mascara_parede(x: int, y: int) -> int:
	var m := 0
	if _solido(x, y - 1):
		m |= 1
	if _solido(x + 1, y):
		m |= 2
	if _solido(x, y + 1):
		m |= 4
	if _solido(x - 1, y):
		m |= 8
	return m


func _solido(x: int, y: int) -> bool:
	return tipo(x, y) == "parede"


func limites() -> Rect2:
	return Rect2(0, 0, LARGURA * T, ALTURA * T)


# ---------------------------------------------------------------------------
func construir() -> void:
	_piso = Piso.new()
	_piso.mundo = self
	add_child(_piso)
	_decor_piso = Node2D.new()
	add_child(_decor_piso)
	_decor_parede = Node2D.new()
	add_child(_decor_parede)
	ysort = Node2D.new()
	ysort.y_sort_enabled = true
	add_child(ysort)
	_corpo = StaticBody2D.new()
	add_child(_corpo)
	_colisoes_paredes()
	_mobiliar()
	_piso.queue_redraw()


func _colisoes_paredes() -> void:
	for y in ALTURA:
		var inicio := -1
		for x in LARGURA + 1:
			var solido := x < LARGURA and tipo(x, y) in ["parede", "porta", "frente"]
			if solido and inicio < 0:
				inicio = x
			elif not solido and inicio >= 0:
				_colisao(Rect2(inicio * T, y * T, (x - inicio) * T, T))
				inicio = -1


func _colisao(r: Rect2) -> void:
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = r.size
	forma.shape = ret
	forma.position = r.get_center()
	_corpo.add_child(forma)


## Coloca um móvel. (tx, ty) é o canto superior esquerdo em tiles.
## op: pe (altura da colisão em px), id (objeto interativo), camada ("ysort", "piso", "parede"),
##     quadros (animação horizontal), alcance, texto (placa).
func movel(nome: String, tx: float, ty: float, op := {}) -> Sprite2D:
	var tex := Jogo.textura("moveis/" + nome)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var quadros: int = op.get("quadros", 1)
	s.hframes = quadros
	var w := float(tex.get_width() / quadros)
	var h := float(tex.get_height())
	var camada: String = op.get("camada", "ysort")
	var rect: Rect2
	var topo: Vector2
	if camada == "ysort":
		s.offset = Vector2(0, -h)
		s.position = Vector2(roundf(tx * T), roundf(ty * T + h))
		ysort.add_child(s)
		var pe: float = op.get("pe", 12.0)
		rect = Rect2(s.position.x, s.position.y - maxf(pe, 4.0), w, maxf(pe, 4.0))
		if pe > 0:
			_colisao(Rect2(s.position.x + 1, s.position.y - pe, w - 2, pe))
		topo = Vector2(s.position.x + w / 2, s.position.y - h - 4)
	else:
		s.position = Vector2(roundf(tx * T), roundf(ty * T))
		(_decor_piso if camada == "piso" else _decor_parede).add_child(s)
		rect = Rect2(s.position.x, 3 * T - 4, w, 4)
		if camada == "parede" and s.position.y >= (ALTURA - 1) * T:
			rect = Rect2(s.position.x, s.position.y - 2, w, 2)
		topo = Vector2(s.position.x + w / 2, s.position.y - 2)
	if op.has("texto"):
		var l: Label = Jogo.rotulo(op["texto"], 7, Jogo.COR_CLARA, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(w, h)
		l.position = Vector2(0, -1)
		s.add_child(l)
	if op.has("id"):
		var id: String = op["id"]
		interativos.append({"id": id, "tipo": "obj", "rect": rect, "alcance": op.get("alcance", 12.0)})
		var m := Sprite2D.new()
		m.texture = Jogo.textura("ui/marcador")
		m.position = topo
		m.visible = false
		m.z_index = 10
		add_child(m)
		if not marcadores.has(id):
			marcadores[id] = []
		marcadores[id].append(m)
	if quadros > 1:
		_racks.append(s)
	return s


func _mobiliar() -> void:
	# --- Primeiro Atendimento -------------------------------------------------
	movel("quadro_branco", 21.4, 1.15, {"camada": "parede", "id": "quadro_branco"})
	movel("janela", 25.0, 1.1, {"camada": "parede"})
	_janelas.append(25.0 * T)
	movel("placa", 27.6, 1.3, {"camada": "parede", "texto": "PRIMEIRO ATENDIMENTO"})
	movel("janela", 36.6, 1.1, {"camada": "parede"})
	_janelas.append(36.6 * T)
	movel("relogio", 39.4, 1.4, {"camada": "parede"})
	movel("janela", 41.1, 1.1, {"camada": "parede"})
	_janelas.append(41.1 * T)
	movel("arquivo", 20.2, 2.4, {"pe": 10})
	movel("mesa_celia", 21.0, 3.6)
	movel("planta_alta", 20.1, 5.4, {"pe": 8, "id": "planta"})
	var mesa := movel("mesa_gabriel", 26.0, 4.0, {"id": "mesa_gabriel", "alcance": 14.0})
	telefone = Sprite2D.new()
	telefone.texture = Jogo.textura("moveis/telefone")
	telefone.hframes = 2
	telefone.centered = false
	telefone.position = Vector2(16, -25)
	mesa.add_child(telefone)
	movel("cadeira", 26.55, 5.85, {"pe": 5})
	movel("mesa_rafa", 30.0, 4.0)
	movel("cadeira", 30.55, 5.85, {"pe": 5})
	movel("mesa_bia", 34.0, 4.0)
	movel("cadeira", 34.55, 5.85, {"pe": 5})
	movel("impressora", 38.4, 2.5, {"id": "impressora", "alcance": 14.0})
	movel("cafeteira", 40.3, 2.5, {"id": "cafeteira"})
	movel("bebedouro", 41.75, 2.5, {"pe": 10, "id": "bebedouro"})
	movel("planta", 42.7, 6.6, {"pe": 8, "id": "planta"})
	movel("lixeira", 24.9, 8.7, {"pe": 5})
	movel("balcao", 26.0, 9.9, {"pe": 18})
	movel("tapete", 28.0, 12.7, {"camada": "piso"})
	movel("capacho", 30.0, 16.25, {"camada": "piso"})
	movel("cadeiras_espera", 20.5, 13.6, {"pe": 8})
	movel("cadeiras_espera", 38.0, 13.6, {"pe": 8})
	movel("planta", 20.2, 14.9, {"pe": 8, "id": "planta"})
	movel("planta_alta", 42.6, 14.0, {"pe": 8, "id": "planta"})
	movel("porta_vidro", 30.0, 17.0, {"camada": "parede", "id": "porta", "alcance": 10.0})

	# --- Backoffice ------------------------------------------------------------
	movel("janela", 2.4, 1.1, {"camada": "parede"})
	_janelas.append(2.4 * T)
	movel("placa", 6.0, 1.3, {"camada": "parede", "texto": "BACKOFFICE"})
	movel("quadro", 15.2, 1.4, {"camada": "parede"})
	movel("janela", 16.8, 1.1, {"camada": "parede"})
	_janelas.append(16.8 * T)
	movel("estante_estoque", 1.15, 2.0, {"id": "estoque", "alcance": 14.0})
	movel("estante_estoque", 3.4, 2.0, {"id": "estoque", "alcance": 14.0})
	movel("caixas", 5.7, 3.3, {"pe": 8})
	movel("arquivo", 16.0, 2.4, {"pe": 10})
	movel("arquivo", 17.1, 2.4, {"pe": 10})
	movel("mesa_otavio", 9.0, 4.5)
	movel("cadeira", 10.3, 6.35, {"pe": 5})
	movel("mesa_vazia", 13.6, 9.2)
	movel("cadeira", 14.15, 11.05, {"pe": 5})
	movel("mesa_reuniao", 3.8, 9.6, {"pe": 14, "id": "mesa_reuniao", "alcance": 14.0})
	movel("cadeira_vermelha", 4.6, 11.7, {"pe": 5})
	movel("cadeira_vermelha", 7.4, 11.7, {"pe": 5})
	movel("planta", 1.2, 14.6, {"pe": 8, "id": "planta"})
	movel("planta_alta", 17.3, 14.0, {"pe": 8, "id": "planta"})
	movel("lixeira", 12.2, 15.6, {"pe": 5})

	# --- Telecom -----------------------------------------------------------------
	movel("tv_painel", 46.0, 1.2, {"camada": "parede", "id": "tv_painel"})
	movel("placa", 50.0, 1.3, {"camada": "parede", "texto": "TELECOM"})
	movel("ar_condicionado", 59.0, 1.3, {"camada": "parede"})
	movel("poster", 61.4, 1.15, {"camada": "parede", "id": "poster"})
	movel("rack_rede", 50.6, 2.4, {"quadros": 2, "id": "rack_rede", "alcance": 14.0})
	movel("rack", 52.2, 2.4, {"quadros": 2, "id": "rack"})
	movel("rack", 53.8, 2.4, {"quadros": 2, "id": "rack"})
	movel("rack", 55.4, 2.4, {"quadros": 2, "id": "rack"})
	movel("bancada", 58.2, 6.0, {"id": "bancada"})
	movel("bobina", 61.6, 8.4, {"pe": 6})
	movel("bobina", 61.2, 9.6, {"pe": 6})
	movel("mesa_luana", 46.0, 5.0)
	movel("cadeira", 46.55, 6.85, {"pe": 5})
	movel("mesa_davi", 46.0, 11.0)
	movel("cadeira", 46.55, 12.85, {"pe": 5})
	movel("caixas", 60.6, 14.2, {"pe": 8})
	movel("planta", 61.6, 15.0, {"pe": 8, "id": "planta"})
	movel("lixeira", 57.2, 15.7, {"pe": 5})


func mostrar_marcador(id: String, visivel: bool) -> void:
	for m in marcadores.get(id, []):
		m.visible = visivel


func _process(delta: float) -> void:
	_t += delta
	var oscila := roundf(sin(_t * 5.0) * 2.0)
	for lista in marcadores.values():
		for m in lista:
			m.offset.y = oscila
	for i in _racks.size():
		_racks[i].frame = int(_t * 1.6 + i * 0.7) % 2
	if telefone:
		if tocando:
			telefone.frame = int(_t * 12.0) % 2
			telefone.offset.x = roundf(sin(_t * 60.0) * 0.6)
		else:
			telefone.frame = 0
			telefone.offset.x = 0
