from pathlib import Path
import hashlib
import json
import subprocess
import zipfile
root=Path(__file__).resolve().parents[1]
out=root/'deliverables'; out.mkdir(exist_ok=True)
apk=out/'calley-debug.apk'; video=out/'calley-android-emulator-demo.mp4'
if not apk.exists() or not video.exists(): raise RuntimeError('APK and Android recording are required.')
files=subprocess.check_output(['git','ls-files','-z'],cwd=root).decode().split('\0')
archive=out/'calley-flutter-submission.zip'; manifest={}
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for name in files:
        if name and (root/name).is_file(): z.write(root/name,'source/'+name)
    for path in [apk,video]:
        z.write(path,path.name); manifest[path.name]=hashlib.sha256(path.read_bytes()).hexdigest()
    z.write(root/'ASSIGNMENT.md','README.md'); z.writestr('SHA256.json',json.dumps(manifest,indent=2))
size=archive.stat().st_size
print(f'{archive}: {size/1024/1024:.2f} MiB ({size} bytes)')
if size>50_000_000: raise RuntimeError('Package exceeds conservative 50 MB portal limit.')
