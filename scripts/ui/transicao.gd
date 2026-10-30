extends ColorRect
## Escurecer/clarear a tela e o cartão de abertura de cada dia.

var _titulo: Label
var _subtitulo: Label


func _ready() -> void:
	Jogo.tela_cheia(self)
	color = Color("2a1b23")
	mouse_filter = MOUSE_FILTER_IGNORE
	_titulo = Jogo.rotulo("", 24, Jogo.COR_CLARA, true)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.size = Vector2(480, 30)
	_titulo.position = Vector2(0, 108)
	add_child(_titulo)
	_subtitulo = Jogo.rotulo("", 10, Color("e0c49a"))
	_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitulo.size = Vector2(480, 14)
	_subtitulo.position = Vector2(0, 142)
	add_child(_subtitulo)
	_titulo.modulate.a = 0.0
	_subtitulo.modulate.a = 0.0


func escurecer(duracao := 0.5) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, duracao)
	await t.finished


func clarear(duracao := 0.6) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, duracao)
	await t.finished


func cartao(titulo: String, subtitulo: String) -> void:
	modulate.a = 1.0
	_titulo.text = titulo
	_subtitulo.text = subtitulo
	var t := create_tween()
	t.tween_property(_titulo, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(_subtitulo, "modulate:a", 1.0, 0.5)
	t.tween_interval(1.6)
	t.tween_property(_titulo, "modulate:a", 0.0, 0.4)
	t.parallel().tween_property(_subtitulo, "modulate:a", 0.0, 0.4)
	await t.finished
