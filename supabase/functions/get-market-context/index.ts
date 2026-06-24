import { handleCors } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";
import {
  boolFromUnknown,
  buildMarketContextRow,
  DEFAULT_INDEX_SYMBOL,
  DEFAULT_MARKET_CODE,
  DEFAULT_PROVIDER_NAME,
  ensureProviderSource,
  marketCacheTtlSeconds,
  providerMeta,
  resolveProviderRuntime,
  sanitizeMarketContext,
  toMarketContextDbRow,
} from "../_shared/marketData.ts";

type MarketContextBody = {
  market_code?: string;
  index_symbol?: string;
  allow_stale?: unknown;
  create_sample_if_missing?: unknown;
};

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (!["GET", "POST"].includes(req.method)) throw methodNotAllowed();

    await requireAuth(req);
    const url = new URL(req.url);
    const body = req.method === "POST" ? await req.json().catch(() => ({})) as MarketContextBody : {};

    const marketCode = (body.market_code ?? url.searchParams.get("market_code") ?? DEFAULT_MARKET_CODE)
      .trim()
      .toUpperCase();
    const indexSymbol = (body.index_symbol ?? url.searchParams.get("index_symbol") ?? DEFAULT_INDEX_SYMBOL)
      .trim()
      .toUpperCase();
    const allowStale = boolFromUnknown(body.allow_stale ?? url.searchParams.get("allow_stale"), true);
    const createSampleIfMissing = boolFromUnknown(
      body.create_sample_if_missing ?? url.searchParams.get("create_sample_if_missing"),
      true,
    );

    const supabase = createAdminClient();
    const runtime = resolveProviderRuntime();
    const ttlSeconds = marketCacheTtlSeconds();

    const { data: snapshots, error: snapshotError } = await supabase
      .from("market_context_snapshots")
      .select("*")
      .eq("market_code", marketCode)
      .eq("index_symbol", indexSymbol)
      .order("observed_at", { ascending: false })
      .limit(1);

    if (snapshotError) throw databaseError("Failed to load market context", snapshotError);

    let snapshot = snapshots?.[0] ?? null;
    let providerMode = runtime.mode;
    let providerStatusOverride: string | null = null;

    if (!snapshot && createSampleIfMissing) {
      const provider = await ensureProviderSource(supabase, runtime.activeProviderName, runtime.providerType);
      const fallbackProvider = runtime.mode === "live"
        ? await ensureProviderSource(supabase, DEFAULT_PROVIDER_NAME, "sample")
        : provider;
      const builtContext = await buildMarketContextRow(provider, runtime, new Date().toISOString(), fallbackProvider);
      providerMode = builtContext.providerMode;
      providerStatusOverride = builtContext.providerStatus;
      const { data: inserted, error: insertError } = await supabase
        .from("market_context_snapshots")
        .insert({
          ...toMarketContextDbRow(builtContext.marketContext),
          market_code: marketCode,
          index_symbol: indexSymbol,
        })
        .select("*")
        .single();

      if (insertError) throw databaseError("Failed to create sample market context", insertError);
      snapshot = inserted;
    }

    const marketContext = sanitizeMarketContext(snapshot, ttlSeconds, runtime);
    if (providerStatusOverride) {
      marketContext.provider_status = providerStatusOverride;
    }
    const hasFreshProviderContext = ["live", "delayed", "production"].includes(marketContext.data_quality?.toString());
    const effectiveProviderMode = hasFreshProviderContext || runtime.mode !== "live"
      ? providerMode
      : "provider_error";
    const staleBlocked = marketContext.is_stale && !allowStale;

    return ok({
      market_context: marketContext,
      provider: {
        ...providerMeta(runtime),
        provider_name: snapshot?.provider_name ?? runtime.activeProviderName,
        provider_mode: effectiveProviderMode,
        provider_status: marketContext.provider_status,
        data_quality: marketContext.data_quality,
      },
      cache: {
        allow_stale: allowStale,
        stale_blocked: staleBlocked,
        ttl_seconds: ttlSeconds,
      },
      disclaimer:
        "Market context bersifat edukatif untuk watchlist candidate, risk warning, dan invalidation level; bukan instruksi transaksi.",
    }, {
      data_quality: marketContext.data_quality,
      provider_name: snapshot?.provider_name ?? runtime.activeProviderName,
      provider_status: marketContext.provider_status,
      provider_mode: effectiveProviderMode,
    });
  } catch (error) {
    return fail(error);
  }
});
