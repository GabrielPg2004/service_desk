# Chamado Aberto: documento de design

Este documento reúne as respostas ao [questionário](../QUESTIONARIO.md) e as decisões tomadas durante o desenvolvimento autônomo.

## Respostas do questionário

| Tema | Definição |
|---|---|
| Pitch | Como é trabalhar num Service Desk cheio de personalidades fortes e diferentes. Histórias de desenvolvimento de personagem, tom leve e aconchegante, cerca de 1 hora. |
| Plataforma | Web, feito em Godot |
| Controles | Setas, botão de interação; o minigame usa as setas |
| Visual e áudio | Inspirados no clima aconchegante de Stardew Valley, com arte própria |
| Cenário | Goestalpine IT-Group; protagonista Gabriel Esteka; equipe de analistas e estagiários |
| Atendimento | Sempre três opções de diálogo, uma delas a certa |
| Tipos de chamado | Instalar impressora, abrir solicitação de compra de computador etc. |
| Progressão | Não precisa |
| Mapa | Três salas: Primeiro Atendimento, Backoffice e Telecom |
| Idioma | Português, sem opções de acessibilidade |

## Decisões tomadas

**Tecnologia.** Godot 4.5.1 (GDScript) com o renderizador Compatibility (WebGL 2). A exportação web usa a variante sem threads, para rodar no GitHub Pages sem cabeçalhos COOP/COEP. A resolução interna é 480x270, ampliada no modo `canvas_items` com filtro *nearest*.

**Arte gerada por código.** `tools/gerar_arte.py` desenha tudo pixel a pixel: personagens 16x32 com 4 direções e 4 quadros, retratos 40x40, tiles 16x16, móveis e interface. Usa paleta quente, sombras puxadas para o roxo, luz puxada para o amarelo e contorno automático marrom-arroxeado, para lembrar o clima de Stardew Valley sem copiar nenhum asset.

**Som gerado por código.** `tools/gerar_sons.py` sintetiza os efeitos (blipe de texto, telefone, campainha do balcão, acerto, erro, alarme) e duas músicas em loop: uma *chiptune* tranquila em Fá maior para o escritório e uma tensa em Ré menor para o incidente.

**Fontes.** Jersey 10 no texto corrido, porque em tamanho pequeno os números ficam legíveis (na Pixelify Sans o 5 parecia S). Pixelify Sans Bold nos títulos e nomes. As duas usam a licença OFL.

**Estrutura da semana.** São 5 dias, de segunda a sexta, das 8h às 17h, com almoço ao meio-dia. Cada minuto de jogo dura 0,75 s quando há algo a fazer. Quando não há chamado aberto nem conversa disponível, o relógio acelera (»). O relógio para durante diálogos e minigames. Cada dia dura de 10 a 12 minutos.

**Chamados.** São 24 no total, de 4 a 5 por dia. Chegam pelo balcão (o cliente entra pela porta e vai até uma das três vagas), pelo telefone da mesa ou por um colega. Cada etapa tem 3 opções em ordem aleatória. Errar mostra uma reação, geralmente engraçada, tira a opção errada e permite tentar de novo. A avaliação começa em 3 estrelas e perde 1 por erro, com mínimo de 1. Depois do diálogo, alguns chamados têm tarefas: ir até um colega, um objeto ou um minigame, e às vezes voltar ao cliente no balcão.

**Minigame.** Sequência de setas de 5 a 8 teclas. Um erro não reinicia a sequência, para manter o clima tranquilo.

**Equipe e histórias.** São seis colegas, cada um com um arco de cinco cenas, uma por dia:

| Colega | Arco |
|---|---|
| Dona Célia (coordenadora) | Pensa em se aposentar diante da chegada de um chatbot; decide ficar mais um ano para conduzir a transição. |
| Rafa (analista N1) | O "palhaço do setor" que reprovou duas vezes na certificação de redes; no incidente, acha a VLAN errada. |
| Bia (estagiária) | Perfeccionista com pavor de telefone; no incidente, atende doze ligações sozinha. |
| Otávio (Backoffice) | Ranzinza, criador da Planilha Mestra que vai ser descontinuada; acaba liderando a migração. |
| Luana (Telecom) | Sente-se invisível ("quando funciona ninguém lembra"); planeja a migração de sexta. |
| Davi (estagiário de Telecom) | Confiante demais; mexe no patch panel sem documentar e causa o incidente, que depois assume. |

Um balão amarelo indica que há conversa disponível. Escolher a resposta empática ou adequada vale um coração (máximo de 5 por pessoa). No final, quem tem 3 corações ou mais ganha o epílogo "bom".

**Clímax.** Na sexta, às 13h30, a rede cai. Célia organiza o atendimento, a equipe vai ao Telecom, Rafa encontra a VLAN errada, Davi confessa e Gabriel corrige o cabo no patch panel. As histórias de sexta de Célia, Rafa, Bia, Luana e Davi só ficam disponíveis depois disso.

**Mapa.** Um único andar de 64x18 tiles, com o Backoffice à esquerda, o Primeiro Atendimento no centro e o Telecom à direita. As salas se ligam por portas laterais, e o balcão separa a área da equipe da recepção.

**Salvamento.** Automático no fim de cada dia, no `user://` (IndexedDB, no navegador). A opção "Continuar" retoma no início do dia seguinte.

**Ficção.** Pessoas, sistemas e situações são fictícios. Marcas reais aparecem como termos genéricos ("app de reunião", "central de software").

## Testes automatizados

- `tools/validar_dados.py` confere a estrutura e as regras do conteúdo.
- `testes/teste_mapa.gd` faz uma busca em largura com a física real e confere se todos os 32 alvos interativos são alcançáveis a partir da entrada e se o caminho dos clientes está livre.
- `testes/piloto.gd` joga a semana inteira sozinho, de dois jeitos: com as respostas certas (deve terminar com 24/24 chamados e 30 corações) e respondendo ao acaso (testa o fluxo de erro).
- `tools/testar.sh` roda tudo e é usado no CI antes de publicar.
