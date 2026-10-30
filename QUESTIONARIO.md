# Questionário de Definição — Jogo Pixel Art Top-Down sobre Service Desk

Este questionário reúne tudo o que precisa estar definido para que o jogo seja desenvolvido **do zero e de forma autônoma**, sem precisar parar para perguntar no meio do caminho.

## Como responder

- Marque as opções com `[x]` ou escreva na linha **Resposta:**.
- Perguntas com ⭐ são **essenciais**: sem elas não dá para começar.
- As demais têm um **Padrão** sugerido. Se ficarem em branco, o padrão será usado.
- "Tanto faz / decida você" é uma resposta válida: o padrão será aplicado e registrado.
- Escreva livremente em **Observações** no fim de cada seção.

---

## 1. Visão e objetivo

**1.1 ⭐ Qual é o objetivo principal do projeto?**
- [ ] Portfólio / projeto pessoal
- [ ] Ferramenta de treinamento para analistas de Service Desk (gamificação)
- [ ] Entretenimento / humor para quem trabalha com TI
- [ ] Produto comercial (venda em loja)
- [ ] Outro:

**1.2 ⭐ Descreva o jogo em uma ou duas frases (o "pitch").**
> Exemplo: "Você é um analista N1 recém-contratado e precisa sobreviver a uma semana de chamados, atendendo telefone, correndo até a mesa dos usuários e resolvendo problemas antes do SLA estourar."

Resposta:

**1.3 Quem é o público-alvo?**
- [ ] Profissionais de TI / Service Desk (piadas internas, termos técnicos)
- [ ] Público geral (termos explicados, humor acessível)
- [ ] Novos colaboradores em treinamento
> Padrão: profissionais de TI, mas jogável por leigos.

**1.4 Qual o tom?**
- [ ] Comédia / sátira do dia a dia corporativo
- [ ] Realista / educativo
- [ ] Caótico e frenético (gerenciamento de tempo)
- [ ] Tranquilo / "cozy"
> Padrão: comédia leve com ritmo frenético nos picos.

**1.5 Quanto tempo deve durar uma partida completa?**
- [ ] 10–20 min (demo / jam)
- [ ] 1–2 h
- [ ] 5 h ou mais
> Padrão: 1–2 h (uma "semana" de trabalho, 5 dias de ~10 min cada).

Observações:

---

## 2. Plataforma e tecnologia

**2.1 ⭐ Onde o jogo vai rodar?**
- [ ] Navegador (web), jogável por link
- [ ] Desktop (Windows / Linux / macOS)
- [ ] Mobile
- [ ] Mais de um (especifique):
> Padrão: navegador, com deploy no GitHub Pages.

**2.2 Engine / tecnologia preferida?**
- [ ] Phaser 3 + TypeScript (web, leve, fácil de publicar)
- [ ] Godot 4 (GDScript), exportando para web/desktop
- [ ] Canvas/JavaScript puro, sem engine
- [ ] Outra:
- [ ] Decida você
> Padrão: Phaser 3 + TypeScript + Vite.

**2.3 Controles principais:**
- [ ] Teclado (WASD/setas + teclas de ação)
- [ ] Mouse (clicar para mover/interagir)
- [ ] Teclado + mouse
- [ ] Gamepad também
- [ ] Toque (mobile)
> Padrão: teclado para mover, mouse para UI/minigames.

**2.4 Resolução / proporção:**
- [ ] 16:9 com resolução interna de 320×180 (escalada ×4/×6)
- [ ] 16:9 com 480×270
- [ ] 4:3 retrô
> Padrão: 16:9, interna 480×270, escala inteira (pixel perfect).

Observações:

---

## 3. Estilo visual (pixel art)

**3.1 ⭐ De onde vêm os gráficos?** *(ponto crítico para desenvolvimento autônomo: o agente não usa editores de imagem como Aseprite)*
- [ ] Gerados por código (sprites desenhados como matrizes de pixels em scripts e exportados para PNG)
- [ ] Packs gratuitos com licença livre (CC0 / CC-BY) baixados da internet
- [ ] Você vai fornecer os assets (pasta/link):
- [ ] Placeholders simples agora; arte final depois
> Padrão: gerados por código, com paleta fixa e estilo consistente.

**3.2 Tamanho do tile / personagem:**
- [ ] 16×16 (mais simples e retrô)
- [ ] 32×32 (mais detalhe)
> Padrão: tiles de 16×16, personagens de 16×24.

**3.3 Perspectiva top-down:**
- [ ] 3/4 (vê-se frente e topo dos objetos, como RPGs clássicos de 16 bits)
- [ ] Totalmente vista de cima
> Padrão: 3/4.

**3.4 Paleta de cores:**
- [ ] Paleta limitada pronta (ex.: PICO-8, Endesga 32, Resurrect 64)
- [ ] Tons de escritório corporativo (cinzas, azuis, bege) com destaques fortes
- [ ] Cores da sua empresa (informe os hex):
> Padrão: Endesga 32.

**3.5 Nível de animação:**
- [ ] Mínimo (andar em 4 direções com 2–4 frames)
- [ ] Médio (andar, digitar, falar ao telefone, reações)
- [ ] Rico (muitas expressões e animações de objetos)
> Padrão: médio.

**3.6 Referências visuais** (links, imagens ou nomes de estilos que você gosta):

Resposta:

Observações:

---

## 4. Áudio

**4.1 Trilha e efeitos:**
- [ ] Sem áudio no início
- [ ] Efeitos sonoros gerados por código (estilo chiptune / jsfxr)
- [ ] Músicas e efeitos livres (CC0) baixados
- [ ] Você vai fornecer
> Padrão: efeitos gerados por código + 1–2 músicas chiptune livres.

**4.2 Sons característicos desejados** (ex.: telefone tocando sem parar, notificação do Teams, impressora travando):

Resposta:

Observações:

---

## 5. Ambientação, história e personagens

**5.1 ⭐ Empresa e cenário:**
- [ ] Empresa fictícia genérica (nome inventado)
- [ ] Inspirada na sua empresa real, sem nomes reais
- [ ] Outra ideia:
> Padrão: empresa fictícia com nome bem-humorado. **Não** serão usadas marcas ou pessoas reais.

Nome da empresa (opcional):

**5.2 Protagonista:**
- [ ] Analista N1 iniciante, que pode ser promovido
- [ ] Personagem customizável (aparência e nome)
- [ ] Personagem fixo com nome e personalidade:
> Padrão: analista N1 com aparência customizável simples (cabelo, roupa, tom de pele).

**5.3 Existe uma história/narrativa?**
- [ ] Não, só gameplay por turnos/dias
- [ ] Leve: eventos entre os dias (e-mails do chefe, fofocas, incidentes grandes)
- [ ] Forte: enredo com começo, meio e fim (ex.: migração de sistema que dá errado)
> Padrão: leve, com um grande incidente no último dia.

**5.4 Quais NPCs devem existir?** (marque todos)
- [ ] Coordenador(a) / gestor(a) do Service Desk
- [ ] Colegas N1 (ajudam ou atrapalham)
- [ ] Equipe N2/N3 (infra, redes, sistemas) para escalonamento
- [ ] Usuário VIP / diretoria
- [ ] Usuário que "não mexeu em nada"
- [ ] Usuário que liga por tudo
- [ ] Estagiário(a)
- [ ] Fornecedor / técnico terceirizado
- [ ] Outros:
> Padrão: todos acima.

**5.5 Situações reais do dia a dia que você quer ver no jogo** (quanto mais, melhor; isso vira conteúdo):

Resposta:

Observações:

---

## 6. Gênero e loop principal de gameplay

**6.1 ⭐ Qual o gênero principal?**
- [ ] Gerenciamento de tempo: fila de chamados, correr entre tarefas, bater SLA
- [ ] Simulação de rotina com exploração livre do escritório
- [ ] RPG leve: diálogos, escolhas, evolução de habilidades
- [ ] Puzzle: cada chamado é um quebra-cabeça
- [ ] Mistura (descreva):
> Padrão: gerenciamento de tempo + exploração do escritório + minigames de resolução.

**6.2 Loop principal proposto — concorda?**
> Começa o expediente → chamados chegam por vários canais → jogador faz triagem (categoria e prioridade) → resolve remotamente (minigame no PC), vai até o usuário, ou escalona → fecha o chamado → fim do dia mostra métricas (SLA, satisfação, chamados resolvidos) → recebe pontos/upgrades → próximo dia, mais difícil.

- [ ] Sim
- [ ] Sim, com ajustes:
- [ ] Não, prefiro:

**6.3 O jogador anda fisicamente pelo escritório?**
- [ ] Sim, é parte central (ir à mesa do usuário, buscar periférico no estoque, ir à sala de servidores)
- [ ] Pouco, a maior parte acontece na estação de trabalho
> Padrão: sim, é central.

**6.4 Tempo:**
- [ ] Relógio em tempo real acelerado (ex.: 1 dia de trabalho = 8–10 min)
- [ ] Por turnos/ações
> Padrão: tempo real acelerado, com pausa.

Observações:

---

## 7. Mecânicas de Service Desk

**7.1 ⭐ Nível de fidelidade aos processos (ITIL etc.):**
- [ ] Alto: incidente × requisição × problema × mudança, SLA por prioridade, base de conhecimento, escalonamento formal
- [ ] Médio: prioridade, SLA e escalonamento, com termos simplificados
- [ ] Baixo: só "resolver problemas rápido"
> Padrão: médio.

**7.2 Canais de entrada de chamados:** (marque todos)
- [ ] Telefone (tocando na mesa)
- [ ] E-mail / portal de chamados
- [ ] Chat
- [ ] Presencial (usuário aparece no balcão)
- [ ] Monitoramento / alertas automáticos
> Padrão: telefone, portal, chat e presencial.

**7.3 Tipos de chamado no MVP:** (marque os que entram)
- [ ] Reset de senha / conta bloqueada
- [ ] Impressora (papel, fila travada, driver)
- [ ] Sem internet / Wi-Fi / VPN
- [ ] E-mail / Outlook / caixa cheia
- [ ] Instalação de software / licença
- [ ] Liberação de acesso / permissão de pasta
- [ ] Hardware (mouse, teclado, monitor, notebook lento)
- [ ] Onboarding de novo colaborador
- [ ] Phishing / suspeita de vírus
- [ ] Sistema fora do ar (incidente massivo)
- [ ] "O computador não liga" (tomada desligada)
- [ ] Outros:

**7.4 Prioridades e SLA:**
- [ ] P1 a P4 com prazos diferentes
- [ ] Baixa / Média / Alta / Crítica
- [ ] Sem prioridade explícita, só tempo de paciência do usuário
> Padrão: P1–P4, com o SLA visível em cada chamado.

**7.5 Escalonamento:** o jogador pode repassar para N2/N3?
- [ ] Sim, sem custo
- [ ] Sim, mas com penalidade se for algo que o N1 resolveria ("escalonamento indevido")
- [ ] Não
> Padrão: sim, com penalidade quando indevido.

**7.6 Métricas avaliadas no fim do dia:** (marque todas)
- [ ] % de SLA cumprido
- [ ] Satisfação do usuário (CSAT, estrelinhas)
- [ ] Resolução no primeiro contato (FCR)
- [ ] Tempo médio de atendimento (TMA)
- [ ] Chamados abandonados / reabertos
- [ ] Nível de estresse / energia do analista
> Padrão: SLA, CSAT, FCR e estresse.

**7.7 Recursos de apoio:**
- [ ] Base de conhecimento consultável no jogo (dá dicas, gasta tempo)
- [ ] Ferramentas de acesso remoto
- [ ] Café como recurso de energia
- [ ] Colegas que podem ajudar (cooldown)
> Padrão: todos.

Observações:

---

## 8. Minigames de resolução

**8.1 Como os chamados são resolvidos?**
- [ ] Minigames curtos e específicos por tipo (ex.: digitar comandos, ligar cabos na ordem, achar e-mail de phishing, trocar toner)
- [ ] Escolha de diálogo / diagnóstico por perguntas ("Já tentou reiniciar?")
- [ ] Apenas ação + barra de progresso
- [ ] Mistura
> Padrão: mistura de diagnóstico por diálogo com minigames curtos (10–30 s).

**8.2 Ideias de minigames que você quer** (opcional):

Resposta:

**8.3 Dificuldade dos minigames:**
- [ ] Fácil, o desafio é a gestão do tempo
- [ ] Moderada
- [ ] Exigente (habilidade / reflexo)
> Padrão: fácil a moderada, aumentando ao longo dos dias.

Observações:

---

## 9. Progressão, economia e dificuldade

**9.1 Estrutura de progressão:**
- [ ] Dias de uma semana (5 dias) com dificuldade crescente
- [ ] Carreira: N1 → N2 → Coordenador, com mecânicas novas a cada cargo
- [ ] Modo infinito (sobreviver o máximo possível)
- [ ] Mais de um (especifique):
> Padrão: 5 dias de história + modo infinito desbloqueável.

**9.2 Recompensas / upgrades:**
- [ ] Upgrades do analista (velocidade, paciência, conhecimento)
- [ ] Upgrades do ambiente (segundo monitor, headset, cadeira, cafeteira)
- [ ] Cosméticos (decoração da mesa, roupas)
- [ ] Sem upgrades
> Padrão: upgrades de equipamento e do analista, comprados com pontos de desempenho.

**9.3 Condição de derrota:**
- [ ] Não há derrota; só nota no fim do dia
- [ ] Demitido se as métricas ficarem abaixo da meta X dias
- [ ] Burnout se o estresse chegar ao máximo
> Padrão: nota diária; game over por burnout ou por 2 dias seguidos abaixo da meta.

**9.4 Condição de vitória / final:**
- [ ] Sobreviver à semana
- [ ] Ser promovido
- [ ] Múltiplos finais conforme o desempenho
> Padrão: múltiplos finais (promoção, mantido no cargo, "realocado").

**9.5 Opções de dificuldade:**
- [ ] Única
- [ ] Fácil / Normal / Difícil
> Padrão: Fácil / Normal / Difícil.

Observações:

---

## 10. Mapa e mundo

**10.1 Ambientes do escritório:** (marque todos)
- [ ] Ilha do Service Desk (estação do jogador)
- [ ] Balcão de atendimento presencial
- [ ] Open space com mesas dos usuários
- [ ] Sala da diretoria
- [ ] Sala de servidores / rack
- [ ] Almoxarifado / estoque de periféricos
- [ ] Copa / cafeteria
- [ ] Salas de reunião
- [ ] Sala de impressão
> Padrão: todos, num único andar.

**10.2 Tamanho do mapa:**
- [ ] Um andar pequeno (cabe em 2–3 telas)
- [ ] Um andar grande com câmera seguindo
- [ ] Vários andares (elevador)
> Padrão: um andar grande com câmera seguindo; andares extras desbloqueáveis.

**10.3 O escritório muda ao longo dos dias?** (novos setores, obras, decoração temática)
- [ ] Sim
- [ ] Não
> Padrão: sim, com mudanças pequenas.

Observações:

---

## 11. Interface (UI/HUD)

**11.1 Elementos do HUD:** (marque todos)
- [ ] Relógio do expediente
- [ ] Fila de chamados com timer de SLA
- [ ] Barra de estresse / energia
- [ ] Minimapa com indicador de usuários esperando
- [ ] Notificações (telefone, chat, e-mail)
> Padrão: todos.

**11.2 Fonte:**
- [ ] Fonte pixel livre (ex.: Press Start 2P, m5x7, Pixel Operator)
- [ ] Decida você
> Padrão: fonte pixel livre e legível em português (com acentos).

**11.3 Menus necessários:**
- [ ] Título, Novo jogo, Continuar, Opções, Créditos
- [ ] Tutorial interativo no primeiro dia
- [ ] Tela de resultados no fim do dia
> Padrão: todos.

Observações:

---

## 12. Idioma, acessibilidade e conteúdo

**12.1 ⭐ Idioma(s):**
- [ ] Apenas português (BR)
- [ ] Português + inglês
- [ ] Outros:
> Padrão: PT-BR, com textos centralizados em arquivo para traduzir depois.

**12.2 Acessibilidade:** (marque o que é desejado)
- [ ] Remapear teclas
- [ ] Ajustar velocidade do jogo
- [ ] Modo sem pressão de tempo
- [ ] Indicadores além de cor (para daltonismo)
- [ ] Tamanho de texto ajustável
> Padrão: velocidade ajustável, indicadores além de cor, volume separado.

**12.3 Limites de conteúdo:**
- [ ] Livre para todos (sem palavrão)
- [ ] Humor ácido permitido, sem ofensas
> Padrão: livre para todos, humor corporativo leve.

Observações:

---

## 13. Escopo da primeira versão (MVP)

**13.1 ⭐ O que a primeira versão entregável precisa ter?**
- [ ] Vertical slice: 1 dia completo e polido
- [ ] MVP: 5 dias, 6–8 tipos de chamado, 4–5 minigames, tela de resultados
- [ ] Jogo completo conforme este questionário
> Padrão: MVP de 5 dias.

**13.2 Existe prazo?**

Resposta:

**13.3 O que fica de fora com certeza nesta versão?** (ex.: multiplayer, mobile, dublagem)

Resposta:

Observações:

---

## 14. Persistência e dados

**14.1 Salvamento:**
- [ ] Autosave no fim de cada dia (armazenamento local do navegador)
- [ ] Vários slots
- [ ] Sem save (partidas curtas)
> Padrão: autosave no fim do dia, 1 slot.

**14.2 Ranking / placar online?**
- [ ] Não
- [ ] Sim (exige backend; informe preferência):
> Padrão: não (só recorde local).

**14.3 Conteúdo editável por dados?** (chamados, diálogos e dias definidos em JSON para você adicionar casos sem programar)
- [ ] Sim
- [ ] Não precisa
> Padrão: sim.

Observações:

---

## 15. Entrega técnica e qualidade

**15.1 Publicação:**
- [ ] GitHub Pages (link público automático a cada push)
- [ ] itch.io
- [ ] Apenas build local
> Padrão: GitHub Pages via GitHub Actions.

**15.2 Testes automatizados:**
- [ ] Testes unitários da lógica (fila, SLA, pontuação)
- [ ] Testes de fumaça no navegador (abrir o jogo, jogar um dia simulado, tirar screenshots)
- [ ] Nenhum
> Padrão: ambos.

**15.3 Licença do código:**
- [ ] MIT
- [ ] Proprietário / todos os direitos reservados
- [ ] Outra:
> Padrão: MIT para o código; assets conforme as licenças de origem, listadas em `CREDITS.md`.

**15.4 Documentação desejada:**
- [ ] README com como rodar e jogar
- [ ] Documento de design do jogo (GDD) mantido no repositório
- [ ] Guia para adicionar novos chamados/minigames
> Padrão: todos.

Observações:

---

## 16. Processo de desenvolvimento autônomo

**16.1 ⭐ Nível de autonomia:**
- [ ] Total: desenvolver tudo e só mostrar no final
- [ ] Por marcos: parar para revisão a cada marco (ex.: protótipo jogável → arte → conteúdo → polimento)
- [ ] Decidir sozinho, mas registrar todas as decisões num arquivo `DECISOES.md`
> Padrão: por marcos, sempre registrando decisões em `DECISOES.md`.

**16.2 Marcos propostos — concorda?**
1. Base técnica: projeto, movimentação top-down no escritório com colisão, câmera
2. Loop principal: fila de chamados, SLA, triagem, fechar chamado, fim de dia
3. Minigames e escalonamento
4. Arte pixel e animações definitivas, áudio
5. Conteúdo: 5 dias, NPCs, eventos, tutorial
6. Polimento: menus, save, balanceamento, testes, publicação

- [ ] Sim
- [ ] Com ajustes:

**16.3 Como você quer acompanhar?**
- [ ] Commits frequentes na branch de desenvolvimento
- [ ] Pull request por marco
- [ ] Screenshots/GIFs a cada marco
- [ ] Link jogável atualizado
> Padrão: commits frequentes + link jogável + screenshots por marco.

**16.4 Quando houver dúvida não prevista, o agente deve:**
- [ ] Escolher a opção mais simples e seguir
- [ ] Escolher a opção mais divertida e seguir
- [ ] Parar e perguntar
> Padrão: escolher a mais simples que preserve a diversão, e registrar.

**16.5 Critério de "pronto" de cada marco:**
- [ ] Roda sem erros no navegador
- [ ] Testes passando
- [ ] Jogável do início ao fim do escopo do marco
- [ ] Outros:
> Padrão: todos acima.

Observações:

---

## 17. Referências e restrições

**17.1 Jogos que inspiram a sensação ou a mecânica** (servem como referência de sensação, não para cópia):

Resposta:

**17.2 Algo que você NÃO quer de jeito nenhum?**

Resposta:

**17.3 Restrições legais/corporativas:**
- [ ] Não usar logotipos, softwares ou marcas reais (ex.: nomes de sistemas de chamados reais)
- [ ] Não retratar colegas reais
- [ ] Outra:
> Padrão: as duas primeiras; tudo será fictício, inclusive os nomes de softwares (paródias genéricas).

---

## 18. Prioridades (ordene de 1 a 5)

| Aspecto | Prioridade (1 = mais importante) |
|---|---|
| Diversão / ritmo do gameplay | |
| Fidelidade ao dia a dia real de Service Desk | |
| Qualidade visual da pixel art | |
| Quantidade de conteúdo (chamados, dias, NPCs) | |
| Rapidez para ter algo jogável | |

---

## Resumo do que é imprescindível (⭐)

Para começar o desenvolvimento autônomo, basta responder:

1. **1.1** Objetivo do projeto
2. **1.2** Pitch do jogo
3. **2.1** Plataforma
4. **3.1** Origem dos gráficos
5. **5.1** Empresa / cenário
6. **6.1** Gênero principal
7. **7.1** Fidelidade aos processos de Service Desk
8. **12.1** Idioma
9. **13.1** Escopo da primeira versão
10. **16.1** Nível de autonomia

Todo o resto pode ficar com o padrão sugerido.
