import { handleCors } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, validationError } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";

type ChartDataBody = {
  symbol_code?: string;
  timeframe?: string;
  limit?: unknown;
};

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") throw methodNotAllowed();
    await requireAuth(req);

    const body = await req.json().catch(() => ({})) as ChartDataBody;
    const symbolCode = (body.symbol_code ?? "BBCA").trim().toUpperCase();
    const timeframe = (body.timeframe ?? "1d").trim().toLowerCase();
    const limit = clampNumber(body.limit, 60, 5, 120);

    if (!/^[A-Z0-9.:-]{2,16}$/.test(symbolCode)) {
      throw validationError("symbol_code is invalid");
    }
    if (!["1d", "1w", "1mo"].includes(timeframe)) {
      throw validationError("timeframe is invalid", { allowed: ["1d", "1w", "1mo"] });
    }

    const supabase = createAdminClient();
    const { data: barsDesc, error: barsError } = await supabase
      .from("ohlcv_bars")
      .select(
        "symbol_code, provider_name, timeframe, observed_at, open_price, high_price, low_price, close_price, volume, data_quality",
      )
      .eq("symbol_code", symbolCode)
      .eq("timeframe", timeframe)
      .order("observed_at", { ascending: false })
      .limit(limit);

    if (barsError) throw databaseError("Failed to load OHLCV bars", barsError);

    const bars = (barsDesc ?? []).slice().reverse().map((bar) => ({
      symbol_code: bar.symbol_code,
      provider_name: bar.provider_name,
      timeframe: bar.timeframe,
      observed_at: bar.observed_at,
      open: Number(bar.open_price),
      high: Number(bar.high_price),
      low: Number(bar.low_price),
      close: Number(bar.close_price),
      volume: bar.volume === null ? null : Number(bar.volume),
      data_quality: bar.data_quality,
    }));
    const latestBar = bars.at(-1);

    const { data: indicators, error: indicatorError } = await supabase
      .from("technical_indicator_snapshots")
      .select("ema_20, ema_50, rsi_14, trend_state, technical_score, rule_version, observed_at, data_quality")
      .eq("symbol_code", symbolCode)
      .eq("timeframe", timeframe)
      .order("observed_at", { ascending: false })
      .limit(1);

    if (indicatorError) throw databaseError("Failed to load chart indicators", indicatorError);

    const dataQuality = latestBar?.data_quality ?? "needs_more_data";
    const providerName = latestBar?.provider_name ?? "provider_cache";
    const providerStatus = bars.length > 0
      ? "Provider-backed delayed OHLCV cache tersedia"
      : "OHLCV cache belum tersedia untuk symbol/timeframe ini";

    return ok({
      chart: {
        symbol_code: symbolCode,
        timeframe,
        bars,
        bar_count: bars.length,
        data_quality: dataQuality,
        latest_observed_at: latestBar?.observed_at ?? null,
      },
      provider: {
        provider_name: providerName,
        provider_status: providerStatus,
        data_quality: dataQuality,
      },
      indicators: indicators?.[0] ?? null,
      risk_warning: bars.length > 0
        ? [{
          level: "low",
          message: "OHLCV data bersifat delayed provider-backed; gunakan sebagai konteks edukatif watchlist candidate.",
        }]
        : [{
          level: "medium",
          message: "OHLCV cache belum cukup. Jalankan sync market data atau pilih symbol lain.",
        }],
      disclaimer:
        "Chart Lab memakai OHLCV cache edukatif untuk watchlist candidate, risk warning, dan invalidation level; bukan instruksi transaksi.",
    }, {
      rule_version: "p3_chart_lab_ohlcv_cache_v1",
      provider_name: providerName,
      provider_status: providerStatus,
      provider_mode: bars.length > 0 ? "live" : "fallback_sample",
      data_quality: dataQuality,
      bar_count: bars.length,
    });
  } catch (error) {
    return fail(error);
  }
});

function clampNumber(value: unknown, fallback: number, min: number, max: number): number {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(Math.max(Math.trunc(parsed), min), max);
}
