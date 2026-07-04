extends Area2D

func _ready():
	# Menghubungkan sinyal langsung lewat kode begitu game dimulai
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Jika yang menginjak adalah Player (punya fungsi die), eksekusi!
	if body.has_method("die"):
		body.die()
