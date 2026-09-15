from pathlib import Path

p = Path(__file__).with_name('v02.gd')
s = p.read_text(encoding='utf-8')

s = s.replace(
    'var types := ["lobo", "acechador", "saqueador"]\n\t\tvar kind := types[local_rng.randi_range(0, types.size() - 1)]',
    'var types: Array[String] = ["lobo", "acechador", "saqueador"]\n\t\tvar kind: String = String(types[local_rng.randi_range(0, types.size() - 1)])'
)
s = s.replace('draw_ellipse(p + Vector2(0, 13), Vector2(11, 4), Color(0.0, 0.0, 0.0, 0.26))', '_draw_ellipse_px(p + Vector2(0, 13), Vector2(11, 4), Color(0.0, 0.0, 0.0, 0.26))')
s = s.replace('func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:', 'func _draw_ellipse_px(center: Vector2, radius: Vector2, color: Color) -> void:')

p.write_text(s, encoding='utf-8')
print('Normalized v02.gd source fixes')
