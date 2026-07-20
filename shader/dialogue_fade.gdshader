shader_type canvas_item;

// Mengontrol seberapa lebar efek fade di sisi kanan dan kiri (0.0 - 0.5)
uniform float fade_width : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	// Hitung fade untuk sisi kiri (dari 0.0 sampai batas fade_width)
	float fade_left = smoothstep(0.0, fade_width, UV.x);
	
	// Hitung fade untuk sisi kanan (dari batas 1.0 - fade_width sampai 1.0)
	float fade_right = smoothstep(1.0, 1.0 - fade_width, UV.x);
	
	// Gabungkan kedua efek fade (kiri dan kanan)
	float final_fade = fade_left * fade_right;
	
	// PERBAIKAN: Cukup kalikan alpha bawaan node dengan efek fade kita.
	// Warna hitam dan alpha awal 150 kamu akan tetap terjaga di bagian tengah!
	COLOR.a *= final_fade;
}