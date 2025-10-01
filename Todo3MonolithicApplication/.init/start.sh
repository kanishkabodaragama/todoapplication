#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/todoapplication/Todo3MonolithicApplication"
cd "$WORKSPACE"
export CI=true
export NODE_ENV=development
export BROWSER=none
export HOST=0.0.0.0
export PORT=3000
# start via npm run start but use exec so signals forwarded; run in background and capture child node pid
nohup sh -c 'exec npm run start >/dev/null 2>&1' >/dev/null 2>&1 &
LAUNCHER_PID=$!
# give short time for child to spawn
sleep 1
# find node process listening on PORT (best-effort)
PIDS=$(ss -ltnp 2>/dev/null | awk -v p=":$PORT" '$4 ~ p {print $6}' | sed -n '1p' | sed 's/.*pid=\([0-9]*\),.*/\1/')
if [ -n "$PIDS" ]; then
  PID=$PIDS
else
  # fallback: take child of launcher if any
  PID=$(pgrep -P "$LAUNCHER_PID" || true)
  [ -n "$PID" ] || PID=$LAUNCHER_PID
fi
PGID=$(ps -o pgid= -p "$PID" | tr -d ' ' || true)
echo "{\"launcher_pid\":$LAUNCHER_PID,\"server_pid\":$PID,\"pgid\":${PGID:-0}}" > "$WORKSPACE/server_pids.json"
# healthcheck
TRIES=0;MAX=30;SUCCESS=1
while [ $TRIES -lt $MAX ]; do
  if curl -sSf --retry 2 --max-time 2 http://127.0.0.1:3000/ >/dev/null 2>&1; then SUCCESS=0; break; fi
  sleep 1; TRIES=$((TRIES+1))
done
if [ $SUCCESS -ne 0 ]; then echo "dev server not responding on :3000" >&2; exit 7; fi
# provide stop helper
cat > "$WORKSPACE/stop_server.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
WD="$(dirname "$0")"
JSON="$WD/server_pids.json"
[ -f "$JSON" ] || { echo "no server_pids.json" >&2; exit 1; }
PID=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["server_pid"])' "$JSON")
PGID=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["pgid"])' "$JSON")
if [ "$PGID" -ne 0 ]; then
  kill -TERM -"$PGID" >/dev/null 2>&1 || true; sleep 2; kill -KILL -"$PGID" >/dev/null 2>&1 || true
else
  kill -TERM "$PID" >/dev/null 2>&1 || true; sleep 2; kill -KILL "$PID" >/dev/null 2>&1 || true
fi
EOF
chmod +x "$WORKSPACE/stop_server.sh"
