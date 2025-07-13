# Build .vercel/output locally and deploy to Vercel (Prebuilt, production).
# Usage: From project root in PowerShell:  .\scripts\deploy-vercel.ps1
# On Git Bash use:  bash scripts/deploy-vercel.sh

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "==> Building .vercel/output (Flutter + v3 format)..."
& $PSScriptRoot\build-vercel-output.ps1

Write-Host "==> Vercel deploy (prebuilt, production)..."
vercel deploy --prebuilt --prod

Write-Host "==> Deploy complete. Check your production domain (e.g. ai-chatting-one.vercel.app)."
