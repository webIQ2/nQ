#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
ONECLICK_DIR="$ROOT_DIR/vyos/oneclick"
MODE="${MODE:-fabric}"
PARAMS_IN="${PARAMS_IN:-$ONECLICK_DIR/parameters.webiq.json}"
PARAMS_FILE="$ONECLICK_DIR/parameters.runtime.${MODE}.json"
COMMERCIAL_TEST_VM_SIZE="${COMMERCIAL_TEST_VM_SIZE:-Standard_D2s_v3}"
GOVERNMENT_TEST_VM_SIZE="${GOVERNMENT_TEST_VM_SIZE:-Standard_D2s_v3}"
python3 - "$PARAMS_IN" "$PARAMS_FILE" "$MODE" "$COMMERCIAL_TEST_VM_SIZE" "$GOVERNMENT_TEST_VM_SIZE" <<'PY'
import json,sys
src,dst,mode,comm_size,gov_size=sys.argv[1:]
with open(src,'r',encoding='utf-8') as f: d=json.load(f)
p=d.setdefault('parameters',{})
if mode=='fabric':
    p['deployCommercialTestVm']={'value':False}
    p['deployGovernmentTestVm']={'value':False}
else:
    p['deployCommercialTestVm']={'value':True}
    p['deployGovernmentTestVm']={'value':True}
    p['commercialTestVmSize']={'value':comm_size}
    p['governmentTestVmSize']={'value':gov_size}
with open(dst,'w',encoding='utf-8') as f: json.dump(d,f,indent=2)
PY
export PARAMS_FILE
cd "$ONECLICK_DIR"
./deploy.sh
