extends Node
## Efeitos sonoros e música de fundo.

const VOLUME_MUSICA_DB := -10.0

var musica_ligada := true
var _musica: AudioStreamPlayer
var _musica_atual := ""
var _canais: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_musica = AudioStreamPlayer.new()
	_musica.volume_db = VOLUME_MUSICA_DB
	add_child(_musica)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_canais.append(p)


func _carregar(nome: String) -> AudioStream:
	if not _cache.has(nome):
		_cache[nome] = load("res://assets/audio/%s.wav" % nome)
	return _cache[nome]


func tocar(nome: String, volume_db := 0.0, tom := 1.0) -> void:
	for p in _canais:
		if not p.playing:
			p.stream = _carregar(nome)
			p.volume_db = volume_db
			p.pitch_scale = tom
			p.play()
			return


func tocar_musica(nome: String) -> void:
	if nome == _musica_atual:
		return
	_musica_atual = nome
	var stream := _carregar(nome) as AudioStreamWAV
	if stream:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	var t := create_tween()
	if _musica.playing:
		t.tween_property(_musica, "volume_db", -40.0, 0.4)
	t.tween_callback(func():
		_musica.stream = stream
		_musica.volume_db = VOLUME_MUSICA_DB if musica_ligada else -80.0
		_musica.play())


func parar_musica() -> void:
	_musica_atual = ""
	_musica.stop()


func alternar_musica() -> bool:
	musica_ligada = not musica_ligada
	_musica.volume_db = VOLUME_MUSICA_DB if musica_ligada else -80.0
	return musica_ligada
