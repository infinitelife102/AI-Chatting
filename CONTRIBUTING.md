# Contributing to AI Business Mentor

Thank you for considering contributing. This document covers how to set up the project and submit changes.

## Code of conduct

Be respectful and constructive. Report issues and suggest improvements in a clear, professional way.

## How to contribute

- **Bug reports** – Open an issue with steps to reproduce, expected vs actual behavior, and your environment (Flutter version, OS).
- **Feature ideas** – Open an issue or discussion describing the use case and proposed solution.
- **Documentation** – Fix typos or clarify setup/API docs.
- **Code** – Follow the workflow below.

## Development setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x, Dart 3.10+)
- A [Supabase](https://supabase.com) project and [Groq](https://console.groq.com) API key (see [README](README.md#setup))

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Gemini-Chatting.git
   cd Gemini-Chatting
   ```

2. Open the app package and install dependencies:
   ```bash
   cd examples/flyer_chat
   flutter pub get
   ```

3. Configure environment:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `GROQ_API_KEY`. Create the `messages` table in Supabase as described in the [README](README.md#3-supabase-table).

4. Run the app:
   ```bash
   flutter run
   ```

## Code style

- Follow the project’s `analysis_options.yaml` / lint rules.
- Run `flutter analyze` and fix reported issues.
- Format before committing: `dart format .` or your IDE’s format command.

## Pull request process

1. Create a branch from `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b your-branch-name
   ```

2. Make your changes and add or update tests if applicable.

3. Run checks:
   ```bash
   flutter analyze
   flutter test
   ```

4. Commit with a clear message (e.g. `fix: connection check when key is empty`, `docs: update SETUP`).

5. Push and open a Pull Request against `main`. Describe what changed and why; link any related issues.

6. Address review feedback. Once approved, maintainers will merge.

## License

By contributing, you agree that your contributions are licensed under the same terms as the project (see [LICENSE](LICENSE)).
