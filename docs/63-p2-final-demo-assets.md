# P2 Final Demo Assets

Dokumen ini menjadi panduan pengambilan screenshot dan alur demo final untuk milestone P2 market data. Tujuannya adalah menyiapkan bukti visual yang rapi untuk presentasi, laporan akademik, dan repository handoff tanpa mengekspos secret.

## Recommended Screenshot List

Ambil screenshot berikut untuk paket demo final:

1. Main Watchlist
   - Tampilkan watchlist candidate, latest score, invalidation level, dan risk warning.

2. AI Stock Screener
   - Tampilkan screener categories dan hasil watchlist candidate bila tersedia.

3. P2 Market Data Sync
   - Tampilkan status `Delayed provider-backed data`.
   - Tampilkan `Multi-provider`.
   - Tampilkan `No symbol fallback`.
   - Tampilkan tertiary provider `eodhd` hanya sebagai safe diagnostics.

4. Market Context
   - Tampilkan market context yang selaras dengan delayed provider-backed data.
   - Pastikan tidak ada stale/sample fallback messaging ketika fallback symbol kosong.

5. Chart Lab
   - Tampilkan provider-backed delayed preview.
   - Pastikan copy menyebut interactive OHLCV chart masih tahap integrasi.

6. Stock Detail Analysis
   - Tampilkan technical setup, fundamental snapshot, risk analysis, strategy explanation, dan calculator edukatif.

7. Smart Alert
   - Tampilkan form smart alert berbasis risk warning, technical setup, score, atau invalidation level.

8. README / docs summary jika dibutuhkan
   - Tampilkan README atau `docs/62-p2-final-project-packaging.md` sebagai bukti repository readiness.

## Final Demo Flow

1. Jalankan Flutter web dengan Supabase dart-defines:

   ```powershell
   cd apps/mobile
   flutter run -d web-server --web-port=3000 `
     --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co `
     --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

2. Login dengan akun demo yang aman.

3. Buka Main Watchlist.
   - Tunjukkan watchlist candidate dan latest score.
   - Tunjukkan risk warning dan invalidation level.

4. Buka AI Stock Screener.
   - Pilih kategori screener.
   - Jalankan screener jika perlu.

5. Trigger atau cek P2 Market Data Sync.
   - Pastikan status provider-backed delayed terlihat.
   - Pastikan evidence final terlihat: multi-provider dan no symbol fallback.

6. Review Market Context.
   - Tunjukkan konteks market yang sudah aligned dengan delayed provider-backed data.

7. Review Chart Lab.
   - Tunjukkan preview chart edukatif.
   - Jelaskan bahwa interactive OHLCV chart adalah future integration.

8. Buka Stock Detail Analysis.
   - Tunjukkan score, risk analysis, strategy explanation, dan calculator edukatif.

9. Buat atau tampilkan Smart Alert.
   - Gunakan contoh berbasis risk warning, technical setup, score, atau invalidation level.

## Expected Evidence

Evidence yang sebaiknya terlihat pada screenshot atau catatan demo:

```text
Delayed provider-backed data
Multi-provider
No symbol fallback
live_symbol_count = 5
fallback_symbol_count = 0
tertiary provider = eodhd
```

Expected backend context:

```text
provider_mode = live
data_quality = delayed
selected_provider = mixed_live_providers
fallback_provider_used = false
```

Expected provider chain:

```text
alpha_vantage -> twelve_data -> eodhd -> sample_provider
```

## Security Checklist for Screenshots

Sebelum menyimpan atau membagikan screenshot, pastikan tidak terlihat:

- API key
- JWT token
- service role key
- Authorization header
- full provider URL containing secrets
- raw provider response
- Supabase dashboard secrets page
- browser devtools Network tab yang menampilkan header private

Screenshot aman bila hanya menampilkan:

- app UI
- safe provider metadata
- sanitized diagnostics
- placeholder Supabase URL bila diperlukan di dokumentasi
- wording edukatif dan risk-aware

## Demo Wording Guide

Gunakan wording berikut saat presentasi:

- delayed provider-backed data
- watchlist candidate
- saham layak dianalisis
- technical setup
- risk warning
- invalidation level
- educational market context

Hindari klaim hasil pasti atau instruksi transaksi. Jelaskan bahwa P2 menyediakan data dan konteks edukatif untuk analisis, bukan keputusan otomatis.

## Known Demo Notes

- Data bersifat delayed provider-backed, bukan real-time trading data.
- Chart Lab masih preview sampai interactive OHLCV chart diintegrasikan.
- Beberapa screener categories dapat kosong sampai backend presets tambahan dibuat.
- News provider masih placeholder.
- AI/RAG explanation layer belum aktif dalam flow P2.

## Final Asset Checklist

- [ ] Screenshot Main Watchlist
- [ ] Screenshot AI Stock Screener
- [ ] Screenshot P2 Market Data Sync
- [ ] Screenshot Market Context
- [ ] Screenshot Chart Lab
- [ ] Screenshot Stock Detail Analysis
- [ ] Screenshot Smart Alert
- [ ] Screenshot README atau docs summary bila dibutuhkan
- [ ] Security visual QA selesai
- [ ] Tidak ada secret di screenshot
- [ ] Demo notes menyebut delayed provider-backed data dan limitation dengan jelas
