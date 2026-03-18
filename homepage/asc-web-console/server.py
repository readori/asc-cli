#!/usr/bin/env python3
"""Lightweight dev server for ASC Web Console. Serves static files and proxies CLI commands."""

import http.server
import json
import os
import shutil
import subprocess
import sys
import urllib.parse

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8420
HOST = "127.0.0.1"

ASC_BIN = shutil.which("asc") or os.path.expanduser("~/.local/bin/asc")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.path.dirname(os.path.abspath(__file__)), **kwargs)

    def do_POST(self):
        if self.path == "/api/run":
            self._handle_run()
        else:
            self.send_error(404)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.send_header("Content-Length", "0")
        self.end_headers()

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _handle_run(self):
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length)) if length else {}
        cmd = body.get("command", "").strip()

        if not cmd:
            self._json_response(400, {"error": "Missing 'command' field"})
            return

        # Security: only allow `asc` commands
        parts = cmd.split()
        if not parts or parts[0] != "asc":
            self._json_response(400, {"error": "Only 'asc' commands are allowed"})
            return

        # Block dangerous shell characters
        dangerous = set(";|&$`\\(){}[]!><\n\r")
        if any(c in dangerous for c in cmd):
            self._json_response(400, {"error": "Command contains disallowed characters"})
            return

        try:
            args = [ASC_BIN] + parts[1:]
            result = subprocess.run(
                args,
                capture_output=True,
                text=True,
                timeout=30,
                env={**os.environ, "NO_COLOR": "1"},
            )
            self._json_response(200, {
                "stdout": result.stdout,
                "stderr": result.stderr,
                "exit_code": result.returncode,
            })
        except FileNotFoundError:
            self._json_response(500, {"error": f"'asc' binary not found at {ASC_BIN}. Build with: swift build"})
        except subprocess.TimeoutExpired:
            self._json_response(504, {"error": "Command timed out (30s limit)"})
        except Exception as e:
            self._json_response(500, {"error": str(e)})

    def _json_response(self, code, data):
        body = json.dumps(data).encode()
        self.send_response(code)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        status = args[1] if len(args) > 1 else ""
        path = args[0] if args else ""
        if "/api/" in str(path):
            print(f"  \033[36mAPI\033[0m {path} \033[33m{status}\033[0m")


if __name__ == "__main__":
    print(f"\n  \033[1;34mASC Web Console\033[0m")
    print(f"  \033[90m{'─' * 36}\033[0m")
    print(f"  Local:   \033[1mhttp://{HOST}:{PORT}\033[0m")
    print(f"  ASC bin: \033[90m{ASC_BIN}\033[0m")
    print(f"  \033[90m{'─' * 36}\033[0m\n")

    server = http.server.HTTPServer((HOST, PORT), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Stopped.")
        server.server_close()
