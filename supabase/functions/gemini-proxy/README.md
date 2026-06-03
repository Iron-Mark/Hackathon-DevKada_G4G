# `gemini-proxy` Edge Function

Server-side proxy for Google AI Studio (Gemini) calls. The Flutter client
authenticates with its Supabase user JWT; this function verifies the JWT,
applies a best-effort per-user rate limit, then forwards the request to the
Gemini REST API using a `GEMINI_API_KEY` that lives **only** in the function's
environment. This prevents the key from shipping inside the Flutter APK / web
bundle.

## Deploy

```bash
# 1. Set the upstream Gemini key (one-time; rotate as needed).
supabase secrets set GEMINI_API_KEY=<your-google-ai-studio-key>

# 2. Deploy the function.
supabase functions deploy gemini-proxy
```

> Both steps are required. Until the secret is set **and** the function is
> deployed, **cloud Gemma features in the Kudlit app will fail** (chat,
> sketchpad analysis, and challenge generation will surface an error from
> `CloudGemmaDatasource`).

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically by
Supabase into every deployed function — you do not need to set those.

## Request shape

The client sends (via `supabase.functions.invoke('gemini-proxy', body: ...)`):

```json
{
  "model": "gemma-4-26b-a4b-it",
  "stream": false,
  "payload": {
    "contents": [...],
    "systemInstruction": { "parts": [{ "text": "..." }] },
    "generationConfig": { ... }
  }
}
```

- `model` — optional, defaults to `gemma-4-26b-a4b-it`.
- `stream` — when `true`, the function calls Gemini's
  `streamGenerateContent` endpoint with `alt=sse` and pipes the SSE response
  back to the caller. When `false`, it calls `generateContent` and returns the
  full JSON response.
- `payload` — forwarded verbatim as the Gemini REST request body.

## Rate limiting

In-memory: 10 requests / 60s / user, per Supabase Edge isolate. This is a
best-effort soft limit — under multi-isolate fan-out the effective ceiling can
be N × 10 / minute. For a hard global limit, swap the in-memory map for a
Supabase table or Upstash/Redis counter keyed by `user_id` with a 60s TTL
(see the `TODO` in `index.ts`).

## Failure modes

| Status | `error` body                | Meaning                                       |
| ------ | --------------------------- | --------------------------------------------- |
| 401    | `missing_authorization`     | No `Authorization: Bearer …` header           |
| 401    | `invalid_jwt`               | JWT failed Supabase auth verification         |
| 400    | `invalid_json` / `missing_payload` | Bad client request body                |
| 429    | `rate_limited`              | Per-user 10/min ceiling reached               |
| 500    | `server_misconfigured`      | `SUPABASE_URL` / service-role key missing     |
| 500    | `upstream_key_missing`      | `GEMINI_API_KEY` secret not set               |
| 5xx    | (Gemini body passed through) | Upstream Google AI error                     |
