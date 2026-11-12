from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from io import BytesIO

root = Path(__file__).resolve().parent
entry = root / 'elfis_bastille_podmien_front.rb'
files = [entry] + sorted(p for p in (root / 'elfis_bastille_podmien_front').rglob('*') if p.is_file() and p.name != 'door_complete.wav')
target = root / 'ELFIS_Profile_Library_2.9.14.rbz'
buffer = BytesIO()
with ZipFile(buffer, 'w', ZIP_DEFLATED) as package:
    for file in files:
        if file.is_file():
            package.write(file, file.relative_to(root).as_posix())
payload = buffer.getvalue()
if target.exists():
    if target.read_bytes() != payload:
        raise SystemExit(f'Archive preserved: {target.name} already exists with different contents. Set a new version number.')
else:
    with target.open('xb') as archive:
        archive.write(payload)
with ZipFile(target) as package:
    assert package.testzip() is None
    assert 'elfis_bastille_podmien_front/jpull.rb' in package.namelist()
    assert 'elfis_bastille_podmien_front/onepiece.rb' in package.namelist()
    assert 'elfis_bastille_podmien_front/order_list.rb' in package.namelist()
    assert 'elfis_bastille_podmien_front/order_list.html' in package.namelist()
    assert 'elfis_bastille_podmien_front/order_list.svg' in package.namelist()
    assert 'elfis_bastille_podmien_front/families.rb' in package.namelist()
print(f'{target.name}: {len(files)} files, {target.stat().st_size} bytes, verified')
