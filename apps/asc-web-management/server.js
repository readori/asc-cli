#!/usr/bin/env node
// ASC Web Management — Local bridge server
// Runs `asc` CLI commands and returns JSON to the web UI
//
// Usage:
//   node server.js              # starts on port 8421
//   node server.js --port 3000  # custom port
//
// Prerequisites:
//   - `asc` CLI installed and on PATH (or built: swift run asc)
//   - Authenticated: `asc auth check` should pass

const http = require('http');
const { execFile } = require('child_process');
const path = require('path');
const fs = require('fs');

const PORT = parseInt(process.argv.find((_, i, a) => a[i - 1] === '--port') || '8421', 10);
const ASC_BIN = process.argv.find((_, i, a) => a[i - 1] === '--asc-bin') || 'asc';

function runASC(command) {
  return new Promise((resolve) => {
    const args = command.split(/\s+/);
    // Always request JSON output for parsing
    if (!args.includes('--output')) {
      args.push('--output', 'json');
    }

    execFile(ASC_BIN, args, { timeout: 30000, maxBuffer: 10 * 1024 * 1024 }, (err, stdout, stderr) => {
      if (err) {
        resolve({ error: err.message, stderr: stderr?.trim() });
        return;
      }
      try {
        const parsed = JSON.parse(stdout);
        resolve({ result: parsed });
      } catch {
        // Return raw output if not JSON
        resolve({ result: stdout.trim(), raw: true });
      }
    });
  });
}

function serveStatic(filePath, res) {
  const ext = path.extname(filePath);
  const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.png': 'image/png', '.webp': 'image/webp' };
  const contentType = types[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

const server = http.createServer(async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // API endpoint — execute asc commands
  if (req.method === 'POST' && req.url === '/api/exec') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', async () => {
      try {
        const { command } = JSON.parse(body);
        if (!command || typeof command !== 'string') {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Missing command' }));
          return;
        }

        // Security: block dangerous patterns
        if (/[;&|`$]/.test(command)) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Invalid characters in command' }));
          return;
        }

        console.log(`  $ asc ${command}`);
        const result = await runASC(command);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // Static file serving — all assets are local
  const urlPath = decodeURIComponent(req.url.split('?')[0]);
  const fullPath = path.join(__dirname, urlPath === '/' ? 'index.html' : urlPath);

  // Security: block path traversal
  if (!fullPath.startsWith(__dirname)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  serveStatic(fullPath, res);
});

server.listen(PORT, () => {
  console.log(`
  ┌─────────────────────────────────────────────┐
  │  ASC Web Management                         │
  │  http://localhost:${PORT}                      │
  │                                             │
  │  Bridge: asc CLI → Web UI                   │
  │  Binary: ${ASC_BIN.padEnd(35)}│
  │                                             │
  │  Press Ctrl+C to stop                       │
  └─────────────────────────────────────────────┘
  `);
});
