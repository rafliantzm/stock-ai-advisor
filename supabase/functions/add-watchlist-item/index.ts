import { handleCors } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, notFound, validationError } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";

type AddWatchlistItemBody = {
  watchlist_id?: string;
  symbol_code?: string;
  user_notes?: string;
  added_reason?: string;
};

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") throw methodNotAllowed();

    const { userId } = await requireAuth(req);
    const body = await req.json().catch(() => ({})) as AddWatchlistItemBody;
    const watchlistId = body.watchlist_id;
    const symbolCode = body.symbol_code?.trim().toUpperCase();

    if (!watchlistId) throw validationError("watchlist_id is required");
    if (!symbolCode) throw validationError("symbol_code is required");

    const supabase = createAdminClient();

    const { data: watchlist, error: watchlistError } = await supabase
      .from("watchlists")
      .select("id, user_id, name, status")
      .eq("id", watchlistId)
      .eq("user_id", userId)
      .neq("status", "archived")
      .maybeSingle();

    if (watchlistError) throw databaseError("Failed to validate watchlist", watchlistError);
    if (!watchlist) throw notFound("Watchlist not found");

    const { data: symbol, error: symbolError } = await supabase
      .from("symbols")
      .select("id, symbol_code, company_name, is_active")
      .eq("symbol_code", symbolCode)
      .eq("is_active", true)
      .maybeSingle();

    if (symbolError) throw databaseError("Failed to load symbol", symbolError);
    if (!symbol) throw notFound("Symbol not found");

    const { data: existing, error: existingError } = await supabase
      .from("watchlist_items")
      .select("*")
      .eq("watchlist_id", watchlistId)
      .eq("symbol_code", symbolCode)
      .maybeSingle();

    if (existingError) throw databaseError("Failed to check watchlist item", existingError);

    if (existing) {
      if (existing.status === "archived") {
        const { data: restored, error: restoreError } = await supabase
          .from("watchlist_items")
          .update({
            status: "active",
            symbol_id: symbol.id,
            user_notes: body.user_notes ?? existing.user_notes,
            added_reason: body.added_reason ?? "manual",
          })
          .eq("id", existing.id)
          .select()
          .single();

        if (restoreError) throw databaseError("Failed to restore watchlist item", restoreError);
        return ok({ item: restored, symbol, restored: true });
      }

      return ok({ item: existing, symbol, already_exists: true });
    }

    const { data: item, error: insertError } = await supabase
      .from("watchlist_items")
      .insert({
        watchlist_id: watchlistId,
        symbol_id: symbol.id,
        symbol_code: symbol.symbol_code,
        user_notes: body.user_notes ?? null,
        added_reason: body.added_reason ?? "manual",
        status: "active",
      })
      .select()
      .single();

    if (insertError) throw databaseError("Failed to add watchlist item", insertError);

    return ok({ item, symbol });
  } catch (error) {
    return fail(error);
  }
});
