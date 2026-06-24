// Supabase Edge Function: send-test-push
// Firebase Cloud Messaging HTTP v1 ile iOS push bildirimi gönderir.
//
// Gerekli secret:
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='<service_account.json içeriği>'
//
// Manuel tetiklemek için:
//   curl -X POST https://<project-ref>.supabase.co/functions/v1/send-test-push \
//     -H "Authorization: Bearer <anon-key>"

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FCM_PROJECT_ID = "matchly-app-a09a2";

// ── Google OAuth2 access token (service account → JWT → token) ───────────────

async function getGoogleAccessToken(serviceAccountJson: string): Promise<string> {
  const sa = JSON.parse(serviceAccountJson);

  const now = Math.floor(Date.now() / 1000);

  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const b64url = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");

  const unsigned = `${b64url(header)}.${b64url(claim)}`;

  // PEM → DER
  const pemContents = sa.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const der = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );

  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const jwt = `${unsigned}.${sigB64}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`Google access token alınamadı: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

// ── FCM HTTP v1 mesaj gönder ──────────────────────────────────────────────────

async function sendFcmMessage(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
): Promise<{ success: boolean; response: unknown }> {
  const url =
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;

  const message = {
    message: {
      token: fcmToken,
      notification: { title, body },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: "default",
            badge: 1,
          },
        },
      },
    },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(message),
  });

  const response = await res.json();
  return { success: res.ok, response };
}

// ── Handler ───────────────────────────────────────────────────────────────────

serve(async (_req) => {
  try {
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!serviceAccountJson) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT_JSON secret eksik" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Supabase client (service role ile device_tokens okur)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // iOS tokenlarını çek
    const { data: tokens, error: dbError } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("platform", "ios");

    if (dbError) {
      return new Response(
        JSON.stringify({ error: `DB hatası: ${dbError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: "device_tokens tablosunda iOS token bulunamadı" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    const accessToken = await getGoogleAccessToken(serviceAccountJson);

    const results = [];
    for (const row of tokens) {
      const result = await sendFcmMessage(
        accessToken,
        row.token,
        "Matchly Test",
        "iPhone bildirimi çalışıyor 🎉",
      );
      results.push({ token: row.token.slice(0, 20) + "...", ...result });
    }

    return new Response(
      JSON.stringify({ sent: results.length, results }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
