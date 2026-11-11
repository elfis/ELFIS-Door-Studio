from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from io import BytesIO
import hashlib, json

root = Path(__file__).resolve().parent
files = [root/'elfis_handles.rb'] + sorted(p for p in (root/'elfis_handles').rglob('*') if p.is_file())
version='1.1.4-beta'
folder = root/'public'/'handles'/version
folder.mkdir(parents=True, exist_ok=True)
target = folder/f'ELFIS_Handles_{version}.rbz'
buffer = BytesIO()
with ZipFile(buffer, 'w', ZIP_DEFLATED) as z:
    for f in files:
        z.writestr(f.relative_to(root).as_posix(), f.read_bytes())
payload = buffer.getvalue()
if target.exists():
    with ZipFile(target) as z:
        assert set(z.namelist()) == {f.relative_to(root).as_posix() for f in files}, 'Existing version preserved: choose a new version.'
        assert all(z.read(f.relative_to(root).as_posix()) == f.read_bytes() for f in files), 'Existing version preserved: choose a new version.'
else:
    target.write_bytes(payload)
with ZipFile(target) as z:
    assert z.testzip() is None
(folder/f'ELFIS_Handles_{version}.sha256').write_text(hashlib.sha256(target.read_bytes()).hexdigest()+'  '+target.name+'\n', encoding='utf-8')
(folder/'README.md').write_text(f'# ELFIS Handles {version}\n\n**BETA — Calibrate standard handles before use and check placement on a test front.**\n\nRemove ELFIS handles by clicking front components. Tap Ctrl to switch horizontal top centre / vertical top right; tap Shift for horizontal top/bottom or vertical right/left. Positions stay after key release. Live settings, independent offsets and fixing-point calibration. Edge-pull mounting rules are unchanged.\n\nRequires ELFIS Door Studio 2.9.1. Install the RBZ through SketchUp Extension Manager, then restart SketchUp.\n\n[English guide](../../../ELFIS_Handles_README.en.md) · [Polska instrukcja](../../../ELFIS_Handles_README.md)\n', encoding='utf-8')
results=json.loads((root/'elfis_handles_test_results.json').read_text(encoding='utf-8-sig'))
assert results['passed'], 'Native geometry checks must pass before packaging'
workflow=json.loads((root/'elfis_handles_calibration_cancel_results.json').read_text(encoding='utf-8-sig'))
assert workflow['passed'], 'Calibration workflow checks must pass before packaging'
print(f'{target}: {len(files)} files; {len(results["checks"])} native checks passed')
