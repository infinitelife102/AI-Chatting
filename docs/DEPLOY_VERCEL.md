# Deploying to Vercel (Local Prebuilt Only)

This project deploys to Vercel using **local build + Prebuilt deploy** only. Flutter is not built on Vercel; you build on your machine and upload the output.

---

## Quick start

1. **One-time setup:** Link the repo to a Vercel project and set environment variables (see below).
2. **Deploy:** From the project root run:
   - **Git Bash / macOS / Linux:** `bash scripts/deploy-vercel.sh`
   - **Windows PowerShell:** `.\scripts\deploy-vercel.ps1`

The script builds the Flutter web app, creates `.vercel/output` in Build Output API v3 format, and runs `vercel deploy --prebuilt --prod`. Your production domain (e.g. `ai-chatting-one.vercel.app`) is updated.

---

## One-time: Vercel project setup

1. Log in at [vercel.com](https://vercel.com) → **Add New… → Project** → Import the **AI-Chatting** repo.
2. Leave **Root Directory** empty. Set **Framework** to **Other**.
3. In **Environment Variables**, add:

   | Name | Value |
   |------|--------|
   | `SUPABASE_URL` | Your Supabase project URL |
   | `SUPABASE_ANON_KEY` | Supabase anon (public) key |
   | `GROQ_API_KEY` | Your Groq API key |

4. Link the project from your machine (once):

   ```bash
   npm i -g vercel
   cd /path/to/AI-Chatting
   vercel link
   ```

   Select the project when prompted.

---

## Local requirements

- **`.env`** in `examples/flyer_chat/` with `SUPABASE_URL` and `SUPABASE_ANON_KEY` (used at build time; do not commit). `GROQ_API_KEY` is not needed in the client for web.
- **Flutter** installed and on your PATH.

---

## What the deploy script does

1. **`scripts/build-vercel-output.sh`** (or `.ps1` on Windows):
   - Runs `flutter pub get` and `flutter build web` in `examples/flyer_chat`.
   - Copies `examples/flyer_chat/build/web/*` into `.vercel/output/static/`.
   - Copies `api/stream-chat.js` into `.vercel/output/functions/api/stream-chat.func/` with a `.vc-config.json` (Node.js serverless).
   - Writes `.vercel/output/config.json` (Build Output API v3, SPA routes).

2. **`vercel deploy --prebuilt --prod`**
   - Uploads `.vercel/output` and updates **Production**. No build runs on Vercel.

---

## Preview vs production

- **`scripts/deploy-vercel.sh`** (and the PowerShell script) runs **`vercel deploy --prebuilt --prod`**, so each run updates **Production** (e.g. `ai-chatting-one.vercel.app`).
- To deploy only to **Preview** (without updating production), run manually after building:
  ```bash
  bash scripts/build-vercel-output.sh
  vercel deploy --prebuilt
  ```
  Use the Preview URL printed in the terminal.

---

## API keys and security

| Key | Where it is used | In client bundle? |
|-----|------------------|--------------------|
| **SUPABASE_URL**, **SUPABASE_ANON_KEY** | Flutter app (from local `.env` at build time). | Yes (anon key is designed to be public; use RLS for data protection.) |
| **GROQ_API_KEY** | Only in Vercel serverless function `api/stream-chat.js` (Vercel env vars). | No. |

The web app calls `/api/stream-chat` on the same origin; the serverless function uses `GROQ_API_KEY` to call Groq. Git push does not trigger a deploy; you must run the deploy script locally.

---

## Deployment layout

```
[Browser] ←→ [Vercel]
              ├── Static files (Flutter web) from .vercel/output/static
              └── /api/stream-chat (serverless) → Groq API (GROQ_API_KEY on server only)
```

---

## Project layout (reference)

- **`api/stream-chat.js`** – Serverless proxy: accepts `messages`, streams from Groq, streams response back. Uses `GROQ_API_KEY` from Vercel env.
- **`vercel.json`** – No install/build commands; only `outputDirectory` and rewrites for reference. Actual deploy uses `.vercel/output` from the script.
- **`scripts/build-vercel-output.sh`** / **`.ps1`** – Build Flutter web and build `.vercel/output` (v3).
- **`scripts/deploy-vercel.sh`** / **`.ps1`** – Run build script then `vercel deploy --prebuilt --prod`.
