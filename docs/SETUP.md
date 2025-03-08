# Setup guide

Step-by-step setup for running the AI Business Mentor app locally.

## 1. Clone and open the app

```bash
git clone <repository-url>
cd Gemini-Chatting/examples/flyer_chat
flutter pub get
```

## 2. Supabase project

1. Go to [Supabase](https://supabase.com) and create a project (or use an existing one).
2. In the dashboard, open **Project Settings** → **API**.
3. Note:
   - **Project URL** → use as `SUPABASE_URL`
   - **anon / public key** → use as `SUPABASE_ANON_KEY`

## 3. Supabase `messages` table

In the Supabase **SQL Editor**, run:

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

Optional: if Row Level Security (RLS) is enabled, add policies so the anon key can read and insert:

```sql
alter table messages enable row level security;

create policy "Allow anon select"
  on messages for select
  using (true);

create policy "Allow anon insert"
  on messages for insert
  with check (true);
```

Adjust policies if you later add auth and want to restrict by user.

## 4. Groq API key

1. Go to [Groq Console](https://console.groq.com).
2. Create or sign in to an account and create an API key.
3. Copy the key (e.g. `gsk_...`) for the next step.

## 5. Environment file

In `examples/flyer_chat`:

```bash
cp .env.example .env
```

Edit `.env` and set:

| Variable             | Where to get it                    |
|----------------------|------------------------------------|
| `SUPABASE_URL`       | Supabase → Project Settings → API |
| `SUPABASE_ANON_KEY` | Same page (anon/public key)        |
| `GROQ_API_KEY`       | Groq Console → API keys           |

Example:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
GROQ_API_KEY=gsk_...
```

Do not commit `.env`; it is listed in `.gitignore`.

## 6. Run the app

From `examples/flyer_chat`:

```bash
flutter run
```

- If `GROQ_API_KEY` is set, the app opens on the chat screen.
- If it is missing, the app shows a message to set `GROQ_API_KEY` and a connection check button.

Use the app bar **connection check** (link icon) to verify Supabase and Groq.

## Troubleshooting

- **Supabase “Failed”** – Check URL and anon key; ensure the `messages` table exists and RLS policies allow anon access if RLS is on.
- **Groq “Failed”** – Check the API key and that the Groq endpoint is reachable from your network.
- **Empty or no chat** – Ensure `.env` is in `examples/flyer_chat` and that the app’s assets include `.env` (see `pubspec.yaml` → `assets`).
