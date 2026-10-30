#!/usr/bin/env bash
# Roda todos os testes automatizados do jogo.
# Uso: tools/testar.sh        (variável GODOT aponta para o executável, padrão: godot)
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
falhou=0

passo() { echo; echo "== $1"; }

passo "Validando conteúdo (dados/*.json)"
python3 tools/validar_dados.py || falhou=1

passo "Importando recursos"
"$GODOT" --headless --path . --import >/dev/null 2>&1

passo "Teste de mapa (tudo alcançável a partir da entrada)"
saida=$("$GODOT" --headless --path . -- --teste-mapa 2>&1)
echo "$saida" | grep -E "TESTE-MAPA|SCRIPT ERROR"
echo "$saida" | grep -q "0 falha(s)" || falhou=1
echo "$saida" | grep -q "SCRIPT ERROR" && falhou=1

for modo in "" "--erra"; do
	passo "Piloto automático: semana completa ${modo:-(respostas certas)}"
	saida=$(timeout 900 "$GODOT" --headless --path . -- --piloto $modo 2>&1)
	echo "$saida" | grep -E "PILOTO: (resumo|semana)|SCRIPT ERROR"
	echo "$saida" | grep -q "PILOTO: semana concluída" || falhou=1
	echo "$saida" | grep -q "SCRIPT ERROR" && falhou=1
done

echo
if [ "$falhou" -ne 0 ]; then
	echo "FALHOU"
	exit 1
fi
echo "Todos os testes passaram."
