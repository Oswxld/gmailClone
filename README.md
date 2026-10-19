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

## First run

```sh
flutter pub get
flutter run
```

Press **Explore without signing in** to inspect the UI without a Supabase connection.

## Connected Supabase authentication

This app uses the existing project URL `https://tspywzqhbrmuwimkvnae.supabase.co` and requires its **publishable** (client-safe) API key at build time. Retrieve the key from Supabase Dashboard → Project Settings → API Keys → publishable key.

```sh
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

You can also create an untracked local file `config.local.json`:

```json
{"SUPABASE_PUBLISHABLE_KEY":"YOUR_PUBLISHABLE_KEY"}
```

Then run:

```sh
flutter run --dart-define-from-file=config.local.json
```

Do not commit any service-role or secret API keys. The publishable key does not bypass RLS.

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
