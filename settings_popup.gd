extends CanvasLayer

@onready var slider = $Panel/VolumeSlider

func _ready():
	# Menghubungkan slider agar saat digeser, fungsi volume terpanggil
	slider.value_changed.connect(_on_slider_changed)
	
	# Set nilai awal slider sesuai volume audio Master
	var bus_idx = AudioServer.get_bus_index("Master")
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

func _on_slider_changed(value):
	# Mengubah volume audio Master secara real-time
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	
	# Mute jika volume 0
	AudioServer.set_bus_mute(bus_idx, value <= 0.01)

func _on_close_button_pressed():
	hide() # Sembunyikan menu saat tombol ditutup
