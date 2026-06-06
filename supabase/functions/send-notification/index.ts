import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface NotificationPayload {
  receiver_id: number;
  sender_id?: number;
  type: string;
  title: string;
  body: string;
  related_id?: number;
  related_table?: string;
}

// Generate OAuth2 Access Token for Firebase Cloud Messaging using Web Crypto API
async function getFcmAccessToken(serviceAccount: any): Promise<string> {
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = serviceAccount.private_key
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const textEncoder = new TextEncoder();
  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const encodedClaim = btoa(JSON.stringify(claim)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const signatureInput = `${encodedHeader}.${encodedClaim}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    textEncoder.encode(signatureInput)
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${signatureInput}.${encodedSignature}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();
  if (data.error) {
    throw new Error(`Failed to get OAuth token: ${data.error_description || data.error}`);
  }
  return data.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const payload: NotificationPayload = await req.json();
    const { receiver_id, sender_id, type, title, body, related_id, related_table } = payload;

    if (!receiver_id || !type || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: receiver_id, type, title, body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Insert notification record in Database
    const { data: dbNotification, error: dbError } = await supabaseClient
      .from("notifications")
      .insert({
        receiver_id,
        sender_id,
        type,
        title,
        body,
        related_id,
        related_table,
        is_read: false,
      })
      .select("*, sender:users!notifications_sender_id_fkey(name, photo_url)")
      .single();

    if (dbError) {
      console.error("DB Insert Error:", dbError);
      return new Response(
        JSON.stringify({ error: dbError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Fetch target user's FCM registration token
    const { data: user, error: userError } = await supabaseClient
      .from("users")
      .select("fcm_token")
      .eq("id", receiver_id)
      .single();

    if (userError) {
      console.error("Error fetching receiver's token:", userError);
    }

    const fcmToken = user?.fcm_token;
    let pushSent = false;
    let pushError = null;

    // 3. Send Push Notification if FCM token is set
    if (fcmToken) {
      const saEnv = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
      if (saEnv) {
        try {
          const serviceAccount = JSON.parse(saEnv);
          const accessToken = await getFcmAccessToken(serviceAccount);

          const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
          const fcmBody = {
            message: {
              token: fcmToken,
              notification: {
                title,
                body,
              },
              data: {
                type,
                related_id: related_id ? String(related_id) : "",
                related_table: related_table ?? "",
              },
            },
          };

          const fcmResponse = await fetch(fcmEndpoint, {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(fcmBody),
          });

          const fcmResult = await fcmResponse.json();
          if (fcmResponse.ok) {
            pushSent = true;
          } else {
            console.error("FCM API error response:", fcmResult);
            pushError = fcmResult.error?.message || "Unknown FCM gateway error";
          }
        } catch (err) {
          console.error("Failed to process push dispatch:", err);
          pushError = err instanceof Error ? err.message : String(err);
        }
      } else {
        console.warn("FIREBASE_SERVICE_ACCOUNT environment variable is not defined. Skipping push dispatch.");
        pushError = "FIREBASE_SERVICE_ACCOUNT secret not configured in Supabase";
      }
    } else {
      console.log(`No registered fcm_token for user ID: ${receiver_id}. Skipping push dispatch.`);
      pushError = "Receiver has no registered FCM token";
    }

    return new Response(
      JSON.stringify({
        success: true,
        notification: dbNotification,
        push_delivered: pushSent,
        push_error: pushError,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Edge function top-level crash:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});