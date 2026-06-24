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

export type MarketDataQuality = "sample" | "stale" | "production";

export type ProviderRuntime = {
  requestedProviderName: string;
  activeProviderName: string;
  providerType: "sample" | "vendor";
  mode: "sample" | "production" | "fallback";
  dataQuality: MarketDataQuality;
  providerStatus: string;
  cacheTtlSeconds: number;
  isProductionConfigured: boolean;
  missingEnv: string[];
  riskWarning: RiskWarning[];
};

export type RiskWarning = {
  level: "low" | "medium" | "high";
  message: string;
};

export type NormalizedPriceSnapshot = {
  symbol_id: string;
  symbol_code: string;
  provider_source_id: string;
  provider_name: string;
  provider_symbol: string;
  observed_at: string;
  last_price: number | null;
  previous_close: number | null;
  open_price: number | null;
  high_price: number | null;
  low_price: number | null;
  change_value: number | null;
  change_percent: number | null;
  volume: number | null;
  value_traded: number | null;
  market_cap: number | null;
  currency: string;
  data_quality: MarketDataQuality;
  is_stale: boolean;
  staleness_warning: string | null;
  raw_payload: Record<string, unknown>;
};

export type NormalizedOhlcvBar = {
  symbol_id: string;
  symbol_code: string;
  provider_source_id: string;
  provider_name: string;
  timeframe: string;
  observed_at: string;
  open_price: number | null;
  high_price: number | null;
  low_price: number | null;
  close_price: number | null;
  volume: number | null;
  value_traded: number | null;
  data_quality: MarketDataQuality;
};

export type NormalizedTechnicalIndicator = {
  symbol_id: string;
  symbol_code: string;
  provider_source_id: string;
  provider_name: string;
  timeframe: string;
  observed_at: string;
  ema_20: number | null;
  ema_50: number | null;
  ema_200: number | null;
  rsi_14: number | null;
  atr_14: number | null;
  average_volume_20: number | null;
  volume_ratio: number | null;
  support_level: number | null;
  resistance_level: number | null;
  trend_state: string;
  candlestick_pattern: string | null;
  indicator_payload: Record<string, unknown>;
  technical_score: number | null;
  trend_score: number | null;
  volume_score: number | null;
  risk_score: number | null;
  invalidation_level: number | null;
  rule_version: string;
  data_quality: MarketDataQuality;
};

export type NormalizedMarketContext = {
  provider_source_id: string;
  provider_name: string;
  market_code: string;
  index_symbol: string;
  observed_at: string;
  index_last: number | null;
  index_change: number | null;
  index_change_percent: number | null;
  index_trend: string;
  market_status: string;
  risk_regime: string;
  breadth_summary: Record<string, unknown>;
  context_payload: Record<string, unknown>;
  data_quality: MarketDataQuality;
  is_stale: boolean;
  staleness_warning: string | null;
};

export type NormalizedProviderSyncRun = {
  provider_name: string;
  provider_status: string;
  data_quality: MarketDataQuality;
  rows_requested: number;
  rows_inserted: number;
  rows_failed: number;
  risk_warning: RiskWarning[];
};

export type MarketCandidateRows = {
  priceSnapshots: NormalizedPriceSnapshot[];
  technicalIndicators: NormalizedTechnicalIndicator[];
  marketContext: NormalizedMarketContext | null;
  dataQuality: MarketDataQuality;
  providerStatus: string;
  riskWarning: RiskWarning[];
  usedProductionAdapter: boolean;
};

export type MarketContextBuildResult = {
  marketContext: NormalizedMarketContext;
  dataQuality: MarketDataQuality;
  providerStatus: string;
  riskWarning: RiskWarning[];
  usedProductionAdapter: boolean;
};

type ProviderQuoteResponse = {
  symbol_code?: unknown;
  symbol?: unknown;
  provider_symbol?: unknown;
  observed_at?: unknown;
  last_price?: unknown;
  price?: unknown;
  previous_close?: unknown;
  open_price?: unknown;
  open?: unknown;
  high_price?: unknown;
  high?: unknown;
  low_price?: unknown;
  low?: unknown;
  change_value?: unknown;
  change?: unknown;
  change_percent?: unknown;
  volume?: unknown;
  value_traded?: unknown;
  market_cap?: unknown;
  currency?: unknown;
};

export const DEFAULT_PROVIDER_NAME = "sample_provider";
export const DEFAULT_MARKET_CODE = "IDX";
export const DEFAULT_INDEX_SYMBOL = "IHSG";
export const SAMPLE_STALENESS_WARNING = "provider belum aktif - sample data";
export const STALE_PROVIDER_WARNING = "provider production belum menghasilkan data baru - memakai fallback aman";
const CONTRACT_VERSION = "p2_market_data_provider_contract_v1";

export function marketProviderName(): string {
  return Deno.env.get("MARKET_DATA_PROVIDER_NAME")?.trim() || DEFAULT_PROVIDER_NAME;
}

export function marketCacheTtlSeconds(): number {
  const raw = Number(Deno.env.get("MARKET_DATA_CACHE_TTL_SECONDS") ?? "900");
  if (!Number.isFinite(raw) || raw < 0) return 900;
  return Math.round(raw);
}

export function resolveProviderRuntime(): ProviderRuntime {
  const requestedProviderName = marketProviderName();
  const requestedMode = (Deno.env.get("MARKET_DATA_PROVIDER_MODE") ?? "").trim().toLowerCase();
  const wantsProduction = requestedMode === "production" || requestedProviderName !== DEFAULT_PROVIDER_NAME;
  const requiredEnv = ["MARKET_DATA_PROVIDER_NAME", "MARKET_DATA_API_BASE_URL", "MARKET_DATA_API_KEY"];
  const missingEnv = wantsProduction
    ? requiredEnv.filter((name) => !Deno.env.get(name)?.trim())
    : [];

  if (!wantsProduction) {
    return {
      requestedProviderName,
      activeProviderName: DEFAULT_PROVIDER_NAME,
      providerType: "sample",
      mode: "sample",
      dataQuality: "sample",
      providerStatus: "provider belum aktif - memakai sample provider",
      cacheTtlSeconds: marketCacheTtlSeconds(),
      isProductionConfigured: false,
      missingEnv,
      riskWarning: [{
        level: "medium",
        message: "Data market memakai sample data karena provider belum aktif.",
      }],
    };
  }

  if (missingEnv.length > 0) {
    return {
      requestedProviderName,
      activeProviderName: DEFAULT_PROVIDER_NAME,
      providerType: "sample",
      mode: "fallback",
      dataQuality: "sample",
      providerStatus: "provider production belum lengkap - fallback sample provider",
      cacheTtlSeconds: marketCacheTtlSeconds(),
      isProductionConfigured: false,
      missingEnv,
      riskWarning: [{
        level: "high",
        message: "Provider production belum lengkap; data hanya sample untuk edukasi.",
      }],
    };
  }

  return {
    requestedProviderName,
    activeProviderName: requestedProviderName,
    providerType: "vendor",
    mode: "production",
    dataQuality: "production",
    providerStatus: "provider production aktif melalui Edge Function",
    cacheTtlSeconds: marketCacheTtlSeconds(),
    isProductionConfigured: true,
    missingEnv,
    riskWarning: [],
  };
}

export function providerMeta(runtime: ProviderRuntime) {
  return {
    provider_name: runtime.activeProviderName,
    requested_provider_name: runtime.requestedProviderName,
    provider_type: runtime.providerType,
    provider_mode: runtime.mode,
    provider_status: runtime.providerStatus,
    data_quality: runtime.dataQuality,
    missing_env: runtime.missingEnv,
  };
}

export function buildRiskWarning(
  quality: MarketDataQuality,
  providerStatus: string,
  additional: RiskWarning[] = [],
): RiskWarning[] {
  if (quality === "production") return additional;
  const baseMessage = quality === "sample"
    ? "Data masih sample; gunakan hanya untuk observasi watchlist candidate."
    : "Data stale; cek ulang sebelum memakai hasil analisis.";
  return [{ level: quality === "sample" ? "medium" : "high", message: baseMessage }, ...additional, {
    level: "medium",
    message: providerStatus,
  }];
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
  providerType: "sample" | "vendor" = providerName === DEFAULT_PROVIDER_NAME ? "sample" : "vendor",
): Promise<ProviderSource> {
  const { data, error } = await supabase
    .from("provider_sources")
    .upsert({
      provider_name: providerName,
      provider_type: providerType,
      supports_quotes: true,
      supports_ohlcv: providerType !== "sample",
      supports_market_context: true,
      supports_news: false,
      cache_ttl_seconds: marketCacheTtlSeconds(),
      status: "active",
      notes: providerType === "sample"
        ? "Development sample provider. provider belum aktif untuk production."
        : "Provider metadata only. Secret disimpan di environment Edge Function.",
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

function nullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function nullableString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeQuality(value: unknown, stale: boolean): MarketDataQuality {
  if (stale) return "stale";
  if (value === "production") return "production";
  if (value === "realtime" || value === "delayed" || value === "computed") return "production";
  if (value === "stale") return "stale";
  return "sample";
}

export function sampleQuote(
  symbol: SymbolRow,
  observedAt: string,
  providerName: string,
  providerSourceId: string,
  dataQuality: MarketDataQuality = "sample",
): NormalizedPriceSnapshot {
  const seed = seedFromText(symbol.symbol_code);
  const previousClose = 800 + (seed % 9000);
  const changePercent = round(((seed % 9) - 4) * 0.42, 2);
  const lastPrice = round(previousClose * (1 + changePercent / 100), 2);
  const spread = Math.max(5, previousClose * 0.012);
  const stale = dataQuality !== "production";

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
    data_quality: dataQuality,
    is_stale: stale,
    staleness_warning: stale
      ? dataQuality === "sample" ? SAMPLE_STALENESS_WARNING : STALE_PROVIDER_WARNING
      : null,
    raw_payload: {
      source: "deterministic_sample",
      contract_version: CONTRACT_VERSION,
      note: "sample data untuk development; provider belum aktif",
    },
  };
}

export function sampleIndicator(
  symbol: SymbolRow,
  observedAt: string,
  providerName: string,
  providerSourceId: string,
  dataQuality: MarketDataQuality = "sample",
): NormalizedTechnicalIndicator {
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
      contract_version: CONTRACT_VERSION,
      note: "technical indicators belum dihitung dari OHLCV provider",
    },
    technical_score: technicalScore,
    trend_score: trendScore,
    volume_score: volumeScore,
    risk_score: riskScore,
    invalidation_level: invalidationLevel,
    rule_version: dataQuality === "production" ? "p2_provider_indicator_contract_v1" : "p2_sample_indicator_v1",
    data_quality: dataQuality,
  };
}

export function sampleMarketContext(
  providerName: string,
  providerSourceId: string,
  observedAt: string,
  dataQuality: MarketDataQuality = "sample",
): NormalizedMarketContext {
  const stale = dataQuality !== "production";
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
    market_status: dataQuality === "production" ? "provider aktif" : "provider belum aktif",
    risk_regime: "needs_more_data",
    breadth_summary: {
      source: dataQuality === "production" ? "provider_contract" : "sample data",
      note: dataQuality === "production"
        ? "Market breadth mengikuti kontrak provider yang dinormalisasi."
        : "Market breadth provider belum aktif.",
    },
    context_payload: {
      label: dataQuality === "production" ? "provider data" : "sample data",
      contract_version: CONTRACT_VERSION,
      disclaimer: "Data market context hanya untuk edukasi.",
    },
    data_quality: dataQuality,
    is_stale: stale,
    staleness_warning: stale
      ? dataQuality === "sample" ? SAMPLE_STALENESS_WARNING : STALE_PROVIDER_WARNING
      : null,
  };
}

export async function buildMarketCandidateRows(
  symbols: SymbolRow[],
  provider: ProviderSource,
  runtime: ProviderRuntime,
  observedAt: string,
  includeMarketContext: boolean,
): Promise<MarketCandidateRows> {
  if (runtime.isProductionConfigured) {
    try {
      const productionRows = await fetchProductionCandidateRows(symbols, provider, runtime, observedAt, includeMarketContext);
      if (productionRows.priceSnapshots.length > 0 || !includeMarketContext || productionRows.marketContext) {
        return productionRows;
      }
    } catch (error) {
      console.warn("Market data provider fallback:", error);
    }
  }

  const fallbackQuality: MarketDataQuality = runtime.mode === "sample" ? "sample" : "stale";
  return {
    priceSnapshots: symbols.map((symbol) =>
      sampleQuote(symbol, observedAt, provider.provider_name, provider.id, fallbackQuality)
    ),
    technicalIndicators: symbols.map((symbol) =>
      sampleIndicator(symbol, observedAt, provider.provider_name, provider.id, fallbackQuality)
    ),
    marketContext: includeMarketContext
      ? sampleMarketContext(provider.provider_name, provider.id, observedAt, fallbackQuality)
      : null,
    dataQuality: fallbackQuality,
    providerStatus: runtime.mode === "sample"
      ? runtime.providerStatus
      : "provider production belum mengembalikan data valid - fallback aman aktif",
    riskWarning: buildRiskWarning(fallbackQuality, runtime.providerStatus, runtime.riskWarning),
    usedProductionAdapter: false,
  };
}

export async function buildMarketContextRow(
  provider: ProviderSource,
  runtime: ProviderRuntime,
  observedAt: string,
): Promise<MarketContextBuildResult> {
  if (runtime.isProductionConfigured) {
    try {
      const marketContext = await fetchProductionMarketContext(provider, observedAt);
      return {
        marketContext,
        dataQuality: marketContext.data_quality,
        providerStatus: marketContext.data_quality === "production"
          ? runtime.providerStatus
          : "provider production aktif tetapi market context stale",
        riskWarning: buildRiskWarning(marketContext.data_quality, runtime.providerStatus, runtime.riskWarning),
        usedProductionAdapter: true,
      };
    } catch (error) {
      console.warn("Market context provider fallback:", error);
    }
  }

  const fallbackQuality: MarketDataQuality = runtime.mode === "sample" ? "sample" : "stale";
  const marketContext = sampleMarketContext(provider.provider_name, provider.id, observedAt, fallbackQuality);
  return {
    marketContext,
    dataQuality: fallbackQuality,
    providerStatus: runtime.mode === "sample"
      ? runtime.providerStatus
      : "provider production belum mengembalikan market context valid - fallback aman aktif",
    riskWarning: buildRiskWarning(fallbackQuality, runtime.providerStatus, runtime.riskWarning),
    usedProductionAdapter: false,
  };
}

async function fetchProductionCandidateRows(
  symbols: SymbolRow[],
  provider: ProviderSource,
  runtime: ProviderRuntime,
  observedAt: string,
  includeMarketContext: boolean,
): Promise<MarketCandidateRows> {
  const quotePayload = await providerPostJson("/quotes", {
    symbol_codes: symbols.map((symbol) => symbol.symbol_code),
  });
  const quoteItems = extractArrayPayload(quotePayload, ["quotes", "data", "items"]);
  const quoteBySymbol = new Map<string, ProviderQuoteResponse>();
  for (const item of quoteItems) {
    if (!isRecord(item)) continue;
    const symbolCode = (item.symbol_code ?? item.symbol ?? item.provider_symbol)?.toString().trim().toUpperCase();
    if (symbolCode) quoteBySymbol.set(symbolCode, item as ProviderQuoteResponse);
  }

  const priceSnapshots: NormalizedPriceSnapshot[] = [];
  const technicalIndicators: NormalizedTechnicalIndicator[] = [];
  const fallbackWarnings: RiskWarning[] = [];
  for (const symbol of symbols) {
    const providerItem = quoteBySymbol.get(symbol.symbol_code);
    if (!providerItem) {
      fallbackWarnings.push({
        level: "medium",
        message: `${symbol.symbol_code} belum tersedia dari provider; memakai fallback stale.`,
      });
      priceSnapshots.push(sampleQuote(symbol, observedAt, provider.provider_name, provider.id, "stale"));
      technicalIndicators.push(sampleIndicator(symbol, observedAt, provider.provider_name, provider.id, "stale"));
      continue;
    }

    const normalizedQuote = normalizeProviderQuote(symbol, providerItem, observedAt, provider);
    if (!hasUsablePriceSnapshot(normalizedQuote)) {
      fallbackWarnings.push({
        level: "medium",
        message: `${symbol.symbol_code} payload provider belum punya price/volume valid; memakai fallback stale.`,
      });
      priceSnapshots.push(sampleQuote(symbol, observedAt, provider.provider_name, provider.id, "stale"));
      technicalIndicators.push(sampleIndicator(symbol, observedAt, provider.provider_name, provider.id, "stale"));
      continue;
    }

    priceSnapshots.push(normalizedQuote);
    technicalIndicators.push(sampleIndicator(symbol, observedAt, provider.provider_name, provider.id, "stale"));
  }

  const marketContext = includeMarketContext
    ? await fetchProductionMarketContext(provider, observedAt).catch(() =>
      sampleMarketContext(provider.provider_name, provider.id, observedAt, "stale")
    )
    : null;

  const hasFallback = fallbackWarnings.length > 0 || technicalIndicators.some((row) => row.data_quality !== "production") ||
    Boolean(marketContext && marketContext.data_quality !== "production");
  const dataQuality: MarketDataQuality = hasFallback ? "stale" : "production";

  return {
    priceSnapshots,
    technicalIndicators,
    marketContext,
    dataQuality,
    providerStatus: hasFallback
      ? "provider production aktif dengan sebagian data fallback"
      : runtime.providerStatus,
    riskWarning: buildRiskWarning(dataQuality, runtime.providerStatus, fallbackWarnings),
    usedProductionAdapter: true,
  };
}

function normalizeProviderQuote(
  symbol: SymbolRow,
  item: ProviderQuoteResponse,
  fallbackObservedAt: string,
  provider: ProviderSource,
): NormalizedPriceSnapshot {
  const observedAt = nullableString(item.observed_at) ?? fallbackObservedAt;
  const stale = isStale(observedAt, provider.cache_ttl_seconds);
  const dataQuality = normalizeQuality("production", stale);
  const lastPrice = nullableNumber(item.last_price ?? item.price);
  const previousClose = nullableNumber(item.previous_close);

  return {
    symbol_id: symbol.id,
    symbol_code: symbol.symbol_code,
    provider_source_id: provider.id,
    provider_name: provider.provider_name,
    provider_symbol: nullableString(item.provider_symbol ?? item.symbol) ?? symbol.symbol_code,
    observed_at: observedAt,
    last_price: lastPrice,
    previous_close: previousClose,
    open_price: nullableNumber(item.open_price ?? item.open),
    high_price: nullableNumber(item.high_price ?? item.high),
    low_price: nullableNumber(item.low_price ?? item.low),
    change_value: nullableNumber(item.change_value ?? item.change),
    change_percent: nullableNumber(item.change_percent),
    volume: nullableNumber(item.volume),
    value_traded: nullableNumber(item.value_traded),
    market_cap: nullableNumber(item.market_cap),
    currency: nullableString(item.currency) ?? symbol.currency ?? "IDR",
    data_quality: dataQuality,
    is_stale: stale,
    staleness_warning: stale ? STALE_PROVIDER_WARNING : null,
    raw_payload: {
      source: "normalized_provider",
      contract_version: CONTRACT_VERSION,
      captured_fields: Object.keys(item).filter((key) => !key.toLowerCase().includes("key")),
    },
  };
}

function hasUsablePriceSnapshot(row: NormalizedPriceSnapshot): boolean {
  return row.last_price !== null || row.previous_close !== null || row.volume !== null;
}

async function fetchProductionMarketContext(
  provider: ProviderSource,
  observedAt: string,
): Promise<NormalizedMarketContext> {
  const payload = await providerPostJson("/market-context", {
    market_code: DEFAULT_MARKET_CODE,
    index_symbol: DEFAULT_INDEX_SYMBOL,
  });
  const context = extractRecordPayload(payload, ["market_context", "context", "data"]);
  const contextObservedAt = nullableString(context.observed_at) ?? observedAt;
  const stale = isStale(contextObservedAt, provider.cache_ttl_seconds);
  const dataQuality = normalizeQuality("production", stale);

  return {
    provider_source_id: provider.id,
    provider_name: provider.provider_name,
    market_code: nullableString(context.market_code) ?? DEFAULT_MARKET_CODE,
    index_symbol: nullableString(context.index_symbol) ?? DEFAULT_INDEX_SYMBOL,
    observed_at: contextObservedAt,
    index_last: nullableNumber(context.index_last),
    index_change: nullableNumber(context.index_change),
    index_change_percent: nullableNumber(context.index_change_percent),
    index_trend: nullableString(context.index_trend) ?? "needs_more_data",
    market_status: nullableString(context.market_status) ?? "provider aktif",
    risk_regime: nullableString(context.risk_regime) ?? "needs_more_data",
    breadth_summary: isRecord(context.breadth_summary) ? context.breadth_summary : {},
    context_payload: {
      label: "provider data",
      contract_version: CONTRACT_VERSION,
      disclaimer: "Data market context hanya untuk edukasi.",
    },
    data_quality: dataQuality,
    is_stale: stale,
    staleness_warning: stale ? STALE_PROVIDER_WARNING : null,
  };
}

async function providerPostJson(pathKey: "/quotes" | "/market-context", body: Record<string, unknown>): Promise<unknown> {
  const baseUrl = Deno.env.get("MARKET_DATA_API_BASE_URL")?.trim();
  const apiKey = Deno.env.get("MARKET_DATA_API_KEY")?.trim();
  if (!baseUrl || !apiKey) throw new Error("Market data provider env is incomplete");

  const pathEnv = pathKey === "/quotes" ? "MARKET_DATA_QUOTES_PATH" : "MARKET_DATA_CONTEXT_PATH";
  const configuredPath = Deno.env.get(pathEnv)?.trim() || pathKey;
  const url = new URL(configuredPath, baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`);
  const headerName = Deno.env.get("MARKET_DATA_API_KEY_HEADER")?.trim() || "Authorization";
  const headerValuePrefix = Deno.env.get("MARKET_DATA_API_KEY_PREFIX")?.trim() ?? "Bearer";
  const authValue = headerValuePrefix ? `${headerValuePrefix} ${apiKey}` : apiKey;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        [headerName]: authValue,
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    if (!response.ok) throw new Error(`Provider returned HTTP ${response.status}`);
    return await response.json();
  } finally {
    clearTimeout(timeout);
  }
}

function extractArrayPayload(payload: unknown, keys: string[]): unknown[] {
  if (Array.isArray(payload)) return payload;
  if (!isRecord(payload)) return [];
  for (const key of keys) {
    const value = payload[key];
    if (Array.isArray(value)) return value;
  }
  return [];
}

function extractRecordPayload(payload: unknown, keys: string[]): Record<string, unknown> {
  if (!isRecord(payload)) return {};
  for (const key of keys) {
    const value = payload[key];
    if (isRecord(value)) return value;
  }
  return payload;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function sanitizeMarketContext(
  row: Record<string, unknown> | null,
  ttlSeconds: number,
  runtime?: ProviderRuntime,
) {
  const stale = row ? Boolean(row.is_stale) || isStale(row.observed_at as string, ttlSeconds) : true;
  const dataQuality = normalizeQuality(row?.data_quality, stale);
  const rowProviderName = typeof row?.provider_name === "string" ? row.provider_name : null;
  const rowUsesFallbackProvider = Boolean(runtime && rowProviderName && rowProviderName !== runtime.activeProviderName);
  const providerStatus = dataQuality === "production"
    ? runtime?.providerStatus ?? "provider production aktif"
    : rowUsesFallbackProvider
    ? "provider production belum mengembalikan data valid - fallback cache aktif"
    : runtime?.providerStatus ?? "provider belum aktif atau cache stale";

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
    data_quality: dataQuality,
    provider_status: providerStatus,
    is_stale: stale,
    staleness_warning: row?.staleness_warning ?? (stale ? STALE_PROVIDER_WARNING : null),
    risk_warning: buildRiskWarning(dataQuality, providerStatus, runtime?.riskWarning ?? []),
  };
}

export function toPriceSnapshotDbRow(row: NormalizedPriceSnapshot) {
  return {
    ...row,
    data_quality: row.data_quality === "production" ? "realtime" : row.data_quality,
  };
}

export function toTechnicalIndicatorDbRow(row: NormalizedTechnicalIndicator) {
  return {
    ...row,
    data_quality: row.data_quality === "production" ? "computed" : row.data_quality,
  };
}

export function toMarketContextDbRow(row: NormalizedMarketContext) {
  return {
    ...row,
    data_quality: row.data_quality === "production" ? "realtime" : row.data_quality,
  };
}
