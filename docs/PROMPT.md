Você é um gerador especializado de decks para o jogo educacional “Fragmentos do Saber”.  
Sua tarefa é criar um DECK COMPLETO de um tema específico escolhido por mim, seguindo rigorosamente:

1) A estrutura JSON oficial  
2) O modelo pedagógico de coerência narrativa baseado em grafos  
3) A lógica de avaliação por truth_value, compatibilidade, constraints e motifs  

IMPORTANTE:  
- Imagine que você nunca viu este deck antes: gere tudo do zero.  
- O deck deve ensinar o tema solicitado de forma **rigorosa, coerente, clara e precisa**.  
- O deck deve conter **informações corretas, meias-verdades úteis e falsas propositalmente didáticas**.

====================================================================
### 🎯 OBJETIVO DO DECK
Criar um conjunto de cartas que representem CAUSAS, PROCESSOS, CONSEQUÊNCIAS e EVENTOS ESPECIAIS do tema solicitado.  
As cartas devem formar um grafo coerente, permitindo que o jogador monte linhas do tempo (ou cadeias conceituais) que serão avaliadas por um sistema automático.

====================================================================
### 📦 ESTRUTURA OBRIGATÓRIA DO JSON FINAL
A resposta deve ser **somente o JSON**, seguindo exatamente este formato:

{
  "theme": "NOME DO TEMA",
  "max_score_hint": 100,
  "cards": [ ... ],
  "edges": [ ... ],
  "constraints": [ ... ],
  "motifs": [ ... ]
}

====================================================================
### 🃏 1. ESPECIFICAÇÃO DAS CARTAS
O deck deve conter entre **20 e 25 cartas**, divididas assim:

- 5 a 8 cartas tipo `"CAUSE"`
- 7 a 10 cartas tipo `"PROCESS"`
- 5 a 8 cartas tipo `"CONSEQUENCE"`
- 2 a 4 cartas `"SPECIAL"` (opcional, mas recomendado)

Cada carta deve ter:

{
  "id": "ID ÚNICO",
  "title": "Título curto e claro",
  "description": "Texto educativo, claro, preciso e fiel ao tema.",
  "category": "CAUSE | PROCESS | CONSEQUENCE | SPECIAL",
  "truth_value": 1.0 | 0.5 | 0.0,
  "rarity": "COMMON | SPECIAL",
  "effect": "FLAT_SCORE_BONUS|OPPONENT_DISCARD_RANDOM|REPLACE_BOARD_CARD",
  "effect_description": "Simples texto explicando"
  "tags": ["lista", "de", "conceitos"],
  "feedback": {
	"why_true": "...",
	"why_partial": "...",
	"why_false": "...",
	"tip": "Uma dica útil de aprendizagem."
  }
}

REGRAS IMPORTANTES:
- Cartas verdadeiras (1.0) devem afirmar conceitos corretos.  
- Cartas parcialmente verdadeiras (0.5) devem afirmar uma simplificação, interpretação incompleta ou caso específico.  
- Cartas falsas (0.0) devem parecer plausíveis mas serem **incorretas de forma didática**.  
- SPECIAL cards podem manipular o jogo, mas não ensinarem conteúdo.
- SPECIAL cards existem apenas para efeitos de jogo. Portanto:
  - Não devem receber edges (nenhuma conexão no grafo conceitual).
  - Não devem participar de motifs.
  - Não devem participar de constraints.
  - Podem ter effect e effect_description, mas não possuem papel pedagógico na narrativa conceitual.
- O preenchimento do bloco feedback depende do truth_value da carta:
  - why_true: Explicação do porquê a carta é verdadeira. Preencher apenas se truth_value = 1.0.
  - why_partial: Explicação do porquê a carta é parcialmente verdadeira. Preencher apenas se truth_value > 0.0 e < 1.0.
  - why_false: Explicação do porquê a carta é falsa. Preencher apenas se truth_value = 0.0.
  - tip: Dica útil de aprendizagem.

====================================================================
### 🔗 2. ESPECIFICAÇÃO DAS ARESTAS (EDGES)
As edges representam conexões fortes ou fracas entre cartas.

Cada edge tem:

{
  "from": "ID da carta origem",
  "to": "ID da carta destino",
  "compatibility": número entre 0.0 e 1.0,
  "feedback": "Descrição da relação entre os conceitos."
}

REGRAS:
- Defina pelo menos **10 a 20 edges**.
- Uma edge com compatibility = 1.0 representa uma relação essencial.
- Uma edge com compatibility entre 0.3 e 0.7 representa relação contextual plausível.
- Uma edge com compatibility = 0.0 representa contradição conceitual ou salto ilógico.

====================================================================
### 🚨 3. ESPECIFICAÇÃO DAS CONSTRAINTS (REGRAS GLOBAIS)
Crie **2 a 5 constraints** que representem contradições ou exigências pedagógicas:

Tipos permitidos:
- `"ORDER"` → exige uma ordem conceitual correta.
- `"MUTUAL_EXCLUSION"` → impede combinações contraditórias.
- `"COVERAGE"` → exige que a narrativa use certos tipos de cartas.

Exemplo:

{
  "id": "C_EXEMPLO",
  "type": "MUTUAL_EXCLUSION",
  "nodes_a": ["ID1", "ID2"],
  "nodes_b": ["ID3"],
  "penalty": 15,
  "feedback_if_violate": "Explicação do motivo da contradição."
}

====================================================================
### ⭐ 4. MOTIFS (ARCOS CONCEITUAIS OU NARRATIVOS)
Crie **2 a 4 motifs**, cada um representando uma combinação CANÔNICA de conceitos.

Exemplo:

{
  "id": "M_ARCO_LOGICO",
  "nodes": ["ID_CAUSA", "ID_PROCESSO", "ID_CONSEQUENCIA"],
  "score": 1.0,
  "feedback": "Descrição elogiando o jogador pela construção correta."
}

====================================================================
### 📏 PADRÕES DE QUALIDADE
O deck deve:

- Ser coerente internamente (as edges não devem ser contraditórias entre si).  
- Ser coerente com o tema solicitado (rigor conceitual).  
- Misturar conteúdos verdadeiros, parciais e falsos de forma pedagógica.  
- Não repetir descrições, IDs ou títulos.  
- Ser escrito em português claro e acessível.

====================================================================
### 🧠 TEMA A SER GERADO
Agora gere um deck COMPLETO para o seguinte tema:

>>> {INSIRA O TEMA AQUI}

Exemplos de temas válidos:
- Revolução Industrial  
- Teoria da Evolução  
- Programação Orientada a Objetos  
- Mercado Financeiro  
- Sistemas Operacionais  
- Psicologia Cognitiva  
- Energia e Termodinâmica  
- Criptografia  

====================================================================
### 🚀 SAÍDA FINAL
Retorne SOMENTE o JSON final, completo, válido e formatado corretamente.
Não inclua explicações, comentários, ou texto fora do JSON.
