from pathlib import Path

p = Path(__file__).resolve().parents[1] / "v03.gd"
s = p.read_text(encoding="utf-8")
old = '''func _chest_transfer(item: String, to_chest: bool) -> void:
	InventorySystem.chest_transfer(self, item, to_chest, false)'''
new = '''func _chest_transfer(item: String, to_chest: bool, all_items: bool = false) -> void:
	InventorySystem.chest_transfer(self, item, to_chest, all_items)'''
if old in s:
    s = s.replace(old, new, 1)
elif new not in s:
    raise RuntimeError("expected chest transfer wrapper not found")
p.write_text(s.rstrip() + "\n", encoding="utf-8")
print("stabilization fixups applied")
