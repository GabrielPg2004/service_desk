# Chamado Aberto

**Uma semana no Service Desk da Goestalpine IT-Group.** Um jogo aconchegante em pixel art, com visão de cima, sobre o dia a dia de um setor de atendimento de TI e as pessoas que trabalham nele.

Você é **Gabriel Esteka**, que acaba de chegar ao Primeiro Atendimento como analista. Durante cinco dias (cerca de 1 hora de jogo) você:

- atende usuários no **balcão** e no **telefone** da sua mesa, sempre escolhendo entre **três respostas**, uma delas a certa;
- leva os chamados adiante: instala impressora, abre solicitação de compra de computador no **Backoffice**, ativa porta de rede no **Telecom**, retira kit no almoxarifado...;
- resolve tarefas técnicas num minigame de **sequência de setas**;
- conversa com uma equipe de personalidades fortes (Dona Célia, Rafa, Bia, Otávio, Luana e Davi). Cada um tem uma história em cinco capítulos, e cada boa conversa vale um **coração**;
- enfrenta, na sexta-feira, um **incidente** que derruba a rede do prédio inteiro.

Não existe game over: errar uma resposta só custa estrelas na avaliação do chamado. No fim da semana, cada colega ganha um epílogo, que depende da amizade construída.

## Controles

| Ação | Teclas |
|---|---|
| Andar | Setas (ou WASD) |
| Interagir / avançar diálogo | Espaço, Enter ou Z |
| Escolher resposta | Cima / Baixo |
| Minigame | Setas, na ordem mostrada |
| Pausa, equipe e música | Esc |

Também funciona com controle (direcional, botão A e Start).

## Como jogar

### No navegador
O workflow `.github/workflows/web.yml` testa, exporta e publica o jogo no **GitHub Pages** a cada push na `main`. Para ativar:

1. Faça o merge desta branch na `main`.
2. No GitHub, vá em **Settings → Pages → Build and deployment → Source** e escolha **GitHub Actions**.
3. O jogo fica em `https://<usuario>.github.io/service_desk/`.

### No Godot
1. Instale o [Godot 4.5](https://godotengine.org/download) (versão padrão, sem .NET).
2. Abra o `project.godot` e aperte **F5**.

### Exportar manualmente para Web
Com os templates de exportação do Godot 4.5.1 instalados:

```bash
godot --headless --path . --export-release "Web" build/web/index.html
cd build/web && python3 -m http.server 8000   # abra http://localhost:8000
```

A exportação usa a variante sem threads, então roda em qualquer servidor estático, sem cabeçalhos especiais.

## Estrutura

```
dados/              conteúdo do jogo em JSON (chamados, histórias, falas, personagens)
scripts/            código GDScript
  jogo.gd           estado global, salvamento, tema (autoload "Jogo")
  som.gd            efeitos e música (autoload "Som")
  escritorio.gd     um dia de trabalho: relógio, chamados, colegas, almoço, fim do dia
  mundo.gd          mapa do andar (Backoffice | Primeiro Atendimento | Telecom), móveis e colisões
  jogador.gd, npc.gd, personagem.gd
  titulo.gd         tela de título
  ui/               diálogo, HUD, minigame, pausa, resumo do dia, final, transições
cenas/              cenas principais (título e escritório)
assets/             sprites, áudio e fontes (gerados pelos scripts em tools/)
tools/              gerar_arte.py, gerar_sons.py, validar_dados.py, testar.sh
testes/             piloto automático e teste de mapa
docs/DESIGN.md      documento de design e decisões
```

## Adicionando conteúdo

Tudo o que acontece no jogo está em `dados/*.json` e pode ser editado sem programar.

**Novo chamado** (`dados/chamados.json`):

```json
{
  "id": "d2_exemplo", "dia": 2, "hora": "10:15", "canal": "balcao", "cliente": "juninho",
  "titulo": "Título curto que aparece no HUD",
  "abertura": ["Fala do cliente ao chegar."],
  "etapas": [
    {"pergunta": "O que você faz?", "opcoes": [
      {"t": "Resposta certa", "ok": true, "r": ["Reação do cliente"]},
      {"t": "Resposta errada", "r": ["Reação engraçada"]},
      {"t": "Outra errada", "r": ["Outra reação"]}
    ]}
  ],
  "tarefas": [
    {"alvo": "obj:impressora", "objetivo": "Texto do objetivo",
     "minigame": {"titulo": "Configurando", "setas": 5}}
  ],
  "conclusao": ["Fala final."]
}
```

- `canal`: `balcao`, `telefone`, `colega` ou `incidente`.
- `alvo` das tarefas: `npc:<colega>`, `obj:<objeto>` (`impressora`, `estoque`, `rack_rede`...) ou `cliente` (o cliente espera no balcão; só vale para `balcao`).
- Em qualquer lista de falas, `"@rafa: texto"` troca quem fala (`@narrador` e `@gabriel` também valem).

Depois de editar, rode `python3 tools/validar_dados.py`: ele confere a estrutura, garante exatamente 3 opções com 1 certa por etapa e verifica falantes e limites de texto.

## Arte, som e testes

- `python3 tools/gerar_arte.py`: redesenha todos os sprites (personagens 16x32, retratos 40x40, móveis, tiles e UI).
- `python3 tools/gerar_sons.py`: sintetiza os efeitos e as duas músicas (precisa de `numpy`).
- `tools/testar.sh`: valida o conteúdo, confere se todo objeto, colega e vaga do balcão é alcançável no mapa e joga a semana inteira duas vezes com o piloto automático (uma com as respostas certas e outra respondendo ao acaso).

## Créditos

- Código, arte e sons gerados para este projeto.
- Fontes [Jersey 10](https://fonts.google.com/specimen/Jersey+10) e [Pixelify Sans](https://fonts.google.com/specimen/Pixelify+Sans), sob a SIL Open Font License (`assets/fontes/`).
- Personagens e situações são ficcionais.
