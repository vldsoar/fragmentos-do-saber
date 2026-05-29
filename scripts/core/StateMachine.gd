class_name StateMachine
extends RefCounted

signal state_changed(old, new)

var current
var transitions := {}

func configure(start, allowed):
	current = start
	transitions = allowed

func transition_to(new):
	if not transitions.has(current) or not new in transitions[current]:
		push_warning("Invalid transition: %s -> %s" % [current, new])
		return
	var old = current
	current = new
	emit_signal("state_changed", old, new)
