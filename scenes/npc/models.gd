# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Node3D

func _ready() -> void:
	var model = get_children().pick_random()
	var skeleton: Skeleton3D = get_parent().get_node("Armature/Skeleton3D")
	model.skeleton = skeleton.get_path()
	remove_child(model)
	skeleton.add_child.call_deferred(model)
