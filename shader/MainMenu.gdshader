shader_type canvas_item;

// Mengontrol opacity hover secara halus (0.0 = hilang, 1.0 = muncul penuh)
uniform float hover_intensity : hint_range(0.0, 1.0) = 0.0;

// Saklar pilihan arah fade di Inspector
uniform bool kanan_kiri_saja = false;
uniform bool atas_bawah_saja = false;

void fragment() {
    // Menghitung jarak koordinat dari titik tengah kotak (0.5, 0.5)
    vec2 uv = UV - vec2(0.5);
    
    float dist = 0.0;
    
    if (kanan_kiri_saja) {
        // Hanya menghitung jarak horizontal (X)
        dist = abs(uv.x) * 2.0;
    } else if (atas_bawah_saja) {
        // Hanya menghitung jarak vertikal (Y)
        dist = abs(uv.y) * 2.0;
    } else {
        // Kotak penuh (Box Vignette asal)
        dist = max(abs(uv.x), abs(uv.y)) * 2.0;
    }
    
    // Menghaluskan transisi pinggiran
    float alpha = smoothstep(1.0, 0.3, dist);
    
    // Menggunakan vec4(1.0, 1.0, 1.0) untuk warna putih bersih.
    // Ditambahkan perkalian * hover_intensity agar bisa dianimasikan lewat script.
    COLOR = vec4(1.0, 1.0, 1.0, alpha * 0.3 * hover_intensity); 
}