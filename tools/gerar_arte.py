#!/usr/bin/env python3
"""Gera toda a arte pixel do jogo (tiles, móveis, personagens, retratos e UI).

Uso: python3 tools/gerar_arte.py

Tudo é desenhado por código, pixel a pixel, com uma paleta quente e aconchegante.
Os contornos são aplicados automaticamente em volta de cada forma.
"""
import os

from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")

# ---------------------------------------------------------------------------
# Paleta e utilidades de cor
# ---------------------------------------------------------------------------
CONTORNO = (52, 30, 40)
OLHO = (40, 28, 46)
BOCA = (156, 72, 82)
BOCHECHA = (238, 150, 140)
BRANCO = (250, 246, 236)
SOMBRA_FRIA = (62, 40, 92)
LUZ_QUENTE = (255, 244, 206)

PELES = [
    ((250, 214, 178), (226, 170, 136)),
    ((232, 180, 134), (200, 140, 100)),
    ((190, 128, 88), (156, 98, 68)),
    ((134, 86, 60), (104, 64, 46)),
]


def mistura(a, b, k):
    return tuple(int(round(a[i] * (1 - k) + b[i] * k)) for i in range(3))


def escuro(c, k=0.28):
    return mistura(c, SOMBRA_FRIA, k)


def claro(c, k=0.25):
    return mistura(c, LUZ_QUENTE, k)


class Tela:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.p = self.img.load()

    def px(self, x, y, c, a=255):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.p[x, y] = (c[0], c[1], c[2], a)

    def ret(self, x0, y0, x1, y1, c, a=255):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, c, a)

    def apaga(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.p[x, y] = (0, 0, 0, 0)

    def cheio(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h and self.p[x, y][3] == 255

    def caixa(self, x0, y0, x1, y1, base, borda=True):
        """Retângulo com luz no topo/esquerda e sombra embaixo/direita."""
        self.ret(x0, y0, x1, y1, base)
        if borda:
            self.ret(x0, y0, x1, y0, claro(base, 0.3))
            self.ret(x0, y0, x0, y1, claro(base, 0.15))
            self.ret(x1, y0, x1, y1, escuro(base, 0.2))
            self.ret(x0, y1, x1, y1, escuro(base, 0.3))

    def elipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1:
                    self.px(x, y, c)

    def contorno(self, cor=CONTORNO, x0=0, y0=0, x1=None, y1=None):
        x1 = self.w - 1 if x1 is None else x1
        y1 = self.h - 1 if y1 is None else y1
        alvos = []
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if self.p[x, y][3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if x0 <= nx <= x1 and y0 <= ny <= y1 and self.p[nx, ny][3] == 255:
                        alvos.append((x, y))
                        break
        for x, y in alvos:
            self.px(x, y, cor)

    def colar(self, outra, ox, oy, espelhar=False):
        img = outra.img.transpose(Image.FLIP_LEFT_RIGHT) if espelhar else outra.img
        self.img.alpha_composite(img, (ox, oy))

    def salvar(self, *caminho):
        destino = os.path.join(RAIZ, *caminho)
        os.makedirs(os.path.dirname(destino), exist_ok=True)
        self.img.save(destino)


# ---------------------------------------------------------------------------
# Personagens (sprites 16x32, 4 quadros x 4 direções: baixo, cima, esq, dir)
# ---------------------------------------------------------------------------
MANGA_LONGA = {"social", "blazer", "moletom", "cardigan", "xadrez", "macacao_longo"}


def corpo_frente(t, c, f, costas):
    pele, pele_s = PELES[c["pele"]]
    r = c["roupa"]
    r2 = c.get("roupa2", BRANCO)
    calca = c["calca"]
    sapato = c.get("sapato", (70, 50, 50))
    estilo = c["estilo"]

    # pernas e sapatos
    for perna, (xa, xb) in enumerate(((5, 7), (8, 10))):
        ergue = 1 if (f == 1 and perna == 0) or (f == 3 and perna == 1) else 0
        base = 28 - ergue
        t.ret(xa, 25, xb, base, calca)
        if perna == 0:
            t.ret(7, 25, 7, base, escuro(calca, 0.3))
        t.ret(xa, base + 1, xb, base + 2, sapato)
        t.px(xa, base + 1, claro(sapato, 0.35))
    # cintura
    t.ret(4, 23, 11, 24, calca)
    if estilo in ("social", "blazer", "xadrez"):
        t.ret(4, 23, 11, 23, escuro(calca, 0.45))
        if not costas:
            t.px(7, 23, (220, 190, 110))
    # tronco
    tronco = r
    if estilo == "macacao":
        t.ret(4, 16, 11, 24, r)
    else:
        t.ret(4, 16, 11, 22, tronco)
    t.ret(4, 16, 4, 22, claro(tronco, 0.12))
    t.ret(11, 16, 11, 22, escuro(tronco, 0.22))
    if estilo == "xadrez":
        for y in range(16, 23):
            for x in range(4, 12):
                if x % 3 == 0 or y % 3 == 0:
                    t.px(x, y, r2)
    # braços
    for lado, x in ((0, 3), (1, 12)):
        balanco = (f == 1 and lado == 1) or (f == 3 and lado == 0)
        mao = 21 if balanco else 22
        if estilo in MANGA_LONGA or estilo == "macacao":
            manga_fim = mao - 1
        else:
            manga_fim = 18
        cor_manga = escuro(r, 0.12) if estilo != "blazer" else escuro(r, 0.1)
        t.ret(x, 16, x, manga_fim, cor_manga)
        t.ret(x, manga_fim + 1, x, mao, pele)
        t.px(x, mao, pele_s)
    # pescoço
    t.ret(6, 15, 9, 15, pele_s)

    if costas:
        if estilo == "moletom":
            t.ret(5, 15, 10, 18, escuro(r, 0.15))
            t.ret(6, 16, 9, 17, escuro(r, 0.3))
        if estilo == "macacao":
            t.ret(5, 16, 5, 22, claro(r, 0.25))
            t.ret(10, 16, 10, 22, claro(r, 0.25))
        return

    # detalhes da frente
    if estilo in ("camiseta", "banda", "blusa"):
        t.px(7, 16, pele_s)
        t.px(8, 16, pele_s)
        if estilo == "blusa":
            t.px(7, 17, pele_s)
            t.px(8, 17, pele_s)
    if estilo == "banda":
        t.ret(6, 18, 9, 20, r2)
        t.px(7, 19, r)
        t.px(8, 18, r)
    if estilo == "polo":
        t.px(6, 16, r2)
        t.px(9, 16, r2)
        t.ret(7, 16, 8, 17, escuro(r, 0.2))
        t.px(10, 18, r2)
    if estilo in ("social", "xadrez"):
        t.px(6, 16, BRANCO if estilo == "social" else r2)
        t.px(9, 16, BRANCO if estilo == "social" else r2)
        if c.get("gravata"):
            g = c["gravata"]
            t.ret(7, 16, 8, 16, escuro(g, 0.2))
            t.ret(7, 17, 8, 20, g)
            t.px(7, 21, g)
        else:
            t.ret(7, 17, 7, 22, escuro(r, 0.15))
    if estilo == "blazer":
        t.ret(7, 16, 8, 22, r2)
        t.px(6, 16, claro(r, 0.3))
        t.px(9, 16, claro(r, 0.3))
        t.px(6, 17, claro(r, 0.2))
        t.px(9, 17, claro(r, 0.2))
        if c.get("gravata"):
            g = c["gravata"]
            t.ret(7, 16, 8, 16, escuro(g, 0.2))
            t.ret(7, 17, 8, 21, g)
    if estilo == "cardigan":
        t.ret(7, 16, 8, 22, r2)
        t.px(6, 19, claro(r, 0.4))
        t.px(6, 21, claro(r, 0.4))
    if estilo == "moletom":
        t.ret(5, 15, 10, 15, escuro(r, 0.15))
        t.px(6, 17, claro(r, 0.5))
        t.px(9, 17, claro(r, 0.5))
        t.ret(5, 20, 10, 21, escuro(r, 0.12))
    if estilo == "macacao":
        t.ret(5, 16, 5, 22, claro(r, 0.25))
        t.ret(10, 16, 10, 22, claro(r, 0.25))
        t.ret(6, 18, 9, 20, escuro(r, 0.15))
        t.px(6, 16, r2)
        t.px(9, 16, r2)
        t.px(7, 16, pele_s)
        t.px(8, 16, pele_s)
    if "cracha" in c.get("acess", []):
        t.px(6, 16, (60, 110, 160))
        t.px(6, 17, (60, 110, 160))
        t.px(7, 18, (60, 110, 160))
        t.ret(8, 19, 9, 20, BRANCO)
        t.px(8, 19, (60, 110, 160))
    if "colar" in c.get("acess", []):
        t.ret(6, 16, 9, 16, (240, 226, 190))


def cabeca_frente(t, c):
    pele, pele_s = PELES[c["pele"]]
    t.ret(4, 7, 11, 14, pele)
    t.apaga(4, 14)
    t.apaga(11, 14)
    t.ret(4, 13, 4, 13, pele_s)
    t.px(11, 13, pele_s)
    t.px(3, 10, pele)
    t.px(3, 11, pele_s)
    t.px(12, 10, pele)
    t.px(12, 11, pele_s)
    t.ret(6, 10, 6, 11, OLHO)
    t.ret(9, 10, 9, 11, OLHO)
    t.px(5, 12, BOCHECHA)
    t.px(10, 12, BOCHECHA)
    t.ret(7, 13, 8, 13, BOCA)


def cabeca_costas(t, c):
    pele, pele_s = PELES[c["pele"]]
    t.ret(4, 7, 11, 14, pele)
    t.ret(5, 13, 10, 14, pele_s)
    t.px(3, 10, pele)
    t.px(12, 10, pele)


def cabelo_frente(t, c, costas):
    h = c["cor_cabelo"]
    hs = escuro(h, 0.3)
    hl = claro(h, 0.35)
    e = c["cabelo"]
    if e in ("curto", "longo", "chanel", "rabo", "coque"):
        t.ret(5, 3, 10, 3, h)
        t.ret(4, 4, 11, 6, h)
        t.ret(3, 5, 3, 9, h)
        t.ret(12, 5, 12, 9, h)
        if costas:
            fim = {"curto": 12, "rabo": 12, "coque": 12, "chanel": 14, "longo": 20}[e]
            t.ret(3, 7, 12, fim, h)
            t.ret(4, fim, 11, fim, hs)
            if e == "longo":
                t.ret(2, 10, 2, 18, h)
                t.ret(13, 10, 13, 18, h)
            if e == "rabo":
                t.ret(7, 12, 8, 19, h)
                t.ret(8, 12, 8, 19, hs)
            if e == "chanel":
                t.ret(2, 9, 2, 13, h)
                t.ret(13, 9, 13, 13, h)
        else:
            t.ret(4, 7, 11, 7, h)
            t.px(8, 8, h)
            t.px(9, 8, h)
            t.px(4, 8, h)
            t.px(11, 8, h)
            if e in ("longo",):
                t.ret(3, 7, 3, 19, h)
                t.ret(12, 7, 12, 19, h)
                t.ret(2, 10, 2, 18, hs)
                t.ret(13, 10, 13, 18, hs)
            if e == "chanel":
                t.ret(3, 7, 3, 13, h)
                t.ret(12, 7, 12, 13, h)
                t.ret(2, 9, 2, 13, hs)
                t.ret(13, 9, 13, 13, hs)
            if e == "rabo":
                t.ret(13, 8, 13, 14, hs)
        t.ret(5, 4, 7, 4, hl)
        t.px(6, 5, hl)
        if e == "coque":
            t.ret(6, 0, 9, 2, h)
            t.px(7, 0, hl)
    elif e == "cacheado":
        t.ret(3, 1, 12, 9, h)
        t.ret(2, 3, 13, 9, h)
        for x, y in ((2, 3), (13, 3), (3, 1), (12, 1), (6, 1), (9, 1)):
            t.apaga(x, y)
        if costas:
            t.ret(2, 9, 13, 14, h)
            t.ret(3, 14, 12, 14, hs)
        else:
            t.ret(2, 9, 3, 14, h)
            t.ret(12, 9, 13, 14, h)
            t.ret(4, 7, 11, 7, h)
            t.px(5, 8, h)
            t.px(8, 8, h)
            t.px(11, 8, h)
        for x, y in ((5, 3), (9, 2), (11, 5), (4, 6), (7, 5), (2, 11), (13, 8)):
            t.px(x, y, hl)
        for x, y in ((6, 6), (10, 4), (3, 8), (12, 12)):
            t.px(x, y, hs)
    elif e == "careca":
        pele = PELES[c["pele"]][0]
        t.ret(5, 4, 10, 4, pele)
        t.ret(4, 5, 11, 6, pele)
        t.px(6, 5, claro(pele, 0.5))
        t.px(7, 5, claro(pele, 0.5))
        if costas:
            t.ret(3, 9, 12, 12, h)
        else:
            t.ret(3, 8, 3, 11, h)
            t.ret(12, 8, 12, 11, h)
            t.px(4, 8, h)
            t.px(11, 8, h)
    elif e == "topete":
        h2 = c.get("cor_cabelo2", (60, 44, 40))
        t.ret(4, 1, 11, 6, h)
        t.ret(5, 0, 7, 0, h)
        t.px(10, 0, h)
        t.ret(5, 1, 6, 2, hl)
        t.ret(3, 6, 3, 9, h2)
        t.ret(12, 6, 12, 9, h2)
        if costas:
            t.ret(3, 6, 12, 12, h2)
        else:
            t.ret(4, 7, 6, 7, h)
    elif e == "baixo":
        t.ret(5, 4, 10, 4, h)
        t.ret(4, 5, 11, 7, h)
        t.ret(3, 6, 3, 8, h)
        t.ret(12, 6, 12, 8, h)
        if costas:
            t.ret(3, 7, 12, 12, h)
        for x, y in ((5, 5), (8, 4), (10, 6), (6, 7)):
            t.px(x, y, hl)


def acessorios_frente(t, c, costas):
    a = c.get("acess", [])
    h = c["cor_cabelo"]
    if costas:
        if "bone" in a:
            b = c["cor_bone"]
            t.ret(3, 3, 12, 7, b)
            t.ret(6, 7, 9, 7, claro(b, 0.3))
        if "headset" in a:
            t.ret(4, 3, 11, 3, (54, 54, 62))
            t.ret(2, 9, 2, 11, (54, 54, 62))
            t.ret(13, 9, 13, 11, (54, 54, 62))
        return
    if "barba" in a:
        t.ret(4, 11, 4, 13, h)
        t.ret(11, 11, 11, 13, h)
        t.ret(5, 13, 10, 14, h)
        t.ret(6, 12, 9, 12, h)
        t.ret(7, 13, 8, 13, BOCA)
    if "bigode" in a:
        t.ret(6, 12, 9, 12, h)
    if "oculos" in a:
        fr = c.get("cor_oculos", (70, 50, 60))
        for x in (5, 7, 8, 10):
            t.ret(x, 10, x, 11, fr)
        t.ret(5, 9, 10, 9, fr)
    if "bone" in a:
        b = c["cor_bone"]
        t.ret(4, 3, 11, 3, b)
        t.ret(3, 4, 12, 6, b)
        t.ret(3, 7, 12, 7, escuro(b, 0.25))
        t.ret(6, 4, 8, 5, claro(b, 0.3))
    if "headset" in a:
        cor = c.get("cor_headset", (54, 54, 62))
        t.ret(4, 2, 11, 2, cor)
        t.px(3, 3, cor)
        t.px(12, 3, cor)
        t.ret(2, 4, 2, 8, cor)
        t.ret(13, 4, 13, 8, cor)
        t.ret(1, 9, 3, 11, cor)
        t.ret(12, 9, 14, 11, cor)
        t.px(4, 12, cor)
        t.px(5, 13, (230, 80, 80))


def corpo_lado(t, c, f):
    """Desenha virado para a esquerda."""
    pele, pele_s = PELES[c["pele"]]
    r = c["roupa"]
    r2 = c.get("roupa2", BRANCO)
    calca = c["calca"]
    sapato = c.get("sapato", (70, 50, 50))
    estilo = c["estilo"]
    # pernas
    if f in (1, 3):
        tras = escuro(calca, 0.25)
        frente_c = calca
        if f == 3:
            tras, frente_c = calca, escuro(calca, 0.25)
        t.ret(8, 25, 10, 28, tras)
        t.ret(8, 29, 11, 30, sapato)
        t.ret(5, 25, 7, 27, frente_c)
        t.ret(4, 28, 7, 29, sapato)
        t.px(4, 28, claro(sapato, 0.35))
    else:
        t.ret(6, 25, 9, 28, calca)
        t.ret(8, 25, 8, 28, escuro(calca, 0.3))
        t.ret(5, 29, 9, 30, sapato)
        t.px(5, 29, claro(sapato, 0.35))
    t.ret(5, 23, 10, 24, calca)
    if estilo in ("social", "blazer", "xadrez"):
        t.ret(5, 23, 10, 23, escuro(calca, 0.45))
    if estilo == "macacao":
        t.ret(5, 16, 10, 24, r)
    else:
        t.ret(5, 16, 10, 22, r)
    t.ret(10, 16, 10, 22, escuro(r, 0.2))
    if estilo == "xadrez":
        for y in range(16, 23):
            for x in range(5, 11):
                if x % 3 == 0 or y % 3 == 0:
                    t.px(x, y, r2)
    if estilo in ("blazer", "cardigan"):
        t.ret(5, 16, 5, 22, r2)
    if estilo == "moletom":
        t.ret(8, 15, 10, 17, escuro(r, 0.15))
    if estilo in ("social", "blazer") and c.get("gravata"):
        t.ret(5, 16, 5, 20, c["gravata"])
    # braço (o que fica à vista)
    desl = {0: 0, 1: -1, 2: 0, 3: 1}[f]
    longa = estilo in MANGA_LONGA or estilo == "macacao"
    xa = 7 + desl
    t.ret(xa, 16, xa + 1, 19 if not longa else 21, escuro(r, 0.12))
    if not longa:
        t.ret(xa, 20, xa + 1, 21, pele)
    t.ret(xa, 22, xa + 1, 22, pele)
    t.px(xa + 1, 22, pele_s)
    t.ret(7, 15, 9, 15, pele_s)


def cabeca_lado(t, c):
    pele, pele_s = PELES[c["pele"]]
    t.ret(4, 7, 10, 14, pele)
    t.ret(9, 8, 11, 13, pele)
    t.apaga(4, 14)
    t.px(3, 11, pele)
    t.px(5, 10, OLHO)
    t.px(5, 11, OLHO)
    t.px(4, 13, BOCA)
    t.px(6, 12, BOCHECHA)
    t.px(8, 10, pele_s)
    t.px(8, 11, pele_s)


def cabelo_lado(t, c):
    h = c["cor_cabelo"]
    hs = escuro(h, 0.3)
    hl = claro(h, 0.35)
    e = c["cabelo"]
    if e in ("curto", "longo", "chanel", "rabo", "coque"):
        t.ret(5, 3, 10, 3, h)
        t.ret(4, 4, 11, 6, h)
        t.ret(4, 7, 6, 7, h)
        t.ret(9, 7, 11, 11, h)
        t.ret(10, 12, 11, 12, hs)
        t.ret(5, 4, 7, 4, hl)
        if e == "longo":
            t.ret(9, 7, 12, 20, h)
            t.ret(12, 10, 12, 20, hs)
        if e == "chanel":
            t.ret(9, 7, 12, 14, h)
            t.ret(12, 9, 12, 14, hs)
        if e == "rabo":
            t.ret(12, 6, 13, 15, h)
            t.ret(13, 8, 13, 15, hs)
        if e == "coque":
            t.ret(10, 1, 13, 4, h)
            t.px(11, 1, hl)
    elif e == "cacheado":
        t.ret(3, 1, 12, 9, h)
        t.ret(8, 9, 13, 14, h)
        for x, y in ((3, 1), (12, 1), (13, 9)):
            t.apaga(x, y)
        t.ret(3, 7, 4, 8, h)
        for x, y in ((5, 2), (9, 3), (11, 6), (12, 11)):
            t.px(x, y, hl)
    elif e == "careca":
        pele = PELES[c["pele"]][0]
        t.ret(5, 4, 10, 6, pele)
        t.px(6, 5, claro(pele, 0.5))
        t.ret(9, 8, 11, 11, h)
    elif e == "topete":
        h2 = c.get("cor_cabelo2", (60, 44, 40))
        t.ret(3, 1, 9, 6, h)
        t.ret(2, 2, 3, 3, h)
        t.ret(4, 1, 6, 2, hl)
        t.ret(8, 6, 11, 11, h2)
        t.ret(10, 4, 11, 6, h2)
    elif e == "baixo":
        t.ret(5, 4, 10, 4, h)
        t.ret(4, 5, 11, 7, h)
        t.ret(9, 7, 11, 11, h)
        t.px(6, 5, hl)
        t.px(9, 6, hl)


def acessorios_lado(t, c):
    a = c.get("acess", [])
    h = c["cor_cabelo"]
    if "barba" in a:
        t.ret(5, 12, 8, 14, h)
        t.ret(8, 11, 8, 12, h)
        t.px(4, 14, h)
        t.px(4, 13, BOCA)
    if "bigode" in a:
        t.ret(4, 12, 5, 12, h)
    if "oculos" in a:
        fr = c.get("cor_oculos", (70, 50, 60))
        t.ret(4, 9, 6, 9, fr)
        t.ret(4, 10, 4, 11, fr)
        t.ret(6, 10, 6, 11, fr)
        t.ret(7, 10, 8, 10, fr)
    if "bone" in a:
        b = c["cor_bone"]
        t.ret(4, 3, 11, 6, b)
        t.ret(1, 7, 6, 7, escuro(b, 0.25))
        t.ret(5, 4, 7, 5, claro(b, 0.3))
    if "headset" in a:
        cor = c.get("cor_headset", (54, 54, 62))
        t.ret(8, 2, 9, 8, cor)
        t.ret(8, 9, 10, 11, cor)
        t.ret(5, 12, 7, 12, cor)
        t.px(4, 12, (230, 80, 80))


def quadro_personagem(c, vista, f):
    t = Tela(16, 32)
    if vista == "baixo":
        corpo_frente(t, c, f, False)
        cabeca_frente(t, c)
        cabelo_frente(t, c, False)
        acessorios_frente(t, c, False)
    elif vista == "cima":
        corpo_frente(t, c, f, True)
        cabeca_costas(t, c)
        cabelo_frente(t, c, True)
        acessorios_frente(t, c, True)
    else:
        corpo_lado(t, c, f)
        cabeca_lado(t, c)
        cabelo_lado(t, c)
        acessorios_lado(t, c)
    t.contorno()
    return t


def folha_personagem(nome, c):
    folha = Tela(64, 128)
    for linha, vista in enumerate(("baixo", "cima", "esq", "dir")):
        for f in range(4):
            if vista == "dir":
                q = quadro_personagem(c, "esq", f)
                folha.colar(q, f * 16, linha * 16 * 2, espelhar=True)
            else:
                q = quadro_personagem(c, vista, f)
                folha.colar(q, f * 16, linha * 32)
    folha.salvar("personagens", nome + ".png")


# ---------------------------------------------------------------------------
# Retratos 40x40
# ---------------------------------------------------------------------------
def retrato(nome, c):
    t = Tela(40, 40)
    pele, pele_s = PELES[c["pele"]]
    h = c["cor_cabelo"]
    hs = escuro(h, 0.3)
    hl = claro(h, 0.35)
    r = c["roupa"]
    r2 = c.get("roupa2", BRANCO)
    e = c["cabelo"]
    a = c.get("acess", [])
    estilo = c["estilo"]

    # cabelo de trás (fica atrás do rosto)
    if e == "longo":
        t.ret(8, 10, 31, 37, h)
        t.ret(8, 30, 11, 37, hs)
        t.ret(28, 30, 31, 37, hs)
    if e == "chanel":
        t.ret(8, 9, 31, 27, h)
        t.ret(8, 24, 31, 27, hs)
    if e == "cacheado":
        import math
        t.elipse(19.5, 14, 13, 11, h)
        t.ret(7, 14, 32, 28, h)
        for k in range(13):
            ang = math.pi * (1.1 - 1.2 * k / 12)
            t.elipse(19.5 + 13 * math.cos(ang), 14 - 11 * math.sin(ang), 3.5, 3.5, h)
        for y in (18, 23, 28):
            t.elipse(7, y, 3, 3, h)
            t.elipse(32, y, 3, 3, h)
    if e == "rabo":
        t.ret(29, 12, 33, 30, h)
        t.ret(32, 14, 33, 30, hs)
    if e == "coque":
        t.elipse(19.5, 4, 5, 4, h)
        t.px(18, 2, hl)

    # ombros e roupa
    t.ret(5, 32, 34, 39, r)
    t.ret(7, 31, 32, 31, r)
    t.ret(5, 32, 34, 32, claro(r, 0.2))
    t.ret(31, 33, 34, 39, escuro(r, 0.2))
    if estilo == "xadrez":
        for y in range(31, 40):
            for x in range(5, 35):
                if x % 4 == 0 or y % 4 == 0:
                    t.px(x, y, r2)
    # pescoço
    t.ret(16, 26, 23, 32, pele_s)
    t.ret(17, 26, 22, 28, escuro(pele_s, 0.12))
    # gola por estilo
    if estilo in ("camiseta", "banda", "blusa"):
        t.ret(15, 31, 24, 32, pele_s)
        if estilo == "blusa":
            t.ret(17, 33, 22, 34, pele_s)
            t.ret(18, 35, 21, 35, pele_s)
        if estilo == "banda":
            t.ret(14, 35, 25, 39, r2)
            t.ret(17, 36, 22, 38, r)
            t.px(19, 37, r2)
    if estilo == "polo":
        t.ret(14, 31, 17, 33, r2)
        t.ret(22, 31, 25, 33, r2)
        t.ret(19, 33, 20, 37, escuro(r, 0.2))
        t.px(27, 35, r2)
        t.px(28, 35, r2)
    if estilo in ("social", "xadrez"):
        cola = BRANCO if estilo == "social" else r2
        t.ret(14, 30, 17, 33, cola)
        t.ret(22, 30, 25, 33, cola)
        if c.get("gravata"):
            g = c["gravata"]
            t.ret(18, 32, 21, 33, escuro(g, 0.2))
            t.ret(18, 34, 21, 39, g)
            t.ret(19, 34, 19, 39, claro(g, 0.2))
    if estilo == "blazer":
        t.ret(15, 31, 24, 39, r2)
        for i in range(6):
            t.px(14 + i // 2, 31 + i, claro(r, 0.25))
            t.px(25 - i // 2, 31 + i, claro(r, 0.25))
        if c.get("gravata"):
            g = c["gravata"]
            t.ret(18, 32, 21, 33, escuro(g, 0.2))
            t.ret(18, 34, 21, 39, g)
        else:
            t.ret(17, 31, 22, 32, pele_s)
    if estilo == "cardigan":
        t.ret(16, 31, 23, 39, r2)
        t.ret(15, 31, 24, 32, pele_s)
        t.px(17, 35, claro(r, 0.4))
        t.px(17, 38, claro(r, 0.4))
    if estilo == "moletom":
        t.ret(10, 28, 29, 32, escuro(r, 0.15))
        t.ret(14, 29, 25, 31, escuro(r, 0.3))
        t.ret(16, 33, 16, 37, claro(r, 0.5))
        t.ret(23, 33, 23, 37, claro(r, 0.5))
    if estilo == "macacao":
        t.ret(15, 31, 24, 32, pele_s)
        t.ret(11, 31, 13, 39, claro(r, 0.25))
        t.ret(26, 31, 28, 39, claro(r, 0.25))
        t.ret(15, 34, 24, 39, escuro(r, 0.12))
        t.ret(12, 35, 12, 35, (230, 210, 120))
        t.ret(27, 35, 27, 35, (230, 210, 120))
    if "cracha" in a:
        t.ret(13, 31, 13, 34, (60, 110, 160))
        t.ret(26, 31, 26, 34, (60, 110, 160))
        t.ret(26, 35, 30, 39, BRANCO)
        t.ret(26, 35, 30, 36, (60, 110, 160))
    if "colar" in a:
        for x in range(14, 26, 2):
            t.px(x, 31 + (1 if 16 <= x <= 23 else 0), (246, 236, 210))

    # rosto
    t.ret(11, 8, 28, 24, pele)
    t.ret(12, 25, 27, 25, pele)
    t.ret(13, 26, 26, 26, pele)
    t.ret(15, 27, 24, 27, pele)
    for x, y in ((11, 8), (28, 8), (11, 24), (28, 24)):
        t.apaga(x, y)
    t.ret(26, 12, 28, 23, pele_s)
    t.ret(24, 25, 27, 25, pele_s)
    t.ret(22, 26, 26, 26, pele_s)
    t.ret(9, 15, 10, 20, pele)
    t.ret(29, 15, 30, 20, pele_s)
    t.px(10, 17, pele_s)
    # olhos
    for ox in (14, 23):
        t.ret(ox, 16, ox + 2, 16, OLHO)
        t.ret(ox, 17, ox + 2, 19, BRANCO)
        t.ret(ox + 1, 17, ox + 2, 19, c.get("cor_olho", (74, 52, 44)))
        t.px(ox + 1, 17, BRANCO)
    # sobrancelhas
    sob = escuro(h, 0.25) if e not in ("careca",) else escuro(h, 0.1)
    if e == "topete":
        sob = escuro(c.get("cor_cabelo2", h), 0.1)
    t.ret(14, 14, 16, 14, sob)
    t.ret(23, 14, 25, 14, sob)
    # nariz, boca, bochechas
    t.px(20, 20, pele_s)
    t.ret(19, 21, 20, 21, pele_s)
    t.ret(18, 24, 21, 24, BOCA)
    t.px(17, 23, BOCA)
    t.px(22, 23, BOCA)
    t.ret(13, 21, 14, 21, BOCHECHA)
    t.ret(25, 21, 26, 21, BOCHECHA)

    # cabelo da frente
    if e in ("curto", "longo", "chanel", "rabo", "coque"):
        t.ret(12, 4, 27, 5, h)
        t.ret(10, 6, 29, 11, h)
        t.ret(9, 9, 10, 15, h)
        t.ret(29, 9, 30, 15, h)
        if e == "chanel":
            t.ret(11, 11, 28, 13, h)
            t.ret(8, 10, 10, 26, h)
            t.ret(29, 10, 31, 26, h)
        elif e == "longo":
            t.ret(8, 10, 10, 34, h)
            t.ret(29, 10, 31, 34, h)
            t.ret(11, 11, 18, 12, h)
            t.ret(11, 13, 14, 13, h)
            t.ret(22, 11, 28, 11, h)
        elif e == "coque":
            t.ret(11, 11, 15, 12, h)
            t.ret(24, 11, 28, 11, h)
        else:
            t.ret(11, 11, 17, 12, h)
            t.ret(11, 13, 13, 13, h)
            t.ret(21, 11, 28, 12, h)
            t.ret(26, 13, 28, 13, h)
        t.ret(14, 6, 19, 7, hl)
        t.ret(12, 8, 14, 8, hl)
        t.ret(22, 9, 27, 10, hs)
    elif e == "cacheado":
        t.ret(11, 5, 28, 12, h)
        for x, y in ((12, 13), (16, 13), (20, 12), (25, 13), (28, 14), (11, 14)):
            t.px(x, y, h)
        for x, y in ((9, 6), (14, 4), (20, 3), (26, 5), (31, 9), (7, 12), (32, 16), (6, 20),
                     (33, 23), (12, 9), (24, 10), (18, 7)):
            t.px(x, y, hl)
            t.px(x + 1, y, hl)
        for x, y in ((11, 5), (23, 4), (29, 12), (8, 17), (31, 21), (16, 10)):
            t.px(x, y, hs)
            t.px(x, y + 1, hs)
    elif e == "careca":
        t.ret(12, 4, 27, 7, pele)
        t.ret(11, 5, 28, 7, pele)
        t.ret(15, 5, 18, 5, claro(pele, 0.5))
        t.ret(9, 10, 11, 17, h)
        t.ret(28, 10, 30, 17, h)
    elif e == "topete":
        h2 = c.get("cor_cabelo2", (60, 44, 40))
        t.ret(9, 7, 11, 16, h2)
        t.ret(28, 7, 30, 16, h2)
        t.ret(11, 1, 28, 10, h)
        t.ret(13, 0, 18, 0, h)
        t.ret(22, 0, 25, 0, h)
        t.ret(11, 11, 15, 12, h)
        t.ret(13, 1, 17, 3, hl)
        t.ret(20, 2, 24, 3, hl)
        t.ret(24, 8, 28, 10, hs)
    elif e == "baixo":
        t.ret(12, 5, 27, 5, h)
        t.ret(10, 6, 29, 10, h)
        t.ret(9, 8, 10, 14, h)
        t.ret(29, 8, 30, 14, h)
        for x, y in ((13, 6), (17, 7), (22, 6), (26, 8), (11, 9), (15, 9), (20, 9)):
            t.px(x, y, hl)

    # acessórios
    if "barba" in a:
        t.ret(11, 19, 12, 25, h)
        t.ret(27, 19, 28, 25, h)
        t.ret(12, 23, 27, 27, h)
        t.ret(15, 28, 24, 28, h)
        t.ret(17, 23, 22, 23, h)
        t.ret(18, 24, 21, 24, BOCA)
        t.ret(14, 25, 25, 25, hs)
    if "bigode" in a:
        t.ret(16, 22, 23, 23, h)
        t.ret(18, 24, 21, 24, BOCA)
    if "oculos" in a:
        fr = c.get("cor_oculos", (70, 50, 60))
        for ox in (13, 22):
            t.ret(ox, 15, ox + 4, 15, fr)
            t.ret(ox, 20, ox + 4, 20, fr)
            t.ret(ox, 15, ox, 20, fr)
            t.ret(ox + 4, 15, ox + 4, 20, fr)
        t.ret(18, 16, 21, 16, fr)
        t.ret(10, 16, 12, 16, fr)
        t.ret(27, 16, 29, 16, fr)
    if "bone" in a:
        b = c["cor_bone"]
        t.ret(12, 2, 27, 3, b)
        t.ret(10, 4, 29, 9, b)
        t.ret(8, 10, 31, 11, escuro(b, 0.25))
        t.ret(14, 4, 19, 6, claro(b, 0.3))
        t.ret(18, 5, 21, 7, BRANCO)
    if "headset" in a:
        cor = c.get("cor_headset", (54, 54, 62))
        t.ret(12, 1, 27, 2, cor)
        t.ret(9, 3, 11, 4, cor)
        t.ret(28, 3, 30, 4, cor)
        t.ret(7, 5, 8, 13, cor)
        t.ret(31, 5, 32, 13, cor)
        t.ret(5, 14, 9, 21, cor)
        t.ret(30, 14, 34, 21, cor)
        t.ret(6, 15, 8, 20, claro(cor, 0.3))
        t.ret(9, 22, 10, 23, cor)
        t.ret(11, 24, 15, 24, cor)
        t.ret(16, 24, 16, 24, (230, 80, 80))

    t.contorno()
    t.salvar("retratos", nome + ".png")
    return t


# ---------------------------------------------------------------------------
# Elenco
# ---------------------------------------------------------------------------
AZUL_EMPRESA = (58, 122, 172)

ELENCO = {
    "gabriel": dict(pele=1, cabelo="curto", cor_cabelo=(58, 40, 36), estilo="polo", roupa=AZUL_EMPRESA,
                    roupa2=(236, 240, 240), calca=(66, 78, 112), sapato=(236, 232, 224), acess=["cracha"],
                    cor_olho=(80, 54, 40)),
    "celia": dict(pele=0, cabelo="chanel", cor_cabelo=(188, 186, 196), estilo="blazer", roupa=(140, 52, 78),
                  roupa2=(246, 230, 200), calca=(70, 62, 78), sapato=(50, 36, 44), acess=["oculos", "colar"],
                  cor_oculos=(150, 60, 90), cor_olho=(90, 110, 80)),
    "rafa": dict(pele=2, cabelo="cacheado", cor_cabelo=(40, 30, 34), estilo="camiseta", roupa=(226, 172, 60),
                 calca=(64, 82, 120), sapato=(206, 64, 60), acess=["headset"], cor_headset=(214, 70, 70),
                 cor_olho=(60, 40, 30)),
    "bia": dict(pele=0, cabelo="longo", cor_cabelo=(176, 82, 48), estilo="cardigan", roupa=(176, 146, 206),
                roupa2=(250, 240, 220), calca=(200, 176, 140), sapato=(130, 90, 70), acess=["oculos", "cracha"],
                cor_oculos=(80, 70, 110), cor_olho=(70, 110, 70)),
    "otavio": dict(pele=1, cabelo="careca", cor_cabelo=(84, 70, 66), estilo="social", roupa=(132, 146, 168),
                   gravata=(120, 60, 50), calca=(56, 56, 70), sapato=(60, 40, 34), acess=["barba"],
                   cor_olho=(60, 60, 50)),
    "luana": dict(pele=3, cabelo="rabo", cor_cabelo=(34, 26, 34), estilo="banda", roupa=(44, 40, 52),
                  roupa2=(206, 58, 66), calca=(36, 34, 44), sapato=(40, 30, 30), acess=[],
                  cor_olho=(50, 34, 30)),
    "davi": dict(pele=2, cabelo="topete", cor_cabelo=(236, 204, 110), cor_cabelo2=(52, 38, 34), estilo="moletom",
                 roupa=(104, 182, 96), calca=(110, 100, 80), sapato=(240, 240, 236), acess=["cracha"],
                 cor_olho=(60, 40, 30)),
    "marlene": dict(pele=1, cabelo="cacheado", cor_cabelo=(150, 54, 70), estilo="blusa", roupa=(232, 128, 160),
                    calca=(240, 234, 222), sapato=(200, 80, 110), acess=["colar"], cor_olho=(80, 50, 40)),
    "helio": dict(pele=0, cabelo="curto", cor_cabelo=(170, 168, 176), estilo="blazer", roupa=(44, 54, 96),
                  roupa2=(240, 240, 246), gravata=(190, 50, 56), calca=(44, 54, 96), sapato=(36, 28, 30),
                  acess=["bigode"], cor_olho=(70, 90, 120)),
    "juninho": dict(pele=1, cabelo="curto", cor_cabelo=(90, 60, 40), estilo="camiseta", roupa=(84, 186, 200),
                    calca=(70, 90, 130), sapato=(240, 150, 60), acess=["bone"], cor_bone=(236, 132, 54),
                    cor_olho=(70, 50, 40)),
    "sandra": dict(pele=3, cabelo="coque", cor_cabelo=(30, 24, 30), estilo="blazer", roupa=(176, 178, 190),
                   roupa2=(250, 248, 244), calca=(90, 90, 104), sapato=(30, 26, 30), acess=["colar"],
                   cor_olho=(50, 34, 30)),
    "tiao": dict(pele=2, cabelo="careca", cor_cabelo=(120, 116, 116), estilo="macacao", roupa=(70, 112, 156),
                 roupa2=(240, 200, 80), calca=(70, 112, 156), sapato=(80, 56, 40), acess=["bigode", "bone"],
                 cor_bone=(70, 112, 156), cor_olho=(60, 40, 30)),
    "katia": dict(pele=0, cabelo="rabo", cor_cabelo=(226, 186, 104), estilo="social", roupa=(244, 240, 232),
                  calca=(62, 92, 150), sapato=(150, 60, 60), acess=["cracha"], cor_olho=(70, 100, 140)),
    "pedro": dict(pele=3, cabelo="baixo", cor_cabelo=(36, 28, 30), estilo="xadrez", roupa=(78, 132, 92),
                  roupa2=(52, 94, 64), calca=(188, 166, 120), sapato=(90, 64, 50), acess=["cracha"],
                  cor_olho=(50, 34, 30)),
}


# ---------------------------------------------------------------------------
# Tiles 16x16
# ---------------------------------------------------------------------------
MADEIRA = (198, 136, 84)
MADEIRA_C = (220, 164, 104)
MADEIRA_E = (162, 104, 66)
MADEIRA_L = (126, 78, 54)


def tile_madeira(t, ox, oy, var):
    for linha in range(4):
        y0 = oy + linha * 4
        base = [MADEIRA, mistura(MADEIRA, MADEIRA_C, 0.4), mistura(MADEIRA, MADEIRA_E, 0.3), MADEIRA][(linha + var) % 4]
        t.ret(ox, y0, ox + 15, y0 + 2, base)
        t.ret(ox, y0 + 3, ox + 15, y0 + 3, MADEIRA_L)
        t.ret(ox, y0, ox + 15, y0, claro(base, 0.12))
        emenda = (linha * 7 + var * 5 + 3) % 16
        t.ret(ox + emenda, y0, ox + emenda, y0 + 2, MADEIRA_L)
        t.px(ox + (emenda + 5) % 16, y0 + 1, escuro(base, 0.1))
        t.px(ox + (emenda + 11) % 16, y0 + 2, claro(base, 0.15))


def tile_linoleo(t, ox, oy, var):
    a, b = (222, 206, 170), (204, 184, 146)
    for y in range(16):
        for x in range(16):
            cor = a if ((x // 8) + (y // 8) + var) % 2 == 0 else b
            t.px(ox + x, oy + y, cor)
    for x, y in ((3, 2), (11, 5), (6, 12), (13, 13), (1, 9), (9, 1)):
        t.px(ox + x, oy + y, escuro(t.p[ox + x, oy + y][:3], 0.08))
    t.ret(ox, oy + 15, ox + 15, oy + 15, (190, 168, 130))
    t.ret(ox + 15, oy, ox + 15, oy + 15, (190, 168, 130))


def tile_piso_elevado(t, ox, oy, var):
    base = (156, 166, 176)
    t.ret(ox, oy, ox + 15, oy + 15, base)
    t.ret(ox, oy, ox + 15, oy, claro(base, 0.3))
    t.ret(ox, oy, ox, oy + 15, claro(base, 0.2))
    t.ret(ox + 15, oy, ox + 15, oy + 15, escuro(base, 0.3))
    t.ret(ox, oy + 15, ox + 15, oy + 15, escuro(base, 0.35))
    if var == 1:
        for y in range(3, 13, 2):
            for x in range(3, 13, 2):
                t.px(ox + x, oy + y, escuro(base, 0.35))
    else:
        for x, y in ((2, 2), (13, 2), (2, 13), (13, 13)):
            t.px(ox + x, oy + y, escuro(base, 0.25))
        t.px(ox + 7, oy + 8, claro(base, 0.15))


def tile_carpete(t, ox, oy, var):
    a = (92, 120, 150)
    b = (84, 110, 140)
    for y in range(16):
        for x in range(16):
            t.px(ox + x, oy + y, a if (x + y * 3 + var) % 5 else b)
    for x, y in ((4, 4), (12, 12)):
        t.ret(ox + x - 1, oy + y, ox + x + 1, oy + y, (112, 140, 168))
        t.ret(ox + x, oy + y - 1, ox + x, oy + y + 1, (112, 140, 168))


def tile_parede_topo(t, ox, oy, mascara):
    """mascara: bits N=1, L=2, S=4, O=8 indicam vizinho que também é parede."""
    base = (92, 66, 70)
    t.ret(ox, oy, ox + 15, oy + 15, base)
    for x in range(16):
        for y in range(16):
            if (x + y) % 6 == 0:
                t.px(ox + x, oy + y, mistura(base, (104, 76, 80), 0.6))
    borda = (152, 112, 98)
    sombra = (64, 44, 52)
    if not mascara & 1:
        t.ret(ox, oy, ox + 15, oy + 1, borda)
    if not mascara & 4:
        t.ret(ox, oy + 14, ox + 15, oy + 15, borda)
        t.ret(ox, oy + 15, ox + 15, oy + 15, sombra)
    if not mascara & 8:
        t.ret(ox, oy, ox + 1, oy + 15, borda)
    if not mascara & 2:
        t.ret(ox + 14, oy, ox + 15, oy + 15, borda)
        t.ret(ox + 15, oy, ox + 15, oy + 15, sombra)


PAREDES = {
    "pa": dict(papel=(240, 222, 182), listra=(228, 204, 160), lambri=(170, 112, 72)),
    "bo": dict(papel=(196, 214, 176), listra=(182, 202, 160), lambri=(132, 96, 70)),
    "tc": dict(papel=(150, 170, 192), listra=(138, 158, 180), lambri=(86, 96, 116)),
}


def tile_parede_frente(t, ox, oy, sala, var):
    p = PAREDES[sala]
    t.ret(ox, oy, ox + 15, oy + 31, p["papel"])
    for x in range(0, 16, 4):
        t.ret(ox + x + (1 if var else 0), oy + 2, ox + x + (1 if var else 0), oy + 19, p["listra"])
    if sala == "bo":
        for y in range(4, 19, 5):
            for x in range(2, 16, 6):
                t.px(ox + x + (y % 2), oy + y, escuro(p["papel"], 0.18))
    t.ret(ox, oy, ox + 15, oy + 1, claro(p["lambri"], 0.2))
    t.ret(ox, oy + 2, ox + 15, oy + 2, escuro(p["papel"], 0.2))
    t.ret(ox, oy + 20, ox + 15, oy + 21, claro(p["lambri"], 0.3))
    t.ret(ox, oy + 22, ox + 15, oy + 29, p["lambri"])
    t.ret(ox + 2, oy + 23, ox + 13, oy + 23, escuro(p["lambri"], 0.2))
    t.ret(ox + 2, oy + 23, ox + 2, oy + 28, escuro(p["lambri"], 0.2))
    t.ret(ox + 3, oy + 28, ox + 13, oy + 28, claro(p["lambri"], 0.18))
    t.ret(ox + 13, oy + 24, ox + 13, oy + 28, claro(p["lambri"], 0.18))
    t.ret(ox, oy + 30, ox + 15, oy + 31, escuro(p["lambri"], 0.4))


def gerar_tiles():
    t = Tela(16 * 16, 16 * 4)
    tile_madeira(t, 0, 0, 0)
    tile_madeira(t, 16, 0, 1)
    tile_linoleo(t, 32, 0, 0)
    tile_linoleo(t, 48, 0, 1)
    tile_piso_elevado(t, 64, 0, 0)
    tile_piso_elevado(t, 80, 0, 1)
    tile_carpete(t, 96, 0, 0)
    tile_carpete(t, 112, 0, 2)
    # soleira de porta
    t.ret(128, 0, 143, 15, (150, 120, 96))
    t.ret(128, 0, 143, 1, (180, 150, 120))
    t.ret(128, 14, 143, 15, (120, 92, 76))
    # fundo escuro (fora do prédio)
    t.ret(144, 0, 159, 15, (40, 30, 40))
    for m in range(16):
        tile_parede_topo(t, m * 16, 16, m)
    for i, sala in enumerate(("pa", "bo", "tc")):
        tile_parede_frente(t, i * 32, 32, sala, 0)
        tile_parede_frente(t, i * 32 + 16, 32, sala, 1)
    t.salvar("tiles.png")


# ---------------------------------------------------------------------------
# Móveis e objetos
# ---------------------------------------------------------------------------
TELA_PC = (96, 176, 214)
CINZA = (176, 176, 184)
CINZA_E = (98, 98, 112)
PRETO = (52, 50, 60)


def monitor(t, x, y, w=14, h=10, cor_tela=TELA_PC, conteudo="texto"):
    t.ret(x, y, x + w - 1, y + h - 1, PRETO)
    t.ret(x + 1, y + 1, x + w - 2, y + h - 2, cor_tela)
    t.ret(x + 1, y + 1, x + w - 2, y + 1, claro(cor_tela, 0.35))
    if conteudo == "texto":
        for i, ly in enumerate(range(y + 3, y + h - 2, 2)):
            t.ret(x + 2, ly, x + 2 + (w - 6) - (i * 3) % 5, ly, claro(cor_tela, 0.55))
    elif conteudo == "grafico":
        for i in range(w - 4):
            hh = (i * 7 + 3) % (h - 4) + 1
            t.px(x + 2 + i, y + h - 2 - hh, (120, 230, 140))
    elif conteudo == "planilha":
        for ly in range(y + 2, y + h - 1, 2):
            t.ret(x + 1, ly, x + w - 2, ly, claro(cor_tela, 0.6))
        for lx in range(x + 4, x + w - 1, 4):
            t.ret(lx, y + 1, lx, y + h - 2, claro(cor_tela, 0.6))
    cx = x + w // 2
    t.ret(cx - 1, y + h, cx, y + h + 1, CINZA_E)
    t.ret(cx - 3, y + h + 2, cx + 2, y + h + 2, CINZA_E)


def mesa(nome, extra=None, largura=32, teclado_x=None):
    w = largura
    t = Tela(w, 28)
    tampo = (214, 168, 112)
    frente = (170, 116, 76)
    t.ret(0, 10, w - 1, 17, tampo)
    t.ret(0, 10, w - 1, 10, claro(tampo, 0.35))
    t.ret(0, 17, w - 1, 17, escuro(tampo, 0.15))
    t.ret(0, 18, w - 1, 25, frente)
    t.ret(0, 18, w - 1, 18, escuro(frente, 0.25))
    t.ret(w - 12, 19, w - 2, 24, claro(frente, 0.1))
    t.ret(w - 12, 21, w - 2, 21, escuro(frente, 0.3))
    t.ret(w - 8, 20, w - 6, 20, (230, 210, 150))
    t.ret(w - 8, 23, w - 6, 23, (230, 210, 150))
    t.ret(1, 26, 2, 27, escuro(frente, 0.35))
    t.ret(w - 3, 26, w - 2, 27, escuro(frente, 0.35))
    # teclado
    kx = w // 2 - 6 if teclado_x is None else teclado_x
    t.ret(kx, 14, kx + 11, 16, (220, 220, 226))
    for x in range(kx + 1, kx + 11, 2):
        t.px(x, 15, CINZA)
    t.ret(kx + 14, 15, kx + 15, 16, (220, 220, 226))
    if extra:
        extra(t, w)
    else:
        monitor(t, w // 2 - 7, 0)
    t.contorno()
    t.salvar("moveis", nome + ".png")


def caneca(t, x, y, cor=BRANCO):
    t.ret(x, y, x + 2, y + 3, cor)
    t.px(x + 3, y + 1, cor)
    t.px(x + 1, y, (120, 70, 50))


def suculenta(t, x, y, verde=(108, 168, 96)):
    t.ret(x, y + 3, x + 3, y + 5, (190, 110, 80))
    t.ret(x, y + 3, x + 3, y + 3, claro((190, 110, 80), 0.3))
    t.ret(x, y + 1, x + 3, y + 2, verde)
    t.px(x + 1, y, verde)
    t.px(x + 2, y, claro(verde, 0.3))


def mesa_gabriel(t, w):
    # o telefone é um sprite à parte (anima quando toca), à direita do monitor
    monitor(t, 2, 0)
    caneca(t, 27, 12, (58, 122, 172))


def mesa_rafa(t, w):
    monitor(t, 9, 0, cor_tela=(150, 110, 200))
    t.ret(26, 9, 27, 14, (230, 60, 60))
    t.ret(26, 9, 27, 9, (240, 240, 240))
    t.ret(3, 10, 5, 14, (240, 200, 60))
    t.ret(3, 9, 5, 9, (60, 60, 60))
    t.px(4, 11, (60, 60, 60))


def mesa_bia(t, w):
    monitor(t, 9, 0)
    t.ret(2, 12, 8, 16, (250, 170, 190))
    t.ret(2, 12, 2, 16, (200, 110, 140))
    for i, cor in enumerate(((230, 80, 80), (80, 160, 230), (110, 200, 110), (240, 200, 60))):
        t.ret(24 + i, 11, 24 + i, 14, cor)
    t.ret(10, 2, 12, 4, (250, 236, 120))
    t.ret(19, 2, 21, 4, (250, 160, 200))


def mesa_celia(t, w):
    monitor(t, 9, 0)
    suculenta(t, 1, 9)
    suculenta(t, 5, 10, (140, 180, 110))
    suculenta(t, 26, 9, (100, 150, 120))
    caneca(t, 22, 11, (190, 70, 100))


def mesa_otavio(t, w):
    monitor(t, 1, 1, 14, 9, conteudo="planilha")
    monitor(t, 17, 0, 14, 10, conteudo="planilha")
    monitor(t, 33, 1, 14, 9, conteudo="texto")
    # bonsai
    t.ret(3, 15, 9, 17, (120, 80, 160))
    t.ret(5, 13, 6, 14, (110, 80, 60))
    t.elipse(5.5, 11, 4, 2, (90, 150, 80))
    t.px(4, 10, (130, 190, 110))
    caneca(t, 41, 13, (60, 50, 50))


def mesa_luana(t, w):
    monitor(t, 9, 0, cor_tela=(40, 60, 70), conteudo="grafico")
    t.px(11, 2, (230, 60, 70))
    t.px(12, 2, (230, 60, 70))
    t.ret(1, 13, 6, 14, (60, 120, 210))
    t.ret(2, 12, 5, 12, (60, 120, 210))
    t.ret(24, 11, 29, 14, (60, 60, 70))
    t.ret(25, 12, 28, 13, (120, 220, 140))


def mesa_davi(t, w):
    monitor(t, 9, 0)
    t.ret(25, 4, 25, 13, CINZA_E)
    t.ret(23, 1, 27, 5, (60, 60, 70))
    t.ret(24, 2, 26, 4, (140, 200, 240))
    t.ret(2, 11, 6, 14, (240, 120, 60))
    t.ret(2, 11, 6, 11, (250, 230, 200))


def cadeira(nome="cadeira", cor=(70, 76, 96)):
    t = Tela(14, 20)
    t.ret(2, 0, 11, 8, cor)
    t.ret(2, 0, 11, 0, claro(cor, 0.3))
    t.ret(3, 2, 10, 6, claro(cor, 0.12))
    t.ret(1, 9, 12, 12, escuro(cor, 0.1))
    t.ret(1, 9, 12, 9, claro(cor, 0.2))
    t.ret(6, 13, 7, 15, CINZA_E)
    t.ret(1, 16, 12, 16, CINZA_E)
    t.px(1, 17, PRETO)
    t.px(12, 17, PRETO)
    t.px(6, 17, PRETO)
    t.contorno()
    t.salvar("moveis", nome + ".png")


def balcao():
    w = 128
    t = Tela(w, 30)
    tampo = (236, 226, 208)
    frente = (150, 98, 64)
    t.ret(0, 4, w - 1, 12, tampo)
    t.ret(0, 4, w - 1, 4, BRANCO)
    for x in range(3, w, 9):
        t.px(x, 7 + (x % 3), (214, 202, 182))
    t.ret(0, 12, w - 1, 12, escuro(tampo, 0.2))
    t.ret(0, 13, w - 1, 28, frente)
    t.ret(0, 16, w - 1, 18, AZUL_EMPRESA)
    t.ret(0, 16, w - 1, 16, claro(AZUL_EMPRESA, 0.3))
    for x in range(0, w, 32):
        t.ret(x, 19, x, 28, escuro(frente, 0.3))
        t.ret(x + 1, 19, x + 1, 28, claro(frente, 0.15))
    t.ret(0, 27, w - 1, 28, escuro(frente, 0.35))
    # campainha
    t.ret(62, 1, 66, 3, (230, 190, 80))
    t.ret(63, 0, 65, 0, (250, 220, 120))
    t.ret(61, 4, 67, 4, (160, 120, 60))
    # monitores voltados para dentro
    for x in (20, 60, 100):
        t.ret(x, 0, x + 11, 4, PRETO)
        t.ret(x + 1, 1, x + 10, 3, (70, 70, 84))
    t.contorno()
    t.salvar("moveis", "balcao.png")


def impressora():
    t = Tela(26, 30)
    gab = (120, 110, 104)
    t.caixa(2, 16, 23, 29, gab)
    t.ret(4, 19, 21, 20, escuro(gab, 0.2))
    t.ret(4, 24, 21, 25, escuro(gab, 0.2))
    t.ret(11, 21, 14, 21, CINZA)
    t.ret(11, 26, 14, 26, CINZA)
    corpo = (226, 226, 232)
    t.caixa(1, 4, 24, 15, corpo)
    t.ret(4, 1, 17, 4, BRANCO)
    t.ret(4, 1, 17, 1, (236, 236, 236))
    t.ret(3, 10, 18, 11, escuro(corpo, 0.25))
    t.ret(6, 12, 15, 12, BRANCO)
    t.ret(18, 5, 23, 8, (60, 64, 74))
    t.ret(19, 6, 21, 7, (120, 200, 160))
    t.px(23, 9, (110, 220, 110))
    t.contorno()
    t.salvar("moveis", "impressora.png")


def cafeteira():
    t = Tela(20, 30)
    mov = (170, 116, 76)
    t.caixa(0, 14, 19, 29, mov)
    t.ret(2, 18, 17, 18, escuro(mov, 0.3))
    t.ret(9, 20, 10, 22, (230, 210, 150))
    t.ret(3, 2, 12, 13, (60, 50, 56))
    t.ret(3, 2, 12, 3, (200, 60, 60))
    t.ret(5, 8, 10, 12, (170, 200, 220))
    t.ret(6, 10, 9, 12, (110, 70, 50))
    t.ret(5, 5, 6, 5, (120, 220, 120))
    for x in (14, 17):
        caneca(t, x - 1, 10, BRANCO)
    t.contorno()
    t.salvar("moveis", "cafeteira.png")


def bebedouro():
    t = Tela(14, 30)
    t.ret(3, 0, 10, 10, (150, 200, 236))
    t.ret(4, 1, 5, 9, (200, 230, 250))
    t.ret(5, 0, 8, 0, (110, 160, 210))
    t.caixa(1, 11, 12, 29, (236, 236, 240))
    t.px(4, 15, (230, 70, 70))
    t.px(9, 15, (70, 120, 230))
    t.ret(3, 17, 10, 18, CINZA)
    t.contorno()
    t.salvar("moveis", "bebedouro.png")


def planta(nome="planta", alta=False):
    h = 34 if alta else 28
    t = Tela(18, h)
    vaso = (196, 112, 76)
    t.ret(4, h - 9, 13, h - 1, vaso)
    t.ret(3, h - 10, 14, h - 8, claro(vaso, 0.2))
    t.ret(12, h - 7, 13, h - 1, escuro(vaso, 0.25))
    verde, verde_c, verde_e = (92, 156, 84), (136, 194, 106), (62, 114, 74)
    if alta:
        t.ret(8, 8, 9, h - 10, (110, 80, 60))
        folhas = [(9, 6, 6, 5), (5, 11, 4, 3), (13, 12, 4, 3), (8, 2, 4, 3), (4, 18, 3, 3), (14, 19, 3, 3)]
    else:
        folhas = [(9, 9, 5, 4), (4, 13, 4, 4), (14, 13, 4, 4), (6, 5, 3, 3), (12, 5, 3, 3), (9, 15, 4, 3)]
    for cx, cy, rx, ry in folhas:
        t.elipse(cx, cy, rx, ry, verde)
    for cx, cy, rx, ry in folhas:
        t.elipse(cx - 1, cy - 1, max(1, rx - 2), max(1, ry - 2), verde_c)
        t.px(cx + rx - 1, cy + 1, verde_e)
    t.contorno()
    t.salvar("moveis", nome + ".png")


def arquivo():
    t = Tela(16, 28)
    cor = (150, 160, 170)
    t.caixa(0, 0, 15, 27, cor)
    for y in (8, 16, 24):
        t.ret(1, y, 14, y, escuro(cor, 0.3))
    for y in (4, 12, 20):
        t.ret(6, y, 9, y, (80, 80, 92))
        t.ret(5, y - 2, 10, y - 2, (240, 236, 220))
    t.contorno()
    t.salvar("moveis", "arquivo.png")


def estante(nome="estante", conteudo="caixas"):
    t = Tela(34, 38)
    mad = (150, 100, 66)
    t.ret(0, 0, 33, 37, escuro(mad, 0.3))
    t.ret(0, 0, 1, 37, mad)
    t.ret(32, 0, 33, 37, mad)
    t.ret(0, 0, 33, 1, claro(mad, 0.2))
    for y in (12, 24, 36):
        t.ret(0, y, 33, y + 1, mad)
        t.ret(0, y, 33, y, claro(mad, 0.25))
    cores = [(200, 160, 110), (90, 130, 190), (220, 220, 226), (200, 90, 80), (110, 170, 110), (60, 60, 70)]
    if conteudo == "caixas":
        itens = [(2, 4, 10, 11, 0), (12, 6, 19, 11, 1), (21, 3, 31, 11, 0), (2, 16, 8, 23, 2), (10, 15, 20, 23, 0),
                 (22, 18, 31, 23, 3), (2, 28, 13, 35, 0), (15, 30, 22, 35, 4), (24, 27, 31, 35, 5)]
    else:
        itens = [(2, 3, 15, 11, 2), (17, 3, 31, 11, 2), (2, 16, 9, 23, 5), (11, 16, 18, 23, 5), (20, 15, 31, 23, 0),
                 (2, 27, 10, 35, 1), (12, 29, 20, 35, 3), (22, 28, 31, 35, 4)]
    for x0, y0, x1, y1, ci in itens:
        t.caixa(x0, y0, x1, y1, cores[ci])
        if ci == 0:
            t.ret((x0 + x1) // 2, y0, (x0 + x1) // 2, y1, escuro(cores[0], 0.2))
        if ci == 2 and conteudo != "caixas":
            t.ret(x0 + 2, y0 + 2, x1 - 2, y0 + 3, AZUL_EMPRESA)
    t.contorno()
    t.salvar("moveis", nome + ".png")


def rack(nome="rack", cabos=False):
    folha = Tela(44, 42)
    for quadro in range(2):
        t = Tela(22, 42)
        cor = (50, 52, 62)
        t.ret(0, 0, 21, 41, cor)
        t.ret(0, 0, 21, 1, claro(cor, 0.25))
        t.ret(0, 0, 0, 41, claro(cor, 0.15))
        t.ret(21, 0, 21, 41, escuro(cor, 0.3))
        for i, y in enumerate(range(3, 38, 5)):
            t.ret(2, y, 19, y + 3, (78, 82, 96))
            t.ret(2, y, 19, y, (104, 108, 124))
            for k in range(3):
                aceso = (i + k + quadro) % 3 != 0
                cor_led = [(110, 230, 120), (250, 190, 70), (110, 230, 120)][k]
                t.px(4 + k * 2, y + 2, cor_led if aceso else (40, 60, 44))
            if cabos:
                for k, cc in enumerate(((70, 140, 230), (240, 200, 60), (230, 80, 80), (110, 200, 110),
                                        (70, 140, 230), (240, 240, 240))):
                    t.px(10 + k * 1 + (k // 2), y + 1, cc)
                    t.px(10 + k + (k // 2), y + 2, cc)
            else:
                t.ret(10, y + 1, 18, y + 2, (60, 62, 74))
        if cabos:
            for k, cc in enumerate(((70, 140, 230), (240, 200, 60), (230, 80, 80), (110, 200, 110))):
                t.ret(20 + (k % 2), 6 + k * 7, 20 + (k % 2), 36, cc)
        t.ret(2, 39, 4, 41, PRETO)
        t.ret(17, 39, 19, 41, PRETO)
        t.contorno()
        folha.colar(t, quadro * 22, 0)
    folha.salvar("moveis", nome + ".png")


def bobina():
    t = Tela(16, 16)
    mad = (190, 140, 90)
    t.elipse(7.5, 7.5, 7, 7, mad)
    t.elipse(7.5, 7.5, 5, 5, (70, 130, 220))
    t.elipse(7.5, 7.5, 2, 2, escuro(mad, 0.2))
    for a in range(0, 10, 3):
        t.px(4 + a, 4 + (a % 4), claro((70, 130, 220), 0.4))
    t.contorno()
    t.salvar("moveis", "bobina.png")


def bancada():
    t = Tela(34, 26)
    topo = (150, 156, 166)
    t.ret(0, 8, 33, 15, topo)
    t.ret(0, 8, 33, 8, claro(topo, 0.35))
    t.ret(0, 16, 33, 22, escuro(topo, 0.25))
    t.ret(1, 23, 2, 25, CINZA_E)
    t.ret(31, 23, 32, 25, CINZA_E)
    t.ret(3, 10, 10, 13, (240, 200, 60))
    t.ret(5, 11, 8, 12, (60, 60, 70))
    t.ret(13, 11, 21, 11, (220, 60, 60))
    t.ret(21, 11, 23, 11, CINZA)
    t.ret(25, 9, 31, 13, (70, 120, 210))
    t.ret(26, 10, 30, 12, (110, 160, 230))
    t.ret(5, 2, 12, 7, (230, 200, 120))
    t.ret(6, 3, 11, 6, (250, 230, 170))
    t.contorno()
    t.salvar("moveis", "bancada.png")


def quadro_branco():
    t = Tela(40, 24)
    t.ret(0, 0, 39, 21, CINZA)
    t.ret(1, 1, 38, 20, BRANCO)
    t.ret(0, 22, 39, 23, CINZA_E)
    for x in (13, 26):
        t.ret(x, 2, x, 19, (200, 200, 210))
    for col, cor in enumerate(((250, 230, 120), (250, 170, 200), (150, 210, 240))):
        for i in range(3 - col % 2):
            x = 3 + col * 13 + (i % 2) * 4
            y = 4 + i * 5
            t.ret(x, y, x + 3, y + 3, cor)
    t.ret(3, 2, 9, 2, (70, 110, 200))
    t.ret(16, 2, 22, 2, (200, 80, 80))
    t.ret(29, 2, 35, 2, (80, 160, 90))
    t.contorno()
    t.salvar("moveis", "quadro_branco.png")


def janela():
    t = Tela(30, 22)
    moldura = (244, 236, 218)
    t.ret(0, 0, 29, 21, moldura)
    ceu, ceu2 = (150, 206, 238), (190, 228, 246)
    t.ret(2, 2, 27, 18, ceu)
    t.ret(2, 12, 27, 18, ceu2)
    t.elipse(9, 8, 4, 2, BRANCO)
    t.elipse(12, 7, 3, 2, BRANCO)
    t.elipse(22, 13, 3, 1, BRANCO)
    t.ret(2, 16, 27, 18, (120, 180, 110))
    t.ret(14, 2, 15, 18, moldura)
    t.ret(2, 10, 27, 10, moldura)
    t.ret(0, 19, 29, 21, claro(MADEIRA, 0.1))
    t.ret(3, 3, 4, 6, BRANCO)
    t.contorno()
    t.salvar("moveis", "janela.png")


def relogio():
    t = Tela(12, 12)
    t.elipse(5.5, 5.5, 5, 5, (150, 100, 66))
    t.elipse(5.5, 5.5, 4, 4, BRANCO)
    t.ret(5, 2, 5, 5, PRETO)
    t.ret(6, 5, 7, 5, PRETO)
    t.contorno()
    t.salvar("moveis", "relogio.png")


def cadeiras_espera():
    t = Tela(46, 22)
    for i in range(3):
        x = i * 15 + 1
        assento = (70, 130, 170)
        t.ret(x, 0, x + 13, 8, assento)
        t.ret(x, 0, x + 13, 0, claro(assento, 0.3))
        t.ret(x + 1, 9, x + 12, 13, escuro(assento, 0.12))
        t.ret(x + 1, 9, x + 12, 9, claro(assento, 0.2))
    t.ret(0, 14, 45, 15, CINZA_E)
    for x in (2, 22, 43):
        t.ret(x, 16, x + 1, 21, CINZA_E)
    t.contorno()
    t.salvar("moveis", "cadeiras_espera.png")


def mesa_reuniao():
    t = Tela(56, 32)
    tampo = (176, 118, 76)
    t.elipse(27.5, 12, 27, 10, tampo)
    t.elipse(27.5, 11, 25, 8, claro(tampo, 0.15))
    t.ret(6, 20, 49, 24, escuro(tampo, 0.25))
    t.ret(10, 25, 12, 31, escuro(tampo, 0.4))
    t.ret(43, 25, 45, 31, escuro(tampo, 0.4))
    t.ret(14, 7, 22, 12, (60, 60, 70))
    t.ret(15, 8, 21, 11, TELA_PC)
    t.ret(30, 9, 36, 14, BRANCO)
    t.ret(38, 8, 43, 12, BRANCO)
    caneca(t, 46, 7)
    t.contorno()
    t.salvar("moveis", "mesa_reuniao.png")


def ar_condicionado():
    t = Tela(30, 12)
    t.caixa(0, 0, 29, 11, (236, 236, 240))
    t.ret(2, 8, 27, 8, CINZA)
    t.ret(2, 10, 27, 10, CINZA)
    t.px(26, 3, (110, 220, 110))
    t.contorno()
    t.salvar("moveis", "ar_condicionado.png")


def tapete():
    t = Tela(80, 48)
    base = (176, 92, 76)
    t.ret(0, 0, 79, 47, base)
    t.ret(3, 3, 76, 44, (236, 204, 150))
    t.ret(5, 5, 74, 42, (90, 120, 150))
    t.ret(8, 8, 71, 39, (200, 120, 92))
    for x in range(10, 70, 8):
        for y in range(10, 38, 8):
            t.px(x + 3, y + 3, (236, 204, 150))
            t.px(x + 2, y + 3, (236, 204, 150))
            t.px(x + 4, y + 3, (236, 204, 150))
            t.px(x + 3, y + 2, (236, 204, 150))
            t.px(x + 3, y + 4, (236, 204, 150))
    t.salvar("moveis", "tapete.png")


def capacho():
    t = Tela(48, 12)
    t.ret(0, 0, 47, 11, (120, 84, 60))
    t.ret(2, 2, 45, 9, (150, 106, 74))
    for x in range(3, 45, 3):
        t.ret(x, 3, x, 8, (130, 92, 66))
    t.salvar("moveis", "capacho.png")


def porta_vidro():
    t = Tela(48, 16)
    t.ret(0, 0, 47, 15, (60, 60, 72))
    t.ret(2, 4, 45, 11, (170, 210, 230))
    t.ret(2, 4, 45, 5, (210, 236, 246))
    t.ret(23, 2, 24, 13, (60, 60, 72))
    t.ret(10, 6, 14, 6, BRANCO)
    t.salvar("moveis", "porta_vidro.png")


def caixas():
    t = Tela(18, 22)
    pap = (200, 156, 104)
    t.caixa(0, 10, 17, 21, pap)
    t.ret(8, 10, 9, 21, escuro(pap, 0.2))
    t.caixa(3, 0, 14, 9, claro(pap, 0.1))
    t.ret(5, 3, 12, 6, BRANCO)
    t.ret(6, 4, 11, 4, AZUL_EMPRESA)
    t.contorno()
    t.salvar("moveis", "caixas.png")


def lixeira():
    t = Tela(10, 12)
    t.ret(1, 2, 8, 11, (110, 140, 120))
    t.ret(0, 0, 9, 2, (130, 160, 140))
    t.ret(2, 0, 7, 0, (240, 240, 230))
    t.contorno()
    t.salvar("moveis", "lixeira.png")


def poster():
    t = Tela(18, 24)
    t.ret(0, 0, 17, 23, (30, 28, 36))
    t.ret(2, 2, 15, 21, (44, 40, 52))
    t.elipse(8.5, 10, 5, 5, (206, 58, 66))
    t.elipse(8.5, 10, 3, 3, (44, 40, 52))
    t.ret(3, 17, 14, 18, (240, 230, 220))
    t.ret(5, 20, 12, 20, (206, 58, 66))
    t.contorno()
    t.salvar("moveis", "poster.png")


def quadro_paisagem():
    t = Tela(22, 16)
    t.ret(0, 0, 21, 15, (170, 120, 70))
    t.ret(2, 2, 19, 13, (160, 210, 236))
    t.ret(2, 9, 19, 13, (110, 170, 100))
    t.elipse(8, 9, 5, 3, (90, 150, 90))
    t.elipse(16, 4, 2, 2, (250, 220, 120))
    t.contorno()
    t.salvar("moveis", "quadro.png")


def tv_painel():
    t = Tela(36, 22)
    t.ret(0, 0, 35, 21, PRETO)
    t.ret(2, 2, 33, 19, (30, 44, 52))
    for i in range(28):
        y = 12 + int(4 * ((i * 37) % 7 - 3) / 3)
        t.px(4 + i, y, (110, 230, 140))
    for i in range(5):
        t.ret(4 + i * 6, 4, 7 + i * 6, 6, (110, 230, 140) if i != 3 else (250, 190, 70))
    t.ret(4, 16, 31, 17, (60, 90, 110))
    t.contorno()
    t.salvar("moveis", "tv_painel.png")


def telefone():
    folha = Tela(24, 12)
    for q in range(2):
        t = Tela(12, 12)
        corpo = (66, 66, 78)
        t.ret(1, 5, 10, 10, corpo)
        t.ret(1, 5, 10, 5, claro(corpo, 0.3))
        for x in range(3, 9, 2):
            t.px(x, 7, CINZA)
            t.px(x, 9, CINZA)
        dy = -2 if q == 1 else 0
        t.ret(0, 3 + dy, 11, 4 + dy, escuro(corpo, 0.1))
        t.ret(0, 2 + dy, 2, 3 + dy, escuro(corpo, 0.1))
        t.ret(9, 2 + dy, 11, 3 + dy, escuro(corpo, 0.1))
        if q == 1:
            t.px(10, 9, (250, 90, 90))
        t.contorno()
        folha.colar(t, q * 12, 0)
    folha.salvar("moveis", "telefone.png")


def placa():
    w = 140
    t = Tela(w, 14)
    mad = (140, 92, 60)
    t.ret(0, 0, w - 1, 13, mad)
    t.ret(1, 1, w - 2, 12, (176, 122, 80))
    t.ret(1, 1, w - 2, 1, claro(mad, 0.4))
    t.px(3, 6, (230, 210, 150))
    t.px(w - 4, 6, (230, 210, 150))
    t.contorno()
    t.salvar("moveis", "placa.png")


# ---------------------------------------------------------------------------
# Interface
# ---------------------------------------------------------------------------
def ui():
    # caixa de diálogo (9-patch 24x24, margem 8)
    t = Tela(24, 24)
    mad_e, mad, mad_c = (96, 56, 40), (150, 92, 58), (196, 132, 82)
    papel = (252, 236, 200)
    t.ret(0, 0, 23, 23, mad_e)
    t.ret(1, 1, 22, 22, mad)
    t.ret(1, 1, 22, 1, mad_c)
    t.ret(1, 1, 1, 22, mad_c)
    t.ret(3, 3, 20, 20, mad_e)
    t.ret(4, 4, 19, 19, papel)
    t.ret(4, 4, 19, 4, claro(papel, 0.5))
    t.ret(4, 19, 19, 19, escuro(papel, 0.08))
    for x, y in ((1, 1), (22, 1), (1, 22), (22, 22)):
        t.px(x, y, (230, 196, 110))
    t.salvar("ui", "caixa.png")

    # painel escuro para HUD
    t = Tela(16, 16)
    t.ret(0, 0, 15, 15, mad_e)
    t.ret(1, 1, 14, 14, (122, 76, 50))
    t.ret(2, 2, 13, 13, (70, 44, 36))
    t.ret(2, 2, 13, 2, (90, 58, 44))
    t.salvar("ui", "painel.png")

    # seleção de opção
    t = Tela(16, 16)
    t.ret(0, 0, 15, 15, (232, 196, 120))
    t.ret(1, 1, 14, 14, (250, 222, 150))
    t.salvar("ui", "selecao.png")

    # cursor (mãozinha / seta)
    t = Tela(8, 8)
    for i in range(4):
        t.ret(i, i, i, 7 - i, (200, 60, 50))
    t.ret(0, 3, 3, 4, (240, 110, 80))
    t.contorno()
    t.salvar("ui", "cursor.png")

    # coração
    def coracao(cheio):
        t = Tela(11, 10)
        cor = (226, 60, 80) if cheio else (120, 96, 100)
        for x, y in ((1, 1), (2, 1), (3, 1), (6, 1), (7, 1), (8, 1)):
            t.px(x + 0, y, cor)
        t.ret(0, 2, 9, 4, cor)
        t.ret(1, 5, 8, 5, cor)
        t.ret(2, 6, 7, 6, cor)
        t.ret(3, 7, 6, 7, cor)
        t.ret(4, 8, 5, 8, cor)
        if cheio:
            t.px(2, 2, (255, 190, 200))
            t.px(1, 3, (255, 160, 170))
        t.contorno()
        return t

    coracao(True).salvar("ui", "coracao.png")
    coracao(False).salvar("ui", "coracao_vazio.png")

    def estrela(cheia):
        t = Tela(11, 11)
        cor = (250, 200, 60) if cheia else (130, 110, 100)
        t.ret(5, 0, 5, 2, cor)
        t.ret(4, 2, 6, 3, cor)
        t.ret(0, 3, 10, 4, cor)
        t.ret(2, 5, 8, 6, cor)
        t.ret(2, 7, 4, 8, cor)
        t.ret(6, 7, 8, 8, cor)
        t.px(1, 9, cor)
        t.px(9, 9, cor)
        if cheia:
            t.px(5, 1, (255, 240, 170))
            t.px(4, 3, (255, 240, 170))
        t.contorno()
        return t

    estrela(True).salvar("ui", "estrela.png")
    estrela(False).salvar("ui", "estrela_vazia.png")

    # balões
    def balao(nome, cor_fundo, desenho):
        t = Tela(12, 14)
        t.ret(1, 0, 10, 9, cor_fundo)
        t.ret(0, 1, 11, 8, cor_fundo)
        t.ret(4, 10, 7, 10, cor_fundo)
        t.ret(5, 11, 6, 11, cor_fundo)
        desenho(t)
        t.contorno()
        t.salvar("ui", nome + ".png")

    def exclamacao(t):
        t.ret(5, 2, 6, 5, (200, 70, 50))
        t.ret(5, 7, 6, 7, (200, 70, 50))

    def interrogacao(t):
        cor = (40, 90, 150)
        t.ret(4, 2, 7, 2, cor)
        t.px(8, 3, cor)
        t.px(3, 3, cor)
        t.px(7, 4, cor)
        t.ret(5, 5, 6, 5, cor)
        t.ret(5, 7, 6, 7, cor)

    def coracaozinho(t):
        cor = (220, 60, 80)
        t.ret(3, 3, 4, 3, cor)
        t.ret(7, 3, 8, 3, cor)
        t.ret(3, 4, 8, 5, cor)
        t.ret(4, 6, 7, 6, cor)
        t.ret(5, 7, 6, 7, cor)

    def reticencias(t):
        for x in (2, 5, 8):
            t.px(x, 5, (110, 100, 110))

    balao("balao_historia", (255, 236, 130), exclamacao)
    balao("balao_chamado", (236, 246, 255), interrogacao)
    balao("balao_coracao", (255, 236, 240), coracaozinho)
    balao("balao_espera", (240, 236, 232), reticencias)

    # marcador de tarefa (seta para baixo)
    t = Tela(11, 10)
    cor = (90, 200, 120)
    t.ret(3, 0, 7, 3, cor)
    t.ret(0, 4, 10, 4, cor)
    t.ret(1, 5, 9, 5, cor)
    t.ret(2, 6, 8, 6, cor)
    t.ret(3, 7, 7, 7, cor)
    t.ret(4, 8, 6, 8, cor)
    t.ret(4, 1, 5, 2, claro(cor, 0.5))
    t.contorno()
    t.salvar("ui", "marcador.png")

    # tecla de seta (minigame) - aponta para cima; o jogo rotaciona
    for nome, fundo in (("tecla", (236, 228, 214)), ("tecla_ok", (150, 220, 150)), ("tecla_erro", (240, 140, 130))):
        t = Tela(20, 20)
        t.ret(1, 0, 18, 18, escuro(fundo, 0.3))
        t.ret(0, 1, 19, 17, escuro(fundo, 0.3))
        t.ret(1, 1, 18, 15, fundo)
        t.ret(2, 1, 17, 1, claro(fundo, 0.5))
        seta = (70, 50, 60)
        t.ret(9, 4, 10, 4, seta)
        t.ret(8, 5, 11, 5, seta)
        t.ret(7, 6, 12, 6, seta)
        t.ret(6, 7, 13, 7, seta)
        t.ret(8, 8, 11, 12, seta)
        t.contorno()
        t.salvar("ui", nome + ".png")

    # ícones pequenos
    def icone(nome, desenho, w=10, h=10):
        t = Tela(w, h)
        desenho(t)
        t.contorno()
        t.salvar("ui", nome + ".png")

    def ic_telefone(t):
        cor = (240, 240, 240)
        t.ret(1, 1, 3, 3, cor)
        t.ret(6, 1, 8, 3, cor)
        t.ret(2, 2, 7, 3, cor)
        t.ret(1, 5, 8, 8, (230, 90, 80))

    def ic_balcao(t):
        pele = PELES[1][0]
        t.ret(3, 0, 6, 3, pele)
        t.ret(1, 5, 8, 9, (110, 170, 220))

    def ic_equipe(t):
        t.ret(3, 0, 6, 3, (250, 220, 120))
        t.ret(1, 5, 8, 9, (226, 120, 90))

    def ic_alerta(t):
        cor = (240, 80, 70)
        t.ret(4, 0, 5, 9, cor)
        t.ret(2, 3, 7, 7, cor)
        t.ret(4, 2, 5, 5, BRANCO)
        t.ret(4, 7, 5, 7, BRANCO)

    icone("icone_telefone", ic_telefone)
    icone("icone_balcao", ic_balcao)
    icone("icone_equipe", ic_equipe)
    icone("icone_alerta", ic_alerta)


# ---------------------------------------------------------------------------
def main():
    gerar_tiles()
    for nome, c in ELENCO.items():
        folha_personagem(nome, c)
        retrato(nome, c)

    mesa("mesa_gabriel", mesa_gabriel, teclado_x=3)
    mesa("mesa_rafa", mesa_rafa)
    mesa("mesa_bia", mesa_bia)
    mesa("mesa_celia", mesa_celia)
    mesa("mesa_otavio", mesa_otavio, largura=48)
    mesa("mesa_luana", mesa_luana)
    mesa("mesa_davi", mesa_davi)
    mesa("mesa_vazia", lambda t, w: monitor(t, 9, 0, cor_tela=(70, 80, 100), conteudo=None))
    cadeira()
    cadeira("cadeira_vermelha", (150, 60, 66))
    balcao()
    impressora()
    cafeteira()
    bebedouro()
    planta("planta")
    planta("planta_alta", alta=True)
    arquivo()
    estante("estante")
    estante("estante_estoque", "estoque")
    rack("rack")
    rack("rack_rede", cabos=True)
    bobina()
    bancada()
    quadro_branco()
    janela()
    relogio()
    cadeiras_espera()
    mesa_reuniao()
    ar_condicionado()
    tapete()
    capacho()
    porta_vidro()
    caixas()
    lixeira()
    poster()
    quadro_paisagem()
    tv_painel()
    telefone()
    placa()
    ui()

    # ícone do projeto: retrato do Gabriel em fundo azul
    ret = Image.open(os.path.join(RAIZ, "retratos", "gabriel.png"))
    icone = Image.new("RGBA", (40, 40), (58, 122, 172, 255))
    icone.alpha_composite(ret)
    icone = icone.resize((128, 128), Image.NEAREST)
    icone.save(os.path.join(RAIZ, "..", "..", "icon.png"))
    print("Arte gerada em", os.path.normpath(RAIZ))


if __name__ == "__main__":
    main()
