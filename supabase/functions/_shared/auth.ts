import { createUserClient } from "./supabaseClient.ts";
import { unauthorized } from "./errors.ts";

export type AuthContext = {
  userId: string;
  accessToken: string;
};

export function getBearerToken(req: Request): string {
  const header = req.headers.get("Authorization") ?? "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match?.[1]) {
    throw unauthorized("Missing bearer token");
  }

  return match[1];
}

export async function requireAuth(req: Request): Promise<AuthContext> {
  const accessToken = getBearerToken(req);
  const supabase = createUserClient(accessToken);
  const { data, error } = await supabase.auth.getUser(accessToken);

  if (error || !data.user) {
    throw unauthorized("Invalid or expired user token");
  }

  return {
    userId: data.user.id,
    accessToken,
  };
}
