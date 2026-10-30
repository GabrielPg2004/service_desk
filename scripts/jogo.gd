extends Node
## Estado global: conteúdo (dados/*.json), progresso da semana, salvamento e tema visual.

const CAMINHO_SAVE := "user://progresso.json"
const DIAS := ["", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira"]
const DIAS_CURTOS := ["", "Seg", "Ter", "Qua", "Qui", "Sex"]
const TOTAL_DIAS := 5
const TELA := Vector2(480, 270)
const COLEGAS := ["celia", "rafa", "bia", "otavio", "luana", "davi"]
const MAX_CORACOES := 5

const COR_TEXTO := Color("4a2c22")
const COR_TEXTO_SUAVE := Color("8a6352")
const COR_CLARA := Color("fbecc8")
const COR_DESTAQUE := Color("c0453a")
const COR_OURO := Color("f2c14e")

var personagens: Dictionary = {}
var chamados: Array = []
var historias: Dictionary = {}
var falas: Dictionary = {}

var dia := 1
var amizade: Dictionary = {}
var historico: Array = []
var cenas_vistas: Dictionary = {}

var fonte: Font
var fonte_negrito: Font
var tema: Theme
var _texturas: Dictionary = {}


func _ready() -> void:
	_configurar_entrada()
	personagens = _carregar_json("res://dados/personagens.json")
	chamados = _carregar_json("res://dados/chamados.json")
	historias = _carregar_json("res://dados/historias.json")
	falas = _carregar_json("res://dados/falas.json")
	_criar_tema()
	novo_jogo()
	# ganchos de teste automatizado (ver testes/ e tools/testar.sh)
	if "--piloto" in OS.get_cmdline_user_args():
		add_child(load("res://testes/piloto.gd").new())
	if "--teste-mapa" in OS.get_cmdline_user_args():
		add_child(load("res://testes/teste_mapa.gd").new())


func _carregar_json(caminho: String) -> Variant:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	assert(arquivo != null, "Não foi possível abrir " + caminho)
	var dados = JSON.parse_string(arquivo.get_as_text())
	assert(dados != null, "JSON inválido: " + caminho)
	return dados


func _configurar_entrada() -> void:
	var teclas := {
		"mover_cima": [KEY_UP, KEY_W],
		"mover_baixo": [KEY_DOWN, KEY_S],
		"mover_esq": [KEY_LEFT, KEY_A],
		"mover_dir": [KEY_RIGHT, KEY_D],
		"interagir": [KEY_Z, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E],
		"menu": [KEY_ESCAPE, KEY_P],
	}
	var botoes := {
		"mover_cima": [JOY_BUTTON_DPAD_UP],
		"mover_baixo": [JOY_BUTTON_DPAD_DOWN],
		"mover_esq": [JOY_BUTTON_DPAD_LEFT],
		"mover_dir": [JOY_BUTTON_DPAD_RIGHT],
		"interagir": [JOY_BUTTON_A],
		"menu": [JOY_BUTTON_START],
	}
	for acao in teclas:
		if not InputMap.has_action(acao):
			InputMap.add_action(acao)
		for tecla in teclas[acao]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla
			InputMap.action_add_event(acao, ev)
		for botao in botoes[acao]:
			var evj := InputEventJoypadButton.new()
			evj.button_index = botao
			InputMap.action_add_event(acao, evj)


func _criar_tema() -> void:
	# Jersey 10 no texto corrido (números bem legíveis); Pixelify Sans Bold nos títulos
	var regular: FontFile = load("res://assets/fontes/Jersey10-Regular.woff2")
	var negrito: FontFile = load("res://assets/fontes/PixelifySans-Bold.woff2")
	for f in [regular, negrito]:
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	fonte = regular
	fonte_negrito = negrito
	tema = Theme.new()
	tema.default_font = fonte
	tema.default_font_size = tamanho_fonte(10)
	tema.set_color("font_color", "Label", COR_TEXTO)


# ---------------------------------------------------------------------------
# Progresso
# ---------------------------------------------------------------------------
func novo_jogo() -> void:
	dia = 1
	amizade = {}
	for c in COLEGAS:
		amizade[c] = 0
	historico = []
	cenas_vistas = {}


func tem_save() -> bool:
	return FileAccess.file_exists(CAMINHO_SAVE)


func salvar() -> void:
	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		push_warning("Não foi possível salvar o progresso.")
		return
	arquivo.store_string(JSON.stringify({
		"versao": 1, "dia": dia, "amizade": amizade, "historico": historico, "cenas_vistas": cenas_vistas,
	}))


func carregar() -> bool:
	if not tem_save():
		return false
	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	var dados = JSON.parse_string(arquivo.get_as_text())
	if typeof(dados) != TYPE_DICTIONARY:
		return false
	novo_jogo()
	dia = clampi(int(dados.get("dia", 1)), 1, TOTAL_DIAS)
	for c in COLEGAS:
		amizade[c] = int(dados.get("amizade", {}).get(c, 0))
	historico = dados.get("historico", [])
	cenas_vistas = dados.get("cenas_vistas", {})
	return true


func dia_salvo() -> int:
	if not tem_save():
		return 0
	var dados = JSON.parse_string(FileAccess.open(CAMINHO_SAVE, FileAccess.READ).get_as_text())
	return int(dados.get("dia", 0)) if typeof(dados) == TYPE_DICTIONARY else 0


func apagar_save() -> void:
	if tem_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO_SAVE))


func dar_coracao(id: String) -> void:
	amizade[id] = mini(int(amizade.get(id, 0)) + 1, MAX_CORACOES)


func total_coracoes() -> int:
	var total := 0
	for c in COLEGAS:
		total += int(amizade.get(c, 0))
	return total


func media_estrelas_semana() -> float:
	var soma := 0.0
	var qtd := 0
	for r in historico:
		soma += float(r.get("estrelas", 0))
		qtd += int(r.get("atendidos", 0))
	return soma / qtd if qtd > 0 else 0.0


func titulo_final() -> String:
	var media := media_estrelas_semana()
	for t in falas["titulos"]:
		if media >= float(t["min"]):
			return t["titulo"]
	return falas["titulos"][-1]["titulo"]


# ---------------------------------------------------------------------------
# Consultas de conteúdo
# ---------------------------------------------------------------------------
func chamados_do_dia(d: int) -> Array:
	var lista: Array = []
	for i in chamados.size():
		var c: Dictionary = chamados[i]
		if int(c["dia"]) == d:
			var copia := c.duplicate(true)
			copia["numero"] = 1041 + i
			lista.append(copia)
	lista.sort_custom(func(a, b): return minutos_de(a["hora"]) < minutos_de(b["hora"]))
	return lista


func nome(id: String) -> String:
	return personagens.get(id, {}).get("nome", id)


func cargo(id: String) -> String:
	return personagens.get(id, {}).get("cargo", "")


func descricao(id: String) -> String:
	return personagens.get(id, {}).get("descricao", "")


func minutos_de(hora: String) -> int:
	var partes := hora.split(":")
	return int(partes[0]) * 60 + int(partes[1])


func formatar_hora(minutos: int) -> String:
	return "%02d:%02d" % [minutos / 60, minutos % 60]


func textura(caminho: String) -> Texture2D:
	if not _texturas.has(caminho):
		_texturas[caminho] = load("res://assets/sprites/" + caminho + ".png")
	return _texturas[caminho]


func retrato(id: String) -> Texture2D:
	return textura("retratos/" + id)


func folha(id: String) -> Texture2D:
	return textura("personagens/" + id)


## Os tamanhos no código seguem a escala da fonte dos títulos; a fonte do texto corrido é menor
## no mesmo tamanho nominal, então é ajustada aqui.
func tamanho_fonte(tamanho: int, negrito := false) -> int:
	return tamanho if negrito else tamanho + 4


func rotulo(texto: String, tamanho := 10, cor := COR_TEXTO, negrito := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", fonte_negrito if negrito else fonte)
	l.add_theme_font_size_override("font_size", tamanho_fonte(tamanho, negrito))
	l.add_theme_color_override("font_color", cor)
	return l


## Faz o controle cobrir a tela base inteira (480x270).
func tela_cheia(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.position = Vector2.ZERO
	c.size = TELA


func painel(textura_nome := "ui/caixa", margem := 8) -> NinePatchRect:
	var p := NinePatchRect.new()
	p.texture = textura(textura_nome)
	p.patch_margin_left = margem
	p.patch_margin_right = margem
	p.patch_margin_top = margem
	p.patch_margin_bottom = margem
	return p
