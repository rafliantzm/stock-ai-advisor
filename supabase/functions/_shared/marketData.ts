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

export type MarketDataQuality = "sample" | "stale" | "live" | "delayed" | "production";

export type ProviderRuntime = {
  requestedProviderName: string;
  activeProviderName: string;
  providerType: "sample" | "vendor";
  mode: ProviderMode;
  dataQuality: MarketDataQuality;
  providerStatus: string;
  providerAdapter: string;
  cacheTtlSeconds: number;
  isLiveConfigured: boolean;
  missingEnv: string[];
  riskWarning: RiskWarning[];
};

export type ProviderMode = "sample" | "live" | "fallback_sample" | "provider_error";

export type RiskWarning = {
  level: "low" | "medium" | "high";
  message: string;
};

export type ProviderDiagnostics = {
  provider_configured: boolean;
  provider_host: string | null;
  requested_symbol_count?: number;
  provider_http_status?: number;
  provider_status_code?: number;
  provider_content_type?: string | null;
  json_top_level_keys?: string[];
  provider_response_keys?: string[];
  symbol_diagnostics?: ProviderSymbolDiagnostics[];
  provider_attempts?: ProviderAttemptDiagnostics[];
  selected_provider?: string;
  fallback_provider_used?: boolean;
  provider_failover_reason?: string;
  secondary_provider_configured?: boolean;
  secondary_provider_name?: string;
  secondary_provider_host?: string | null;
  secondary_provider_status_code?: number;
  secondary_provider_content_type?: string | null;
  secondary_provider_response_keys?: string[];
  secondary_provider_fallback_reason?: string;
  fallback_reason: string;
};

export type ProviderAttemptDiagnostics = {
  provider_name: string;
  provider_role: "primary" | "secondary" | "sample";
  provider_configured: boolean;
  provider_status: "attempted" | "skipped" | "selected" | "fallback";
  data_quality: MarketDataQuality;
  fallback_reason: string;
};

export type ProviderSymbolDiagnostics = {
  requested_symbol: string;
  attempted_provider_symbols: string[];
  selected_provider_symbol: string | null;
  fallback_reason: string;
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
  provider_symbol: string;
  timeframe: string;
  observed_at: string;
  open_price: number;
  high_price: number;
  low_price: number;
  close_price: number;
  volume: number | null;
  value_traded: number | null;
  data_quality: MarketDataQuality;
  raw_payload: Record<string, unknown>;
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
  ohlcvBars: NormalizedOhlcvBar[];
  technicalIndicators: NormalizedTechnicalIndicator[];
  marketContext: NormalizedMarketContext | null;
  liveSymbols: string[];
  fallbackSymbols: string[];
  dataQuality: MarketDataQuality;
  providerStatus: string;
  riskWarning: RiskWarning[];
  usedLiveAdapter: boolean;
  providerMode: ProviderMode;
  diagnostics?: ProviderDiagnostics;
};

export type MarketContextBuildResult = {
  marketContext: NormalizedMarketContext;
  dataQuality: MarketDataQuality;
  providerStatus: string;
  riskWarning: RiskWarning[];
  usedLiveAdapter: boolean;
  providerMode: ProviderMode;
  diagnostics?: ProviderDiagnostics;
};

type ProviderJsonResult = {
  payload: unknown;
  diagnostics: ProviderDiagnostics;
};

type ProviderQuoteResponse = {
  symbol_code?: unknown;
  symbol?: unknown;
  provider_symbol?: unknown;
  company_name?: unknown;
  name?: unknown;
  observed_at?: unknown;
  source_time?: unknown;
  timestamp?: unknown;
  time?: unknown;
  date?: unknown;
  last_price?: unknown;
  price?: unknown;
  close_price?: unknown;
  close?: unknown;
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
  data_quality?: unknown;
  is_delayed?: unknown;
};

type AlphaVantageQuoteResult = {
  quote: Record<string, unknown>;
  providerSymbol: string;
  attemptedProviderSymbols: string[];
  diagnostics: ProviderDiagnostics;
};

type AlphaVantageStopState = {
  diagnostics: ProviderDiagnostics;
  reason: string;
};

type SecondaryProviderQuoteResult = {
  quote: ProviderQuoteResponse;
  providerSymbol: string;
  attemptedProviderSymbols: string[];
  diagnostics: ProviderDiagnostics;
};

export const DEFAULT_PROVIDER_NAME = "sample_provider";
export const DEFAULT_MARKET_CODE = "IDX";
export const DEFAULT_INDEX_SYMBOL = "IHSG";
export const SAMPLE_STALENESS_WARNING = "provider belum aktif - sample data";
export const STALE_PROVIDER_WARNING = "provider live belum menghasilkan data baru - memakai fallback aman";
const CONTRACT_VERSION = "p2_market_data_live_provider_contract_v1";

class ProviderFetchError extends Error {
  diagnostics: ProviderDiagnostics;

  constructor(message: string, diagnostics: ProviderDiagnostics) {
    super(message);
    this.name = "ProviderFetchError";
    this.diagnostics = diagnostics;
  }
}

export function marketProviderName(): string {
  return envFirst(["MARKET_DATA_PROVIDER", "MARKET_DATA_PROVIDER_NAME"]) || DEFAULT_PROVIDER_NAME;
}

export function marketCacheTtlSeconds(): number {
  const raw = Number(Deno.env.get("MARKET_DATA_CACHE_TTL_SECONDS") ?? "900");
  if (!Number.isFinite(raw) || raw < 0) return 900;
  return Math.round(raw);
}

export function resolveProviderRuntime(): ProviderRuntime {
  const requestedProviderName = marketProviderName();
  const requestedMode = normalizeProviderMode(Deno.env.get("MARKET_DATA_PROVIDER_MODE"));
  const providerAdapter = liveProviderAdapterName();
  const wantsLive = requestedMode === "live" || requestedProviderName !== DEFAULT_PROVIDER_NAME;
  const missingEnv = wantsLive ? missingLiveProviderConfigNames() : [];

  if (!wantsLive) {
    return {
      requestedProviderName,
      activeProviderName: DEFAULT_PROVIDER_NAME,
      providerType: "sample",
      mode: "sample",
      dataQuality: "sample",
      providerStatus: "provider belum aktif - memakai sample provider",
      providerAdapter,
      cacheTtlSeconds: marketCacheTtlSeconds(),
      isLiveConfigured: false,
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
      mode: "fallback_sample",
      dataQuality: "sample",
      providerStatus: "provider live belum lengkap - fallback sample provider",
      providerAdapter,
      cacheTtlSeconds: marketCacheTtlSeconds(),
      isLiveConfigured: false,
      missingEnv,
      riskWarning: [{
        level: "high",
        message: "Provider live belum lengkap; data hanya sample untuk edukasi.",
      }],
    };
  }

  return {
    requestedProviderName,
    activeProviderName: requestedProviderName,
    providerType: "vendor",
    mode: "live",
    dataQuality: "live",
    providerStatus: "provider live aktif melalui Edge Function",
    providerAdapter,
    cacheTtlSeconds: marketCacheTtlSeconds(),
    isLiveConfigured: true,
    missingEnv,
    riskWarning: [],
  };
}

function normalizeProviderMode(value: string | undefined | null): "sample" | "live" {
  const normalized = value?.trim().toLowerCase();
  if (normalized === "live" || normalized === "production") return "live";
  return "sample";
}

function liveProviderAdapterName(): string {
  const configuredAdapter = Deno.env.get("MARKET_DATA_PROVIDER_ADAPTER")?.trim().toLowerCase();
  if (configuredAdapter) return configuredAdapter;

  const providerName = marketProviderName().trim().toLowerCase();
  if (providerName === "alpha_vantage" || providerName === "alphavantage") return "alpha_vantage";
  return "generic_json";
}

function envFirst(names: string[]): string | null {
  for (const name of names) {
    const value = Deno.env.get(name)?.trim();
    if (value) return value;
  }
  return null;
}

function missingLiveProviderConfigNames(): string[] {
  const missing: string[] = [];
  if (!envFirst(["MARKET_DATA_PROVIDER", "MARKET_DATA_PROVIDER_NAME"])) missing.push("provider");
  if (!envFirst(["MARKET_DATA_PROVIDER_BASE_URL", "MARKET_DATA_API_BASE_URL"])) missing.push("base_url");
  if (!envFirst(["MARKET_DATA_PROVIDER_API_KEY", "MARKET_DATA_API_KEY"])) missing.push("api_key");
  return missing;
}

function buildProviderDiagnostics(
  runtime: ProviderRuntime,
  requestedSymbolCount: number | undefined,
  fallbackReason: string,
): ProviderDiagnostics {
  return buildProviderDiagnosticsFromConfig(
    envFirst(["MARKET_DATA_PROVIDER_BASE_URL", "MARKET_DATA_API_BASE_URL"]),
    runtime.isLiveConfigured,
    requestedSymbolCount,
    fallbackReason,
  );
}

function buildProviderDiagnosticsFromConfig(
  baseUrl: string | null,
  hasApiKey: boolean,
  requestedSymbolCount: number | undefined,
  fallbackReason: string,
): ProviderDiagnostics {
  return {
    provider_configured: Boolean(baseUrl && hasApiKey),
    provider_host: safeProviderHost(baseUrl),
    requested_symbol_count: requestedSymbolCount,
    fallback_reason: fallbackReason,
  };
}

function diagnosticsFromError(
  error: unknown,
  runtime: ProviderRuntime,
  requestedSymbolCount: number | undefined,
  fallbackReason: string,
): ProviderDiagnostics {
  if (error instanceof ProviderFetchError) return error.diagnostics;
  return buildProviderDiagnostics(runtime, requestedSymbolCount, fallbackReason);
}

export function marketSecondaryProviderName(): string {
  return envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER",
    "MARKET_DATA_SECONDARY_PROVIDER",
    "MARKET_DATA_SECONDARY_PROVIDER_NAME",
    "MARKET_DATA_FALLBACK_PROVIDER",
    "MARKET_DATA_FALLBACK_PROVIDER_NAME",
  ]) ?? "secondary_provider";
}

function secondaryProviderBaseUrl(): string | null {
  return envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_BASE_URL",
    "MARKET_DATA_SECONDARY_PROVIDER_BASE_URL",
    "MARKET_DATA_SECONDARY_API_BASE_URL",
    "MARKET_DATA_FALLBACK_PROVIDER_BASE_URL",
    "MARKET_DATA_FALLBACK_API_BASE_URL",
  ]);
}

function secondaryProviderApiKey(): string | null {
  return envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_API_KEY",
    "MARKET_DATA_SECONDARY_PROVIDER_API_KEY",
    "MARKET_DATA_SECONDARY_API_KEY",
    "MARKET_DATA_FALLBACK_PROVIDER_API_KEY",
    "MARKET_DATA_FALLBACK_API_KEY",
  ]);
}

export function hasSecondaryProviderConfig(): boolean {
  return Boolean(
    envFirst([
      "SECONDARY_MARKET_DATA_PROVIDER",
      "MARKET_DATA_SECONDARY_PROVIDER",
      "MARKET_DATA_SECONDARY_PROVIDER_NAME",
      "MARKET_DATA_FALLBACK_PROVIDER",
      "MARKET_DATA_FALLBACK_PROVIDER_NAME",
    ]) && secondaryProviderBaseUrl() && secondaryProviderApiKey(),
  );
}

function secondaryProviderFallbackReason(): string {
  return hasSecondaryProviderConfig()
    ? "secondary_provider_no_valid_quote"
    : "secondary_provider_not_configured";
}

function secondaryProviderDiagnostics(
  fallbackReason: string,
  statusCode?: number,
  responseKeys?: string[],
  contentType?: string | null,
): Pick<
  ProviderDiagnostics,
  | "secondary_provider_configured"
  | "secondary_provider_name"
  | "secondary_provider_host"
  | "secondary_provider_status_code"
  | "secondary_provider_content_type"
  | "secondary_provider_response_keys"
  | "secondary_provider_fallback_reason"
> {
  return {
    secondary_provider_configured: hasSecondaryProviderConfig(),
    secondary_provider_name: marketSecondaryProviderName(),
    secondary_provider_host: safeProviderHost(secondaryProviderBaseUrl()),
    secondary_provider_status_code: statusCode,
    secondary_provider_content_type: contentType,
    secondary_provider_response_keys: responseKeys,
    secondary_provider_fallback_reason: fallbackReason,
  };
}

function providerFallbackAttempts(
  runtime: ProviderRuntime,
  selectedProvider: string,
  fallbackProviderUsed: boolean,
  secondaryProviderUsed: boolean,
  failoverReason: string,
  dataQuality: MarketDataQuality,
): ProviderAttemptDiagnostics[] {
  const attempts: ProviderAttemptDiagnostics[] = [{
    provider_name: runtime.activeProviderName,
    provider_role: "primary",
    provider_configured: runtime.isLiveConfigured,
    provider_status: selectedProvider === runtime.activeProviderName ? "selected" : "attempted",
    data_quality: selectedProvider === runtime.activeProviderName ? dataQuality : "stale",
    fallback_reason: failoverReason,
  }];

  const secondaryProviderConfigured = hasSecondaryProviderConfig();
  attempts.push({
    provider_name: marketSecondaryProviderName(),
    provider_role: "secondary",
    provider_configured: secondaryProviderConfigured,
    provider_status: secondaryProviderUsed
      ? selectedProvider === marketSecondaryProviderName() ? "selected" : "attempted"
      : secondaryProviderConfigured && fallbackProviderUsed
      ? "attempted"
      : "skipped",
    data_quality: secondaryProviderUsed ? dataQuality : "stale",
    fallback_reason: secondaryProviderUsed ? "none" : secondaryProviderFallbackReason(),
  });

  attempts.push({
    provider_name: DEFAULT_PROVIDER_NAME,
    provider_role: "sample",
    provider_configured: true,
    provider_status: fallbackProviderUsed ? "fallback" : "skipped",
    data_quality: fallbackProviderUsed ? "stale" : dataQuality,
    fallback_reason: fallbackProviderUsed ? failoverReason : "not_needed",
  });

  return attempts;
}

function withProviderFallbackDiagnostics(
  diagnostics: ProviderDiagnostics | undefined,
  runtime: ProviderRuntime,
  dataQuality: MarketDataQuality,
  fallbackProviderUsed: boolean,
  failoverReason: string,
  secondaryProviderUsed = false,
): ProviderDiagnostics | undefined {
  if (!diagnostics) return undefined;
  const selectedProvider = fallbackProviderUsed
    ? DEFAULT_PROVIDER_NAME
    : secondaryProviderUsed
    ? marketSecondaryProviderName()
    : runtime.activeProviderName;
  return {
    ...diagnostics,
    provider_attempts: providerFallbackAttempts(
      runtime,
      selectedProvider,
      fallbackProviderUsed,
      secondaryProviderUsed,
      failoverReason,
      dataQuality,
    ),
    selected_provider: selectedProvider,
    fallback_provider_used: fallbackProviderUsed,
    provider_failover_reason: failoverReason,
    ...secondaryProviderDiagnostics(secondaryProviderFallbackReason()),
  };
}

function safeProviderHost(baseUrl: string | null): string | null {
  if (!baseUrl) return null;
  try {
    return new URL(baseUrl).hostname;
  } catch {
    return null;
  }
}

function requestedSymbolCountFromBody(body: Record<string, unknown>): number | undefined {
  const symbols = body.symbol_codes;
  return Array.isArray(symbols) ? symbols.length : undefined;
}

function topLevelJsonKeys(payload: unknown): string[] {
  if (Array.isArray(payload)) return ["array"];
  if (!isRecord(payload)) return [];
  return Object.keys(payload)
    .filter((key) => !/key|token|secret|authorization|credential|password/i.test(key))
    .slice(0, 20);
}

export function providerMeta(runtime: ProviderRuntime) {
  return {
    provider_name: runtime.activeProviderName,
    requested_provider_name: runtime.requestedProviderName,
    provider_type: runtime.providerType,
    provider_mode: runtime.mode,
    provider_adapter: runtime.providerAdapter,
    provider_status: runtime.providerStatus,
    data_quality: runtime.dataQuality,
    missing_env_count: runtime.missingEnv.length,
  };
}

export function buildRiskWarning(
  quality: MarketDataQuality,
  providerStatus: string,
  additional: RiskWarning[] = [],
): RiskWarning[] {
  if (isProviderFreshQuality(quality)) return additional;
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
        ? "Development sample provider. provider live belum aktif."
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

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, round(value, 2)));
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
  if (value === "live") return "live";
  if (value === "delayed") return "delayed";
  if (value === "production") return "production";
  if (value === "realtime" || value === "computed") return "live";
  if (value === "stale") return "stale";
  return "sample";
}

function normalizeProviderDataQuality(value: unknown, stale: boolean, delayed: boolean): MarketDataQuality {
  if (stale) return "stale";
  const normalized = value?.toString().trim().toLowerCase();
  if (normalized === "delayed" || delayed) return "delayed";
  if (normalized === "live" || normalized === "realtime" || normalized === "production") return "live";
  return "live";
}

function isProviderFreshQuality(value: MarketDataQuality): boolean {
  return value === "live" || value === "delayed" || value === "production";
}

function mergeProviderQualities(values: MarketDataQuality[]): MarketDataQuality {
  if (values.includes("stale")) return "stale";
  if (values.includes("sample") || values.length === 0) return "sample";
  if (values.includes("delayed")) return "delayed";
  return "live";
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
  const stale = !isProviderFreshQuality(dataQuality);

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
    rule_version: isProviderFreshQuality(dataQuality) ? "p2_provider_indicator_contract_v1" : "p2_sample_indicator_v1",
    data_quality: dataQuality,
  };
}

export function sampleMarketContext(
  providerName: string,
  providerSourceId: string,
  observedAt: string,
  dataQuality: MarketDataQuality = "sample",
): NormalizedMarketContext {
  const stale = !isProviderFreshQuality(dataQuality);
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
    market_status: isProviderFreshQuality(dataQuality) ? "provider aktif" : "provider belum aktif",
    risk_regime: "needs_more_data",
    breadth_summary: {
      source: isProviderFreshQuality(dataQuality) ? "provider_contract" : "sample data",
      note: isProviderFreshQuality(dataQuality)
        ? "Market breadth mengikuti kontrak provider yang dinormalisasi."
        : "Market breadth provider belum aktif.",
    },
    context_payload: {
      label: isProviderFreshQuality(dataQuality) ? "provider data" : "sample data",
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
  fallbackProvider: ProviderSource = provider,
  secondaryProvider?: ProviderSource,
): Promise<MarketCandidateRows> {
  if (runtime.isLiveConfigured) {
    try {
      const liveRows = await fetchLiveCandidateRows(
        symbols,
        provider,
        fallbackProvider,
        runtime,
        observedAt,
        includeMarketContext,
        secondaryProvider,
      );
      if (liveRows.priceSnapshots.length > 0 || !includeMarketContext || liveRows.marketContext) {
        return liveRows;
      }
    } catch (error) {
      const diagnostics = diagnosticsFromError(error, runtime, symbols.length, "provider_fetch_failed");
      console.warn("Market data provider fallback:", diagnostics);
      return buildFallbackCandidateRows(
        symbols,
        fallbackProvider,
        runtime,
        observedAt,
        includeMarketContext,
        "provider_error",
        "provider live error - fallback sample aktif",
        [{
          level: "high",
          message: "Provider live belum bisa dipakai saat ini; data fallback hanya untuk observasi watchlist candidate.",
        }],
        diagnostics,
      );
    }
  }

  return buildFallbackCandidateRows(
    symbols,
    provider,
    runtime,
    observedAt,
    includeMarketContext,
    runtime.mode === "sample" ? "sample" : "fallback_sample",
    runtime.mode === "sample"
      ? runtime.providerStatus
      : "provider live belum lengkap - fallback sample aktif",
    runtime.riskWarning,
    runtime.mode === "sample" ? undefined : buildProviderDiagnostics(runtime, symbols.length, "provider_env_incomplete"),
  );
}

function buildFallbackCandidateRows(
  symbols: SymbolRow[],
  provider: ProviderSource,
  runtime: ProviderRuntime,
  observedAt: string,
  includeMarketContext: boolean,
  providerMode: ProviderMode,
  providerStatus: string,
  additionalWarnings: RiskWarning[],
  diagnostics?: ProviderDiagnostics,
): MarketCandidateRows {
  const fallbackQuality: MarketDataQuality = providerMode === "provider_error" ? "stale" : "sample";
  const fallbackDiagnostics = diagnostics?.provider_attempts
    ? diagnostics
    : withProviderFallbackDiagnostics(
      diagnostics,
      runtime,
      fallbackQuality,
      providerMode !== "sample",
      diagnostics?.fallback_reason ?? (providerMode === "sample" ? "not_needed" : "provider_fallback_active"),
    );
  return {
    priceSnapshots: symbols.map((symbol) =>
      sampleQuote(symbol, observedAt, provider.provider_name, provider.id, fallbackQuality)
    ),
    ohlcvBars: [],
    technicalIndicators: symbols.map((symbol) =>
      sampleIndicator(symbol, observedAt, provider.provider_name, provider.id, fallbackQuality)
    ),
    marketContext: includeMarketContext
      ? sampleMarketContext(provider.provider_name, provider.id, observedAt, fallbackQuality)
      : null,
    liveSymbols: [],
    fallbackSymbols: symbols.map((symbol) => symbol.symbol_code),
    dataQuality: fallbackQuality,
    providerStatus,
    riskWarning: buildRiskWarning(fallbackQuality, providerStatus, additionalWarnings),
    usedLiveAdapter: false,
    providerMode,
    diagnostics: fallbackDiagnostics,
  };
}

export async function buildMarketContextRow(
  provider: ProviderSource,
  runtime: ProviderRuntime,
  observedAt: string,
  fallbackProvider: ProviderSource = provider,
): Promise<MarketContextBuildResult> {
  if (runtime.isLiveConfigured) {
    try {
      assertSupportedLiveAdapter(runtime);
      const marketContext = runtime.providerAdapter === "alpha_vantage"
        ? await fetchAlphaVantageMarketContext(provider, observedAt)
        : await fetchLiveMarketContext(provider, observedAt);
      return {
        marketContext,
        dataQuality: marketContext.data_quality,
        providerStatus: isProviderFreshQuality(marketContext.data_quality)
          ? runtime.providerStatus
          : "provider live aktif tetapi market context stale",
        riskWarning: buildRiskWarning(marketContext.data_quality, runtime.providerStatus, runtime.riskWarning),
        usedLiveAdapter: true,
        providerMode: isProviderFreshQuality(marketContext.data_quality) ? "live" : "provider_error",
      };
    } catch (error) {
      const diagnostics = diagnosticsFromError(error, runtime, undefined, "market_context_fetch_failed");
      console.warn("Market context provider fallback:", diagnostics);
      const marketContext = sampleMarketContext(fallbackProvider.provider_name, fallbackProvider.id, observedAt, "stale");
      const providerStatus = "provider live error - fallback sample aktif";
      const fallbackDiagnostics = withProviderFallbackDiagnostics(
        diagnostics,
        runtime,
        "stale",
        true,
        diagnostics.fallback_reason,
      );
      return {
        marketContext,
        dataQuality: "stale",
        providerStatus,
        riskWarning: buildRiskWarning("stale", providerStatus, [{
          level: "high",
          message: "Market context live belum tersedia; fallback stale digunakan.",
        }]),
        usedLiveAdapter: false,
        providerMode: "provider_error",
        diagnostics: fallbackDiagnostics,
      };
    }
  }

  const providerMode: ProviderMode = runtime.mode === "sample" ? "sample" : "fallback_sample";
  const fallbackQuality: MarketDataQuality = providerMode === "fallback_sample" ? "sample" : "stale";
  const marketContext = sampleMarketContext(provider.provider_name, provider.id, observedAt, fallbackQuality);
  const providerStatus = runtime.mode === "sample"
    ? runtime.providerStatus
    : "provider live belum lengkap - fallback sample aktif";
  return {
    marketContext,
    dataQuality: fallbackQuality,
    providerStatus,
    riskWarning: buildRiskWarning(fallbackQuality, providerStatus, runtime.riskWarning),
    usedLiveAdapter: false,
    providerMode,
    diagnostics: runtime.mode === "sample"
      ? undefined
      : withProviderFallbackDiagnostics(
        buildProviderDiagnostics(runtime, undefined, "provider_env_incomplete"),
        runtime,
        fallbackQuality,
        true,
        "provider_env_incomplete",
      ),
  };
}

async function fetchLiveCandidateRows(
  symbols: SymbolRow[],
  provider: ProviderSource,
  fallbackProvider: ProviderSource,
  runtime: ProviderRuntime,
  observedAt: string,
  includeMarketContext: boolean,
  secondaryProvider?: ProviderSource,
): Promise<MarketCandidateRows> {
  assertSupportedLiveAdapter(runtime);
  if (runtime.providerAdapter === "alpha_vantage") {
    return fetchAlphaVantageCandidateRows(symbols, provider, fallbackProvider, runtime, observedAt, includeMarketContext, secondaryProvider);
  }

  const quoteResult = await providerPostJson("/quotes", {
    symbol_codes: symbols.map((symbol) => symbol.symbol_code),
  });
  const quotePayload = quoteResult.payload;
  const diagnostics = { ...quoteResult.diagnostics };
  const quoteItems = extractArrayPayload(quotePayload, ["quotes", "data", "items"]);
  if (quoteItems.length === 0) {
    throw new ProviderFetchError("Provider JSON does not contain quote items", {
      ...diagnostics,
      fallback_reason: "provider_json_missing_quotes",
    });
  }
  const quoteBySymbol = new Map<string, ProviderQuoteResponse>();
  for (const item of quoteItems) {
    if (!isRecord(item)) continue;
    const symbolCode = (item.symbol_code ?? item.symbol ?? item.provider_symbol)?.toString().trim().toUpperCase();
    if (symbolCode) quoteBySymbol.set(symbolCode, item as ProviderQuoteResponse);
  }

  const priceSnapshots: NormalizedPriceSnapshot[] = [];
  const ohlcvBars: NormalizedOhlcvBar[] = [];
  const technicalIndicators: NormalizedTechnicalIndicator[] = [];
  const fallbackWarnings: RiskWarning[] = [];
  const liveSymbols: string[] = [];
  const fallbackSymbols: string[] = [];
  for (const symbol of symbols) {
    const providerItem = quoteBySymbol.get(symbol.symbol_code);
    if (!providerItem) {
      fallbackSymbols.push(symbol.symbol_code);
      fallbackWarnings.push({
        level: "medium",
        message: `${symbol.symbol_code} belum tersedia dari provider; memakai fallback stale.`,
      });
      priceSnapshots.push(sampleQuote(symbol, observedAt, fallbackProvider.provider_name, fallbackProvider.id, "stale"));
      technicalIndicators.push(
        sampleIndicator(symbol, observedAt, fallbackProvider.provider_name, fallbackProvider.id, "stale"),
      );
      continue;
    }

    const normalizedQuote = normalizeProviderQuote(symbol, providerItem, observedAt, provider);
    if (!hasUsablePriceSnapshot(normalizedQuote)) {
      fallbackSymbols.push(symbol.symbol_code);
      fallbackWarnings.push({
        level: "medium",
        message: `${symbol.symbol_code} payload provider belum punya price/volume valid; memakai fallback stale.`,
      });
      priceSnapshots.push(sampleQuote(symbol, observedAt, fallbackProvider.provider_name, fallbackProvider.id, "stale"));
      technicalIndicators.push(
        sampleIndicator(symbol, observedAt, fallbackProvider.provider_name, fallbackProvider.id, "stale"),
      );
      continue;
    }

    priceSnapshots.push(normalizedQuote);
    liveSymbols.push(symbol.symbol_code);
    const ohlcvBar = ohlcvBarFromQuote(symbol, normalizedQuote, provider);
    if (ohlcvBar) ohlcvBars.push(ohlcvBar);
    technicalIndicators.push(providerIndicatorFromQuote(symbol, normalizedQuote, provider));
  }

  let marketContext: NormalizedMarketContext | null = null;
  let marketContextFallback = false;
  if (includeMarketContext) {
    try {
      marketContext = await fetchLiveMarketContext(provider, observedAt);
    } catch {
      marketContextFallback = true;
      marketContext = sampleMarketContext(fallbackProvider.provider_name, fallbackProvider.id, observedAt, "stale");
    }
  }

  const hasFallback = fallbackWarnings.length > 0 || technicalIndicators.some((row) => !isProviderFreshQuality(row.data_quality)) ||
    Boolean(marketContext && !isProviderFreshQuality(marketContext.data_quality));
  const dataQuality = hasFallback ? "stale" : mergeProviderQualities([
    ...priceSnapshots.map((row) => row.data_quality),
    ...ohlcvBars.map((row) => row.data_quality),
    ...technicalIndicators.map((row) => row.data_quality),
    ...(marketContext ? [marketContext.data_quality] : []),
  ]);
  const providerFailoverReason = fallbackWarnings.length > 0
    ? "provider_payload_missing_or_incomplete_symbols"
    : marketContextFallback
    ? "market_context_fallback"
    : hasFallback
    ? "provider_payload_stale_or_partial"
    : "none";
  const fallbackDiagnostics = withProviderFallbackDiagnostics({
    ...diagnostics,
    fallback_reason: providerFailoverReason,
  }, runtime, dataQuality, hasFallback, providerFailoverReason);

  return {
    priceSnapshots,
    ohlcvBars,
    technicalIndicators,
    marketContext,
    liveSymbols,
    fallbackSymbols,
    dataQuality,
    providerStatus: hasFallback
      ? "provider live aktif dengan sebagian data fallback"
      : runtime.providerStatus,
    riskWarning: buildRiskWarning(dataQuality, runtime.providerStatus, fallbackWarnings),
    usedLiveAdapter: true,
    providerMode: hasFallback ? "provider_error" : "live",
    diagnostics: hasFallback ? fallbackDiagnostics : undefined,
  };
}

function normalizeProviderQuote(
  symbol: SymbolRow,
  item: ProviderQuoteResponse,
  fallbackObservedAt: string,
  provider: ProviderSource,
): NormalizedPriceSnapshot {
  const observedAt = nullableString(item.source_time) ?? nullableString(item.observed_at) ??
    nullableString(item.timestamp) ?? nullableString(item.time) ?? nullableString(item.date) ?? fallbackObservedAt;
  const stale = isStale(observedAt, provider.cache_ttl_seconds);
  const dataQuality = normalizeProviderDataQuality(item.data_quality, stale, item.is_delayed === true);
  const lastPrice = nullableNumber(item.last_price ?? item.price ?? item.close_price ?? item.close);
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
      company_name: nullableString(item.company_name ?? item.name),
      source_time: observedAt,
      note: "provider payload normalized; raw response is not exposed",
    },
  };
}

function providerIndicatorFromQuote(
  symbol: SymbolRow,
  quote: NormalizedPriceSnapshot,
  provider: ProviderSource,
): NormalizedTechnicalIndicator {
  const changePercent = quote.change_percent ?? (
    quote.last_price !== null && quote.previous_close !== null && quote.previous_close !== 0
      ? ((quote.last_price - quote.previous_close) / quote.previous_close) * 100
      : null
  );
  const technicalScore = changePercent === null ? null : clamp(50 + changePercent * 5, 0, 100);
  const riskScore = changePercent === null ? null : clamp(85 - Math.abs(changePercent) * 6, 0, 100);
  const invalidationLevel = quote.last_price === null ? null : round(quote.last_price * 0.97, 2);

  return {
    symbol_id: symbol.id,
    symbol_code: symbol.symbol_code,
    provider_source_id: provider.id,
    provider_name: provider.provider_name,
    timeframe: "1d",
    observed_at: quote.observed_at,
    ema_20: null,
    ema_50: null,
    ema_200: null,
    rsi_14: null,
    atr_14: null,
    average_volume_20: null,
    volume_ratio: null,
    support_level: quote.low_price,
    resistance_level: quote.high_price,
    trend_state: changePercent === null ? "needs_more_data" : changePercent >= 0 ? "watchlist_context_positive" : "risk_warning_context",
    candlestick_pattern: null,
    indicator_payload: {
      source: "live_quote_minimal",
      contract_version: CONTRACT_VERSION,
      note: "Minimal technical snapshot from provider quote only; OHLCV indicators pending.",
    },
    technical_score: technicalScore,
    trend_score: technicalScore,
    volume_score: quote.volume === null ? null : clamp(45 + Math.log10(Math.max(quote.volume, 1)), 0, 100),
    risk_score: riskScore,
    invalidation_level: invalidationLevel,
    rule_version: "p2_live_quote_indicator_v1",
    data_quality: quote.data_quality,
  };
}

function hasUsablePriceSnapshot(row: NormalizedPriceSnapshot): boolean {
  return row.last_price !== null || row.previous_close !== null || row.volume !== null;
}

function ohlcvBarFromQuote(
  symbol: SymbolRow,
  quote: NormalizedPriceSnapshot,
  provider: ProviderSource,
): NormalizedOhlcvBar | null {
  const closePrice = quote.last_price;
  if (
    quote.open_price === null ||
    quote.high_price === null ||
    quote.low_price === null ||
    closePrice === null
  ) {
    return null;
  }

  return {
    symbol_id: symbol.id,
    symbol_code: symbol.symbol_code,
    provider_source_id: provider.id,
    provider_name: provider.provider_name,
    provider_symbol: quote.provider_symbol,
    timeframe: "1d",
    observed_at: quote.observed_at,
    open_price: quote.open_price,
    high_price: quote.high_price,
    low_price: quote.low_price,
    close_price: closePrice,
    volume: quote.volume,
    value_traded: quote.value_traded,
    data_quality: quote.data_quality,
    raw_payload: {
      source: "normalized_provider_quote",
      contract_version: CONTRACT_VERSION,
      note: "OHLCV derived from normalized provider quote; raw provider response is not stored.",
    },
  };
}

async function fetchAlphaVantageCandidateRows(
  symbols: SymbolRow[],
  provider: ProviderSource,
  fallbackProvider: ProviderSource,
  runtime: ProviderRuntime,
  observedAt: string,
  includeMarketContext: boolean,
  secondaryProvider?: ProviderSource,
): Promise<MarketCandidateRows> {
  const priceSnapshots: NormalizedPriceSnapshot[] = [];
  const ohlcvBars: NormalizedOhlcvBar[] = [];
  const technicalIndicators: NormalizedTechnicalIndicator[] = [];
  const fallbackWarnings: RiskWarning[] = [];
  const liveSymbols: string[] = [];
  const fallbackSymbols: string[] = [];
  const symbolDiagnostics: ProviderSymbolDiagnostics[] = [];
  let latestDiagnostics: ProviderDiagnostics | undefined;
  let providerStopState: AlphaVantageStopState | null = null;

  for (const symbol of symbols) {
    if (providerStopState) {
      latestDiagnostics = providerStopState.diagnostics;
      fallbackSymbols.push(symbol.symbol_code);
      symbolDiagnostics.push(alphaVantageSymbolDiagnostic(
        symbol.symbol_code,
        [],
        null,
        providerStopState.reason,
      ));
      fallbackWarnings.push({
        level: "medium",
        message: `${symbol.symbol_code} memakai fallback stale karena Alpha Vantage membatasi atau mengirim pesan provider.`,
      });
      priceSnapshots.push(sampleQuote(symbol, observedAt, fallbackProvider.provider_name, fallbackProvider.id, "stale"));
      technicalIndicators.push(sampleIndicator(symbol, observedAt, fallbackProvider.provider_name, fallbackProvider.id, "stale"));
      continue;
    }

    try {
      const quoteResult = await fetchAlphaVantageQuote(symbol);
      latestDiagnostics = quoteResult.diagnostics;
      const normalizedQuote = normalizeAlphaVantageQuote(symbol, quoteResult.quote, observedAt, provider);

      if (!hasUsablePriceSnapshot(normalizedQuote)) {
        throw new ProviderFetchError("Alpha Vantage quote has no usable price fields", {
          ...quoteResult.diagnostics,
          fallback_reason: "alpha_vantage_quote_incomplete",
          symbol_diagnostics: [
            alphaVantageSymbolDiagnostic(
              symbol.symbol_code,
              quoteResult.attemptedProviderSymbols,
              normalizedQuote.provider_symbol,
              "alpha_vantage_quote_incomplete",
            ),
          ],
        });
      }

      priceSnapshots.push(normalizedQuote);
      liveSymbols.push(symbol.symbol_code);
      symbolDiagnostics.push(alphaVantageSymbolDiagnostic(
        symbol.symbol_code,
        quoteResult.attemptedProviderSymbols,
        normalizedQuote.provider_symbol,
        "none",
      ));

      let ohlcvBar: NormalizedOhlcvBar | null = null;
      try {
        ohlcvBar = await fetchAlphaVantageDailyBar(symbol, normalizedQuote.provider_symbol, provider);
      } catch (error) {
        const dailyDiagnostics = diagnosticsFromError(error, runtime, symbols.length, "alpha_vantage_daily_fetch_failed");
        latestDiagnostics = dailyDiagnostics;
        if (shouldStopAlphaVantageRun(dailyDiagnostics.fallback_reason)) {
          providerStopState = {
            diagnostics: dailyDiagnostics,
            reason: dailyDiagnostics.fallback_reason,
          };
        }
        ohlcvBar = ohlcvBarFromQuote(symbol, normalizedQuote, provider);
      }
      if (ohlcvBar) ohlcvBars.push(ohlcvBar);

      technicalIndicators.push(providerIndicatorFromQuote(symbol, normalizedQuote, provider));
    } catch (error) {
      latestDiagnostics = diagnosticsFromError(error, runtime, symbols.length, "alpha_vantage_fetch_failed");
      if (shouldStopAlphaVantageRun(latestDiagnostics.fallback_reason)) {
        providerStopState = {
          diagnostics: latestDiagnostics,
          reason: latestDiagnostics.fallback_reason,
        };
      }
      fallbackSymbols.push(symbol.symbol_code);
      symbolDiagnostics.push(alphaVantageSymbolDiagnostic(
        symbol.symbol_code,
        alphaVantageAttemptedSymbolsFromDiagnostics(latestDiagnostics),
        null,
        latestDiagnostics.fallback_reason,
      ));
      fallbackWarnings.push({
        level: "medium",
        message: latestDiagnostics.fallback_reason === "alpha_vantage_invalid_symbol"
          ? `${symbol.symbol_code} belum didukung provider setelah varian simbol dicoba; memakai fallback stale.`
          : `${symbol.symbol_code} belum tersedia dari Alpha Vantage; memakai fallback stale.`,
      });
      priceSnapshots.push(sampleQuote(symbol, observedAt, fallbackProvider.provider_name, fallbackProvider.id, "stale"));
      technicalIndicators.push(sampleIndicator(symbol, observedAt, fallbackProvider.provider_name, fallbackProvider.id, "stale"));
    }
  }

  let secondaryProviderUsed = false;
  if (fallbackSymbols.length > 0 && secondaryProvider && hasSecondaryProviderConfig()) {
    const secondaryCandidates = symbols.filter((symbol) => fallbackSymbols.includes(symbol.symbol_code));
    for (const symbol of secondaryCandidates) {
      try {
        const secondaryResult = await fetchSecondaryProviderQuote(symbol);
        latestDiagnostics = secondaryResult.diagnostics;
        const normalizedQuote = normalizeProviderQuote(symbol, secondaryResult.quote, observedAt, secondaryProvider);
        if (!hasUsablePriceSnapshot(normalizedQuote)) {
          throw new ProviderFetchError("Secondary provider quote has no usable price fields", {
            ...secondaryResult.diagnostics,
            fallback_reason: "secondary_provider_quote_incomplete",
            symbol_diagnostics: [
              alphaVantageSymbolDiagnostic(
                symbol.symbol_code,
                secondaryResult.attemptedProviderSymbols,
                secondaryResult.providerSymbol,
                "secondary_provider_quote_incomplete",
              ),
            ],
          });
        }

        replacePriceSnapshot(priceSnapshots, normalizedQuote);
        const secondaryOhlcv = ohlcvBarFromQuote(symbol, normalizedQuote, secondaryProvider);
        if (secondaryOhlcv) replaceOhlcvBar(ohlcvBars, secondaryOhlcv);
        replaceTechnicalIndicator(technicalIndicators, providerIndicatorFromQuote(symbol, normalizedQuote, secondaryProvider));
        removeValue(fallbackSymbols, symbol.symbol_code);
        removeSymbolWarnings(fallbackWarnings, symbol.symbol_code);
        if (!liveSymbols.includes(symbol.symbol_code)) liveSymbols.push(symbol.symbol_code);
        secondaryProviderUsed = true;
        symbolDiagnostics.push(alphaVantageSymbolDiagnostic(
          symbol.symbol_code,
          secondaryResult.attemptedProviderSymbols,
          normalizedQuote.provider_symbol,
          "none",
        ));
      } catch (error) {
        const secondaryDiagnostics = diagnosticsFromError(error, runtime, symbols.length, "secondary_provider_fetch_failed");
        latestDiagnostics = {
          ...secondaryDiagnostics,
          fallback_reason: secondaryDiagnostics.secondary_provider_fallback_reason ??
            secondaryDiagnostics.fallback_reason,
        };
        symbolDiagnostics.push(alphaVantageSymbolDiagnostic(
          symbol.symbol_code,
          secondaryAttemptedSymbolsFromDiagnostics(secondaryDiagnostics),
          null,
          latestDiagnostics.fallback_reason,
        ));
      }
    }
  }

  let marketContext: NormalizedMarketContext | null = null;
  let marketContextFallback = false;
  if (includeMarketContext) {
    try {
      if (providerStopState) {
        throw new ProviderFetchError("Alpha Vantage provider message already received in this sync run", providerStopState.diagnostics);
      }
      marketContext = await fetchAlphaVantageMarketContext(provider, observedAt);
    } catch (error) {
      const contextDiagnostics = diagnosticsFromError(error, runtime, symbols.length, "alpha_vantage_market_context_fetch_failed");
      latestDiagnostics = contextDiagnostics;
      if (shouldStopAlphaVantageRun(contextDiagnostics.fallback_reason)) {
        providerStopState = {
          diagnostics: contextDiagnostics,
          reason: contextDiagnostics.fallback_reason,
        };
      }
      marketContextFallback = true;
      marketContext = sampleMarketContext(fallbackProvider.provider_name, fallbackProvider.id, observedAt, "stale");
    }
  }

  const hasFallback = fallbackWarnings.length > 0 || technicalIndicators.some((row) => !isProviderFreshQuality(row.data_quality)) ||
    Boolean(marketContext && !isProviderFreshQuality(marketContext.data_quality));
  const dataQuality = hasFallback ? "stale" : mergeProviderQualities([
    ...priceSnapshots.map((row) => row.data_quality),
    ...ohlcvBars.map((row) => row.data_quality),
    ...technicalIndicators.map((row) => row.data_quality),
    ...(marketContext ? [marketContext.data_quality] : []),
  ]);
  const providerFailoverReason = latestDiagnostics
    ? alphaVantageAggregateFallbackReason(
      latestDiagnostics.fallback_reason,
      providerStopState?.reason,
      fallbackWarnings.length > 0,
      marketContextFallback,
    )
    : hasFallback
    ? "alpha_vantage_payload_stale_or_partial"
    : "none";
  const sampleFallbackUsed = fallbackSymbols.length > 0 || marketContextFallback;
  const diagnostics = hasFallback && latestDiagnostics
    ? withProviderFallbackDiagnostics({
      ...latestDiagnostics,
      symbol_diagnostics: symbolDiagnostics,
      fallback_reason: providerFailoverReason,
    }, runtime, dataQuality, sampleFallbackUsed, providerFailoverReason, secondaryProviderUsed)
    : withProviderFallbackDiagnostics(latestDiagnostics, runtime, dataQuality, false, providerFailoverReason, secondaryProviderUsed);

  return {
    priceSnapshots,
    ohlcvBars,
    technicalIndicators,
    marketContext,
    liveSymbols,
    fallbackSymbols,
    dataQuality,
    providerStatus: hasFallback
      ? "Alpha Vantage aktif dengan sebagian data fallback"
      : runtime.providerStatus,
    riskWarning: buildRiskWarning(dataQuality, runtime.providerStatus, fallbackWarnings),
    usedLiveAdapter: true,
    providerMode: hasFallback ? "provider_error" : "live",
    diagnostics,
  };
}

async function fetchAlphaVantageQuote(symbol: SymbolRow): Promise<AlphaVantageQuoteResult> {
  let latestDiagnostics: ProviderDiagnostics | undefined;
  const candidates = alphaVantageSymbolCandidates(symbol.symbol_code);
  const attemptedProviderSymbols: string[] = [];
  for (let index = 0; index < candidates.length; index += 1) {
    const providerSymbol = candidates[index];
    attemptedProviderSymbols.push(providerSymbol);
    const result = await alphaVantageQuery("GLOBAL_QUOTE", providerSymbol);
    latestDiagnostics = result.diagnostics;
    const quote = extractAlphaVantageQuote(result.payload);
    if (quote) {
      return {
        quote,
        providerSymbol,
        attemptedProviderSymbols,
        diagnostics: result.diagnostics,
      };
    }

    if (isAlphaVantageHardFailure(result.payload) || result.diagnostics.fallback_reason !== "none") {
      latestDiagnostics = {
        ...result.diagnostics,
        fallback_reason: alphaVantageFallbackReason(result.payload),
        symbol_diagnostics: [
          alphaVantageSymbolDiagnostic(
            symbol.symbol_code,
            attemptedProviderSymbols,
            null,
            alphaVantageFallbackReason(result.payload),
          ),
        ],
      };
      const canRetryWithSuffix = latestDiagnostics.fallback_reason === "alpha_vantage_invalid_symbol" && index < candidates.length - 1;
      if (canRetryWithSuffix) continue;
      throw new ProviderFetchError("Alpha Vantage quote response is invalid or unsupported", latestDiagnostics);
    }
  }

  throw new ProviderFetchError("Alpha Vantage quote response is invalid or unsupported", {
    ...(latestDiagnostics ??
      buildProviderDiagnosticsFromConfig(
        envFirst(["MARKET_DATA_PROVIDER_BASE_URL", "MARKET_DATA_API_BASE_URL"]),
        Boolean(envFirst(["MARKET_DATA_PROVIDER_API_KEY", "MARKET_DATA_API_KEY"])),
        1,
        "alpha_vantage_quote_missing",
      )),
    fallback_reason: latestDiagnostics?.fallback_reason && latestDiagnostics.fallback_reason !== "none"
      ? latestDiagnostics.fallback_reason
      : "alpha_vantage_quote_missing",
    symbol_diagnostics: [
      alphaVantageSymbolDiagnostic(
        symbol.symbol_code,
        attemptedProviderSymbols,
        null,
        latestDiagnostics?.fallback_reason && latestDiagnostics.fallback_reason !== "none"
          ? latestDiagnostics.fallback_reason
          : "alpha_vantage_quote_missing",
      ),
    ],
  });
}

async function fetchAlphaVantageDailyBar(
  symbol: SymbolRow,
  providerSymbol: string,
  provider: ProviderSource,
): Promise<NormalizedOhlcvBar | null> {
  const shouldFetchDaily = boolEnv("MARKET_DATA_ALPHA_VANTAGE_FETCH_DAILY", true);
  if (!shouldFetchDaily) return null;

  const result = await alphaVantageQuery("TIME_SERIES_DAILY", providerSymbol, {
    outputsize: "compact",
  });
  const dailySeries = extractAlphaVantageDailySeries(result.payload);
  if (!dailySeries) {
    throw new ProviderFetchError("Alpha Vantage daily series response is invalid", {
      ...result.diagnostics,
      fallback_reason: alphaVantageFallbackReason(result.payload),
    });
  }

  const latestDate = Object.keys(dailySeries).sort().reverse()[0];
  const latestBar = latestDate ? dailySeries[latestDate] : null;
  if (!latestDate || !isRecord(latestBar)) return null;

  const open = nullableNumber(latestBar["1. open"] ?? latestBar.open);
  const high = nullableNumber(latestBar["2. high"] ?? latestBar.high);
  const low = nullableNumber(latestBar["3. low"] ?? latestBar.low);
  const close = nullableNumber(latestBar["4. close"] ?? latestBar.close);
  if (open === null || high === null || low === null || close === null) return null;

  const quality = alphaVantageDataQuality(latestDate);
  return {
    symbol_id: symbol.id,
    symbol_code: symbol.symbol_code,
    provider_source_id: provider.id,
    provider_name: provider.provider_name,
    provider_symbol: providerSymbol,
    timeframe: "1d",
    observed_at: alphaVantageObservedAt(latestDate),
    open_price: open,
    high_price: high,
    low_price: low,
    close_price: close,
    volume: nullableNumber(latestBar["5. volume"] ?? latestBar.volume),
    value_traded: null,
    data_quality: quality,
    raw_payload: {
      source: "alpha_vantage_time_series_daily",
      contract_version: CONTRACT_VERSION,
      note: "Latest daily OHLCV normalized from Alpha Vantage; raw response is not stored.",
    },
  };
}

async function fetchAlphaVantageMarketContext(
  provider: ProviderSource,
  observedAt: string,
): Promise<NormalizedMarketContext> {
  const indexSymbol = Deno.env.get("MARKET_DATA_ALPHA_VANTAGE_INDEX_SYMBOL")?.trim() || DEFAULT_INDEX_SYMBOL;
  const result = await alphaVantageQuery("GLOBAL_QUOTE", indexSymbol);
  const quote = extractAlphaVantageQuote(result.payload);
  if (!quote) {
    throw new ProviderFetchError("Alpha Vantage market context response is invalid", {
      ...result.diagnostics,
      fallback_reason: alphaVantageFallbackReason(result.payload),
    });
  }

  const latestDay = nullableString(quote["07. latest trading day"]);
  const sourceTime = alphaVantageObservedAt(latestDay ?? observedAt);
  const quality = alphaVantageDataQuality(sourceTime);
  const changePercent = alphaVantagePercent(quote["10. change percent"]);
  return {
    provider_source_id: provider.id,
    provider_name: provider.provider_name,
    market_code: DEFAULT_MARKET_CODE,
    index_symbol: indexSymbol,
    observed_at: sourceTime,
    index_last: nullableNumber(quote["05. price"]),
    index_change: nullableNumber(quote["09. change"]),
    index_change_percent: changePercent,
    index_trend: changePercent === null ? "needs_more_data" : changePercent >= 0 ? "watchlist_context_positive" : "risk_warning_context",
    market_status: "provider aktif",
    risk_regime: "needs_more_data",
    breadth_summary: {
      source: "alpha_vantage_global_quote",
      note: "Market context memakai index quote dari provider bila tersedia.",
    },
    context_payload: {
      label: "provider data",
      contract_version: CONTRACT_VERSION,
      disclaimer: "Data market context hanya untuk edukasi.",
    },
    data_quality: quality,
    is_stale: !isProviderFreshQuality(quality),
    staleness_warning: !isProviderFreshQuality(quality) ? STALE_PROVIDER_WARNING : null,
  };
}

function normalizeAlphaVantageQuote(
  symbol: SymbolRow,
  quote: Record<string, unknown>,
  fallbackObservedAt: string,
  provider: ProviderSource,
): NormalizedPriceSnapshot {
  const latestDay = nullableString(quote["07. latest trading day"]);
  const observedAt = alphaVantageObservedAt(latestDay ?? fallbackObservedAt);
  const dataQuality = alphaVantageDataQuality(observedAt);
  const lastPrice = nullableNumber(quote["05. price"]);
  const volume = nullableNumber(quote["06. volume"]);
  const changeValue = nullableNumber(quote["09. change"]);
  const changePercent = alphaVantagePercent(quote["10. change percent"]);

  return {
    symbol_id: symbol.id,
    symbol_code: symbol.symbol_code,
    provider_source_id: provider.id,
    provider_name: provider.provider_name,
    provider_symbol: nullableString(quote["01. symbol"]) ?? symbol.symbol_code,
    observed_at: observedAt,
    last_price: lastPrice,
    previous_close: nullableNumber(quote["08. previous close"]),
    open_price: nullableNumber(quote["02. open"]),
    high_price: nullableNumber(quote["03. high"]),
    low_price: nullableNumber(quote["04. low"]),
    change_value: changeValue,
    change_percent: changePercent,
    volume,
    value_traded: lastPrice !== null && volume !== null ? round(lastPrice * volume, 2) : null,
    market_cap: null,
    currency: symbol.currency ?? "IDR",
    data_quality: dataQuality,
    is_stale: !isProviderFreshQuality(dataQuality),
    staleness_warning: !isProviderFreshQuality(dataQuality) ? STALE_PROVIDER_WARNING : null,
    raw_payload: {
      source: "alpha_vantage_global_quote",
      contract_version: CONTRACT_VERSION,
      source_time: observedAt,
      note: "Alpha Vantage quote normalized; API key and raw response are not exposed.",
    },
  };
}

async function fetchSecondaryProviderQuote(symbol: SymbolRow): Promise<SecondaryProviderQuoteResult> {
  if (!hasSecondaryProviderConfig()) {
    throw new ProviderFetchError("Secondary provider is not configured", {
      ...buildProviderDiagnosticsFromConfig(secondaryProviderBaseUrl(), false, 1, "secondary_provider_not_configured"),
      ...secondaryProviderDiagnostics("secondary_provider_not_configured"),
    });
  }

  const candidates = secondaryProviderSymbolCandidates(symbol.symbol_code);
  const attemptedProviderSymbols: string[] = [];
  let latestDiagnostics: ProviderDiagnostics | undefined;
  for (const providerSymbol of candidates) {
    attemptedProviderSymbols.push(providerSymbol);
    try {
      const result = await secondaryProviderQuery(providerSymbol);
      latestDiagnostics = result.diagnostics;
      const quote = normalizeSecondaryProviderQuotePayload(symbol, result.payload);
      if (quote) {
        return {
          quote,
          providerSymbol,
          attemptedProviderSymbols,
          diagnostics: result.diagnostics,
        };
      }
      latestDiagnostics = {
        ...result.diagnostics,
        fallback_reason: "secondary_provider_no_valid_quote",
      };
    } catch (error) {
      latestDiagnostics = diagnosticsFromError(error, resolveProviderRuntime(), 1, "secondary_provider_fetch_failed");
      if (shouldStopSecondaryProviderCandidateAttempts(latestDiagnostics.fallback_reason)) {
        break;
      }
    }
  }

  throw new ProviderFetchError("Secondary provider returned no usable quote", {
    ...(latestDiagnostics ??
      buildProviderDiagnosticsFromConfig(
        secondaryProviderBaseUrl(),
        Boolean(secondaryProviderApiKey()),
        1,
        "secondary_provider_no_valid_quote",
      )),
    ...secondaryProviderDiagnostics(
      latestDiagnostics?.secondary_provider_fallback_reason ?? "secondary_provider_no_valid_quote",
      latestDiagnostics?.secondary_provider_status_code,
      latestDiagnostics?.secondary_provider_response_keys,
      latestDiagnostics?.secondary_provider_content_type,
    ),
    fallback_reason: latestDiagnostics?.fallback_reason && latestDiagnostics.fallback_reason !== "none"
      ? latestDiagnostics.fallback_reason
      : "secondary_provider_no_valid_quote",
    symbol_diagnostics: [
      alphaVantageSymbolDiagnostic(
        symbol.symbol_code,
        attemptedProviderSymbols,
        null,
        latestDiagnostics?.fallback_reason && latestDiagnostics.fallback_reason !== "none"
          ? latestDiagnostics.fallback_reason
          : "secondary_provider_no_valid_quote",
      ),
    ],
  });
}

async function secondaryProviderQuery(providerSymbol: string): Promise<ProviderJsonResult> {
  const baseUrl = secondaryProviderBaseUrl();
  const apiKey = secondaryProviderApiKey();
  const diagnostics = {
    ...buildProviderDiagnosticsFromConfig(baseUrl, Boolean(apiKey), 1, "secondary_provider_request_started"),
    ...secondaryProviderDiagnostics("secondary_provider_request_started"),
  };
  if (!baseUrl || !apiKey) {
    throw new ProviderFetchError("Secondary provider env is incomplete", {
      ...diagnostics,
      ...secondaryProviderDiagnostics("secondary_provider_not_configured"),
      fallback_reason: "secondary_provider_not_configured",
    });
  }

  const isTwelveData = marketSecondaryProviderName().trim().toLowerCase() === "twelve_data";
  const url = isTwelveData
    ? buildTwelveDataQuoteUrl(baseUrl, providerSymbol, apiKey)
    : buildGenericSecondaryQuoteUrl(baseUrl, providerSymbol);
  const authHeaders = isTwelveData ? {} : buildGenericSecondaryAuthHeaders(apiKey);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);
  try {
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Accept": "application/json",
        ...authHeaders,
      },
      signal: controller.signal,
    });
    const contentType = response.headers.get("content-type");
    const text = await response.text();
    let payload: unknown;
    try {
      payload = text ? JSON.parse(text) : null;
    } catch {
      throw new ProviderFetchError("Secondary provider returned invalid JSON", {
        ...diagnostics,
        ...secondaryProviderDiagnostics("secondary_provider_invalid_json", response.status, undefined, contentType),
        provider_http_status: response.status,
        provider_status_code: response.status,
        provider_content_type: contentType,
        fallback_reason: "secondary_provider_invalid_json",
      });
    }

    const responseKeys = topLevelJsonKeys(payload);
    const providerPayloadError = secondaryProviderPayloadFallbackReason(payload);
    const responseDiagnostics: ProviderDiagnostics = {
      ...diagnostics,
      ...secondaryProviderDiagnostics(
        response.ok ? providerPayloadError : `secondary_provider_http_${response.status}`,
        response.status,
        responseKeys,
        contentType,
      ),
      provider_http_status: response.status,
      provider_status_code: response.status,
      provider_content_type: contentType,
      json_top_level_keys: responseKeys,
      provider_response_keys: responseKeys,
      fallback_reason: response.ok ? providerPayloadError : `secondary_provider_http_${response.status}`,
    };
    if (!response.ok) {
      throw new ProviderFetchError(`Secondary provider returned HTTP ${response.status}`, responseDiagnostics);
    }
    if (providerPayloadError !== "none") {
      throw new ProviderFetchError("Secondary provider returned error payload", responseDiagnostics);
    }

    return {
      payload,
      diagnostics: responseDiagnostics,
    };
  } catch (error) {
    if (error instanceof ProviderFetchError) throw error;
    const fallbackReason = error instanceof DOMException && error.name === "AbortError"
      ? "secondary_provider_timeout"
      : "secondary_provider_request_failed";
    throw new ProviderFetchError("Secondary provider request failed", {
      ...diagnostics,
      ...secondaryProviderDiagnostics(fallbackReason),
      fallback_reason: fallbackReason,
    });
  } finally {
    clearTimeout(timeout);
  }
}

function buildTwelveDataQuoteUrl(baseUrl: string, providerSymbol: string, apiKey: string): URL {
  const normalizedBase = normalizeUrlInput(baseUrl);
  const url = new URL(normalizedBase);
  if (url.pathname === "/" || url.pathname === "") {
    url.pathname = envFirst([
      "SECONDARY_MARKET_DATA_PROVIDER_QUOTE_PATH",
      "MARKET_DATA_SECONDARY_PROVIDER_QUOTE_PATH",
    ]) ?? "/quote";
  }
  url.searchParams.set("symbol", providerSymbol);
  url.searchParams.set("apikey", apiKey);
  return url;
}

function buildGenericSecondaryQuoteUrl(baseUrl: string, providerSymbol: string): URL {
  const symbolParam = envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_SYMBOL_PARAM",
    "MARKET_DATA_SECONDARY_PROVIDER_SYMBOL_PARAM",
  ]) ?? "symbol";
  const normalizedBase = normalizeUrlInput(baseUrl);
  const configuredUrl = normalizedBase.includes("{symbol}")
    ? normalizedBase.replace("{symbol}", encodeURIComponent(providerSymbol))
    : normalizedBase;
  const url = new URL(configuredUrl);
  if (!normalizedBase.includes("{symbol}")) url.searchParams.set(symbolParam, providerSymbol);
  return url;
}

function buildGenericSecondaryAuthHeaders(apiKey: string): Record<string, string> {
  const headerName = envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_AUTH_HEADER",
    "MARKET_DATA_SECONDARY_PROVIDER_AUTH_HEADER",
  ]) ?? "Authorization";
  const configuredPrefix = envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_AUTH_PREFIX",
    "MARKET_DATA_SECONDARY_PROVIDER_AUTH_PREFIX",
  ]);
  const defaultPrefix = headerName.toLowerCase() === "authorization" ? "Bearer" : "";
  const authPrefix = configuredPrefix ?? defaultPrefix;
  return {
    [headerName]: authPrefix ? `${authPrefix} ${apiKey}` : apiKey,
  };
}

function normalizeUrlInput(value: string): string {
  return /^https?:\/\//i.test(value) ? value : `https://${value}`;
}

function secondaryProviderPayloadFallbackReason(payload: unknown): string {
  if (!isRecord(payload)) return "secondary_provider_no_valid_quote";
  const status = nullableString(payload.status)?.toLowerCase();
  const code = payload.code === undefined || payload.code === null ? null : String(payload.code).trim().toLowerCase();
  const message = nullableString(payload.message)?.toLowerCase();
  if (status === "error" && (code === "429" || message?.includes("rate"))) return "secondary_provider_rate_limited";
  if (status === "error") return "secondary_provider_error_response";
  if (payload.code !== undefined && payload.message !== undefined && payload.close === undefined && payload.price === undefined) {
    if (code === "429" || message?.includes("rate")) return "secondary_provider_rate_limited";
    return "secondary_provider_error_response";
  }
  return "none";
}

function normalizeSecondaryProviderQuotePayload(symbol: SymbolRow, payload: unknown): ProviderQuoteResponse | null {
  const record = extractRecordPayload(payload, ["quote", "quotes", "data", "item", "result", "payload"]);
  if (!isRecord(record)) return null;
  const providerSymbol = nullableString(
    record.symbol ?? record.symbol_code ?? record.ticker ?? record.code ?? record.provider_symbol,
  );
  const lastPrice = nullableNumber(
    record.price ?? record.last ?? record.last_price ?? record.close ?? record.close_price,
  );
  const volume = nullableNumber(record.volume ?? record.vol);
  if (lastPrice === null && volume === null) return null;

  return {
    symbol_code: symbol.symbol_code,
    symbol: providerSymbol ?? symbol.symbol_code,
    provider_symbol: providerSymbol ?? symbol.symbol_code,
    source_time: record.timestamp ?? record.datetime ?? record.date ?? record.time ?? record.observed_at,
    price: lastPrice,
    close: record.close ?? record.close_price ?? lastPrice,
    open: record.open ?? record.open_price,
    high: record.high ?? record.high_price,
    low: record.low ?? record.low_price,
    previous_close: record.previous_close ?? record.prev_close,
    change: record.change ?? record.change_value,
    change_percent: record.change_percent ?? record.percent_change,
    volume,
    currency: record.currency,
    data_quality: record.data_quality ?? record.quality ?? "delayed",
    is_delayed: record.is_delayed ?? true,
  };
}

function secondaryProviderSymbolCandidates(symbolCode: string): string[] {
  const normalized = symbolCode.trim().toUpperCase();
  if (marketSecondaryProviderName().trim().toLowerCase() === "twelve_data") {
    return twelveDataSymbolCandidates(normalized);
  }

  const candidates = [normalized];
  const configuredSuffix = envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_SYMBOL_SUFFIX",
    "MARKET_DATA_SECONDARY_PROVIDER_SYMBOL_SUFFIX",
  ]);
  if (configuredSuffix && !normalized.endsWith(configuredSuffix.toUpperCase())) {
    candidates.push(`${normalized}${configuredSuffix.toUpperCase()}`);
  }
  return [...new Set(candidates)];
}

function twelveDataSymbolCandidates(symbolCode: string): string[] {
  const normalized = symbolCode.trim().toUpperCase();
  const candidates: string[] = [];
  pushSafeProviderSymbol(candidates, normalized);

  const configuredSuffix = envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_SYMBOL_SUFFIX",
    "MARKET_DATA_SECONDARY_PROVIDER_SYMBOL_SUFFIX",
    "TWELVE_DATA_SYMBOL_SUFFIX",
  ]) ?? ".JK";
  const suffix = configuredSuffix.trim().toUpperCase();
  if (suffix && /^[A-Z0-9]{2,8}$/.test(normalized) && !normalized.endsWith(suffix)) {
    pushSafeProviderSymbol(candidates, `${normalized}${suffix}`);
  }

  const configuredExchange = envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_EXCHANGE",
    "MARKET_DATA_SECONDARY_PROVIDER_EXCHANGE",
    "TWELVE_DATA_EXCHANGE",
  ]) ?? "IDX";
  const exchange = configuredExchange.trim().toUpperCase();
  if (exchange && /^[A-Z0-9]{2,8}$/.test(normalized) && !normalized.includes(":")) {
    pushSafeProviderSymbol(candidates, `${normalized}:${exchange}`);
  }

  for (const symbol of configuredTwelveDataMappedSymbols(normalized)) {
    pushSafeProviderSymbol(candidates, symbol);
  }
  for (const symbol of defaultTwelveDataMappedSymbols(normalized)) {
    pushSafeProviderSymbol(candidates, symbol);
  }
  return candidates.slice(0, secondaryProviderMaxSymbolAttempts());
}

function configuredTwelveDataMappedSymbols(symbolCode: string): string[] {
  return mappedProviderSymbols(symbolCode, [
    "SECONDARY_MARKET_DATA_PROVIDER_SYMBOL_MAP",
    "MARKET_DATA_SECONDARY_PROVIDER_SYMBOL_MAP",
    "TWELVE_DATA_SYMBOL_MAP",
  ]);
}

function defaultTwelveDataMappedSymbols(symbolCode: string): string[] {
  const defaultAliases: Record<string, string[]> = {
    ASII: ["ASII.JK", "ASII:IDX"],
    BBCA: ["BBCA.JK", "BBCA:IDX"],
    BBRI: ["BBRI.JK", "BBRI:IDX"],
    TLKM: ["TLKM.JK", "TLKM:IDX"],
    UNVR: ["UNVR.JK", "UNVR:IDX"],
  };
  return defaultAliases[symbolCode] ?? [];
}

function secondaryProviderMaxSymbolAttempts(): number {
  const configured = Number(envFirst([
    "SECONDARY_MARKET_DATA_PROVIDER_MAX_SYMBOL_ATTEMPTS",
    "MARKET_DATA_SECONDARY_PROVIDER_MAX_SYMBOL_ATTEMPTS",
  ]) ?? 4);
  if (!Number.isFinite(configured)) return 4;
  return Math.max(1, Math.min(5, Math.round(configured)));
}

function pushSafeProviderSymbol(candidates: string[], value: unknown): void {
  const symbol = safeProviderSymbol(value);
  if (symbol && !candidates.includes(symbol)) candidates.push(symbol);
}

function shouldStopSecondaryProviderCandidateAttempts(reason: string | undefined): boolean {
  return reason === "secondary_provider_timeout" ||
    reason === "secondary_provider_request_failed" ||
    reason === "secondary_provider_http_429" ||
    reason === "secondary_provider_rate_limited";
}

async function fetchLiveMarketContext(
  provider: ProviderSource,
  observedAt: string,
): Promise<NormalizedMarketContext> {
  const result = await providerPostJson("/market-context", {
    market_code: DEFAULT_MARKET_CODE,
    index_symbol: DEFAULT_INDEX_SYMBOL,
  });
  const payload = result.payload;
  const context = extractRecordPayload(payload, ["market_context", "context", "data"]);
  const contextObservedAt = nullableString(context.source_time) ?? nullableString(context.observed_at) ??
    nullableString(context.timestamp) ?? nullableString(context.time) ?? nullableString(context.date) ?? observedAt;
  const stale = isStale(contextObservedAt, provider.cache_ttl_seconds);
  const dataQuality = normalizeProviderDataQuality(context.data_quality, stale, context.is_delayed === true);

  return {
    provider_source_id: provider.id,
    provider_name: provider.provider_name,
    market_code: nullableString(context.market_code) ?? DEFAULT_MARKET_CODE,
    index_symbol: nullableString(context.index_symbol) ?? DEFAULT_INDEX_SYMBOL,
    observed_at: contextObservedAt,
    index_last: nullableNumber(context.index_last ?? context.last_price ?? context.price ?? context.close_price ?? context.close),
    index_change: nullableNumber(context.index_change ?? context.change_value ?? context.change),
    index_change_percent: nullableNumber(context.index_change_percent ?? context.change_percent),
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

function assertSupportedLiveAdapter(runtime: ProviderRuntime): void {
  if (!["generic_json", "alpha_vantage"].includes(runtime.providerAdapter)) {
    throw new Error(`Unsupported live provider adapter: ${runtime.providerAdapter}`);
  }
}

async function alphaVantageQuery(
  functionName: "GLOBAL_QUOTE" | "TIME_SERIES_DAILY",
  providerSymbol: string,
  extraParams: Record<string, string> = {},
): Promise<ProviderJsonResult> {
  const baseUrl = envFirst(["MARKET_DATA_PROVIDER_BASE_URL", "MARKET_DATA_API_BASE_URL"]);
  const apiKey = envFirst(["MARKET_DATA_PROVIDER_API_KEY", "MARKET_DATA_API_KEY"]);
  const diagnostics = buildProviderDiagnosticsFromConfig(baseUrl, Boolean(apiKey), 1, "alpha_vantage_request_started");
  if (!baseUrl || !apiKey) {
    throw new ProviderFetchError("Alpha Vantage env is incomplete", {
      ...diagnostics,
      fallback_reason: "provider_env_incomplete",
    });
  }

  const url = new URL(baseUrl);
  url.searchParams.set("function", functionName);
  url.searchParams.set("symbol", providerSymbol);
  url.searchParams.set("apikey", apiKey);
  for (const [key, value] of Object.entries(extraParams)) {
    url.searchParams.set(key, value);
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);
  try {
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Accept": "application/json",
      },
      signal: controller.signal,
    });
    const responseDiagnostics: ProviderDiagnostics = {
      ...diagnostics,
      provider_http_status: response.status,
      provider_status_code: response.status,
      provider_content_type: response.headers.get("content-type"),
      fallback_reason: response.ok ? "none" : `provider_http_${response.status}`,
    };
    const text = await response.text();
    let payload: unknown;
    try {
      payload = text ? JSON.parse(text) : null;
    } catch {
      throw new ProviderFetchError("Alpha Vantage returned invalid JSON", {
        ...responseDiagnostics,
        fallback_reason: "provider_invalid_json",
      });
    }

    const responseKeys = topLevelJsonKeys(payload);
    const diagnosticsWithKeys: ProviderDiagnostics = {
      ...responseDiagnostics,
      json_top_level_keys: responseKeys,
      provider_response_keys: responseKeys,
    };

    if (!response.ok) {
      throw new ProviderFetchError(`Alpha Vantage returned HTTP ${response.status}`, diagnosticsWithKeys);
    }

    const fallbackReason = alphaVantageFallbackReason(payload);
    return {
      payload,
      diagnostics: {
        ...diagnosticsWithKeys,
        fallback_reason: fallbackReason,
      },
    };
  } catch (error) {
    if (error instanceof ProviderFetchError) throw error;
    throw new ProviderFetchError("Alpha Vantage request failed", {
      ...diagnostics,
      fallback_reason: error instanceof DOMException && error.name === "AbortError"
        ? "provider_timeout"
        : "provider_request_failed",
    });
  } finally {
    clearTimeout(timeout);
  }
}

function alphaVantageSymbolCandidates(symbolCode: string): string[] {
  const normalized = symbolCode.trim().toUpperCase();
  const candidates = [normalized];
  const configuredSuffix = Deno.env.get("MARKET_DATA_ALPHA_VANTAGE_SYMBOL_SUFFIX")?.trim() ??
    Deno.env.get("MARKET_DATA_PROVIDER_SYMBOL_SUFFIX")?.trim();
  const suffix = configuredSuffix || ".JK";
  if (suffix && !normalized.endsWith(suffix.toUpperCase()) && /^[A-Z0-9]{2,8}$/.test(normalized)) {
    candidates.push(`${normalized}${suffix.toUpperCase()}`);
  }
  const mappedSymbol = alphaVantageMappedSymbol(normalized);
  if (mappedSymbol) candidates.push(mappedSymbol);
  return [...new Set(candidates)];
}

function alphaVantageMappedSymbol(symbolCode: string): string | null {
  return mappedProviderSymbols(symbolCode, ["MARKET_DATA_ALPHA_VANTAGE_SYMBOL_MAP", "MARKET_DATA_PROVIDER_SYMBOL_MAP"])[0] ?? null;
}

function mappedProviderSymbols(symbolCode: string, envNames: string[]): string[] {
  const rawMap = envFirst(envNames);
  if (!rawMap) return [];

  try {
    const parsed: unknown = JSON.parse(rawMap);
    if (isRecord(parsed)) {
      return safeProviderSymbolList(parsed[symbolCode] ?? parsed[symbolCode.toLowerCase()]);
    }
  } catch {
    for (const entry of rawMap.split(/[;,]/)) {
      const separatorIndex = entry.search(/[:=]/);
      if (separatorIndex < 0) continue;
      const key = entry.slice(0, separatorIndex).trim();
      const value = entry.slice(separatorIndex + 1).trim();
      if (key.toUpperCase() === symbolCode) return safeProviderSymbolList(value);
    }
  }

  return [];
}

function safeProviderSymbolList(value: unknown): string[] {
  const values = Array.isArray(value) ? value : nullableString(value)?.split("|") ?? [];
  return [...new Set(values.map((item) => safeProviderSymbol(item)).filter((item): item is string => Boolean(item)))];
}

function safeProviderSymbol(value: unknown): string | null {
  const symbol = nullableString(value)?.toUpperCase();
  if (!symbol || !/^[A-Z0-9._:^/-]{1,40}$/.test(symbol)) return null;
  return symbol;
}

function alphaVantageSymbolDiagnostic(
  requestedSymbol: string,
  attemptedProviderSymbols: string[],
  selectedProviderSymbol: string | null,
  fallbackReason: string,
): ProviderSymbolDiagnostics {
  return {
    requested_symbol: requestedSymbol,
    attempted_provider_symbols: [...new Set(attemptedProviderSymbols.map((symbol) => symbol.toUpperCase()))],
    selected_provider_symbol: selectedProviderSymbol,
    fallback_reason: fallbackReason,
  };
}

function alphaVantageAttemptedSymbolsFromDiagnostics(diagnostics: ProviderDiagnostics): string[] {
  const items = diagnostics.symbol_diagnostics ?? [];
  const latest = items.length > 0 ? items[items.length - 1] : undefined;
  return latest?.attempted_provider_symbols ?? [];
}

function secondaryAttemptedSymbolsFromDiagnostics(diagnostics: ProviderDiagnostics): string[] {
  const items = diagnostics.symbol_diagnostics ?? [];
  const latest = items.length > 0 ? items[items.length - 1] : undefined;
  return latest?.attempted_provider_symbols ?? [];
}

function replacePriceSnapshot(rows: NormalizedPriceSnapshot[], row: NormalizedPriceSnapshot): void {
  const index = rows.findIndex((item) => item.symbol_code === row.symbol_code);
  if (index >= 0) rows[index] = row;
  else rows.push(row);
}

function replaceOhlcvBar(rows: NormalizedOhlcvBar[], row: NormalizedOhlcvBar): void {
  const index = rows.findIndex((item) => item.symbol_code === row.symbol_code && item.timeframe === row.timeframe);
  if (index >= 0) rows[index] = row;
  else rows.push(row);
}

function replaceTechnicalIndicator(rows: NormalizedTechnicalIndicator[], row: NormalizedTechnicalIndicator): void {
  const index = rows.findIndex((item) => item.symbol_code === row.symbol_code && item.timeframe === row.timeframe);
  if (index >= 0) rows[index] = row;
  else rows.push(row);
}

function removeValue(values: string[], value: string): void {
  const index = values.indexOf(value);
  if (index >= 0) values.splice(index, 1);
}

function removeSymbolWarnings(warnings: RiskWarning[], symbolCode: string): void {
  for (let index = warnings.length - 1; index >= 0; index -= 1) {
    if (warnings[index].message.startsWith(`${symbolCode} `)) warnings.splice(index, 1);
  }
}

function extractAlphaVantageQuote(payload: unknown): Record<string, unknown> | null {
  if (!isRecord(payload)) return null;
  const quote = payload["Global Quote"];
  if (!isRecord(quote)) return null;
  return Object.keys(quote).length > 0 ? quote : null;
}

function extractAlphaVantageDailySeries(payload: unknown): Record<string, unknown> | null {
  if (!isRecord(payload)) return null;
  const series = payload["Time Series (Daily)"];
  return isRecord(series) ? series : null;
}

function isAlphaVantageHardFailure(payload: unknown): boolean {
  return alphaVantageFallbackReason(payload) !== "none";
}

function alphaVantageFallbackReason(payload: unknown): string {
  if (!isRecord(payload)) return "provider_invalid_json";
  if (typeof payload["Error Message"] === "string") return "alpha_vantage_invalid_symbol";
  if (typeof payload.Note === "string") return "alpha_vantage_rate_limited";
  if (typeof payload.Information === "string") return "alpha_vantage_information_response";
  return "none";
}

function shouldStopAlphaVantageRun(reason: string): boolean {
  return reason === "alpha_vantage_information_response" || reason === "alpha_vantage_rate_limited";
}

function isAlphaVantageProviderMessage(reason: string | undefined): boolean {
  return reason === "alpha_vantage_information_response" ||
    reason === "alpha_vantage_rate_limited" ||
    reason === "alpha_vantage_invalid_symbol";
}

function isSecondaryProviderReason(reason: string | undefined): boolean {
  return Boolean(reason?.startsWith("secondary_provider_"));
}

function alphaVantageAggregateFallbackReason(
  latestReason: string,
  stopReason: string | undefined,
  hasFallbackSymbols: boolean,
  marketContextFallback: boolean,
): string {
  if (stopReason) return stopReason;
  if (isSecondaryProviderReason(latestReason)) return latestReason;
  if (isAlphaVantageProviderMessage(latestReason)) return latestReason;
  if (hasFallbackSymbols) return "alpha_vantage_payload_missing_or_incomplete_symbols";
  if (marketContextFallback) return "market_context_fallback";
  return latestReason !== "none" ? latestReason : "alpha_vantage_payload_stale_or_partial";
}

function alphaVantageObservedAt(value: string): string {
  const parsed = new Date(value);
  if (Number.isFinite(parsed.getTime())) return parsed.toISOString();
  return new Date().toISOString();
}

function alphaVantageDataQuality(observedAt: string): MarketDataQuality {
  const maxAgeDays = numberFromEnv("MARKET_DATA_ALPHA_VANTAGE_STALE_DAYS", 7, 0, 30);
  const observedTime = new Date(observedAt).getTime();
  if (!Number.isFinite(observedTime)) return "stale";
  const ageDays = (Date.now() - observedTime) / 86_400_000;
  return ageDays <= maxAgeDays ? "delayed" : "stale";
}

function alphaVantagePercent(value: unknown): number | null {
  if (typeof value === "string") return nullableNumber(value.replace("%", ""));
  return nullableNumber(value);
}

function boolEnv(name: string, fallback: boolean): boolean {
  const value = Deno.env.get(name)?.trim().toLowerCase();
  if (value === "true" || value === "1" || value === "yes") return true;
  if (value === "false" || value === "0" || value === "no") return false;
  return fallback;
}

function numberFromEnv(name: string, fallback: number, min: number, max: number): number {
  const parsed = Number(Deno.env.get(name) ?? fallback);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(min, Math.min(max, parsed));
}

async function providerPostJson(pathKey: "/quotes" | "/market-context", body: Record<string, unknown>): Promise<ProviderJsonResult> {
  const baseUrl = envFirst(["MARKET_DATA_PROVIDER_BASE_URL", "MARKET_DATA_API_BASE_URL"]);
  const apiKey = envFirst(["MARKET_DATA_PROVIDER_API_KEY", "MARKET_DATA_API_KEY"]);
  const diagnostics = buildProviderDiagnosticsFromConfig(baseUrl, Boolean(apiKey), requestedSymbolCountFromBody(body), "provider_request_started");
  if (!baseUrl || !apiKey) {
    throw new ProviderFetchError("Market data provider env is incomplete", {
      ...diagnostics,
      fallback_reason: "provider_env_incomplete",
    });
  }

  const pathEnv = pathKey === "/quotes" ? "MARKET_DATA_QUOTES_PATH" : "MARKET_DATA_CONTEXT_PATH";
  const configuredPath = Deno.env.get(pathEnv)?.trim() || pathKey;
  const url = new URL(configuredPath, baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`);
  const headerName = Deno.env.get("MARKET_DATA_API_KEY_HEADER")?.trim() || "Authorization";
  const headerValuePrefix = Deno.env.get("MARKET_DATA_API_KEY_PREFIX")?.trim() ?? "Bearer";
  const authValue = headerValuePrefix ? `${headerValuePrefix} ${apiKey}` : apiKey;
  const method = (Deno.env.get("MARKET_DATA_PROVIDER_METHOD")?.trim().toUpperCase() || "POST") === "GET" ? "GET" : "POST";
  if (method === "GET") {
    for (const [key, value] of Object.entries(body)) {
      if (Array.isArray(value)) {
        url.searchParams.set(key, value.join(","));
      } else if (value !== null && value !== undefined) {
        url.searchParams.set(key, value.toString());
      }
    }
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);
  try {
    const response = await fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        [headerName]: authValue,
      },
      body: method === "POST" ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    });
    const responseDiagnostics: ProviderDiagnostics = {
      ...diagnostics,
      provider_http_status: response.status,
      provider_status_code: response.status,
      provider_content_type: response.headers.get("content-type"),
      fallback_reason: response.ok ? "none" : `provider_http_${response.status}`,
    };
    const text = await response.text();
    let payload: unknown;
    try {
      payload = text ? JSON.parse(text) : null;
    } catch {
      throw new ProviderFetchError("Provider returned invalid JSON", {
        ...responseDiagnostics,
        fallback_reason: "provider_invalid_json",
      });
    }
    const jsonTopLevelKeys = topLevelJsonKeys(payload);
    if (!response.ok) {
      throw new ProviderFetchError(`Provider returned HTTP ${response.status}`, {
        ...responseDiagnostics,
        json_top_level_keys: jsonTopLevelKeys,
        provider_response_keys: jsonTopLevelKeys,
      });
    }
    return {
      payload,
      diagnostics: {
        ...responseDiagnostics,
        json_top_level_keys: jsonTopLevelKeys,
        provider_response_keys: jsonTopLevelKeys,
        fallback_reason: "none",
      },
    };
  } catch (error) {
    if (error instanceof ProviderFetchError) throw error;
    throw new ProviderFetchError("Provider request failed", {
      ...diagnostics,
      fallback_reason: error instanceof DOMException && error.name === "AbortError"
        ? "provider_timeout"
        : "provider_request_failed",
    });
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
    if (isRecord(value)) {
      const nested = extractArrayPayload(value, keys);
      if (nested.length > 0) return nested;
    }
  }
  return [];
}

function extractRecordPayload(payload: unknown, keys: string[]): Record<string, unknown> {
  if (Array.isArray(payload)) {
    const first = payload.find(isRecord);
    return first ?? {};
  }
  if (!isRecord(payload)) return {};
  for (const key of keys) {
    const value = payload[key];
    if (isRecord(value)) return value;
    if (Array.isArray(value)) {
      const first = value.find(isRecord);
      if (first) return first;
    }
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
  const providerStatus = isProviderFreshQuality(dataQuality)
    ? runtime?.providerStatus ?? "provider live aktif"
    : runtime?.mode === "live" || runtime?.mode === "provider_error"
    ? "provider live belum mengembalikan data valid - fallback cache aktif"
    : rowUsesFallbackProvider
    ? "provider live belum mengembalikan data valid - fallback cache aktif"
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
    data_quality: row.data_quality === "live" || row.data_quality === "production" ? "realtime" : row.data_quality,
  };
}

export function toOhlcvBarDbRow(row: NormalizedOhlcvBar) {
  return {
    ...row,
    data_quality: row.data_quality === "live" || row.data_quality === "production" ? "realtime" : row.data_quality,
  };
}

export function toTechnicalIndicatorDbRow(row: NormalizedTechnicalIndicator) {
  return {
    ...row,
    data_quality: isProviderFreshQuality(row.data_quality) ? "computed" : row.data_quality,
  };
}

export function toMarketContextDbRow(row: NormalizedMarketContext) {
  return {
    ...row,
    data_quality: row.data_quality === "live" || row.data_quality === "production" ? "realtime" : row.data_quality,
  };
}
