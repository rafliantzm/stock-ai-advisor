# P3 OHLCV Chart Lab Integration

P3 memulai integrasi Chart Lab dengan OHLCV cache yang sudah ditulis oleh P2 provider chain.

## Current Data Flow

1. `sync-market-candidates` mengambil data provider melalui Edge Function.
2. Jika provider response memiliki `open`, `high`, `low`, dan `close` valid, function menulis cache ke `public.ohlcv_bars`.
3. Flutter tidak membaca tabel `ohlcv_bars` secara langsung.
4. P3 menambahkan Edge Function read-only `get-stock-chart-data` untuk membaca cache tersebut secara aman.

## New Endpoint

```text
POST /functions/v1/get-stock-chart-data
```

Payload:

```json
{
  "symbol_code": "BBCA",
  "timeframe": "1d",
  "limit": 60
}
```

Response berisi:

- sanitized OHLCV bars
- provider name/status
- optional latest indicator snapshot
- educational risk warning
- disclaimer

Endpoint ini tidak memanggil provider eksternal dan tidak mengembalikan raw provider payload.

## Flutter Chart Lab

Chart Lab sekarang mendukung:

- provider-backed delayed OHLCV state
- empty/fallback OHLCV cache state
- educational candlestick preview
- safe wording untuk watchlist candidate dan risk warning

## Security Notes

Tidak boleh mengekspos:

- API key
- JWT token
- service role key
- Authorization header
- full provider URL containing secrets
- raw provider response

Flutter tetap memakai Supabase URL, anon key, dan user JWT. Semua akses OHLCV cache berjalan melalui Edge Function.

## Known Limitations

- Chart saat ini menggunakan candlestick painter sederhana.
- Timeframe awal difokuskan pada `1d`.
- Indicator overlay penuh masih future integration.
- Data bersifat delayed provider-backed, bukan real-time trading data.
