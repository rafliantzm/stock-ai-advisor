-- Educational screener preset seed for stock-ai-advisor.
-- Safe wording only: candidate, layak dianalisis, watchlist, risk warning, invalidation level.
-- No destructive SQL, no transaction execution features.

with preset_seed (name, description, category, filter_summary) as (
  values
    (
      'Technical Breakout Candidate',
      'Mencari saham yang layak dianalisis saat technical setup mengarah ke breakout candidate dengan liquidity dan risk warning tetap diperiksa.',
      'technical',
      '{"focus":["technical_score","liquidity_score","volume condition","invalidation level"],"safe_label":"technical setup candidate"}'::jsonb
    ),
    (
      'Fibonacci Support Candidate',
      'Mencari watchlist candidate yang berada dekat area Fibonacci support dengan invalidation level yang jelas.',
      'technical',
      '{"focus":["technical_score","risk_score","fibonacci support","invalidation level"],"safe_label":"fibonacci support candidate"}'::jsonb
    ),
    (
      'Candlestick Reversal Candidate',
      'Mencari candidate berbasis pola candlestick reversal yang perlu dikonfirmasi oleh volume condition dan risk warning.',
      'technical',
      '{"focus":["technical_score","volume condition","risk warning"],"safe_label":"candlestick reversal candidate"}'::jsonb
    ),
    (
      'Volume Accumulation Candidate',
      'Mencari watchlist candidate dengan volume condition yang menunjukkan tekanan akumulasi berbasis proxy volume-price.',
      'volume_price',
      '{"focus":["technical_score","liquidity_score","volume condition"],"safe_label":"volume accumulation candidate"}'::jsonb
    ),
    (
      'Low Risk Watchlist Candidate',
      'Mencari saham layak dianalisis dengan risk_score lebih terkontrol, liquidity memadai, dan invalidation level jelas.',
      'risk',
      '{"focus":["risk_score","liquidity_score","invalidation level"],"safe_label":"low risk watchlist candidate"}'::jsonb
    ),
    (
      'Fundamental Strong Candidate',
      'Mencari watchlist candidate dengan fundamental_score kuat dan risk warning tetap diperhatikan.',
      'fundamental',
      '{"focus":["fundamental_score","risk_score","liquidity_score"],"safe_label":"fundamental strong candidate"}'::jsonb
    ),
    (
      'Dividend Candidate',
      'Mencari saham layak dianalisis berdasarkan kualitas fundamental dan histori dividen bila data tersedia.',
      'fundamental',
      '{"focus":["fundamental_score","risk_score","dividend consistency"],"safe_label":"dividend candidate"}'::jsonb
    ),
    (
      'Trend Following Candidate',
      'Mencari candidate yang selaras dengan trend condition, liquidity memadai, dan risk warning terukur.',
      'technical',
      '{"focus":["technical_score","trend condition","liquidity_score","risk_score"],"safe_label":"trend following candidate"}'::jsonb
    ),
    (
      'Support Resistance Rebound Candidate',
      'Mencari watchlist candidate yang bereaksi di area support/resistance dengan invalidation level yang dapat diaudit.',
      'technical',
      '{"focus":["technical_score","support resistance","risk_score","invalidation level"],"safe_label":"support resistance rebound candidate"}'::jsonb
    ),
    (
      'Harmonic Pattern Candidate',
      'Mencari candidate berbasis harmonic pattern dengan harmony_score, PRZ context, dan risk warning.',
      'technical',
      '{"focus":["harmony_score","technical_score","risk_score","invalidation level"],"safe_label":"harmonic pattern candidate"}'::jsonb
    )
)
insert into public.screener_presets (name, description, category, is_system, filter_summary, status)
select name, description, category, true, filter_summary, 'active'
from preset_seed
where not exists (
  select 1
  from public.screener_presets existing
  where existing.name = preset_seed.name
);

with filter_seed (preset_name, metric, operator, value_json, weight) as (
  values
    ('Technical Breakout Candidate', 'technical_score', 'gte', '{"value":70,"unit":"score"}'::jsonb, 0.35),
    ('Technical Breakout Candidate', 'liquidity_score', 'gte', '{"value":60,"unit":"score"}'::jsonb, 0.20),
    ('Technical Breakout Candidate', 'volume_condition', 'in', '{"values":["above_average","volume_expansion"]}'::jsonb, 0.25),
    ('Technical Breakout Candidate', 'risk_score', 'gte', '{"value":50,"unit":"score"}'::jsonb, 0.20),

    ('Fibonacci Support Candidate', 'technical_score', 'gte', '{"value":65,"unit":"score"}'::jsonb, 0.25),
    ('Fibonacci Support Candidate', 'fibonacci_condition', 'in', '{"values":["near_0_382","near_0_5","near_0_618"]}'::jsonb, 0.35),
    ('Fibonacci Support Candidate', 'risk_score', 'gte', '{"value":55,"unit":"score"}'::jsonb, 0.20),
    ('Fibonacci Support Candidate', 'invalidation_level', 'in', '{"required":true}'::jsonb, 0.20),

    ('Candlestick Reversal Candidate', 'technical_score', 'gte', '{"value":60,"unit":"score"}'::jsonb, 0.25),
    ('Candlestick Reversal Candidate', 'candlestick_condition', 'in', '{"values":["reversal_candidate","engulfing_candidate","hammer_candidate","doji_context"]}'::jsonb, 0.35),
    ('Candlestick Reversal Candidate', 'volume_condition', 'in', '{"values":["confirmed","above_average"]}'::jsonb, 0.20),
    ('Candlestick Reversal Candidate', 'risk_score', 'gte', '{"value":50,"unit":"score"}'::jsonb, 0.20),

    ('Volume Accumulation Candidate', 'technical_score', 'gte', '{"value":60,"unit":"score"}'::jsonb, 0.20),
    ('Volume Accumulation Candidate', 'liquidity_score', 'gte', '{"value":65,"unit":"score"}'::jsonb, 0.20),
    ('Volume Accumulation Candidate', 'volume_condition', 'in', '{"values":["accumulation_pressure_proxy","volume_expansion","positive_obv_proxy"]}'::jsonb, 0.40),
    ('Volume Accumulation Candidate', 'risk_score', 'gte', '{"value":50,"unit":"score"}'::jsonb, 0.20),

    ('Low Risk Watchlist Candidate', 'risk_score', 'gte', '{"value":75,"unit":"score"}'::jsonb, 0.40),
    ('Low Risk Watchlist Candidate', 'liquidity_score', 'gte', '{"value":60,"unit":"score"}'::jsonb, 0.20),
    ('Low Risk Watchlist Candidate', 'invalidation_level', 'in', '{"required":true}'::jsonb, 0.20),
    ('Low Risk Watchlist Candidate', 'technical_score', 'gte', '{"value":50,"unit":"score"}'::jsonb, 0.20),

    ('Fundamental Strong Candidate', 'fundamental_score', 'gte', '{"value":75,"unit":"score"}'::jsonb, 0.45),
    ('Fundamental Strong Candidate', 'risk_score', 'gte', '{"value":60,"unit":"score"}'::jsonb, 0.20),
    ('Fundamental Strong Candidate', 'liquidity_score', 'gte', '{"value":55,"unit":"score"}'::jsonb, 0.15),
    ('Fundamental Strong Candidate', 'technical_score', 'gte', '{"value":45,"unit":"score"}'::jsonb, 0.20),

    ('Dividend Candidate', 'fundamental_score', 'gte', '{"value":65,"unit":"score"}'::jsonb, 0.30),
    ('Dividend Candidate', 'dividend_condition', 'in', '{"values":["consistent_history","positive_yield","cashflow_supported"]}'::jsonb, 0.35),
    ('Dividend Candidate', 'risk_score', 'gte', '{"value":55,"unit":"score"}'::jsonb, 0.20),
    ('Dividend Candidate', 'liquidity_score', 'gte', '{"value":50,"unit":"score"}'::jsonb, 0.15),

    ('Trend Following Candidate', 'technical_score', 'gte', '{"value":70,"unit":"score"}'::jsonb, 0.30),
    ('Trend Following Candidate', 'trend_condition', 'in', '{"values":["uptrend_candidate","higher_high_higher_low","moving_average_alignment"]}'::jsonb, 0.35),
    ('Trend Following Candidate', 'liquidity_score', 'gte', '{"value":60,"unit":"score"}'::jsonb, 0.15),
    ('Trend Following Candidate', 'risk_score', 'gte', '{"value":55,"unit":"score"}'::jsonb, 0.20),

    ('Support Resistance Rebound Candidate', 'technical_score', 'gte', '{"value":65,"unit":"score"}'::jsonb, 0.25),
    ('Support Resistance Rebound Candidate', 'support_resistance_condition', 'in', '{"values":["near_support","rebound_candidate","range_reaction"]}'::jsonb, 0.35),
    ('Support Resistance Rebound Candidate', 'risk_score', 'gte', '{"value":55,"unit":"score"}'::jsonb, 0.20),
    ('Support Resistance Rebound Candidate', 'invalidation_level', 'in', '{"required":true}'::jsonb, 0.20),

    ('Harmonic Pattern Candidate', 'harmony_score', 'gte', '{"value":70,"unit":"score"}'::jsonb, 0.40),
    ('Harmonic Pattern Candidate', 'technical_score', 'gte', '{"value":60,"unit":"score"}'::jsonb, 0.20),
    ('Harmonic Pattern Candidate', 'harmonic_condition', 'in', '{"values":["prz_candidate","xabcd_candidate","pattern_completion_zone"]}'::jsonb, 0.25),
    ('Harmonic Pattern Candidate', 'risk_score', 'gte', '{"value":50,"unit":"score"}'::jsonb, 0.15)
)
insert into public.screener_filters (preset_id, metric, operator, value_json, weight, status)
select presets.id, filter_seed.metric, filter_seed.operator, filter_seed.value_json, filter_seed.weight, 'active'
from filter_seed
join public.screener_presets presets on presets.name = filter_seed.preset_name
where not exists (
  select 1
  from public.screener_filters existing
  where existing.preset_id = presets.id
    and existing.metric = filter_seed.metric
    and existing.operator = filter_seed.operator
    and existing.value_json = filter_seed.value_json
);

-- Verification queries:
-- select name, category, status from public.screener_presets where name in (
--   'Technical Breakout Candidate',
--   'Fibonacci Support Candidate',
--   'Candlestick Reversal Candidate',
--   'Volume Accumulation Candidate',
--   'Low Risk Watchlist Candidate',
--   'Fundamental Strong Candidate',
--   'Dividend Candidate',
--   'Trend Following Candidate',
--   'Support Resistance Rebound Candidate',
--   'Harmonic Pattern Candidate'
-- ) order by name;
--
-- select p.name, count(f.id) as filter_count
-- from public.screener_presets p
-- left join public.screener_filters f on f.preset_id = p.id
-- where p.name in (
--   'Technical Breakout Candidate',
--   'Fibonacci Support Candidate',
--   'Candlestick Reversal Candidate',
--   'Volume Accumulation Candidate',
--   'Low Risk Watchlist Candidate',
--   'Fundamental Strong Candidate',
--   'Dividend Candidate',
--   'Trend Following Candidate',
--   'Support Resistance Rebound Candidate',
--   'Harmonic Pattern Candidate'
-- )
-- group by p.name
-- order by p.name;
