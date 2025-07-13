#!/usr/bin/env bash
# Build Flutter web and create .vercel/output in Build Output API v3 format.
# Usage: From project root:  bash scripts/build-vercel-output.sh

set -e
cd "$(dirname "$0")/.."

echo "==> Flutter web build..."
cd examples/flyer_chat
flutter pub get
flutter build web
cd ../..

echo "==> Creating .vercel/output (v3)..."
rm -rf .vercel/output
mkdir -p .vercel/output/static
cp -r examples/flyer_chat/build/web/* .vercel/output/static/

mkdir -p .vercel/output/functions/api/stream-chat.func
cp api/stream-chat.js .vercel/output/functions/api/stream-chat.func/
echo '{"runtime":"nodejs20.x","launcherType":"Nodejs","handler":"stream-chat.js"}' > .vercel/output/functions/api/stream-chat.func/.vc-config.json

cat > .vercel/output/config.json << 'EOF'
{
  "version": 3,
  "routes": [
    { "handle": "filesystem" },
    { "src": "/(.*)", "dest": "/index.html" }
  ]
}
EOF

echo "==> .vercel/output ready. Run: vercel deploy --prebuilt"
