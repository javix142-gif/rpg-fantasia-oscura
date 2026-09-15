from pathlib import Path
import base64
import hashlib
import zlib

EXPECTED_SHA256 = "87851cd86b1f8cb76f245159f604780954ef6fd4ec548be7dc3d7fd10d1ea971"
root = Path(__file__).with_name("v03_payload")
parts = sorted(root.glob("part_*.txt"))
if len(parts) != 8:
    raise SystemExit(f"Expected 8 payload parts, found {len(parts)}")
payload = "".join(p.read_text(encoding="utf-8").strip() for p in parts)
source = zlib.decompress(base64.b64decode(payload))
digest = hashlib.sha256(source).hexdigest()
if digest != EXPECTED_SHA256:
    raise SystemExit(f"v03 source SHA256 mismatch: {digest}")
out = Path(__file__).with_name("v03.gd")
out.write_bytes(source)
print(f"Generated {out.name}: {out.stat().st_size} bytes SHA256={digest}")
