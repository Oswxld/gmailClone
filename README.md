# Mail Demo — Android Flutter prototype

An **independent, clearly identified demonstration** of an Android mail-reading interface, based on the supplied Stitch visual references. It is not Gmail, is not affiliated with Google or Deriv, and does not receive real email or authorize transactions.

## Implemented
- Flutter-native inbox with sample messages, sender avatars, Primary/Promotions/Social/Updates cards, compose and bottom navigation styling
- Email-reading details with back navigation and dedicated **test-only** verification and security-alert layouts
- A three-second press-and-hold on the account avatar opens developer controls: change its letter, trigger an in-app test notification, or sign out
- Email/password sign-in/sign-up using **the existing Dwellio Supabase project**, reusing `public.profiles` and Supabase Auth
- Mail-only tables prefixed `g_` — `g_messages`, `g_notifications`, and `g_user_settings`
- Feature-first pragmatic Clean Architecture: domain models and repository contracts, data repositories, Riverpod `AsyncValue` providers, presentation widgets
- Guest mode without Supabase configuration for UI development

## First run — root .env

Configuration now comes from a root `.env` file, loaded by `flutter_dotenv` when the app starts. **No `--dart-define` is needed.**

1. Switch to this branch and create your local env file from the checked-in template:

   **PowerShell (Windows):**

   ```powershell
   Copy-Item .env.example .env
   ```

   **macOS / Linux / Git Bash:**

   ```sh
   cp .env.example .env
   ```

2. Open **`.env`** (beside `pubspec.yaml`) and add your Dwellio Supabase **publishable** key:

   ```dotenv
   SUPABASE_URL=https://tspywzqhbrmuwimkvnae.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_ACTUAL_KEY
   ```

   Get the actual key at Supabase Dashboard → Dwellio → Project Settings → API Keys. Do not copy the literal placeholder above.

3. Run normally:

   ```sh
   flutter pub get
   flutter run
   ```

If the publishable key is left blank, you can still open the app using **Explore without signing in**, but live Supabase authentication will remain disabled.

The `.env` file is gitignored. `.env.example` is safe to commit because it contains no keys. Since Flutter bundles env assets into APKs, **never put service_role, sb_secret, FCM server credentials, or other secrets in .env**. A Supabase publishable key and project URL are public client configuration; row-level policies are what protect data. After changing `.env`, fully restart the app (not just hot reload).

## Developer controls

Hold the purple **O** avatar for **3 seconds**. The resulting panel allows:
- Changing the single avatar letter (A–Z). Signed-in changes persist in `g_user_settings`.
- **Generate a test notification**, which adds a clearly labeled demonstration message and an associated `g_notifications` record for the signed-in account. In guest mode it is in-memory only.
- Leaving the guest demo or signing out of Supabase.

The notification card shown while the app is open is an **in-app preview**, not a Firebase Cloud Messaging system push. FCM and Android 13+ notification permission are **not configured yet**. This prototype never sends official-looking Gmail/Deriv notifications and does not issue genuine financial verification codes.

## Sharing a backend with Dwellio

Supabase Auth and `public.profiles` are shared with Dwellio. No Dwellio tables were modified. Mail data belongs only to the corresponding authenticated user through dedicated `g_` tables and row-level policies. Sample messages are inserted once per account using `(owner_id, demo_key)` uniqueness, so refreshing doesn't duplicate the seed data.

## Development

```sh
flutter analyze
flutter test
```

The project was edited remotely through GitHub; the authoring environment did not have the Flutter SDK installed, so run these commands locally and report compiler failures for fixes. `flutter pub get` will update `pubspec.lock`; commit that updated lockfile.

## Next milestones

Compare Android emulator screenshots against the supplied Stitch HTML for exact padding, typography, icons, and colors. When ready, implement opt-in Firebase Cloud Messaging for **demo-branded** notifications, add device-token registration, and open the relevant test message on notification tap.
