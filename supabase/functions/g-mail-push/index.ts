// Mail Demo: insert-only g_notifications webhook -> Firebase Cloud Messaging.
//
// This function is not a public send-anywhere API. The database webhook must
// include X-G-Push-Secret, matching the secret in Supabase Edge Functions.
// Firebase service-account JSON is stored ONLY in Supabase Secrets.
//
// Required secrets:
// G_PUSH_WEBHOOK_SECRET
// G_FIREBASE_SERVICE_ACCOUNT_JSON
//
// The function uses the managed SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY
// (or modern SUPABASE_SECRET_KEYS) provided by Supabase.
import { createClient } from 'npm:@supabase/supabase-js@2';
import { JWT } from 'npm:google-auth-library@9';

interface DatabasePayload {
  type?: string;
  table?: string;
  schema?: string;
  record?: { id?: string };
}

interface FirebaseAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

function response(body: object, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function getSupabaseSecret(): string | undefined {
  const legacy = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (legacy) return legacy;
  try {
    const modern = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') ?? '{}');
    return modern.default;
  } catch {
    return undefined;
  }
}

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return response({ error: 'Method not allowed' }, 405);
  }
  const expectedSecret = Deno.env.get('G_PUSH_WEBHOOK_SECRET');
  if (!expectedSecret ||
      request.headers.get('x-g-push-secret') !== expectedSecret) {
    return response({ error: 'Unauthorized' }, 401);
  }

  let payload: DatabasePayload;
  try {
    payload = await request.json();
  } catch {
    return response({ error: 'Invalid JSON' }, 400);
  }

  if (payload.type !== 'INSERT' ||
      payload.schema !== 'public' ||
      payload.table !== 'g_notifications') {
    return response({ error: 'Unsupported webhook event' }, 400);
  }
  const id = payload.record?.id;
  if (!id || !/^[0-9a-fA-F-]{36}$/.test(id)) {
    return response({ error: 'Missing notification ID' }, 400);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseSecret = getSupabaseSecret();
  const firebaseJson = Deno.env.get('G_FIREBASE_SERVICE_ACCOUNT_JSON');
  if (!supabaseUrl || !supabaseSecret || !firebaseJson) {
    return response({ error: 'Server not configured' }, 503);
  }

  let firebase: FirebaseAccount;
  try {
    firebase = JSON.parse(firebaseJson);
  } catch {
    return response({ error: 'Bad server credential configuration' }, 503);
  }
  if (!firebase.project_id || !firebase.client_email ||
      !firebase.private_key) {
    return response({ error: 'Incomplete server credential configuration' }, 503);
  }

  const db = createClient(supabaseUrl, supabaseSecret, {
    auth: { persistSession: false },
  });

  // Re-read the notification from the database. Webhook payload content
  // is never trusted as the target or display text.
  const { data: notification, error: notificationError } = await db
    .from('g_notifications')
    .select('id,owner_id,message_id,title,body')
    .eq('id', id)
    .maybeSingle();

  if (notificationError) {
    return response({ error: 'Notification lookup failed' }, 500);
  }
  /////////
  /////////
  ////////
  //////////
  ////////////
  ////////////
  ///////////////
  /////////////
  //////////////
  /////////////
  ///////////
  /////////////
  ///////////
  //////////////
  /////////////
  ///////////////


  ////////////////
  ///////////////
  if (!notification || !notification.message_id) {
    return response({ error: 'Notification has no linked email' }, 404);
  }

  // Source email must exist and belong to the notification recipient.
  // Use actual message fields rather than an old fixed test title.
  const { data: mail, error: mailError } = await db
    .from('g_messages')
    .select('id,sender_name,subject,preview,body')
    .eq('id', notification.message_id)
    .eq('owner_id', notification.owner_id)
    .maybeSingle();

  if (mailError) {
    return response({ error: 'Email lookup failed' }, 500);
  }
  if (!mail) {
    return response({ error: 'Linked email not found' }, 404);
  }

  const { data: registrations, error: tokenError } = await db
    .from('g_device_tokens')
    .select('fcm_target')
    .eq('owner_id', notification.owner_id)
    .order('last_seen_at', { ascending: false })
    .limit(10);

  if (tokenError) {
    return response({ error: 'Device token lookup failed' }, 500);
  }
  if (!registrations?.length) {
    return response({ sent: 0, failed: 0, reason: 'No registered devices' });
  }

  const googleJwt = new JWT({
    email: firebase.client_email,
    key: firebase.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });

  let accessToken: string;
  try {
    const token = await googleJwt.getAccessToken();
    if (!token.token) throw new Error('Missing access token');
    accessToken = token.token;
  } catch {
    return response({ error: 'FCM credential exchange failed' }, 503);
  }

  let sent = 0;
  let failed = 0;

  // Fixed source branding. This function never claims to be Gmail, Google,
  // or a financial service, regardless of any user-provided message fields.

  /////////
  ////////////
  ///////////
  ///////////
  ///////////
  ///////////
  ///////////
  //////////
  /////////
  ///////////
  ///////////
  //////////
  //////////
  //////////
  //////////
  /////////
  ///////////
  //////////
  //////////
  ///////////
  //////////////
  //////////
  //////
  for (const row of registrations) {
    try {
      // Android app renders the single custom system notification. Sending a
      // notification payload here as well would produce duplicates.
      const message = {
        token: row.fcm_target,
        data: {
          type: 'demo_mail',
          message_id: String(notification.message_id),
          sender: String(mail.sender_name ?? 'Gmail Clone').slice(0, 80),
          subject: String(mail.subject ?? '').slice(0, 130),
          preview: String(mail.preview || mail.body || notification.body || '')
            .slice(0, 180),
        },
        android: {
          priority: 'high',
        },
      };

      const result = await fetch(
        `https://fcm.googleapis.com/v1/projects/${firebase.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ message }),
        },
      );
      if (result.ok) {
        sent++;
      } else {
        failed++;
        // Never log raw device tokens or secret credentials.
        console.error('Firebase rejected a send:', result.status);
      }
    } catch {
      failed++;
      console.error('Firebase send failed for a registered device.');
    }
  }
  return response({ sent, failed }, failed > 0 ? 502 : 200);
});
