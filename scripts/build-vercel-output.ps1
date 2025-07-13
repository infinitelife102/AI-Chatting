# Build Flutter web and create .vercel/output in Build Output API v3 format.
# Usage: From project root:  .\scripts\build-vercel-output.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "==> Flutter web build..."
Set-Location examples\flyer_chat
flutter pub get
flutter build web
Set-Location ..\..

Write-Host "==> Creating .vercel/output (v3)..."
if (Test-Path .vercel\output) { Remove-Item -Recurse -Force .vercel\output }
New-Item -ItemType Directory -Force -Path .vercel\output\static | Out-Null
Copy-Item -Path examples\flyer_chat\build\web\* -Destination .vercel\output\static -Recurse -Force

New-Item -ItemType Directory -Force -Path .vercel\output\functions\api\stream-chat.func | Out-Null
Copy-Item -Path api\stream-chat.js -Destination .vercel\output\functions\api\stream-chat.func\ -Force
Set-Content -Path .vercel\output\functions\api\stream-chat.func\.vc-config.json -Value '{"runtime":"nodejs20.x","launcherType":"Nodejs","handler":"stream-chat.js"}'

$config = @'
{
  "version": 3,
  "routes": [
    { "handle": "filesystem" },
    { "src": "/(.*)", "dest": "/index.html" }
  ]
}
'@
Set-Content -Path .vercel\output\config.json -Value $config -Encoding UTF8

Write-Host "==> .vercel/output ready. Run: vercel deploy --prebuilt"
