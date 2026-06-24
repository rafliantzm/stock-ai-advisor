import { corsHeaders } from "./cors.ts";
import { ApiError } from "./errors.ts";

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export function ok(data: unknown, meta: Record<string, unknown> = {}): Response {
  return jsonResponse({ ok: true, data, meta });
}

export function fail(error: unknown): Response {
  if (error instanceof ApiError) {
    return jsonResponse(
      {
        ok: false,
        error: {
          code: error.code,
          message: error.message,
          details: error.details ?? null,
        },
      },
      error.status,
    );
  }

  console.error(error);
  return jsonResponse(
    {
      ok: false,
      error: {
        code: "database_error",
        message: "Unexpected server error",
        details: null,
      },
    },
    500,
  );
}
