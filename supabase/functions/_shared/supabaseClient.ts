import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import { validationError } from "./errors.ts";

function getJsonKey(envName: string, keyName = "default"): string | null {
  const raw = Deno.env.get(envName);
  if (!raw) return null;

  try {
    const parsed = JSON.parse(raw);
    return parsed?.[keyName] ?? null;
  } catch {
    return null;
  }
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw validationError(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getSupabaseUrl(): string {
  return requiredEnv("SUPABASE_URL");
}

export function getPublishableOrAnonKey(): string {
  return (
    Deno.env.get("SUPABASE_ANON_KEY") ??
    getJsonKey("SUPABASE_PUBLISHABLE_KEYS") ??
    requiredEnv("SUPABASE_ANON_KEY")
  );
}

export function getSecretOrServiceRoleKey(): string {
  return (
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    getJsonKey("SUPABASE_SECRET_KEYS") ??
    requiredEnv("SUPABASE_SERVICE_ROLE_KEY")
  );
}

export function createUserClient(accessToken: string): SupabaseClient {
  return createClient(getSupabaseUrl(), getPublishableOrAnonKey(), {
    global: {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export function createAdminClient(): SupabaseClient {
  return createClient(getSupabaseUrl(), getSecretOrServiceRoleKey(), {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
