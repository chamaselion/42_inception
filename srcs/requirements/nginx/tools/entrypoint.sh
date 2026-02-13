#!/bin/sh
set -eu

/usr/src/nginx/tools/generate_cert.sh

echo "[nginx] Starting Nginx with TLS..."
exec nginx -g 'daemon off;'
