#!/usr/bin/env bash
# Serves the web app on your Mac so your iPhone can reach it over Wi-Fi.
set -euo pipefail
cd "$(dirname "$0")"
PORT="${1:-8080}"
IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")
echo
echo "  Getting My Pink Back is being served."
echo
echo "  On this Mac:     http://localhost:$PORT"
echo "  On your iPhone:  http://$IP:$PORT     (same Wi-Fi network)"
echo
echo "  In Safari on the iPhone, open that address, then Share -> Add to Home Screen."
echo "  Ctrl-C to stop."
echo
exec python3 -m http.server "$PORT" --bind 0.0.0.0
