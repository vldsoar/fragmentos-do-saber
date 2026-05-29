class_name DropContext
extends RefCounted

enum DropType {
	ON_EMPTY_SLOT,
	ON_TIMELINE_CARD,
	ON_TIMELINE_AREA,
	INVALID,
}

var type: int = DropType.INVALID

var card: CardScn = null
var slot: CardSlotScn = null
var target_card: CardScn = null
var card_was_in_timeline: bool = false
var timeline_target_index: int = -1
