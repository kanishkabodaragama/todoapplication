#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/todoapplication/Todo3MonolithicApplication"
cd "$WORKSPACE"
command -v npm >/dev/null 2>&1 || { echo "npm not found" >&2; exit 2; }
NPM_V=$(npm -v)
NPM_MAJOR=$(printf '%s' "$NPM_V" | cut -d. -f1)
if [ -z "$NPM_MAJOR" ] || [ "$NPM_MAJOR" -lt 7 ]; then echo "npm $NPM_V unsupported; require npm>=7" >&2; exit 3; fi
# quick network check (do not hang long)
if ! curl -sSf --head --max-time 5 https://registry.npmjs.org/ >/dev/null 2>&1; then echo "Network to npm registry unavailable; re-run with network or provide cache" >&2; exit 4; fi
# prefer existing node_modules if critical bins are present
if [ -d node_modules ]; then
  if [ -x ./node_modules/.bin/react-scripts ] && [ -x ./node_modules/.bin/jest ]; then
    exit 0
  else
    rm -rf node_modules
  fi
fi
# deterministic install when lockfile present
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --silent || { echo "npm ci failed" >&2; exit 5; }
else
  npm i --no-audit --no-fund --silent || { echo "npm install failed" >&2; exit 6; }
fi
# verify local bins
[ -x ./node_modules/.bin/react-scripts ] || { echo "react-scripts not installed locally" >&2; exit 7; }
[ -x ./node_modules/.bin/jest ] || { echo "jest not installed locally" >&2; exit 8; }
# ensure react-test-renderer and serve exist as dev deps in package.json and local bins
if ! grep -q '"react-test-renderer"' package.json 2>/dev/null; then echo "react-test-renderer not listed as dependency in package.json; add as devDependency before installing" >&2; exit 9; fi
if ! grep -q '"serve"' package.json 2>/dev/null; then echo "serve not listed as dependency in package.json; add as devDependency before installing" >&2; exit 10; fi
[ -x ./node_modules/.bin/serve ] || { echo "serve not installed locally" >&2; exit 11; }
# Success
exit 0
