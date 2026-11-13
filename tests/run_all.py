"""Run mock tests from any working directory; requires Python and liblua 5.4."""
from pathlib import Path
import subprocess, sys
root=Path(__file__).resolve().parent.parent
cases=sorted((root/'tests').glob('*.lua'))
failed=[]
for case in cases:
    print('\n==',case.name,'==',flush=True)
    try:
        result=subprocess.run([sys.executable,'tests/lua_runner.py',str(case.relative_to(root))],cwd=root,timeout=20)
        if result.returncode: failed.append(case.name)
    except subprocess.TimeoutExpired:
        print('TIMEOUT',flush=True);failed.append(case.name)
print(f'\n{len(cases)-len(failed)}/{len(cases)} passed')
if failed:
    print('Failed:',', '.join(failed));sys.exit(1)
