# Manual do Desenvolvedor - Fragmentos do Saber

Este manual é para quem vai manter, expandir ou adaptar **Fragmentos do Saber**. Ele explica a estrutura principal do projeto e os passos para adicionar novos temas, decks, assets e configurações.

## Visão geral técnica

Fragmentos do Saber é um jogo Godot em que o conteúdo pedagógico fica separado da lógica principal.

O código controla:

- fluxo da partida;
- compra de cartas;
- mão e board;
- IA do oponente;
- pontuação;
- efeitos especiais;
- temas visuais;
- tela final e Modo Professor.

Os decks em JSON controlam:

- conteúdo das cartas;
- relações entre cartas;
- regras de coerência;
- sequências desejadas;
- feedback pedagógico.

Essa separação permite criar novos temas sem alterar o código principal.

## Estrutura principal

| Área | Arquivos principais |
|---|---|
| Cena principal | `scenes/Main.tscn` |
| Orquestração da partida | `scripts/GameManager.gd` |
| Mão e board | `scripts/PlayerHand.gd`, `scripts/OpponentHand.gd`, `scripts/TimelineBase.gd` |
| Cartas | `scenes/Card.tscn`, `scripts/Card.gd` |
| Deck | `scenes/Deck.tscn`, `scripts/Deck.gd` |
| Carregamento de decks | `scripts/core/DeckRepository.gd` |
| Pontuação | `scripts/core/CoherenceScoringEngine.gd` |
| Efeitos | `scripts/core/CardEffectProcessor.gd` |
| IA | `scripts/OpponentAI.gd`, `scripts/core/OpponentDecisionEngine.gd` |
| Resultado | `scripts/GameOverScreen.gd`, `scripts/TeacherAnalysisPanel.gd` |
| Temas | `data/theme_config.json`, `scripts/ThemeManager.gd` |
| Configurações | `scripts/SettingsManager.gd` |

## Como adicionar um novo deck

### 1. Criar o arquivo JSON do deck

Crie um arquivo em `data/`.

Exemplo:

```text
data/deck_hist_industrial.json
```

Estrutura mínima:

```json
{
  "theme": "Revolução Industrial",
  "max_score_hint": 100.0,
  "cards": [],
  "edges": [],
  "constraints": [],
  "motifs": []
}
```

### 2. Definir padrão de IDs

Use prefixo curto, sequencial e sem acentos.

Exemplos:

```text
RI001, RI002, RI003
SO001, SO002, SO003
MB001, MB002, MB003
```

Regras:

- não repetir IDs;
- não usar espaços;
- não usar acentos;
- usar o mesmo padrão em cartas, edges, constraints e motifs.

### 3. Criar cartas comuns

Cartas comuns usam:

- `CAUSE`;
- `PROCESS`;
- `CONSEQUENCE`.

Exemplo:

```json
{
  "id": "RI001",
  "title": "Cercamentos",
  "description": "Os cercamentos alteraram relações agrárias e contribuíram para mudanças econômicas e sociais.",
  "category": "CAUSE",
  "truth_value": 1.0,
  "rarity": "COMMON",
  "effect": "",
  "effect_description": "",
  "tags": ["campo", "economia"],
  "feedback": {
    "why_true": "Os cercamentos ajudaram a transformar a organização agrária e a oferta de trabalho.",
    "tip": "Use esta carta antes de cartas sobre industrialização urbana."
  }
}
```

### 4. Criar cartas especiais

Cartas especiais usam:

- `category: "SPECIAL"`;
- `rarity: "SPECIAL"`;
- `effect`;
- `effect_description`;
- `bonus_score`.

Efeitos atuais:

| Efeito | Uso |
|---|---|
| `FLAT_SCORE_BONUS` | Soma bônus ao resultado final. |
| `OPPONENT_DISCARD_RANDOM` | Remove carta verdadeira do board adversário. |
| `REPLACE_BOARD_CARD` | Troca carta comum da mão por carta do próprio board. |

Exemplo:

```json
{
  "id": "RI021",
  "title": "Revisão Histórica",
  "description": "Permite revisar a organização da narrativa.",
  "category": "SPECIAL",
  "truth_value": 1.0,
  "rarity": "SPECIAL",
  "effect": "REPLACE_BOARD_CARD",
  "effect_description": "Permite trocar uma carta comum da mão por uma carta do próprio board. A carta removida vai para o descarte.",
  "bonus_score": 0.0,
  "tags": ["especial", "revisao"],
  "feedback": {
    "why_true": "Representa uma intervenção estratégica sobre a narrativa construída.",
    "tip": "Use quando uma carta da mão melhorar o board."
  }
}
```

### 5. Criar edges

Edges ligam cartas comuns e afetam o score contextual.

```json
{
  "from": "RI001",
  "to": "RI007",
  "compatibility": 1.0,
  "feedback": "Os cercamentos ajudam a explicar a formação de mão de obra para a industrialização."
}
```

Regras:

- usar apenas cartas comuns;
- não usar cartas `SPECIAL`;
- lembrar que edges são direcionadas;
- criar conexões fortes, médias e algumas fracas para gerar feedback.

### 6. Criar constraints

Constraints avaliam regras globais.

Tipos funcionais:

- `ORDER`;
- `MUTUAL_EXCLUSION`.

Exemplo de ordem:

```json
{
  "id": "C_ORDER_CAUSA_PROCESSO",
  "type": "ORDER",
  "required_before": ["RI001"],
  "required_after": ["RI007"],
  "penalty": 15,
  "feedback_if_violate": "A causa agrária deve aparecer antes do processo industrial associado."
}
```

Exemplo de contradição:

```json
{
  "id": "C_CONTRADICAO_EXEMPLO",
  "type": "MUTUAL_EXCLUSION",
  "nodes_a": ["RI010"],
  "nodes_b": ["RI015"],
  "penalty": 20,
  "feedback_if_violate": "As duas cartas apresentam interpretações incompatíveis."
}
```

### 7. Criar motifs

Motifs são sequências canônicas que recebem bônus.

```json
{
  "id": "M_ARCO_INDUSTRIAL",
  "nodes": ["RI001", "RI007", "RI012"],
  "score": 1.0,
  "feedback": "A sequência mostra causa, processo industrial e consequência social."
}
```

O engine atual só pontua motifs quando a sequência aparece exatamente na mesma ordem e de forma consecutiva no board.

### 8. Registrar no catálogo

Adicione o novo deck em `data/decks.json`.

```json
{
  "area": "História",
  "theme": "Revolução Industrial",
  "path": "res://data/deck_hist_industrial.json",
  "icon": "res://themes/clean_theme/images/decks/hist_industrial_icon.png"
}
```

O campo `icon` é opcional. Se ausente ou inválido, o jogo usa o ícone padrão do tema.

## Proporções recomendadas para decks

Para o estado atual do jogo:

- 20 a 25 cartas;
- 5 a 8 cartas `CAUSE`;
- 7 a 10 cartas `PROCESS`;
- 5 a 8 cartas `CONSEQUENCE`;
- 2 a 4 cartas `SPECIAL`;
- 12 a 24 edges;
- 2 a 4 constraints;
- 2 a 4 motifs.

Distribuição de verdade:

- 65% a 75% verdadeiras;
- 10% a 20% parciais;
- 10% a 20% falsas.

## Validação do deck

Antes de testar no jogo, valide o JSON:

```bash
python3 -m json.tool data/seu_deck.json
```

Depois, revise:

- todos os IDs usados em edges existem em `cards`;
- todos os IDs usados em constraints existem em `cards`;
- todos os IDs usados em motifs existem em `cards`;
- cartas especiais não aparecem em edges, constraints ou motifs;
- cada carta tem `feedback` adequado ao `truth_value`;
- o deck foi registrado em `data/decks.json`.

`DeckRepository.gd` também valida referências ao carregar o deck.

## Como adicionar um novo tema visual

Temas visuais ficam em:

```text
themes/
  default/
  new_theme/
```

Crie uma nova pasta:

```text
themes/meu_tema/
  images/
  fonts/
```

Depois, registre o tema em `data/theme_config.json`.

Exemplo simplificado:

```json
{
  "active_theme": "meu_tema",
  "themes": {
    "meu_tema": {
      "textures": {
        "game_over_background": "res://themes/meu_tema/images/bg_game_over.png"
      },
      "colors": {
        "button_bg": "#202020",
        "button_text": "#F5F5F5"
      }
    }
  }
}
```

Chaves ausentes caem para o tema `default`.

## Texturas configuráveis por tema

Principais chaves:

| Chave | Uso |
|---|---|
| `menu_background` | Fundo do menu e seleção. |
| `board_background` | Fundo da partida. |
| `game_over_background` | Fundo da tela final. |
| `card_front` | Frente padrão das cartas. |
| `card_front_CAUSE` | Frente opcional para cartas de causa. |
| `card_front_PROCESS` | Frente opcional para cartas de processo. |
| `card_front_CONSEQUENCE` | Frente opcional para cartas de consequência. |
| `card_front_SPECIAL` | Frente opcional para cartas especiais. |
| `card_back` | Verso da carta/deck. |
| `card_back_hover` | Verso usado no pulse do deck. |
| `deck_button_bg` | Textura dos botões da seleção de área. |
| `area_icon` | Ícone padrão dos decks. |

## Como adicionar ícone por deck

Coloque os ícones, preferencialmente, em:

```text
themes/<tema>/images/decks/
```

Depois, configure no item do deck:

```json
{
  "area": "Biologia",
  "theme": "Ecologia",
  "path": "res://data/deck_bio_ecologia.json",
  "icon": "res://themes/clean_theme/images/decks/bio_ecologia_icon.png"
}
```

## Como adicionar novos efeitos especiais

Para adicionar um novo efeito, é necessário alterar código.

Pontos principais:

1. Adicionar o efeito em `CardResource.SpecialEffect`.
2. Atualizar o parser de efeito textual.
3. Implementar a regra em `CardEffectProcessor.gd`.
4. Ajustar `GameManager.gd` se o efeito precisar de escolha do jogador.
5. Ajustar `OpponentAI.gd` se o oponente puder usar o efeito.
6. Documentar o efeito em `docs/PROMPT.md`.
7. Atualizar decks que forem usar o novo efeito.

Regra prática:

- efeitos que só somam pontos ficam quase todos em `CardEffectProcessor`;
- efeitos que exigem clique, alvo ou preview precisam de UI coordenada pelo `GameManager`.

## Como ajustar a duração da partida

A duração é calculada em `TurnController.gd`.

Valores globais:

- mínimo: 8 turnos;
- padrão: 10 turnos;
- longo: 12 turnos.

O deck não define diretamente a duração. O jogo calcula a duração a partir da quantidade de cartas.

## Como atualizar documentação

Ao alterar comportamento relevante, atualize:

- `docs/ongoing/Projeto_Resumo.md`;
- `docs/ongoing/Game_Architecture.md`, se mudar arquitetura;
- `docs/ongoing/CoherenceScoringEngine.md`, se mudar pontuação;
- `docs/ongoing/ThemeSystem.md`, se mudar tema;
- `docs/PROMPT.md`, se mudar formato de deck;
- `docs/ongoing/Manual_Jogador_Fragmentos_do_Saber.md`, se mudar regra visível ao jogador.

## Checklist para novo deck

Antes de considerar o deck pronto:

- JSON válido.
- IDs sequenciais e sem duplicação.
- 20 a 25 cartas.
- Proporção adequada de verdade/parcial/falso.
- Edges suficientes para orientar boas sequências.
- Constraints úteis e com feedback claro.
- Motifs relevantes e possíveis no board de 8 cartas.
- Cartas especiais com efeito válido.
- Deck registrado em `data/decks.json`.
- Ícone configurado ou fallback aceito.
- Partida testada.
- Modo Professor revisado.

## Checklist para novo tema visual

- Pasta criada em `themes/<nome>/`.
- Imagens organizadas em `images/`.
- Fontes organizadas em `fonts/`, se houver.
- Tema registrado em `data/theme_config.json`.
- `active_theme` apontando para o tema desejado.
- Fallback para `default` funcionando.
- Cartas, deck e slots com tamanho visual adequado.
- Menu, KnowledgeArea, partida e GameOver revisados.

## Cuidados comuns

- Não usar IDs inexistentes em edges, constraints ou motifs.
- Não colocar cartas especiais em edges ou motifs.
- Não depender de `COVERAGE` para pontuação, pois ainda não é processado.
- Não remover o tema `default`.
- Não editar `.import` manualmente.
- Usar caminhos `res://`.
- Testar visual em mais de uma resolução quando alterar assets.

## Ideia central para manutenção

O projeto escala melhor quando novas áreas de conhecimento entram como dados, não como lógica nova.

Antes de criar código novo, verifique se a necessidade pode ser resolvida com:

- novo deck;
- nova edge;
- nova constraint;
- novo motif;
- novo asset de tema;
- nova configuração no JSON.

Código novo deve ser reservado para novas mecânicas, novos efeitos ou mudanças reais no comportamento do jogo.
