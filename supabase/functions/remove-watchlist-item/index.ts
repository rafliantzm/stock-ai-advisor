import { handleCors } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, notFound, validationError } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") throw methodNotAllowed();

    const { userId } = await requireAuth(req);
    const body = await req.json().catch(() => ({}));
    const watchlistItemId = body.watchlist_item_id;
    if (!watchlistItemId) throw validationError("watchlist_item_id is required");

    const supabase = createAdminClient();

    const { data: item, error: itemError } = await supabase
      .from("watchlist_items")
      .select("id, watchlist_id, symbol_code, status, watchlists!inner(id, user_id)")
      .eq("id", watchlistItemId)
      .eq("watchlists.user_id", userId)
      .maybeSingle();

    if (itemError) throw databaseError("Failed to validate watchlist item", itemError);
    if (!item) throw notFound("Watchlist item not found");

    const { data: updated, error: updateError } = await supabase
      .from("watchlist_items")
      .update({ status: "archived" })
      .eq("id", watchlistItemId)
      .select("id, watchlist_id, symbol_code, status, updated_at")
      .single();

    if (updateError) throw databaseError("Failed to remove watchlist item", updateError);

    return ok({ item: updated });
  } catch (error) {
    return fail(error);
  }
});
