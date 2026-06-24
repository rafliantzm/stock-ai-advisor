import { handleCors } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, notFound, validationError } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";
import {
  authorizeSyncRequest,
  boolFromUnknown,
  ensureProviderSource,
  loadSymbols,
  marketProviderName,
  normalizeSymbolCodes,
  numberFromUnknown,
  sampleIndicator,
  sampleMarketContext,
  sampleQuote,
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
    const providerName = marketProviderName();
    const observedAt = new Date().toISOString();
    const provider = await ensureProviderSource(supabase, providerName);
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
          provider_mode: provider.provider_type,
          note: "sync-market-candidates writes sample/normalized market candidate cache only",
        },
      })
      .select("id")
      .single();

    if (syncRunError) throw databaseError("Failed to create provider sync run", syncRunError);

    let rowsInserted = 0;
    let rowsFailed = 0;

    try {
      if (symbols.length > 0) {
        const quoteRows = symbols.map((symbol) =>
          sampleQuote(symbol, observedAt, provider.provider_name, provider.id)
        );
        const indicatorRows = symbols.map((symbol) =>
          sampleIndicator(symbol, observedAt, provider.provider_name, provider.id)
        );

        const { error: quoteError } = await supabase
          .from("market_price_snapshots")
          .insert(quoteRows);
        if (quoteError) throw databaseError("Failed to insert market price snapshots", quoteError);

        const { error: indicatorError } = await supabase
          .from("technical_indicator_snapshots")
          .insert(indicatorRows);
        if (indicatorError) {
          throw databaseError("Failed to insert technical indicator snapshots", indicatorError);
        }

        rowsInserted += quoteRows.length + indicatorRows.length;
      }

      if (includeMarketContext) {
        const { error: contextError } = await supabase
          .from("market_context_snapshots")
          .insert(sampleMarketContext(provider.provider_name, provider.id, observedAt));
        if (contextError) throw databaseError("Failed to insert market context snapshot", contextError);
        rowsInserted += 1;
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
        },
        synced_symbols: symbols.map((symbol) => ({
          symbol_id: symbol.id,
          symbol_code: symbol.symbol_code,
          company_name: symbol.company_name,
        })),
        synced_count: symbols.length,
        rows_inserted: rowsInserted,
        data_quality: "sample",
        provider_status: provider.provider_type === "sample" ? "provider belum aktif" : "provider configured",
        risk_warning: [{
          level: "medium",
          message: "Market candidate sync memakai sample data sampai provider production aktif.",
        }],
      }, {
        rule_version: "p2_market_data_sample_sync_v1",
        data_quality: "sample",
        provider_name: provider.provider_name,
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
