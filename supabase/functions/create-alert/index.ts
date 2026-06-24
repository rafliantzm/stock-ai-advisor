import { handleCors } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { createAdminClient } from "../_shared/supabaseClient.ts";
import { databaseError, methodNotAllowed, notFound, validationError } from "../_shared/errors.ts";
import { fail, ok } from "../_shared/response.ts";

type AlertCondition = {
  metric?: string;
  operator?: "gt" | "gte" | "lt" | "lte" | "eq" | "between" | "in";
  value_numeric?: number;
  value_text?: string;
  value_json?: Record<string, unknown>;
};

type CreateAlertBody = {
  symbol_code?: string;
  name?: string;
  alert_type?: string;
  cooldown_minutes?: number;
  conditions?: AlertCondition[];
};

const allowedAlertTypes = new Set([
  "price",
  "volume",
  "score",
  "event",
  "invalidation",
  "technical_setup",
  "risk_warning",
]);

const allowedOperators = new Set(["gt", "gte", "lt", "lte", "eq", "between", "in"]);

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") throw methodNotAllowed();

    const { userId } = await requireAuth(req);
    const body = await req.json().catch(() => ({})) as CreateAlertBody;
    const symbolCode = body.symbol_code?.trim().toUpperCase();

    if (!body.name?.trim()) throw validationError("name is required");
    if (!body.alert_type || !allowedAlertTypes.has(body.alert_type)) {
      throw validationError("alert_type is invalid");
    }
    if (!Array.isArray(body.conditions) || body.conditions.length === 0) {
      throw validationError("conditions must contain at least one item");
    }

    const supabase = createAdminClient();
    let symbol: { id: string; symbol_code: string } | null = null;

    if (symbolCode) {
      const { data, error } = await supabase
        .from("symbols")
        .select("id, symbol_code")
        .eq("symbol_code", symbolCode)
        .eq("is_active", true)
        .maybeSingle();

      if (error) throw databaseError("Failed to load symbol", error);
      if (!data) throw notFound("Symbol not found");
      symbol = data;
    }

    for (const condition of body.conditions) {
      if (!condition.metric?.trim()) throw validationError("condition.metric is required");
      if (!condition.operator || !allowedOperators.has(condition.operator)) {
        throw validationError("condition.operator is invalid", condition);
      }
    }

    const { data: alert, error: alertError } = await supabase
      .from("user_alerts")
      .insert({
        user_id: userId,
        symbol_id: symbol?.id ?? null,
        symbol_code: symbol?.symbol_code ?? symbolCode ?? null,
        name: body.name.trim(),
        alert_type: body.alert_type,
        cooldown_minutes: body.cooldown_minutes ?? 60,
        status: "active",
      })
      .select()
      .single();

    if (alertError) throw databaseError("Failed to create smart alert", alertError);

    const conditionRows = body.conditions.map((condition) => ({
      alert_id: alert.id,
      metric: condition.metric!.trim(),
      operator: condition.operator!,
      value_numeric: condition.value_numeric ?? null,
      value_text: condition.value_text ?? null,
      value_json: condition.value_json ?? null,
      status: "active",
    }));

    const { data: conditions, error: conditionsError } = await supabase
      .from("alert_conditions")
      .insert(conditionRows)
      .select();

    if (conditionsError) throw databaseError("Failed to create alert conditions", conditionsError);

    return ok({ alert, conditions });
  } catch (error) {
    return fail(error);
  }
});
