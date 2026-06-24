import { handleCors } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, notFound, validationError } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";

type EvaluateWatchlistBody = {
  watchlist_id?: string;
};

function clampScore(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function seedFromText(text: string): number {
  return [...text].reduce((total, char) => total + char.charCodeAt(0), 0);
}

function dummyScore(symbolCode: string) {
  const seed = seedFromText(symbolCode);
  const technicalScore = clampScore(50 + (seed % 41));
  const harmonyScore = clampScore(40 + ((seed * 3) % 51));
  const fundamentalScore = clampScore(45 + ((seed * 5) % 46));
  const riskScore = clampScore(50 + ((seed * 7) % 41));
  const liquidityScore = clampScore(55 + ((seed * 11) % 38));
  const finalScore = clampScore(
    technicalScore * 0.28 +
      harmonyScore * 0.12 +
      fundamentalScore * 0.25 +
      riskScore * 0.2 +
      liquidityScore * 0.15,
  );

  return {
    technical_score: technicalScore,
    harmony_score: harmonyScore,
    fundamental_score: fundamentalScore,
    risk_score: riskScore,
    liquidity_score: liquidityScore,
    final_score: finalScore,
    invalidation_level: clampScore(100 - riskScore),
  };
}

function labelForScore(finalScore: number, riskScore: number): string {
  if (riskScore < 45) return "risk_flagged";
  if (finalScore >= 72) return "watchlist_candidate";
  if (finalScore >= 55) return "layak_dianalisis";
  return "needs_more_data";
}

function riskWarnings(score: ReturnType<typeof dummyScore>): Array<Record<string, unknown>> {
  const warnings = [];
  if (score.risk_score < 55) {
    warnings.push({
      type: "risk_warning",
      message: "Risk score masih perlu diperiksa sebelum saham masuk watchlist candidate.",
    });
  }
  if (score.liquidity_score < 60) {
    warnings.push({
      type: "liquidity_warning",
      message: "Liquidity score belum ideal untuk technical setup yang stabil.",
    });
  }
  return warnings;
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") throw methodNotAllowed();

    const { userId } = await requireAuth(req);
    const body = await req.json().catch(() => ({})) as EvaluateWatchlistBody;
    if (!body.watchlist_id) throw validationError("watchlist_id is required");

    const supabase = createAdminClient();

    const { data: watchlist, error: watchlistError } = await supabase
      .from("watchlists")
      .select("id, user_id, name, status")
      .eq("id", body.watchlist_id)
      .eq("user_id", userId)
      .neq("status", "archived")
      .maybeSingle();

    if (watchlistError) throw databaseError("Failed to validate watchlist", watchlistError);
    if (!watchlist) throw notFound("Watchlist not found");

    const { data: items, error: itemsError } = await supabase
      .from("watchlist_items")
      .select("id, symbol_id, symbol_code, status")
      .eq("watchlist_id", watchlist.id)
      .neq("status", "archived")
      .order("added_at", { ascending: true });

    if (itemsError) throw databaseError("Failed to load watchlist items", itemsError);

    const evaluated = (items ?? []).map((item) => {
      const scores = dummyScore(item.symbol_code);
      return {
        item,
        scores,
        candidate_label: labelForScore(scores.final_score, scores.risk_score),
        risk_warnings: riskWarnings(scores),
      };
    });

    if (evaluated.length > 0) {
      const rows = evaluated.map((entry) => ({
        watchlist_item_id: entry.item.id,
        symbol_id: entry.item.symbol_id,
        symbol_code: entry.item.symbol_code,
        rule_version: "p0_dummy_scoring_v1",
        overall_score: entry.scores.final_score,
        candidate_label: entry.candidate_label,
        technical_score: entry.scores.technical_score,
        fundamental_score: entry.scores.fundamental_score,
        risk_score: entry.scores.risk_score,
        risk_warnings: entry.risk_warnings,
        invalidation_level: entry.scores.invalidation_level,
        status: "active",
      }));

      const { error: insertError } = await supabase
        .from("watchlist_scores")
        .insert(rows);

      if (insertError) throw databaseError("Failed to store watchlist scores", insertError);
    }

    return ok({
      watchlist,
      evaluated_count: evaluated.length,
      rule_version: "p0_dummy_scoring_v1",
      results: evaluated.map((entry) => ({
        watchlist_item_id: entry.item.id,
        symbol_code: entry.item.symbol_code,
        candidate_label: entry.candidate_label,
        technical_setup: entry.scores.technical_score >= 70 ? "technical setup candidate" : "needs_more_data",
        risk_warning: entry.risk_warnings,
        invalidation_level: entry.scores.invalidation_level,
        scores: entry.scores,
      })),
    }, {
      scoring_mode: "dummy_p0_no_ai_no_rag_no_market_data",
    });
  } catch (error) {
    return fail(error);
  }
});
