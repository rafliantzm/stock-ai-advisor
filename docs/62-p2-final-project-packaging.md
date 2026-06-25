# P2 Final Project Packaging

Dokumen ini disiapkan untuk demo, dukungan laporan akademik, dan readiness repository setelah milestone P2 market data selesai.

## Project Overview

Stock AI Advisor adalah aplikasi analisis saham berbasis Flutter dan Supabase untuk membantu pengguna menyusun watchlist candidate, membaca konteks market, dan memahami risk warning secara edukatif.

Project ini bersifat:

- educational
- watchlist-oriented
- risk-aware
- bukan sistem rekomendasi transaksi langsung

Keputusan investasi tetap berada pada pengguna. Flutter hanya menjadi UI client, sedangkan logic sensitif seperti provider access, scoring, sync, dan diagnostics berada di Supabase Edge Functions.

## Feature Summary

Fitur P2 yang siap untuk demo:

- Main Watchlist
  - Menampilkan watchlist candidate, latest score, invalidation level, dan risk warning.

- AI Stock Screener
  - Menjalankan preset edukatif untuk menemukan saham layak dianalisis.

- P2 Market Data Sync
  - Menjalankan sinkronisasi candidate market data melalui Edge Function.
  - Menampilkan status delayed provider-backed data, multi-provider, dan no symbol fallback.

- Market Context
  - Menampilkan konteks IDX/IHSG yang sudah selaras dengan delayed provider-backed state.

- Chart Lab preview
  - Menampilkan preview edukatif.
  - Menjelaskan bahwa interactive OHLCV chart masih future integration.

- Stock Detail Analysis
  - Menampilkan score, technical setup, fundamental snapshot, risk analysis, strategy explanation, dan calculator edukatif.

- Smart Alert
  - Mendukung alert berbasis risk warning, technical setup, score, dan invalidation level.

## Final Provider Architecture

Provider chain final:

```text
alpha_vantage -> twelve_data -> eodhd -> sample_provider
```

Peran provider:

- `alpha_vantage`: primary provider.
- `twelve_data`: secondary provider.
- `eodhd`: tertiary IDX provider.
- `sample_provider`: fallback edukatif jika provider-backed data tidak tersedia.

Semua provider credential harus disimpan di Supabase Secrets atau Supabase Edge Function environment. Credential tidak boleh berada di Flutter, Git, screenshot, dokumentasi publik, atau response API.

## Final Validated State

Final backend state:

```text
provider_mode = live
data_quality = delayed
live_symbol_count = 5
fallback_symbol_count = 0
selected_provider = mixed_live_providers
fallback_provider_used = false
tertiary_provider_name = eodhd
```

Expected UI state:

- `Delayed provider-backed data`
- `Multi-provider`
- `No symbol fallback`
- Market Context aligned with delayed provider-backed data
- Chart Lab provider-backed delayed preview
- Stock Detail provider-backed delayed context

## Flutter Web Run Instructions

Run from repository root:

```bash
cd apps/mobile
flutter pub get
flutter run -d web-server --web-port=3000 \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

PowerShell example:

```powershell
cd apps/mobile
flutter pub get
flutter run -d web-server --web-port=3000 `
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Flutter must only receive:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Do not pass provider API key, service role key, private JWT, or provider secret to Flutter.

## Supabase Edge Function Notes

P2 Edge Functions used by Flutter:

- `sync-market-candidates`
  - Syncs market candidates through provider chain.
  - Writes provider-backed snapshots and safe diagnostics.
  - Keeps fallback behavior available when provider-backed data is unavailable.

- `get-market-context`
  - Returns IDX/IHSG market context for the app.
  - Aligns stale/sample context with latest provider-backed sync summary when valid delayed data exists.
  - Keeps disclaimer and risk warning educational.

Deploy commands:

```bash
supabase functions deploy sync-market-candidates
supabase functions deploy get-market-context
```

Secrets must remain in Supabase Secrets:

- primary provider key
- secondary provider key
- tertiary provider key
- service role key
- provider base URL or auth config when private

## Security Notes

Never expose:

- API keys
- service role key
- JWT token
- Authorization header
- raw provider response
- full provider URL containing secret

Repository and UI safety expectations:

- Flutter only uses Supabase URL and anon key.
- Provider access happens only inside Supabase Edge Functions.
- API responses return sanitized metadata and diagnostics only.
- Docs must use placeholder values, not real credential values.
- Screenshots for demo must not include tokens, headers, private URLs, or raw payloads.

## Known Limitations

- Data is delayed provider-backed, not real-time trading data.
- Chart Lab interactive OHLCV is still future integration.
- Some screener categories may remain empty until backend presets are added.
- AI/RAG explanation layer is not active in the P2 app flow.
- News provider remains placeholder.

## Demo Checklist

Before demo:

- Confirm Supabase project has latest migrations and seed data.
- Confirm Edge Functions are deployed.
- Confirm provider secrets are configured in Supabase only.
- Run `sync-market-candidates`.
- Confirm backend state shows delayed provider-backed data and no symbol fallback.
- Start Flutter web with anon config only.

Demo screens:

- Main Watchlist
- AI Stock Screener
- P2 Market Data Sync
- Market Context
- Chart Lab preview
- Stock Detail Analysis
- Smart Alert

## Validation Commands

Run before packaging or tagging:

```bash
git diff --check

cd apps/mobile
dart format lib test
flutter analyze
flutter test
```

Expected result:

- formatting unchanged or clean
- analyze has no issues
- all Flutter tests pass

## Recommended Next Phase

- P3 interactive OHLCV chart and indicator overlays.
- Expanded screener presets connected to provider-backed data.
- Rule Engine v2 using delayed provider data and auditable scoring.
- Optional AI/RAG explanation layer after deterministic scoring and data provenance remain stable.
