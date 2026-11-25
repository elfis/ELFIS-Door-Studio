from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from io import BytesIO
import hashlib, json

root = Path(__file__).resolve().parent
files = [root/'elfis_handles.rb'] + sorted(p for p in (root/'elfis_handles').rglob('*') if p.is_file())
version='1.1.10-beta'
folder = root/'public'/'handles'/version
folder.mkdir(parents=True, exist_ok=True)
validation = json.loads((folder / 'VALIDATION.json').read_text(encoding='utf-8'))
assert validation['version'] == version and validation['passed'], 'Release validation must pass before packaging'
assert validation['toolbarTests']['passed'] and validation['uiTests']['passed'], 'Toolbar and UI checks must pass before packaging'
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
print(f'{target}: {len(files)} files, verified')
