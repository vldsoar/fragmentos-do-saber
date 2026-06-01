class_name DropResolver
extends RefCounted


static func resolve(
	card: CardScn,
	slot: CardSlotScn,
	target_card: CardScn,
	player_timeline: PlayerTimeline
) -> DropContext:
	var context: DropContext = DropContext.new()
	context.card = card
	context.slot = slot
	context.target_card = target_card

	if card == null or player_timeline == null:
		return context

	context.card_was_in_timeline = player_timeline.has(card)
	if context.card_was_in_timeline:
		context.timeline_target_index = player_timeline.get_target_position_for_reorder()

	if slot != null and slot.can_accept_card(card):
		context.type = DropContext.DropType.ON_EMPTY_SLOT
		return context

	if target_card != null and target_card != card and player_timeline.has(target_card):
		context.type = DropContext.DropType.ON_TIMELINE_CARD
		return context

	context.type = DropContext.DropType.INVALID
	return context
