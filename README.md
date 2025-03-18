# AI Business Mentor

A Flutter chat app that uses **Groq** (Llama) for AI responses and **Supabase** for message persistence. Messages are stored in Supabase and streamed in real time.

## Features

- **Groq API** – Chat completions with `llama-3.3-70b-versatile`, streaming responses
- **Supabase** – Persist user and AI messages; load history on startup
- **Real-time streaming** – AI replies appear incrementally as they are generated
- **Loading state** – “Thinking” indicator while waiting for the first token
- **Connection check** – Verify Supabase and Groq from the app bar

## Prerequisites

- Flutter 3.x (Dart 3.10+)
- [Supabase](https://supabase.com) project
- [Groq](https://console.groq.com) API key

## Setup

### 1. Clone and install

```bash
cd examples/flyer_chat
flutter pub get
```

### 2. Environment variables

Copy the example env file and set your keys:

```bash
cp .env.example .env
```

Edit `.env`:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Project URL from [Supabase Dashboard](https://supabase.com/dashboard) → Project Settings → API |
| `SUPABASE_ANON_KEY` | Anon/public key from the same API settings |
| `GROQ_API_KEY` | API key from [Groq Console](https://console.groq.com) |

### 3. Supabase table

Create the `messages` table in the SQL Editor:

```sql
create table messages (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamptz default now(),
  text text,
  is_ai boolean default false,
  image_url text,
  author_id text
);
```

If you use Row Level Security (RLS), add policies so the anon key can `SELECT` and `INSERT` on `messages` (e.g. for your auth model).

### 4. Run

```bash
flutter run
```

If `GROQ_API_KEY` is set in `.env`, the app opens directly to the chat screen. Otherwise it shows a setup prompt and a connection check button.

## Flow

1. **Startup** – Load messages from Supabase and show them in the chat.
2. **User sends a message** – Save to Supabase (`is_ai: false`), add to UI, then call Groq.
3. **Groq streaming** – A loading bubble appears; as chunks arrive, the same bubble updates in real time.
4. **Stream done** – Full AI reply is saved to Supabase (`is_ai: true`) and the message is finalized.

## Project structure (relevant parts)

| Path | Purpose |
|------|---------|
| `lib/main.dart` | App entry, Supabase init, env guard, home = chat screen |
| `lib/gemini.dart` | Chat UI, Groq streaming, Supabase save on send/complete |
| `lib/groq_client.dart` | Groq API client: `streamChat()`, `buildMessages()` |
| `lib/supabase_messages.dart` | Supabase: `fetchMessages()`, `insertMessage()` |
| `lib/connection_check.dart` | `verifySupabase()`, `verifyGroq()`, `checkConnections()` |
| `lib/hive_chat_controller.dart` | Local chat state (used with Supabase sync) |
| `lib/gemini_stream_manager.dart` | Streaming message state (loading → chunks → complete) |

## Documentation

- **[docs/SETUP.md](docs/SETUP.md)** – Step-by-step setup (Supabase, Groq, `.env`, table, RLS).
- **[docs/API.md](docs/API.md)** – Groq client, Supabase messages, and connection check APIs.
- **[CONTRIBUTING.md](CONTRIBUTING.md)** – How to contribute and open pull requests.

## Environment & tooling

- **SDK:** Flutter 3.24 (Dart 3.5+)
- **Gradle:** 8.7 with JVM Toolchain (JDK 21)
- **Notable fixes:** Declarative Gradle plugin usage, JVM target alignment, `coreLibraryDesugaring` for legacy support
