import { handleCors } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, notFound, validationError } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";
import {
  authorizeSyncRequest,
  boolFromUnknown,
  buildMarketCandidateRows,
  DEFAULT_PROVIDER_NAME,
  ensureProviderSource,
  hasSecondaryProviderConfig,
  hasTertiaryProviderConfig,
  loadSymbols,
  marketSecondaryProviderName,
  marketTertiaryProviderName,
  normalizeSymbolCodes,
  numberFromUnknown,
  providerMeta,
  resolveProviderRuntime,
  toMarketContextDbRow,
  toOhlcvBarDbRow,
  toPriceSnapshotDbRow,
  toTechnicalIndicatorDbRow,
} from "../_shared/marketData.ts";

type SyncMarketCandidatesBody = {
  symbol_codes?: unknown;
  limit?: unknown;
  include_market_context?: unknown;
  run_mode?: "manual" | "scheduled" | "on_demand";
};

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") throw methodNotAllowed();

    const auth = await authorizeSyncRequest(req);
    const body = await req.json().catch(() => ({})) as SyncMarketCandidatesBody;
    const symbolCodes = normalizeSymbolCodes(body.symbol_codes);
    const limit = numberFromUnknown(body.limit, 10, 1, 50);
    const includeMarketContext = boolFromUnknown(body.include_market_context, true);
    const runMode = body.run_mode ?? "manual";

    if (!["manual", "scheduled", "on_demand"].includes(runMode)) {
      throw validationError("run_mode is invalid");
    }

    const supabase = createAdminClient();
    const runtime = resolveProviderRuntime();
    const observedAt = new Date().toISOString();
    const provider = await ensureProviderSource(supabase, runtime.activeProviderName, runtime.providerType);
    const fallbackProvider = runtime.mode === "live"
      ? await ensureProviderSource(supabase, DEFAULT_PROVIDER_NAME, "sample")
      : provider;
    const secondaryProvider = hasSecondaryProviderConfig()
      ? await ensureProviderSource(supabase, marketSecondaryProviderName(), "vendor")
      : undefined;
    const tertiaryProvider = hasTertiaryProviderConfig()
      ? await ensureProviderSource(supabase, marketTertiaryProviderName(), "vendor")
      : undefined;
    const symbols = await loadSymbols(supabase, symbolCodes, limit);
    if (symbolCodes.length > 0 && symbols.length === 0) {
      throw notFound("No matching active symbols found", { symbol_codes: symbolCodes });
    }

    const { data: syncRun, error: syncRunError } = await supabase
      .from("provider_sync_runs")
      .insert({
        provider_source_id: provider.id,
        provider_name: provider.provider_name,
        sync_type: "quote",
        run_mode: runMode,
        status: "running",
        observed_at: observedAt,
        started_at: observedAt,
        rows_requested: symbols.length,
        metadata: {
          auth_mode: auth.mode,
          user_id: auth.userId,
          requested_symbol_codes: symbolCodes,
          provider: providerMeta(runtime),
          contract_version: "p2_market_data_provider_contract_v1",
          note: "sync-market-candidates writes normalized market candidate cache only",
        },
      })
      .select("id")
      .single();

    if (syncRunError) throw databaseError("Failed to create provider sync run", syncRunError);

    let rowsInserted = 0;
    let rowsFailed = 0;

    try {
      if (symbols.length > 0) {
        const rows = await buildMarketCandidateRows(
          symbols,
          provider,
          runtime,
          observedAt,
          includeMarketContext,
          fallbackProvider,
          secondaryProvider,
          tertiaryProvider,
        );

        const { error: quoteError } = await supabase
          .from("market_price_snapshots")
          .upsert(rows.priceSnapshots.map(toPriceSnapshotDbRow), {
            onConflict: "symbol_code,provider_name,observed_at",
          });
        if (quoteError) throw databaseError("Failed to upsert market price snapshots", quoteError);

        if (rows.ohlcvBars.length > 0) {
          const { error: ohlcvError } = await supabase
            .from("ohlcv_bars")
            .upsert(rows.ohlcvBars.map(toOhlcvBarDbRow), {
              onConflict: "symbol_code,provider_name,timeframe,observed_at",
            });
          if (ohlcvError) throw databaseError("Failed to upsert OHLCV bars", ohlcvError);
        }

        const { error: indicatorError } = await supabase
          .from("technical_indicator_snapshots")
          .upsert(rows.technicalIndicators.map(toTechnicalIndicatorDbRow), {
            onConflict: "symbol_code,timeframe,observed_at,rule_version",
          });
        if (indicatorError) {
          throw databaseError("Failed to upsert technical indicator snapshots", indicatorError);
        }

        rowsInserted += rows.priceSnapshots.length + rows.ohlcvBars.length + rows.technicalIndicators.length;

        if (rows.marketContext) {
          const { error: contextError } = await supabase
            .from("market_context_snapshots")
            .upsert(toMarketContextDbRow(rows.marketContext), {
              onConflict: "market_code,index_symbol,provider_name,observed_at",
            });
          if (contextError) throw databaseError("Failed to upsert market context snapshot", contextError);
          rowsInserted += 1;
        }

        const finishedAt = new Date().toISOString();
        const partialLiveMeta = rows.liveSymbols.length > 0
          ? {
            live_symbol_count: rows.liveSymbols.length,
            fallback_symbol_count: rows.fallbackSymbols.length,
            live_symbols: rows.liveSymbols,
            fallback_symbols: rows.fallbackSymbols,
          }
          : undefined;
        const { error: updateError } = await supabase
          .from("provider_sync_runs")
          .update({
            status: "success",
            finished_at: finishedAt,
            rows_inserted: rowsInserted,
            rows_updated: 0,
            rows_failed: rowsFailed,
            metadata: {
              auth_mode: auth.mode,
              user_id: auth.userId,
              requested_symbol_codes: symbolCodes,
              provider: providerMeta(runtime),
              provider_status: rows.providerStatus,
              data_quality: rows.dataQuality,
              used_production_adapter: rows.usedLiveAdapter,
              used_live_adapter: rows.usedLiveAdapter,
              provider_mode: rows.providerMode,
              ...(partialLiveMeta ?? {}),
              contract_version: "p2_market_data_provider_contract_v1",
            },
          })
          .eq("id", syncRun.id);

        if (updateError) throw databaseError("Failed to finalize provider sync run", updateError);

        const responseMeta: Record<string, unknown> = {
          rule_version: "p2_market_data_provider_sync_v1",
          data_quality: rows.dataQuality,
          provider_name: provider.provider_name,
          provider_status: rows.providerStatus,
          provider_mode: rows.providerMode,
          ...(partialLiveMeta ?? {}),
        };
        if (rows.providerMode === "provider_error" && rows.diagnostics) {
          responseMeta.provider_diagnostics = rows.diagnostics;
        }

        return ok({
          sync_run_id: syncRun.id,
          provider: {
            provider_name: provider.provider_name,
            provider_type: provider.provider_type,
            status: provider.status,
            provider_mode: rows.providerMode,
          },
          synced_symbols: symbols.map((symbol) => ({
            symbol_id: symbol.id,
            symbol_code: symbol.symbol_code,
            company_name: symbol.company_name,
          })),
          synced_count: symbols.length,
          rows_inserted: rowsInserted,
          ohlcv_bars_inserted: rows.ohlcvBars.length,
          ...(partialLiveMeta ?? {}),
          data_quality: rows.dataQuality,
          provider_status: rows.providerStatus,
          risk_warning: rows.riskWarning,
        }, responseMeta);
      }

      const finishedAt = new Date().toISOString();
      const { error: updateError } = await supabase
        .from("provider_sync_runs")
        .update({
          status: "success",
          finished_at: finishedAt,
          rows_inserted: rowsInserted,
          rows_updated: 0,
          rows_failed: rowsFailed,
        })
        .eq("id", syncRun.id);

      if (updateError) throw databaseError("Failed to finalize provider sync run", updateError);

      return ok({
        sync_run_id: syncRun.id,
        provider: {
          provider_name: provider.provider_name,
          provider_type: provider.provider_type,
          status: provider.status,
          provider_mode: runtime.mode,
        },
        synced_symbols: [],
        synced_count: symbols.length,
        rows_inserted: rowsInserted,
        data_quality: runtime.dataQuality,
        provider_status: runtime.providerStatus,
        risk_warning: runtime.riskWarning,
      }, {
        rule_version: "p2_market_data_provider_sync_v1",
        data_quality: runtime.dataQuality,
        provider_name: provider.provider_name,
        provider_status: runtime.providerStatus,
        provider_mode: runtime.mode,
      });
    } catch (error) {
      rowsFailed = symbols.length;
      await supabase
        .from("provider_sync_runs")
        .update({
          status: "failed",
          finished_at: new Date().toISOString(),
          rows_inserted: rowsInserted,
          rows_failed: rowsFailed,
          error_code: error instanceof Error ? error.name : "sync_error",
          error_message: error instanceof Error ? error.message : "Market candidate sync failed",
        })
        .eq("id", syncRun.id);
      throw error;
    }
  } catch (error) {
    return fail(error);
  }
});
