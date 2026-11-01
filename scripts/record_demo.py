"""Record the integration test on a dedicated Android emulator (no UI injection)."""
from pathlib import Path
import subprocess
import sys
import time

root=Path(__file__).resolve().parents[1]
adb=Path.home()/'AppData/Local/Android/sdk/platform-tools/adb.exe'
device='emulator-5556'
remote='/sdcard/calley-demo.mp4'
out=root/'deliverables'
out.mkdir(exist_ok=True)
recorder=None
command=['cmd.exe','/d','/c',r'C:\flutter\bin\flutter.bat','test','integration_test/demo_flow_test.dart','-d',device,'--no-pub']
with (out/'android-integration-test.log').open('w',encoding='utf-8') as log:
    process=subprocess.Popen(command,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace')
    try:
        for line in process.stdout:
            log.write(line); log.flush(); print(line,end='',flush=True)
            if 'CAPTURE_READY' in line and recorder is None:
                recorder=subprocess.Popen([str(adb),'-s',device,'shell','screenrecord','--bit-rate','3000000','--time-limit','120',remote],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        status=process.wait()
    finally:
        if recorder is not None:
            subprocess.run([str(adb),'-s',device,'shell','pkill','-2','screenrecord'],capture_output=True)
            try: recorder.wait(timeout=10)
            except subprocess.TimeoutExpired: recorder.terminate()
            time.sleep(1)
            subprocess.run([str(adb),'-s',device,'pull',remote,str(out/'calley-android-emulator-demo.mp4')],check=True)
    if status: sys.exit(status)
    if recorder is None: raise RuntimeError('No recording marker was emitted.')
    print('Android demo recording saved.',flush=True)
