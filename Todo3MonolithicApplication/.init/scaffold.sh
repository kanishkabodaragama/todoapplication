#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/todoapplication/Todo3MonolithicApplication"
cd "$WORKSPACE"
mkdir -p public src
cat > package.json <<'EOF'
{
  "name": "todo3-monolithic-application",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "BROWSER=none HOST=0.0.0.0 PORT=3000 react-scripts start",
    "build": "react-scripts build",
    "test": "jest --config ./jest.config.json",
    "lint": "eslint . --ext .js,.jsx",
    "lint:ci": "eslint . --ext .js,.jsx"
  },
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "react-scripts": "5.0.1"
  },
  "devDependencies": {
    "jest": "29.6.1",
    "react-test-renderer": "18.2.0",
    "jest-environment-jsdom": "29.6.1",
    "serve": "14.1.2"
  }
}
EOF
cat > jest.config.json <<'EOF'
{ "testEnvironment": "jsdom", "testMatch": ["**/__tests__/**/*.js?(x)", "**/?(*.)+(spec|test).js?(x)"] }
EOF
cat > public/index.html <<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Todo3MonolithicApplication</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOF
cat > src/index.js <<'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
const root = createRoot(document.getElementById('root'));
root.render(<App />);
EOF
cat > src/App.js <<'EOF'
import React from 'react';
export default function App(){
  const [todos, setTodos] = React.useState([]);
  React.useEffect(()=>{
    try { const v = JSON.parse(localStorage.getItem('todos')||'[]'); setTodos(Array.isArray(v)?v:[]); } catch { }
  },[]);
  React.useEffect(()=>{ try { localStorage.setItem('todos', JSON.stringify(todos)) } catch { } },[todos]);
  return React.createElement('div',{style:{fontFamily:'Arial',padding:20}},React.createElement('h1',null,'Todo3 Monolithic (Dev)'),React.createElement('pre',null,JSON.stringify(todos)));
}
EOF
# generate package-lock for deterministic install (npm version sensitive)
npm i --package-lock-only --no-audit --no-fund --silent || { echo "failed to generate package-lock.json" >&2; exit 6; }
