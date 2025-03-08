# API reference

Overview of the main modules used by the AI Business Mentor app. All paths are relative to `examples/flyer_chat/lib/`.

---

## Groq client (`groq_client.dart`)

Uses the [Groq OpenAI-compatible API](https://console.groq.com/docs/openai) for chat completions with streaming.

### `buildMessages(history, userContent)`

Builds the request body `messages` array for the chat API.

- **`history`** – `List<Map<String, String>>` with keys `'role'` (`'user'` or `'assistant'`) and `'content'`.
- **`userContent`** – The latest user message text.

**Returns:** `List<Map<String, String>>` (history plus one `role: 'user', content: userContent`).

### `streamChat(apiKey, messages)`

Calls `POST https://api.groq.com/openai/v1/chat/completions` with `stream: true` and parses SSE.

- **`apiKey`** – Groq API key (e.g. from `.env`).
- **`messages`** – Same shape as returned by `buildMessages`.

**Returns:** `Stream<String>` of content deltas (no batching; each event is one or more characters).

**Throws:** On non-200 HTTP or when the response stream cannot be read. Check `response.statusCode` and body for API errors.

**Model used:** `llama-3.3-70b-versatile` (constant in this file).

---

## Supabase messages (`supabase_messages.dart`)

Reads and writes chat messages in the Supabase `messages` table. Expects columns: `id`, `created_at`, `text`, `is_ai`, `image_url`, `author_id`.

### `fetchMessages()`

Loads all rows from `messages` ordered by `created_at` ascending.

**Returns:** `Future<List<Message>>` (flutter_chat_core `TextMessage` or `ImageMessage`).  
`author_id` is mapped to `authorId`; `image_url` non-null implies `ImageMessage` with `source: image_url`.

### `insertMessage({ id, text, isAi, imageUrl, authorId })`

Inserts one row into `messages`.

- **`id`** – Optional. If omitted, Supabase generates a UUID.
- **`text`** – Message body (required).
- **`isAi`** – `true` for assistant, `false` for user.
- **`imageUrl`** – Optional.
- **`authorId`** – e.g. `'me'` or `'agent'`.

**Returns:** `Future<Map<String, dynamic>>` (inserted row, including `id` and `created_at`).

---

## Connection check (`connection_check.dart`)

Verifies Supabase and Groq configuration and connectivity. Used by the in-app “Check connection” action.

### `verifySupabase()`

Checks that env has `SUPABASE_URL` and `SUPABASE_ANON_KEY` and that `Supabase.instance.client` is usable (e.g. `auth.currentSession` access).

**Returns:** `Future<bool>` – `true` if env is set and client is initialized.

### `verifyGroq()`

Sends a single non-streaming chat completion to Groq (`Say OK only.`) using `GROQ_API_KEY` from env.

**Returns:** `Future<bool>` – `true` if the key is set and the API returns a non-empty content response.

### `checkConnections()`

Runs both checks.

**Returns:** `Future<Map<String, bool>>` with keys `'Supabase'` and `'Groq'` and values `true`/`false`.

---

## Chat screen flow (reference)

- **Startup:** `fetchMessages()` → `setMessages()` on the chat controller.
- **User send:** `insertMessage(..., isAi: false)` → add user message to controller → `streamChat(...)`.
- **Stream chunk:** Append to stream message via `GeminiStreamManager.addChunk`.
- **Stream done:** `insertMessage(..., isAi: true)` with full text → `completeStream(streamId)`.

See [README](README.md#flow) and [SETUP](SETUP.md) for full flow and setup.
