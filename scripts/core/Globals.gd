extends Node
class_name Globals

# Constantes de colisão
const COLLISION_MASK_CARD := 1
const COLLISION_MASK_CARD_SLOT := 2
const COLLISION_MASK_UI := 4

# Constantes gerais do jogo
const GAME_TITLE := "Fragmentos do Saber"
const CARD_WIDTH := 180
const CARD_HEIGHT := 256
const MAX_TURNS := 10
const DEBUG_LOGS := false


static func debug_log(message: String) -> void:
	if DEBUG_LOGS:
		print(message)
