#!/usr/bin/env python3
"""Sintetiza os efeitos sonoros e as músicas (estilo chiptune) do jogo.

Uso: python3 tools/gerar_sons.py
"""
import os
import wave

import numpy as np

TAXA = 22050
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")

NOTAS = {"C": -9, "C#": -8, "Db": -8, "D": -7, "D#": -6, "Eb": -6, "E": -5, "F": -4, "F#": -3, "Gb": -3,
         "G": -2, "G#": -1, "Ab": -1, "A": 0, "A#": 1, "Bb": 1, "B": 2}


def freq(nome):
    """'A4' -> 440 Hz."""
    letra = nome[:-1]
    oitava = int(nome[-1])
    return 440.0 * 2 ** ((NOTAS[letra] + (oitava - 4) * 12) / 12)


def tempo(dur):
    return np.arange(int(TAXA * dur)) / TAXA


def onda(tipo, f, dur, duty=0.5):
    t = tempo(dur)
    fase = (t * f) % 1.0
    if tipo == "seno":
        return np.sin(2 * np.pi * f * t)
    if tipo == "quadrada":
        return np.where(fase < duty, 1.0, -1.0)
    if tipo == "triangulo":
        return 4 * np.abs(fase - 0.5) - 1
    if tipo == "ruido":
        return np.random.default_rng(int(f)).uniform(-1, 1, len(t))
    raise ValueError(tipo)


def envelope(n, ataque=0.005, queda=0.08, sustain=0.6, soltura=0.05):
    env = np.ones(n) * sustain
    a = max(1, int(ataque * TAXA))
    d = max(1, int(queda * TAXA))
    r = max(1, int(soltura * TAXA))
    env[:a] = np.linspace(0, 1, a)[: len(env[:a])]
    fim_d = min(n, a + d)
    env[a:fim_d] = np.linspace(1, sustain, d)[: fim_d - a]
    if n > r:
        env[-r:] *= np.linspace(1, 0, r)
    return env


def decai(n, velocidade):
    return np.exp(-np.arange(n) / TAXA * velocidade)


def salvar(nome, amostras, volume=0.8):
    amostras = np.asarray(amostras, dtype=np.float64)
    pico = np.max(np.abs(amostras)) or 1.0
    dados = (amostras / pico * volume * 32767).astype(np.int16)
    os.makedirs(RAIZ, exist_ok=True)
    with wave.open(os.path.join(RAIZ, nome + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(dados.tobytes())


def concat(*partes):
    return np.concatenate(partes)


def silencio(dur):
    return np.zeros(int(TAXA * dur))


def nota(tipo, f, dur, duty=0.5, **env):
    s = onda(tipo, f, dur, duty)
    return s * envelope(len(s), **env)


# ---------------------------------------------------------------------------
# Efeitos
# ---------------------------------------------------------------------------
def efeitos():
    salvar("texto", nota("quadrada", 740, 0.03, duty=0.25, queda=0.02, sustain=0.3, soltura=0.01), 0.35)
    salvar("cursor", nota("triangulo", 990, 0.05, queda=0.03, sustain=0.4), 0.5)
    salvar("confirmar", concat(nota("quadrada", 660, 0.05, 0.25), nota("quadrada", 990, 0.08, 0.25)), 0.45)
    salvar("cancelar", concat(nota("quadrada", 520, 0.05, 0.25), nota("quadrada", 390, 0.08, 0.25)), 0.4)
    arpejo = [nota("quadrada", freq(n), 0.07, 0.25, queda=0.05, sustain=0.5) for n in ("C5", "E5", "G5")]
    arpejo.append(nota("quadrada", freq("C6"), 0.22, 0.25, queda=0.15, sustain=0.4, soltura=0.1))
    salvar("acerto", concat(*arpejo), 0.5)
    erro = concat(nota("quadrada", 247, 0.12, 0.5, sustain=0.7), nota("quadrada", 185, 0.25, 0.5, sustain=0.6,
                                                                       soltura=0.12))
    salvar("erro", erro * 0.8, 0.45)
    # telefone: trinado duplo
    trinado = []
    for _ in range(2):
        t = tempo(0.45)
        mod = np.where((t * 20) % 1 < 0.5, 1.0, 0.0)
        s = np.sin(2 * np.pi * 880 * t) * mod + np.sin(2 * np.pi * 1100 * t) * (1 - mod)
        trinado.append(s * envelope(len(s), soltura=0.02))
        trinado.append(silencio(0.15))
    salvar("telefone", concat(*trinado), 0.5)
    # campainha de balcão
    t = tempo(1.0)
    s = (np.sin(2 * np.pi * 1880 * t) + 0.5 * np.sin(2 * np.pi * 3760 * t) + 0.3 * np.sin(2 * np.pi * 5020 * t))
    salvar("campainha", s * decai(len(s), 5), 0.5)
    # porta: plim-plom
    salvar("porta", concat(np.sin(2 * np.pi * freq("E5") * tempo(0.35)) * decai(int(TAXA * 0.35), 6),
                           np.sin(2 * np.pi * freq("C5") * tempo(0.6)) * decai(int(TAXA * 0.6), 5)), 0.45)
    brilho = [nota("triangulo", freq(n), 0.06, queda=0.04, sustain=0.5) for n in ("C6", "E6", "G6", "C7")]
    salvar("coracao", concat(*brilho, silencio(0.05)), 0.45)
    t = tempo(1.2)
    f = 650 + 250 * np.sign(np.sin(2 * np.pi * 2.5 * t))
    fase = np.cumsum(f) / TAXA
    salvar("alarme", np.where(fase % 1 < 0.5, 1.0, -1.0) * envelope(len(t), soltura=0.1), 0.35)
    salvar("mini_ok", nota("quadrada", 1320, 0.06, 0.25, queda=0.04), 0.4)
    salvar("mini_erro", nota("quadrada", 140, 0.14, 0.5, sustain=0.8), 0.4)
    fim = [nota("quadrada", freq(n), d, 0.25, queda=0.06, sustain=0.5)
           for n, d in (("G4", 0.12), ("C5", 0.12), ("E5", 0.12), ("G5", 0.12), ("E5", 0.12), ("G5", 0.4))]
    salvar("fim_dia", concat(*fim), 0.5)
    r = onda("ruido", 7, 0.6)
    salvar("cafe", r * decai(len(r), 3) * (0.5 + 0.5 * np.sin(np.arange(len(r)) / 200)), 0.25)
    passo = onda("ruido", 3, 0.04) * decai(int(TAXA * 0.04), 80)
    salvar("passo", passo, 0.15)


# ---------------------------------------------------------------------------
# Música
# ---------------------------------------------------------------------------
def sequencia(notas, colcheia, tipo, duty=0.5, vibrato=0.0, **env):
    """notas: lista de (nome|None, duração em colcheias)."""
    partes = []
    for nome, dur in notas:
        d = dur * colcheia
        if nome is None:
            partes.append(silencio(d))
            continue
        f = freq(nome)
        t = tempo(d)
        if vibrato:
            fase = np.cumsum(f * (1 + vibrato * np.sin(2 * np.pi * 5.5 * t) * np.clip(t * 4, 0, 1))) / TAXA
            s = np.where(fase % 1 < duty, 1.0, -1.0) if tipo == "quadrada" else 4 * np.abs(fase % 1 - 0.5) - 1
        else:
            s = onda(tipo, f, d, duty)
        partes.append(s * envelope(len(s), **env))
    return np.concatenate(partes)


def eco(s, atraso, ganho, vezes=3):
    saida = s.copy()
    n = int(atraso * TAXA)
    for k in range(1, vezes + 1):
        deslocado = np.zeros_like(s)
        deslocado[n * k:] = s[: len(s) - n * k]
        saida += deslocado * ganho ** k
    return saida


def misturar(*faixas):
    n = max(len(f) for f, _ in faixas)
    saida = np.zeros(n)
    for f, v in faixas:
        saida[: len(f)] += f * v
    return saida


def musica_escritorio():
    colcheia = 60 / 92 / 2
    acordes = [("F", ["F4", "A4", "C5", "E5"], "F2", "C3"),
               ("Dm", ["D4", "F4", "A4", "C5"], "D2", "A2"),
               ("Bb", ["Bb3", "D4", "F4", "A4"], "Bb1", "F2"),
               ("C", ["C4", "E4", "G4", "Bb4"], "C2", "G2")]
    melodia = [
        ("A4", 2), ("C5", 2), ("D5", 1), ("C5", 1), ("A4", 2), ("G4", 2), ("A4", 2), ("C5", 4),
        ("D5", 2), ("F5", 2), ("E5", 1), ("D5", 1), ("C5", 2), ("A4", 4), (None, 4),
        ("D5", 2), ("C5", 1), ("A4", 1), ("G4", 2), ("A4", 2), ("Bb4", 2), ("A4", 2), ("G4", 4),
        ("E4", 2), ("G4", 2), ("C5", 2), ("Bb4", 2), ("A4", 2), ("G4", 2), ("E4", 4),
        ("C5", 2), ("F5", 2), ("E5", 1), ("F5", 1), ("G5", 2), ("A5", 2), ("G5", 2), ("F5", 4),
        ("F5", 2), ("E5", 1), ("D5", 1), ("C5", 2), ("D5", 2), ("A4", 6), (None, 2),
        ("Bb4", 2), ("D5", 2), ("F5", 2), ("D5", 2), ("C5", 2), ("Bb4", 2), ("A4", 4),
        ("G4", 2), ("A4", 2), ("Bb4", 2), ("C5", 2), ("E5", 2), ("D5", 2), ("C5", 4),
    ]
    arpejo, baixo = [], []
    for _ in range(2):
        for _, tons, raiz, quinta in acordes:
            for _ in range(2):
                for i in range(8):
                    arpejo.append((tons[(i if i < 4 else 7 - i) % 4], 1))
                baixo += [(raiz, 2), (quinta, 2), (raiz[:-1] + str(int(raiz[-1]) + 1), 2), (quinta, 2)]
    mel = sequencia(melodia, colcheia, "quadrada", duty=0.25, vibrato=0.006, ataque=0.01, queda=0.1,
                    sustain=0.55, soltura=0.06)
    mel = eco(mel, colcheia * 3, 0.3)
    arp = sequencia(arpejo, colcheia, "quadrada", duty=0.125, ataque=0.003, queda=0.08, sustain=0.25,
                    soltura=0.04)
    bas = sequencia(baixo, colcheia, "triangulo", ataque=0.005, queda=0.1, sustain=0.7, soltura=0.05)
    # percussão suave
    n = len(bas)
    perc = np.zeros(n)
    passo = int(colcheia * TAXA)
    chimbal = onda("ruido", 11, 0.03) * decai(int(TAXA * 0.03), 120)
    bumbo_t = tempo(0.12)
    bumbo = np.sin(2 * np.pi * (90 * np.exp(-bumbo_t * 18) + 45) * bumbo_t) * decai(len(bumbo_t), 25)
    for i in range(0, n // passo):
        pos = i * passo
        if i % 2 == 1 and pos + len(chimbal) < n:
            perc[pos:pos + len(chimbal)] += chimbal * 0.6
        if i % 4 == 0 and pos + len(bumbo) < n:
            perc[pos:pos + len(bumbo)] += bumbo
    salvar("musica_escritorio", misturar((mel, 0.32), (arp, 0.12), (bas, 0.45), (perc, 0.35)), 0.6)


def musica_incidente():
    colcheia = 60 / 138 / 2
    baixo = []
    melodia = []
    for raiz, tons in (("D2", ["D5", "F5", "A5", "F5"]), ("Bb1", ["D5", "F5", "Bb5", "F5"]),
                       ("C2", ["E5", "G5", "C6", "G5"]), ("A1", ["C#5", "E5", "A5", "E5"])):
        for _ in range(2):
            baixo += [(raiz, 1), (raiz[:-1] + "2" if raiz[-1] == "1" else raiz[:-1] + "3", 1)] * 4
            melodia += [(tons[0], 2), (tons[1], 1), (tons[2], 1), (tons[3], 2), (None, 2)]
    bas = sequencia(baixo, colcheia, "quadrada", duty=0.5, ataque=0.002, queda=0.05, sustain=0.5, soltura=0.02)
    mel = sequencia(melodia, colcheia, "quadrada", duty=0.25, ataque=0.003, queda=0.06, sustain=0.4,
                    soltura=0.03)
    n = len(bas)
    perc = np.zeros(n)
    passo = int(colcheia * TAXA)
    caixa = onda("ruido", 5, 0.08) * decai(int(TAXA * 0.08), 40)
    for i in range(0, n // passo):
        pos = i * passo
        if i % 4 == 2 and pos + len(caixa) < n:
            perc[pos:pos + len(caixa)] += caixa
    salvar("musica_incidente", misturar((bas, 0.3), (eco(mel, colcheia * 2, 0.25), 0.25), (perc, 0.25)), 0.55)


if __name__ == "__main__":
    efeitos()
    musica_escritorio()
    musica_incidente()
    print("Áudio gerado em", os.path.normpath(RAIZ))
