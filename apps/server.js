#!/usr/bin/env node
// ASC Web Server — Unified bridge for all web apps
// Runs `asc` CLI commands and serves static files for web UIs
//
// Usage:
//   node server.js              # starts on port 8420
//   node server.js --port 3000  # custom port
//
// Routes:
//   /management/  → asc-web-management (dashboard)
//   /console/     → asc-web-console (terminal)
//   /             → asc-web-management (default)
//   /api/run      → execute asc CLI commands
//
// Prerequisites:
//   - `asc` CLI installed and on PATH (or built: swift run asc)
//   - Authenticated: `asc auth check` should pass

const http = require('http');
const { execFile } = require('child_process');
const path = require('path');
const fs = require('fs');

const PORT = parseInt(process.argv.find((_, i, a) => a[i - 1] === '--port') || '8420', 10);
const ASC_BIN = process.argv.find((_, i, a) => a[i - 1] === '--asc-bin') || 'asc';

const APPS_DIR = __dirname;
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

function runASC(command) {
  return new Promise((resolve) => {
    const parts = command.split(/\s+/);
    // Strip leading "asc" if present
    const args = parts[0] === 'asc' ? parts.slice(1) : parts;

    execFile(ASC_BIN, args, {
      timeout: 30000,
      maxBuffer: 10 * 1024 * 1024,
      env: { ...process.env, NO_COLOR: '1' },
    }, (err, stdout, stderr) => {
      resolve({
        stdout: stdout || '',
        stderr: stderr || '',
        exit_code: err ? (err.code || 1) : 0,
      });
    });
  });
}

function serveStatic(filePath, res) {
  const ext = path.extname(filePath);
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.stat(filePath, (statErr, stats) => {
    if (statErr || !stats) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    // If directory, serve index.html inside it
    if (stats.isDirectory()) {
      serveStatic(path.join(filePath, 'index.html'), res);
      return;
    }
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(data);
    });
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
  if (req.method === 'POST' && req.url === '/api/run') {
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

        // Security: block dangerous shell characters
        if (/[;&|`$\\(){}\[\]!><]/.test(command)) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Command contains disallowed characters' }));
          return;
        }

        console.log(`  $ ${command}`);
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

  // Static file serving with app routing
  const urlPath = decodeURIComponent(req.url.split('?')[0]);

  // Route: /management/* → asc-web-management/
  // Route: /console/*    → asc-web-console/
  // Route: /             → asc-web-management/index.html
  let filePath;
  if (urlPath.startsWith('/management')) {
    const subPath = urlPath.slice('/management'.length) || '/';
    filePath = path.join(APPS_DIR, 'asc-web-management', subPath === '/' ? 'index.html' : subPath);
  } else if (urlPath.startsWith('/console')) {
    const subPath = urlPath.slice('/console'.length) || '/';
    filePath = path.join(APPS_DIR, 'asc-web-console', subPath === '/' ? 'index.html' : subPath);
  } else if (urlPath === '/' || urlPath === '/index.html') {
    filePath = path.join(APPS_DIR, 'asc-web-management', 'index.html');
  } else {
    // Try serving from asc-web-management as default
    filePath = path.join(APPS_DIR, 'asc-web-management', urlPath);
  }

  // Security: block path traversal
  if (!filePath.startsWith(APPS_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  serveStatic(filePath, res);
});

server.listen(PORT, () => {
  console.log(`
  ┌───────────────────────────────────────────────┐
  │  ASC Web Server                               │
  │  http://localhost:${String(PORT).padEnd(29)}│
  │                                               │
  │  /management/  Dashboard                      │
  │  /console/     Terminal                       │
  │  /api/run      CLI bridge                     │
  │                                               │
  │  Binary: ${ASC_BIN.padEnd(37)}│
  │  Press Ctrl+C to stop                         │
  └───────────────────────────────────────────────┘
  `);
});
