import { handleCors } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, notFound } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (!["GET", "POST"].includes(req.method)) throw methodNotAllowed();

    const { userId } = await requireAuth(req);
    const body = req.method === "POST" ? await req.json().catch(() => ({})) : {};
    const url = new URL(req.url);
    const watchlistId = body.watchlist_id ?? url.searchParams.get("watchlist_id");
    const supabase = createAdminClient();

    let watchlistQuery = supabase
      .from("watchlists")
      .select("id, name, description, is_default, status, created_at, updated_at")
      .eq("user_id", userId)
      .neq("status", "archived")
      .order("is_default", { ascending: false })
      .order("created_at", { ascending: true });

    if (watchlistId) watchlistQuery = watchlistQuery.eq("id", watchlistId);

    const { data: watchlists, error: watchlistsError } = await watchlistQuery;
    if (watchlistsError) throw databaseError("Failed to load watchlists", watchlistsError);
    if (watchlistId && (!watchlists || watchlists.length === 0)) {
      throw notFound("Watchlist not found");
    }

    const selectedWatchlist = watchlists?.[0] ?? null;
    if (!selectedWatchlist) {
      return ok({ watchlists: [], selected_watchlist: null, items: [] });
    }

    const { data: items, error: itemsError } = await supabase
      .from("watchlist_items")
      .select(`
        id,
        watchlist_id,
        symbol_id,
        symbol_code,
        user_notes,
        added_reason,
        status,
        added_at,
        symbols:symbol_id (
          id,
          symbol_code,
          company_name,
          instrument_type,
          currency,
          is_active
        )
      `)
      .eq("watchlist_id", selectedWatchlist.id)
      .neq("status", "archived")
      .order("added_at", { ascending: false });

    if (itemsError) throw databaseError("Failed to load watchlist items", itemsError);

    const itemIds = (items ?? []).map((item) => item.id);
    const { data: scores, error: scoresError } = itemIds.length === 0
      ? { data: [], error: null }
      : await supabase
        .from("watchlist_scores")
        .select("*")
        .in("watchlist_item_id", itemIds)
        .order("evaluated_at", { ascending: false });

    if (scoresError) throw databaseError("Failed to load watchlist scores", scoresError);

    const latestScoreByItem = new Map<string, unknown>();
    for (const score of scores ?? []) {
      if (!latestScoreByItem.has(score.watchlist_item_id)) {
        latestScoreByItem.set(score.watchlist_item_id, score);
      }
    }

    const enrichedItems = (items ?? []).map((item) => ({
      ...item,
      latest_score: latestScoreByItem.get(item.id) ?? null,
    }));

    return ok({
      watchlists,
      selected_watchlist: selectedWatchlist,
      items: enrichedItems,
    });
  } catch (error) {
    return fail(error);
  }
});
