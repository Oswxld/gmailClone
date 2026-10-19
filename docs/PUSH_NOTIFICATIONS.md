# Android push notifications — Firebase + Supabase (Mail Demo)

This setup delivers **clearly labeled demo notifications** to Android devices for authenticated accounts. It does not send emails, impersonate Gmail or financial services, or create real verification codes.

## Architecture

```text
Signed-in Android app (Flutter)
  -> Firebase Messaging token (per device)
  -> Dwellio Supabase: public.g_device_tokens (owner_id => public.profiles.id)

An authenticated demonstration action
  -> public.g_messages INSERT
  -> public.g_notifications INSERT (owner_id, message_id, title: "Demo: ...")
  -> database webhook (INSERT only; X-G-Push-Secret)
  -> Supabase Edge Function g-mail-push
  -> Google Firebase Cloud Messaging HTTP v1
  -> Android OS notification (background/terminated)
  -> tap -> in-app message via message_id
```

This same Supabase project also runs Dwellio, but no Dwellio-specific tables need modification. **Do not use `public.notifications`**, which belongs to Dwellio; use `public.g_notifications`.

## Current status

- **Done in Supabase:** created `g_device_tokens` with ownership RLS and verified its policies.
- **Done in GitHub:** added the Firebase SDK dependencies, feature-first token repository and registration service, and `supabase/functions/g-mail-push/index.ts` (source only).
- **Still required:** Firebase project setup; Android Firebase configuration; Flutter initialization and lifecycle hook to call `FcmPushService.start`; function deployment with secrets; webhook creation; and Android device testing. **Real push is not working yet.**

## Step 1 — Create a Firebase project (you do this)

1. Go to https://console.firebase.google.com/ and create a Firebase project, for example `mail-demo-push`. This is distinct from your existing Supabase Dwellio project.
2. Choose **Add app** -> Android.
3. In this repo, `android/app/build.gradle.kts` currently has `applicationId = "com.example.gmail_clone"`. Register **exactly `com.example.gmail_clone`** unless we agree to change the app ID *before* registering Firebase.
4. The Firebase Android app **nickname** can be `Mail Demo`.
5. Keep a note of the resulting **Firebase project ID**. We will need it on the server side later.
6. Use a real Android device with Google Play services or an Android emulator image with Google Play support.

## Step 2 — Configure FlutterFire on your Windows computer

From your Flutter project's root, install the CLIs if needed:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

Then ensure you are on the current development branch with the committed Firebase dependencies, and run:

```powershell
flutter pub get
flutterfire configure --platforms=android
```

Select your newly created Firebase project. FlutterFire generates `lib/firebase_options.dart`; for Android, ensure `android/app/google-services.json` is installed/configured and Google Services Gradle plugin is applied following the CLI output. Re-run `flutterfire configure` after adding Firebase plugins if the CLI requests it.

**Important:** After configuration, commit and push the generated **public Firebase app config** and any Android Gradle configuration changes to the same GitHub development branch so we can inspect them and wire up the Dart entrypoint. Do **not** push Firebase service-account credentials.

```powershell
git status
git add lib/firebase_options.dart android/app/build.gradle.kts android/settings.gradle.kts android/app/google-services.json
git commit -m "chore: configure Firebase Android app"
git push origin feat/mail-demo-foundation
```

Only stage files that exist or changed; the CLI can generate different files depending on installed versions.

## Step 3 — Wire the signed-in Flutter app (we will do after the config is pushed)

The following source files are already prepared, not yet activated:

- `lib/features/notifications/domain/repositories/push_token_repository.dart`
- `lib/features/notifications/data/repositories/supabase_push_token_repository.dart`
- `lib/features/notifications/presentation/services/fcm_push_service.dart`

We will add `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` to `main.dart` using the generated options. Then the signed-in app will:

1. Ask Android 13+ for notification permission using `requestPermission`.
2. Call `getToken()` and save the token to `g_device_tokens`, owned by `auth.uid()`.
3. Update the database on `onTokenRefresh`.
4. Listen to `FirebaseMessaging.onMessage` (foreground), `onMessageOpenedApp` (background notification tap), and `getInitialMessage()` (cold-start tap).
5. Use push payload `data.message_id` to retrieve the existing `g_messages` message via ownership-controlled Supabase queries before navigating to `EmailDetailsScreen`. If signed out, open login first.
6. Delete the registered token on sign-out while the Supabase session still exists.

**Do not register FCM tokens for guest/demo mode:** `g_device_tokens.owner_id` must be the real authenticated user. Never store FCM device tokens in `public.profiles` because that table is shared with Dwellio and tokens are per-device.

## Step 4 — Put the server credentials in Supabase Edge Function Secrets

In the Firebase console:

1. Project Settings -> **Service accounts** -> **Generate new private key**. Download the service-account JSON and keep it **private**. The server uses this to authorize FCM HTTP v1 calls.
2. In your Dwellio Supabase project, go to **Edge Functions -> Secrets**.
3. Create `G_FIREBASE_SERVICE_ACCOUNT_JSON` with the **entire JSON document as its value**, and create a separate random high-entropy `G_PUSH_WEBHOOK_SECRET` (at least 32 random bytes).
4. Do **not** put either secret in Flutter's root `.env`, in GitHub, or in this chat. The Flutter `.env` contains only client publishable configuration.

Supabase supplies project credentials to Edge Functions. The function source uses Supabase's server-only service role/secret and keeps those credentials away from Flutter clients.

## Step 5 — Deploy the Edge Function

Function source is already in the repository:

`supabase/functions/g-mail-push/index.ts`

We can deploy this through the Supabase connector after secrets have been configured, or you can deploy using Supabase CLI:

```powershell
supabase login
supabase link --project-ref tspywzqhbrmuwimkvnae
supabase functions deploy g-mail-push --no-verify-jwt
```

`--no-verify-jwt` is necessary for the database webhook request, **not** for public access: the Edge Function rejects requests unless the header `X-G-Push-Secret` equals the server-only `G_PUSH_WEBHOOK_SECRET`.

The function *re-reads* the notification row from `g_notifications` and sends only to device tokens registered to that row's `owner_id`. It always displays the application identity **Mail Demo**.

## Step 6 — Configure the database webhook

In **Supabase -> Database -> Webhooks** create:

| Setting | Value |
|---|---|
| Webhook name | `g_mail_push_on_insert` |
| Schema | `public` |
| Table | `g_notifications` |
| Event | **INSERT** only |
| Destination | Edge Function `g-mail-push` |
| Method | POST |
| Custom HTTP header | `X-G-Push-Secret: <same random secret>` |

Do not enable this webhook for Dwellio's `notifications` table. The function rejects events from any other table.

## Step 7 — Test end-to-end

1. Start the Android app with your Supabase root `.env` configured; log in with an account created in the existing Dwellio Auth project.
2. Accept the Android notification permission request.
3. Verify a registration exists for your account in `g_device_tokens`. Do not copy/paste device tokens into chat or issues.
4. With the app in the **background**, hold the demo developer control (before backgrounding) and generate a test message, or insert a demonstration notification from an authorized server-side workflow. The `g_notifications` INSERT webhook should send an Android notification.
5. Tap it: the app should open the matching message, preserving ownership rules.
6. Test with app in the foreground (Flutter's in-app notification banner is appropriate) and when the app is terminated.

A Firebase test notification sent from the Firebase console can verify device delivery *before* configuring the Supabase webhook. Those console messages won't have our `data.message_id`, so tapping them may just open the app, not a particular email.

## Key notes

- Firebase Cloud Messaging is a push transport, **not an email service**. A row in `g_messages` is an in-app message; it is not a Gmail email.
- Android notification badges and UI style depend on OS version and notification settings.
- A foreground FCM notification does **not** automatically show an OS notification; the current in-app banner is separate.
- For real device notification taps, the app must implement both `onMessageOpenedApp` and `getInitialMessage`.
- Do not use Google's or a trading company's branding to present demo verification codes as genuine.
- The new `g_device_tokens` table uses its own RLS and does not change Dwellio's existing policies.

## Official docs

- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- Firebase Messaging for Flutter: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- Firebase receive handlers: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- Supabase push with FCM: https://supabase.com/docs/guides/functions/examples/push-notifications?platform=fcm
