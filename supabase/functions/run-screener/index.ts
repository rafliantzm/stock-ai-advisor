import { handleCors } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, notFound, validationError } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";

type RunScreenerBody = {
  preset_id?: string;
  preset_name?: string;
  limit?: number;
};

function clampScore(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function seedFromText(text: string): number {
  return [...text].reduce((total, char) => total + char.charCodeAt(0), 0);
}

function dummyScore(symbolCode: string, presetName: string) {
  const seed = seedFromText(`${symbolCode}:${presetName}`);
  const technicalScore = clampScore(48 + (seed % 43));
  const harmonyScore = clampScore(42 + ((seed * 3) % 47));
  const fundamentalScore = clampScore(45 + ((seed * 5) % 45));
  const riskScore = clampScore(50 + ((seed * 7) % 41));
  const liquidityScore = clampScore(55 + ((seed * 11) % 38));
  const finalScore = clampScore(
    technicalScore * 0.25 +
      harmonyScore * 0.15 +
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
  };
}

function candidateLabel(score: number, riskScore: number): string {
  if (riskScore < 45) return "risk_flagged";
  if (score >= 72) return "watchlist_candidate";
  if (score >= 55) return "layak_dianalisis";
  return "needs_more_data";
}

function evaluateFilter(metric: string, score: Record<string, number>): boolean {
  if (metric === "volume_condition") return score.liquidity_score >= 62;
  if (metric === "trend_condition") return score.technical_score >= 68;
  if (metric === "fibonacci_condition") return score.technical_score >= 60;
  if (metric === "candlestick_condition") return score.technical_score >= 58;
  if (metric === "support_resistance_condition") return score.risk_score >= 52;
  if (metric === "dividend_condition") return score.fundamental_score >= 62;
  if (metric === "harmonic_condition") return score.harmony_score >= 65;
  return (score[metric] ?? 0) >= 50;
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") throw methodNotAllowed();

    const { userId } = await requireAuth(req);
    const body = await req.json().catch(() => ({})) as RunScreenerBody;
    const limit = Math.max(1, Math.min(Number(body.limit ?? 25), 100));
    const supabase = createAdminClient();

    let presetQuery = supabase
      .from("screener_presets")
      .select("id, name, description, category, filter_summary, status")
      .eq("status", "active")
      .limit(1);

    if (body.preset_id) presetQuery = presetQuery.eq("id", body.preset_id);
    if (body.preset_name) presetQuery = presetQuery.eq("name", body.preset_name);

    const { data: presets, error: presetError } = await presetQuery;
    if (presetError) throw databaseError("Failed to load screener preset", presetError);
    const preset = presets?.[0];
    if (!preset) throw notFound("Screener preset not found");

    const { data: filters, error: filtersError } = await supabase
      .from("screener_filters")
      .select("id, metric, operator, value_json, weight, status")
      .eq("preset_id", preset.id)
      .eq("status", "active")
      .order("created_at", { ascending: true });

    if (filtersError) throw databaseError("Failed to load screener filters", filtersError);

    const { data: symbols, error: symbolsError } = await supabase
      .from("symbols")
      .select("id, symbol_code, company_name, currency, is_active")
      .eq("is_active", true)
      .order("symbol_code", { ascending: true })
      .limit(limit);

    if (symbolsError) throw databaseError("Failed to load symbols", symbolsError);

    const runId = crypto.randomUUID();
    const results = (symbols ?? []).map((symbol) => {
      const score = dummyScore(symbol.symbol_code, preset.name);
      const matchedFilters = (filters ?? []).map((filter) => ({
        metric: filter.metric,
        operator: filter.operator,
        value_json: filter.value_json,
        weight: filter.weight,
        passed: evaluateFilter(filter.metric, score),
      }));
      const passedCount = matchedFilters.filter((filter) => filter.passed).length;
      const adjustedFinalScore = clampScore(score.final_score + passedCount * 2);
      const label = candidateLabel(adjustedFinalScore, score.risk_score);

      return {
        symbol,
        scores: {
          ...score,
          final_score: adjustedFinalScore,
        },
        candidate_label: label,
        matched_filters: matchedFilters,
      };
    }).sort((left, right) => right.scores.final_score - left.scores.final_score);

    const resultRows = results.map((result) => ({
      user_id: userId,
      preset_id: preset.id,
      symbol_id: result.symbol.id,
      symbol_code: result.symbol.symbol_code,
      rule_version: "p0_dummy_scoring_v1",
      score: result.scores.final_score,
      candidate_label: result.candidate_label,
      matched_filters: result.matched_filters,
      run_id: runId,
      status: "active",
    }));

    if (resultRows.length > 0) {
      const { error: insertError } = await supabase
        .from("screener_results")
        .insert(resultRows);

      if (insertError) throw databaseError("Failed to store screener results", insertError);
    }

    return ok({
      run_id: runId,
      preset,
      filters,
      results,
    }, {
      scoring_mode: "dummy_p0_no_market_data",
    });
  } catch (error) {
    return fail(error);
  }
});
