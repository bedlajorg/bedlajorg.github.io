#!/usr/bin/env bash
# Prints the built Jekyll site (_site) to a PDF with headless Chrome.
#
# Usage: scripts/build-pdf.sh [SITE_DIR] [OUTPUT_PDF]
#   SITE_DIR    directory with the built site (default: _site)
#   OUTPUT_PDF  output file (default: Jan_Bednar_CV.pdf)
#
# Page size and margins come from the @page rule in assets/main.scss.
set -euo pipefail

SITE_DIR="${1:-_site}"
OUTPUT_PDF="${2:-Jan_Bednar_CV.pdf}"
PORT="${PORT:-4321}"
CHROME="${CHROME:-$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser)}"

if [[ ! -f "$SITE_DIR/index.html" ]]; then
  echo "error: $SITE_DIR/index.html not found, build the site first" >&2
  exit 1
fi

# The site links its assets with absolute paths (/assets/...), so it has to be served over HTTP.
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$SITE_DIR" >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT

for _ in $(seq 1 50); do
  curl -sf "http://127.0.0.1:$PORT/" >/dev/null && break
  sleep 0.1
done

"$CHROME" \
  --headless=new \
  --no-sandbox \
  --disable-gpu \
  --hide-scrollbars \
  --no-pdf-header-footer \
  --virtual-time-budget=10000 \
  --print-to-pdf="$OUTPUT_PDF" \
  "http://127.0.0.1:$PORT/" 2>/dev/null

echo "written $OUTPUT_PDF"
