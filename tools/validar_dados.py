#!/usr/bin/env python3
"""Valida o conteúdo em dados/*.json (estrutura, falantes, opções e limites de texto).

Uso: python3 tools/validar_dados.py
Sai com código 1 se encontrar problemas.
"""
import json
import os
import sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dados")
OBJETOS = {"impressora", "estoque", "rack_rede", "rack", "cafeteira", "bebedouro", "quadro_branco", "planta",
           "porta", "tv_painel", "poster", "bancada", "mesa_reuniao"}
COLEGAS = ["celia", "rafa", "bia", "otavio", "luana", "davi"]
LIMITE_FALA = 230
LIMITE_OPCAO = 110

erros = []


def carregar(nome):
    with open(os.path.join(RAIZ, nome), encoding="utf-8") as f:
        return json.load(f)


personagens = carregar("personagens.json")
chamados = carregar("chamados.json")
historias = carregar("historias.json")
falas = carregar("falas.json")


def minutos(hora):
    h, m = hora.split(":")
    return int(h) * 60 + int(m)


def checar_linhas(onde, linhas):
    if not isinstance(linhas, list):
        erros.append(f"{onde}: esperado lista de falas")
        return
    for linha in linhas:
        texto = linha
        if linha.startswith("@"):
            if ":" not in linha:
                erros.append(f"{onde}: marcação de falante sem ':' -> {linha!r}")
                continue
            falante = linha[1:linha.index(":")]
            if falante not in personagens:
                erros.append(f"{onde}: falante desconhecido '{falante}'")
            texto = linha[linha.index(":") + 1:].strip()
        if len(texto) > LIMITE_FALA:
            erros.append(f"{onde}: fala longa demais ({len(texto)}): {texto[:50]}...")
        if not texto:
            erros.append(f"{onde}: fala vazia")


def checar_etapa(onde, etapa):
    opcoes = etapa.get("opcoes", [])
    if len(opcoes) != 3:
        erros.append(f"{onde}: precisa de exatamente 3 opções (tem {len(opcoes)})")
    certas = [o for o in opcoes if o.get("ok")]
    if len(certas) != 1:
        erros.append(f"{onde}: precisa de exatamente 1 opção certa (tem {len(certas)})")
    for i, o in enumerate(opcoes):
        if len(o.get("t", "")) > LIMITE_OPCAO:
            erros.append(f"{onde}: opção {i} longa demais ({len(o['t'])})")
        checar_linhas(f"{onde} opção {i}", o.get("r", []))
    if "pergunta" in etapa and len(etapa["pergunta"]) > LIMITE_OPCAO:
        erros.append(f"{onde}: pergunta longa demais")


ids = set()
for c in chamados:
    onde = c.get("id", "?")
    if onde in ids:
        erros.append(f"{onde}: id repetido")
    ids.add(onde)
    for campo in ("dia", "hora", "canal", "cliente", "titulo", "abertura", "etapas", "conclusao"):
        if campo not in c:
            erros.append(f"{onde}: falta o campo '{campo}'")
    if c.get("canal") not in ("balcao", "telefone", "colega", "incidente"):
        erros.append(f"{onde}: canal inválido {c.get('canal')}")
    if c.get("cliente") not in personagens:
        erros.append(f"{onde}: cliente desconhecido {c.get('cliente')}")
    if not 8 * 60 <= minutos(c.get("hora", "00:00")) <= 16 * 60:
        erros.append(f"{onde}: hora fora do expediente útil")
    if 12 * 60 <= minutos(c.get("hora", "00:00")) < 13 * 60:
        erros.append(f"{onde}: chega no horário de almoço")
    checar_linhas(f"{onde} abertura", c.get("abertura", []))
    checar_linhas(f"{onde} conclusao", c.get("conclusao", []))
    for i, e in enumerate(c.get("etapas", [])):
        checar_etapa(f"{onde} etapa {i}", e)
    for i, t in enumerate(c.get("tarefas", [])):
        alvo = t.get("alvo", "")
        if alvo == "cliente":
            if c.get("canal") != "balcao":
                erros.append(f"{onde} tarefa {i}: só chamados de balcão podem voltar ao cliente")
        elif alvo.startswith("npc:"):
            if alvo[4:] not in COLEGAS:
                erros.append(f"{onde} tarefa {i}: colega desconhecido {alvo}")
        elif alvo.startswith("obj:"):
            if alvo[4:] not in OBJETOS:
                erros.append(f"{onde} tarefa {i}: objeto desconhecido {alvo}")
        else:
            erros.append(f"{onde} tarefa {i}: alvo inválido {alvo}")
        if not t.get("objetivo"):
            erros.append(f"{onde} tarefa {i}: falta objetivo")
        checar_linhas(f"{onde} tarefa {i} falas", t.get("falas", []))
        checar_linhas(f"{onde} tarefa {i} depois", t.get("depois", []))
        if "etapa" in t:
            checar_etapa(f"{onde} tarefa {i} etapa", t["etapa"])
        if "minigame" in t and not 3 <= t["minigame"].get("setas", 0) <= 10:
            erros.append(f"{onde} tarefa {i}: minigame com quantidade de setas inválida")

for colega in COLEGAS:
    cenas = historias.get(colega, [])
    dias = sorted(cena["dia"] for cena in cenas)
    if dias != [1, 2, 3, 4, 5]:
        erros.append(f"historia {colega}: precisa de uma cena por dia (tem {dias})")
    for cena in cenas:
        onde = f"historia {colega} dia {cena['dia']}"
        checar_linhas(onde, cena.get("falas", []))
        checar_linhas(onde + " fim", cena.get("fim", []))
        checar_etapa(onde, cena)
        if "apos" in cena and cena["apos"] not in ids:
            erros.append(f"{onde}: 'apos' aponta para chamado inexistente")
    if colega not in falas["falas_soltas"]:
        erros.append(f"falas_soltas: falta {colega}")
    if colega not in falas["epilogos"]:
        erros.append(f"epilogos: falta {colega}")

for chave in ("inicio_dia", "almoco", "fim_dia"):
    for d in range(1, 6):
        checar_linhas(f"{chave} {d}", falas[chave].get(str(d), []))
checar_linhas("final_abertura", falas["final_abertura"])
for nome, linhas in falas["objetos"].items():
    checar_linhas(f"objeto {nome}", linhas)

por_dia = {}
for c in chamados:
    por_dia[c["dia"]] = por_dia.get(c["dia"], 0) + 1

if erros:
    print("Problemas encontrados:")
    for e in erros:
        print(" -", e)
    sys.exit(1)
print(f"OK: {len(chamados)} chamados ({por_dia}), {sum(len(v) for v in historias.values())} cenas de equipe.")
