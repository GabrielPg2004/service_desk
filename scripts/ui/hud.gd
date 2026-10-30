extends Control
## HUD: relógio, lista de chamados abertos, dica de interação e avisos.

const ICONES := {"balcao": "ui/icone_balcao", "telefone": "ui/icone_telefone", "colega": "ui/icone_equipe",
	"incidente": "ui/icone_alerta"}

var _lbl_dia: Label
var _lbl_hora: Label
var _lbl_rapido: Label
var _painel_chamados: NinePatchRect
var _lista: Control
var _dica: NinePatchRect
var _lbl_dica: Label
var _ajuda: Label
var _avisos: Array[Control] = []


func _ready() -> void:
	Jogo.tela_cheia(self)
	mouse_filter = MOUSE_FILTER_IGNORE

	var relogio := Jogo.painel("ui/painel", 5)
	relogio.position = Vector2(6, 6)
	relogio.size = Vector2(96, 34)
	add_child(relogio)
	_lbl_dia = Jogo.rotulo("", 8, Color("e0c49a"))
	_lbl_dia.position = Vector2(8, 3)
	relogio.add_child(_lbl_dia)
	_lbl_hora = Jogo.rotulo("08:00", 16, Jogo.COR_CLARA)
	_lbl_hora.position = Vector2(8, 12)
	relogio.add_child(_lbl_hora)
	_lbl_rapido = Jogo.rotulo(">>", 10, Jogo.COR_OURO, true)
	_lbl_rapido.position = Vector2(70, 17)
	_lbl_rapido.visible = false
	relogio.add_child(_lbl_rapido)

	_painel_chamados = Jogo.painel("ui/painel", 5)
	_painel_chamados.position = Vector2(298, 6)
	_painel_chamados.size = Vector2(176, 24)
	add_child(_painel_chamados)
	var titulo := Jogo.rotulo("CHAMADOS", 8, Color("e0c49a"), true)
	titulo.position = Vector2(8, 4)
	_painel_chamados.add_child(titulo)
	_lista = Control.new()
	_lista.position = Vector2(6, 16)
	_painel_chamados.add_child(_lista)

	_dica = Jogo.painel("ui/painel", 5)
	_dica.visible = false
	add_child(_dica)
	_lbl_dica = Jogo.rotulo("", 9, Jogo.COR_CLARA)
	_lbl_dica.position = Vector2(8, 3)
	_dica.add_child(_lbl_dica)

	_ajuda = Jogo.rotulo("Setas: andar   Espaço / Z: interagir   Esc: menu", 8, Jogo.COR_CLARA)
	_ajuda.position = Vector2(8, 256)
	_ajuda.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.08, 0.8))
	_ajuda.add_theme_constant_override("shadow_offset_x", 1)
	_ajuda.add_theme_constant_override("shadow_offset_y", 1)
	_ajuda.visible = false
	add_child(_ajuda)


func mostrar_ajuda(visivel: bool) -> void:
	_ajuda.visible = visivel


func atualizar_relogio(dia: int, minutos: int, rapido: bool) -> void:
	_lbl_dia.text = "%s · Dia %d/%d" % [Jogo.DIAS_CURTOS[dia], dia, Jogo.TOTAL_DIAS]
	_lbl_hora.text = Jogo.formatar_hora(minutos)
	_lbl_rapido.visible = rapido


## itens: [{icone, titulo, status, urgente}]
func atualizar_chamados(itens: Array) -> void:
	for filho in _lista.get_children():
		filho.queue_free()
	var y := 0.0
	if itens.is_empty():
		var vazio := Jogo.rotulo("Nenhum chamado aberto", 8, Color("b89c80"))
		vazio.position = Vector2(2, 0)
		_lista.add_child(vazio)
		y = 12.0
	for i in mini(itens.size(), 4):
		var item: Dictionary = itens[i]
		var icone := TextureRect.new()
		icone.texture = Jogo.textura(ICONES.get(item["icone"], "ui/icone_balcao"))
		icone.position = Vector2(2, y + 2)
		_lista.add_child(icone)
		var titulo := Jogo.rotulo(item["titulo"], 9, Jogo.COR_OURO if item.get("urgente", false) else Jogo.COR_CLARA)
		titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		titulo.position = Vector2(16, y)
		titulo.size = Vector2(146, 12)
		_lista.add_child(titulo)
		var status := Jogo.rotulo(item["status"], 8, Color("d9bf98"))
		status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		status.position = Vector2(16, y + 11)
		status.size = Vector2(146, 10)
		_lista.add_child(status)
		y += 24.0
	if itens.size() > 4:
		var mais := Jogo.rotulo("+ %d chamado(s)" % (itens.size() - 4), 8, Color("d9bf98"))
		mais.position = Vector2(16, y)
		_lista.add_child(mais)
		y += 11.0
	_painel_chamados.size.y = 22.0 + y


func mostrar_dica(texto: String) -> void:
	_dica.visible = texto != ""
	if texto == "":
		return
	_lbl_dica.text = "[Espaço]  " + texto
	var largura := _lbl_dica.get_minimum_size().x
	_dica.size = Vector2(largura + 16, 18)
	_dica.position = Vector2(240 - _dica.size.x / 2, 236)


func aviso(texto: String, icone := "", estrelas := -1, cor := Jogo.COR_CLARA) -> void:
	var p := Jogo.painel("ui/painel", 5)
	var x := 8.0
	if icone != "":
		var ic := TextureRect.new()
		ic.texture = Jogo.textura(icone)
		ic.position = Vector2(7, 5)
		p.add_child(ic)
		x = 21.0
	var l := Jogo.rotulo(texto, 9, cor)
	l.position = Vector2(x, 3)
	p.add_child(l)
	var largura := l.get_minimum_size().x + x + 8
	if estrelas >= 0:
		for i in 3:
			var e := TextureRect.new()
			e.texture = Jogo.textura("ui/estrela" if i < estrelas else "ui/estrela_vazia")
			e.position = Vector2(largura - 4 + i * 12, 4)
			p.add_child(e)
		largura += 38
	p.size = Vector2(largura, 20)
	add_child(p)
	_avisos.append(p)
	_reposicionar_avisos()
	p.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(p, "modulate:a", 1.0, 0.2)
	t.tween_interval(3.6)
	t.tween_property(p, "modulate:a", 0.0, 0.4)
	t.tween_callback(func():
		_avisos.erase(p)
		p.queue_free()
		_reposicionar_avisos())


func _reposicionar_avisos() -> void:
	# empilhados de baixo para cima, acima da dica de interação
	var y := 212.0
	for i in range(_avisos.size() - 1, -1, -1):
		var p := _avisos[i]
		p.position = Vector2(roundf(240 - p.size.x / 2), y)
		y -= 23.0
