# 🚀 AI Business Mentor 🤖

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Groq_API-000000?style=for-the-badge&logo=openai&logoColor=white" alt="Groq API" />
</div>

<div align="center">
  <h2>🌟 Live Demo: <a href="https://ai-chatting-one.vercel.app/" target="_blank">AI Chatting App</a> 🌟</h2>
</div>

## 📖 Overview

Welcome to the **AI Business Mentor**! This is a state-of-the-art Flutter real-time chat application powered by **Groq (Llama-3.3-70b-versatile)** for lightning-fast AI responses and **Supabase** for robust message persistence. 

This project demonstrates advanced capabilities in building modern cross-platform mobile and web applications, seamlessly integrating third-party AI LLMs with scalable Backend-as-a-Service (BaaS) solutions.

---

## ✨ Key Features

- ⚡ **Ultra-Fast AI Responses**: Integrates the **Groq API** enabling the `llama-3.3-70b-versatile` model with real-time streaming response capabilities.
- 💾 **Real-Time Data Persistence**: Powered by **Supabase**. User and AI conversations are securely stored and loaded instantly upon startup.
- 🌊 **Live Streaming Experience**: Watch the AI think and type in real-time, providing a highly engaging and dynamic user experience.
- 🔄 **Smart Loading & Connection States**: Sophisticated UI states including a "Thinking" indicator while waiting for the first token, and seamless connection verifications for APIs and databases directly from the app bar.
- 🛡️ **Scalable & Secure Architecture**: Written with modern maintainability standards using clean architecture principles and robust environmental guards.

---

## 🛠️ Tech Stack & Architecture

### **Frontend**
- **Framework**: `Flutter 3.x` (Dart 3.10+)
- **State Management**: Reactive Stream Managers (`gemini_stream_manager.dart`) & Local Hive Chat Controllers

### **Backend & AI**
- **Database**: `Supabase` (PostgreSQL)
- **AI Engine**: `Groq Console` (LLaMA 3.3)
- **Security**: Row Level Security (RLS) configured in Supabase.

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites
- Flutter SDK 3.24
- A [Supabase](https://supabase.com) project
- A [Groq](https://console.groq.com) API key

### Installation

**1. Clone the repository and install dependencies**
```bash
cd examples/flyer_chat
flutter pub get
```

**2. Configure Environment Variables**
Build the bridge between the app and the cloud services. Make a copy of the `.env.example`:
```bash
cp .env.example .env
```
Inside your `.env` file, configure your keys:
- `SUPABASE_URL`: Your Supabase Project API URL.
- `SUPABASE_ANON_KEY`: Your Supabase Anon/Public Key.
- `GROQ_API_KEY`: Your Groq API Key.

**3. Setup the Supabase Database**
Run the following SQL snippet in your Supabase SQL Editor to prepare your messages table:
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
*(Ensure RLS policies allow for SELECT and INSERT operations)*

**4. Run the Application**
```bash
flutter run
```

---

## 🏗️ Project Architecture Overview

| Path | Purpose & Mechanics |
|------|---------------------|
| 🚀 `lib/main.dart` | The beating heart of the app. Handles Supabase init, environment guards, and routing. |
| 💬 `lib/gemini.dart` | The UI Engine. Manages the chat interface, Groq stream orchestration, and Supabase save triggers. |
| 🔌 `lib/groq_client.dart` | The Brain Connection. Connects to Groq API using `streamChat()` and `buildMessages()`. |
| 🗄️ `lib/supabase_messages.dart` | The Memory. Handles CRUD operations like `fetchMessages()` and `insertMessage()`. |
| 🚦 `lib/connection_check.dart` | The Guard. Failsafe mechanisms like `verifySupabase()` and `verifyGroq()`. |

---

## 📚 Detailed Documentation
Dive deeper into the sub-modules:
- 📖 [**SETUP Guide**](docs/SETUP.md): Step-by-step intricate backend setup instructions.
- 🔌 [**API Documentation**](docs/API.md): Breakdown of the Groq Client and Supabase bridging mechanisms.
- 🤝 [**Contributing Guide**](CONTRIBUTING.md): Become a part of the journey.

---
<div align="center">
  <i>Crafted with passion to bridge human interaction with cutting-edge artificial intelligence.</i>
</div>
