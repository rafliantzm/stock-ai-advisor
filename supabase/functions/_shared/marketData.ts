import { type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { databaseError, unauthorized, validationError } from "./errors.ts";
import { requireAuth } from "./auth.ts";

export type SyncAuthContext = {
  mode: "sync_token" | "user_jwt";
  userId: string | null;
};

export type ProviderSource = {
  id: string;
  provider_name: string;
  provider_type: string;
  cache_ttl_seconds: number;
  status: string;
};

export type SymbolRow = {
  id: string;
  symbol_code: string;
  company_name: string;
  currency: string;
};

export const DEFAULT_PROVIDER_NAME = "sample_provider";
export const DEFAULT_MARKET_CODE = "IDX";
export const DEFAULT_INDEX_SYMBOL = "IHSG";
export const SAMPLE_STALENESS_WARNING = "provider belum aktif - sample data";

export function marketProviderName(): string {
  return Deno.env.get("MARKET_DATA_PROVIDER_NAME")?.trim() || DEFAULT_PROVIDER_NAME;
}

export function marketCacheTtlSeconds(): number {
  const raw = Number(Deno.env.get("MARKET_DATA_CACHE_TTL_SECONDS") ?? "900");
  if (!Number.isFinite(raw) || raw < 0) return 900;
  return Math.round(raw);
}

export async function authorizeSyncRequest(req: Request): Promise<SyncAuthContext> {
  const syncToken = Deno.env.get("MARKET_DATA_SYNC_TOKEN");
  if (syncToken) {
    const provided = req.headers.get("x-sync-token");
    if (provided !== syncToken) throw unauthorized("Invalid sync token");
    return { mode: "sync_token", userId: null };
  }

  const auth = await requireAuth(req);
  return { mode: "user_jwt", userId: auth.userId };
}

export function normalizeSymbolCodes(input: unknown): string[] {
  if (!Array.isArray(input)) return [];

  const seen = new Set<string>();
  const output: string[] = [];
  for (const item of input) {
    const code = item?.toString().trim().toUpperCase();
    if (!code || seen.has(code)) continue;
    if (!/^[A-Z0-9._-]{1,20}$/.test(code)) {
      throw validationError("symbol_codes contains invalid symbol", { symbol_code: code });
    }
    seen.add(code);
    output.push(code);
  }
  return output;
}

export function boolFromUnknown(value: unknown, fallback: boolean): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    if (value.toLowerCase() === "true") return true;
    if (value.toLowerCase() === "false") return false;
  }
  return fallback;
}

export function numberFromUnknown(value: unknown, fallback: number, min: number, max: number): number {
  const parsed = Number(value ?? fallback);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(min, Math.min(max, Math.round(parsed)));
}

export async function ensureProviderSource(
  supabase: SupabaseClient,
  providerName = marketProviderName(),
): Promise<ProviderSource> {
  const providerType = providerName === DEFAULT_PROVIDER_NAME ? "sample" : "vendor";

  const { data, error } = await supabase
    .from("provider_sources")
    .upsert({
      provider_name: providerName,
      provider_type: providerType,
      supports_quotes: true,
      supports_ohlcv: providerType === "sample",
      supports_market_context: true,
      supports_news: false,
      cache_ttl_seconds: marketCacheTtlSeconds(),
      status: "active",
      notes: providerType === "sample"
        ? "Development sample provider. provider belum aktif untuk production."
        : "Provider metadata only. API key is stored in Edge Function environment.",
    }, { onConflict: "provider_name" })
    .select("id, provider_name, provider_type, cache_ttl_seconds, status")
    .single();

  if (error) throw databaseError("Failed to ensure provider source", error);
  return data as ProviderSource;
}

export async function loadSymbols(
  supabase: SupabaseClient,
  symbolCodes: string[],
  limit: number,
): Promise<SymbolRow[]> {
  let query = supabase
    .from("symbols")
    .select("id, symbol_code, company_name, currency")
    .eq("is_active", true)
    .order("symbol_code", { ascending: true })
    .limit(limit);

  if (symbolCodes.length > 0) {
    query = query.in("symbol_code", symbolCodes);
  }

  const { data, error } = await query;
  if (error) throw databaseError("Failed to load symbols", error);
  return (data ?? []) as SymbolRow[];
}

export function isStale(observedAt: string | null | undefined, ttlSeconds: number): boolean {
  if (!observedAt) return true;
  const observedTime = new Date(observedAt).getTime();
  if (!Number.isFinite(observedTime)) return true;
  return Date.now() - observedTime > ttlSeconds * 1000;
}

function seedFromText(text: string): number {
  return [...text].reduce((total, char) => total + char.charCodeAt(0), 0);
}

function round(value: number, digits = 2): number {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}

export function sampleQuote(symbol: SymbolRow, observedAt: string, providerName: string, providerSourceId: string) {
  const seed = seedFromText(symbol.symbol_code);
  const previousClose = 800 + (seed % 9000);
  const changePercent = round(((seed % 9) - 4) * 0.42, 2);
  const lastPrice = round(previousClose * (1 + changePercent / 100), 2);
  const spread = Math.max(5, previousClose * 0.012);

  return {
    symbol_id: symbol.id,
    symbol_code: symbol.symbol_code,
    provider_source_id: providerSourceId,
    provider_name: providerName,
    provider_symbol: symbol.symbol_code,
    observed_at: observedAt,
    last_price: lastPrice,
    previous_close: previousClose,
    open_price: round(previousClose * (1 + ((seed % 5) - 2) / 100), 2),
    high_price: round(Math.max(lastPrice, previousClose) + spread, 2),
    low_price: round(Math.min(lastPrice, previousClose) - spread, 2),
    change_value: round(lastPrice - previousClose, 2),
    change_percent: changePercent,
    volume: 1_000_000 + seed * 1000,
    value_traded: round((1_000_000 + seed * 1000) * lastPrice, 2),
    market_cap: null,
    currency: symbol.currency ?? "IDR",
    data_quality: "sample",
    is_stale: true,
    staleness_warning: SAMPLE_STALENESS_WARNING,
    raw_payload: {
      source: "deterministic_sample",
      note: "sample data untuk development; provider belum aktif",
    },
  };
}

export function sampleIndicator(symbol: SymbolRow, observedAt: string, providerName: string, providerSourceId: string) {
  const seed = seedFromText(symbol.symbol_code);
  const technicalScore = 45 + (seed % 41);
  const trendScore = 40 + ((seed * 3) % 45);
  const volumeScore = 42 + ((seed * 5) % 44);
  const riskScore = 50 + ((seed * 7) % 38);
  const invalidationLevel = 800 + (seed % 9000) - (seed % 250);

  return {
    symbol_id: symbol.id,
    symbol_code: symbol.symbol_code,
    provider_source_id: providerSourceId,
    provider_name: providerName,
    timeframe: "1d",
    observed_at: observedAt,
    ema_20: null,
    ema_50: null,
    ema_200: null,
    rsi_14: null,
    atr_14: null,
    average_volume_20: null,
    volume_ratio: null,
    support_level: null,
    resistance_level: null,
    trend_state: "needs_more_data",
    candlestick_pattern: null,
    indicator_payload: {
      source: "deterministic_sample",
      note: "technical indicators belum dihitung dari OHLCV provider",
    },
    technical_score: technicalScore,
    trend_score: trendScore,
    volume_score: volumeScore,
    risk_score: riskScore,
    invalidation_level: invalidationLevel,
    rule_version: "p2_sample_indicator_v1",
    data_quality: "sample",
  };
}

export function sampleMarketContext(providerName: string, providerSourceId: string, observedAt: string) {
  return {
    provider_source_id: providerSourceId,
    provider_name: providerName,
    market_code: DEFAULT_MARKET_CODE,
    index_symbol: DEFAULT_INDEX_SYMBOL,
    observed_at: observedAt,
    index_last: null,
    index_change: null,
    index_change_percent: null,
    index_trend: "needs_more_data",
    market_status: "provider belum aktif",
    risk_regime: "needs_more_data",
    breadth_summary: {
      source: "sample data",
      note: "Market breadth provider belum aktif.",
    },
    context_payload: {
      label: "sample data",
      disclaimer: "Data market context hanya untuk edukasi.",
    },
    data_quality: "sample",
    is_stale: true,
    staleness_warning: SAMPLE_STALENESS_WARNING,
  };
}

export function sanitizeMarketContext(row: Record<string, unknown> | null, ttlSeconds: number) {
  const stale = row ? Boolean(row.is_stale) || isStale(row.observed_at as string, ttlSeconds) : true;
  return {
    market_code: row?.market_code ?? DEFAULT_MARKET_CODE,
    index_symbol: row?.index_symbol ?? DEFAULT_INDEX_SYMBOL,
    market_status: row?.market_status ?? "provider belum aktif",
    index_trend: row?.index_trend ?? "needs_more_data",
    risk_regime: row?.risk_regime ?? "needs_more_data",
    index_last: row?.index_last ?? null,
    index_change: row?.index_change ?? null,
    index_change_percent: row?.index_change_percent ?? null,
    last_updated: row?.observed_at ?? null,
    data_quality: row?.data_quality ?? "sample",
    is_stale: stale,
    staleness_warning: row?.staleness_warning ?? SAMPLE_STALENESS_WARNING,
    risk_warning: stale
      ? [{
        level: "medium",
        message: "Market context memakai sample data atau cache stale; provider belum aktif.",
      }]
      : [],
  };
}
