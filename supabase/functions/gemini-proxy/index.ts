// supabase/functions/gemini-proxy/index.ts
//
// Gemini API proxy. The client must NOT hold a `GEMINI_API_KEY` — that key
// lives only in this function's environment (set via
// `supabase secrets set GEMINI_API_KEY=...`).
//
// The client calls this function with a Supabase user JWT in the
// `Authorization` header (the supabase-js / supabase_flutter SDK forwards it
// automatically when using `functions.invoke`). We verify the JWT, apply a
// best-effort per-user rate limit, then forward the request body to the
// Google AI Studio Gemini REST endpoint and stream the response back.
//
// Deploy:
//   supabase functions deploy gemini-proxy
//
// Set the upstream key (one-time):
//   supabase secrets set GEMINI_API_KEY=<your-google-ai-studio-key>

// deno-lint-ignore-file no-explicit-any
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

// ─── Config ──────────────────────────────────────────────────────────────────

const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const DEFAULT_MODEL = 'gemma-4-26b-a4b-it';

// Rate limit: 10 requests per 60s per user. In-memory, per-isolate
// (best-effort — Supabase may spin up multiple isolates, so the effective
// ceiling can be N×10/min where N = active isolate count).
// TODO: For a hard global limit, swap this for a Supabase table or
// Upstash/Redis counter keyed by user_id with a 60s TTL.
const RATE_LIMIT_MAX = 10;
const RATE_LIMIT_WINDOW_MS = 60_000;
const recentCallsByUser = new Map<string, number[]>();

function isRateLimited(userId: string): boolean {
  const now = Date.now();
  const calls = recentCallsByUser.get(userId) ?? [];
  const fresh = calls.filter((t) => now - t < RATE_LIMIT_WINDOW_MS);
  if (fresh.length >= RATE_LIMIT_MAX) {
    recentCallsByUser.set(userId, fresh);
    return true;
  }
  fresh.push(now);
  recentCallsByUser.set(userId, fresh);
  return false;
}

// ─── CORS ────────────────────────────────────────────────────────────────────

const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

// ─── Handler ─────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  // 1. Extract & verify the user's JWT.
  const authHeader = req.headers.get('Authorization') ?? '';
  const jwt = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!jwt) {
    return jsonResponse({ error: 'missing_authorization' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'server_misconfigured' }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userErr } = await supabase.auth.getUser(jwt);
  if (userErr || !userData?.user) {
    return jsonResponse({ error: 'invalid_jwt' }, 401);
  }
  const userId = userData.user.id;

  // 2. Per-user rate limit.
  if (isRateLimited(userId)) {
    return jsonResponse(
      { error: 'rate_limited', retry_after_seconds: 60 },
      429,
    );
  }

  // 3. Verify upstream key.
  const geminiKey = Deno.env.get('GEMINI_API_KEY') ?? '';
  if (!geminiKey) {
    return jsonResponse({ error: 'upstream_key_missing' }, 500);
  }

  // 4. Parse request body. Expected shape:
  //    {
  //      "model"?: string,           // defaults to gemma-4-26b-a4b-it
  //      "stream"?: boolean,         // SSE pass-through when true
  //      "payload": <Gemini REST body — passed verbatim>
  //    }
  let body: any;
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ error: 'invalid_json' }, 400);
  }

  const model =
    typeof body?.model === 'string' && body.model.length > 0
      ? body.model
      : DEFAULT_MODEL;
  const stream = body?.stream === true;
  const payload = body?.payload;
  if (!payload || typeof payload !== 'object') {
    return jsonResponse({ error: 'missing_payload' }, 400);
  }

  const endpoint = stream ? 'streamGenerateContent' : 'generateContent';
  const upstreamUrl =
    `${GEMINI_BASE}/${encodeURIComponent(model)}:${endpoint}` +
    `?key=${encodeURIComponent(geminiKey)}` +
    (stream ? '&alt=sse' : '');

  // 5. Forward to Gemini.
  const upstreamRes = await fetch(upstreamUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  // 6. Stream the response back to the caller unchanged.
  if (stream) {
    return new Response(upstreamRes.body, {
      status: upstreamRes.status,
      headers: {
        ...CORS_HEADERS,
        'Content-Type':
          upstreamRes.headers.get('Content-Type') ?? 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
    });
  }

  const text = await upstreamRes.text();
  return new Response(text, {
    status: upstreamRes.status,
    headers: {
      ...CORS_HEADERS,
      'Content-Type':
        upstreamRes.headers.get('Content-Type') ?? 'application/json',
    },
  });
});
