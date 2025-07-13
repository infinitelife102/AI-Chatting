#!/usr/bin/env bash
# Build .vercel/output locally and deploy to Vercel (Prebuilt, production).
# Usage: From project root:  bash scripts/deploy-vercel.sh
# (Use this script on Git Bash instead of .ps1.)

set -e
cd "$(dirname "$0")/.."

echo "==> Building .vercel/output (Flutter + v3 format)..."
bash scripts/build-vercel-output.sh

echo "==> Vercel deploy (prebuilt, production)..."
vercel deploy --prebuilt --prod

echo "==> Deploy complete. Check your production domain (e.g. ai-chatting-one.vercel.app)."
