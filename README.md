# Fragmentos do Saber

Jogo educacional de cartas em que o jogador monta uma timeline coerente sobre um tema (História, Tecnologia, Biologia ou Literatura), enquanto um oponente automatizado monta a própria. A pontuação vem de um motor de coerência, não só de “cartas certas”.

## Tecnologias

| Item | Detalhe |
|------|---------|
| Engine | [Godot](https://godotengine.org/) **4.6** |
| Linguagem | GDScript |
| Renderização | GL Compatibility |
| Conteúdo | JSON em `data/` (decks, catálogo, tema visual) |
| Export | Web (PWA) em `exec/` |
| Resolução base | 1920×1080 |

Não há Node, npm, Cargo nem backend. O jogo roda no editor Godot ou no export HTML5.

## Pré-requisito

1. Instale o **Godot 4.6** (Standard, não .NET).
2. Clone este repositório.

No VS Code / Cursor, o editor Godot local pode ser apontado em `.vscode/settings.json` (`godotTools.editorPath.godot4`).

## Rodar no editor

1. Abra a pasta do projeto no Godot (`Project` → `Import`, ou arraste `project.godot`).
2. Pressione **F5** (Play).

A cena inicial é o menu. Dali: iniciar partida → escolher área/tema → jogar.

Decks atuais:

| Área | Tema | Arquivo |
|------|------|---------|
| História | Revolução Francesa | `data/deck_rf.json` |
| Tecnologia | Programação Orientada a Objetos | `data/deck_poo.json` |
| Biologia | Teoria da Evolução | `data/deck_te.json` |
| Literatura | Modernismo Brasileiro | `data/deck_lit_modern.json` |

O catálogo lido pelo jogo está em `data/decks.json`.

## Export Web

Há um preset **Web** em `export_presets.cfg`. A saída vai para `exec/fragmentos-do-saber.html`.

No Godot:

1. `Project` → `Export…`
2. Selecione **Web**
3. `Export Project…` (ou `Export With Debug` para testar)

O export usa threads (SharedArrayBuffer). Não abra o HTML direto pelo Finder (`file://`): o navegador bloqueia. Também não basta `python3 -m http.server` sem headers extras.

### Servir o export localmente

Na pasta `exec/`, um servidor com COOP/COEP:

```bash
cd exec
python3 - <<'PY'
from http.server import HTTPServer, SimpleHTTPRequestHandler

class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

print("http://127.0.0.1:8080/fragmentos-do-saber.html")
HTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
PY
```

Abra `http://127.0.0.1:8080/fragmentos-do-saber.html`.

Alternativa: no diálogo de Export do Godot, use **Run in Browser** — o editor sobe um servidor com os headers certos.

## Estrutura rápida

```
fragmentos-do-saber/
├── project.godot      # config Godot 4.6
├── scenes/            # menu, partida, cartas, HUD
├── scripts/           # lógica (GDScript)
│   └── core/          # pontuação, efeitos, IA, decks
├── data/              # decks JSON + catálogo
├── themes/            # tema visual e ícones
├── assets/            # áudio
├── exec/              # build Web gerado
└── docs/              # documentação
```

## Documentação extra

- [Manual do jogador](Manual_Jogador_Fragmentos_do_Saber.md) — regras e tela final
- [Manual do desenvolvedor](Manual_Desenvolvedor_Fragmentos_do_Saber.md) — novos decks e manutenção
