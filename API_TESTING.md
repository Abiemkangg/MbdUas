# API Testing Guide - Sistem Pemesanan Tiket Bioskop

Base URL: `http://localhost:3000`

## Test Sequence (Recommended Order)

### 1. Login as Admin
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "rizki123",
    "password": "pass123"
  }'
```

### 2. Get All Films
```bash
curl http://localhost:3000/api/films
```

### 3. Add New Film (Admin)
```bash
curl -X POST http://localhost:3000/api/films \
  -H "Content-Type: application/json" \
  -d '{
    "judul_film": "Oppenheimer",
    "genre": "Biography",
    "durasi": "180 menit",
    "sutradara": "Christopher Nolan",
    "sinopsis": "The story of American scientist J. Robert Oppenheimer",
    "rating": "R",
    "tanggal_rilis": "2023-07-21",
    "status_film": "Tayang",
    "admin_id": 1
  }'
```

### 4. Get All Studios
```bash
curl http://localhost:3000/api/studio
```

### 5. Add New Jadwal (Admin)
```bash
curl -X POST http://localhost:3000/api/jadwal \
  -H "Content-Type: application/json" \
  -d '{
    "film_id": 1,
    "studio_id": 1,
    "tanggal": "2025-12-10",
    "waktu_mulai": "14:00:00",
    "waktu_selesai": "17:00:00",
    "harga_tiket": 65000,
    "admin_id": 1
  }'
```

### 6. Get Jadwal Tayang (User View)
```bash
curl "http://localhost:3000/api/jadwal/tayang/list?tanggal=2025-12-10"
```

### 7. Get Kursi Tersedia for Jadwal
```bash
curl "http://localhost:3000/api/jadwal/kursi/tersedia?jadwal_id=1"
```

### 8. Get Kursi Terisi for Jadwal
```bash
curl http://localhost:3000/api/jadwal/1/kursi/terisi
```

### 9. Login as Kasir
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "rizki123",
    "password": "pass123"
  }'
```

### 10. Create Tiket (Kasir)
```bash
curl -X POST http://localhost:3000/api/tiket \
  -H "Content-Type: application/json" \
  -d '{
    "jadwal_id": 1,
    "kasir_id": 1,
    "nomor_kursi": "B5",
    "metode_pembayaran": "QRIS"
  }'
```

### 11. Get Tiket by Kode
```bash
curl http://localhost:3000/api/tiket/kode/TKT000001
```

### 12. Get Detail Tiket (View)
```bash
curl http://localhost:3000/api/tiket/detail/TKT000001
```

### 13. Cancel Tiket (Kasir)
```bash
curl -X PUT http://localhost:3000/api/tiket/TKT000003/batal \
  -H "Content-Type: application/json" \
  -d '{
    "kasir_id": 1
  }'
```

### 14. Get Dashboard Admin
```bash
curl http://localhost:3000/api/dashboard/admin
```

### 15. Get Laporan Penjualan
```bash
curl "http://localhost:3000/api/laporan/penjualan?tanggal_mulai=2025-09-01&tanggal_akhir=2025-12-31"
```

### 16. Get Statistik Film
```bash
curl http://localhost:3000/api/films/statistik/all
```

### 17. Get Top 5 Film Terlaris
```bash
curl http://localhost:3000/api/films/top/terlaris
```

### 18. Get Statistik Pembayaran
```bash
curl "http://localhost:3000/api/pembayaran/statistik/metode?tanggal_mulai=2025-09-01&tanggal_akhir=2025-12-31"
```

### 19. Get Riwayat Transaksi Kasir
```bash
curl http://localhost:3000/api/kasir/1/riwayat
```

### 20. Update Film (Admin)
```bash
curl -X PUT http://localhost:3000/api/films/1 \
  -H "Content-Type: application/json" \
  -d '{
    "judul_film": "Avengers: Endgame - Remastered",
    "genre": "Action",
    "durasi": "180 menit",
    "sutradara": "Anthony & Joe Russo",
    "sinopsis": "Pertarungan terakhir melawan Thanos",
    "rating": "PG-13",
    "tanggal_rilis": "2019-04-26",
    "status_film": "Tayang",
    "admin_id": 1
  }'
```

### 21. Delete Tiket Batal (Admin Maintenance)
```bash
curl -X DELETE http://localhost:3000/api/tiket/batal/hapus \
  -H "Content-Type: application/json" \
  -d '{
    "admin_id": 1
  }'
```

## PowerShell Version (for Windows)

### Login
```powershell
$body = @{
    username = "rizki123"
    password = "pass123"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method Post -Body $body -ContentType "application/json"
```

### Create Tiket
```powershell
$body = @{
    jadwal_id = 1
    kasir_id = 1
    nomor_kursi = "C10"
    metode_pembayaran = "Tunai"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/tiket" -Method Post -Body $body -ContentType "application/json"
```

### Get Jadwal Tayang
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/jadwal/tayang/list?tanggal=2025-12-10"
```

## Common Errors & Solutions

### Error: "Kursi sudah terisi"
- Solution: Pilih nomor kursi yang berbeda untuk jadwal yang sama

### Error: "Jadwal bentrok"
- Solution: Pastikan waktu tidak overlap dengan jadwal lain di studio yang sama

### Error: "Film tidak dalam status tayang"
- Solution: Update status_film menjadi 'Tayang' sebelum membuat jadwal

### Error: "Kapasitas studio sudah penuh"
- Solution: Pilih jadwal lain atau tambah jadwal baru

## Notes
- Semua endpoint yang modify data memerlukan `kasir_id` atau `admin_id`
- Kode tiket auto-generate dengan format TKT000001, TKT000002, dst.
- Trigger otomatis mengelola kapasitas_tersisa saat tiket dibuat/dibatalkan
- Pembayaran otomatis dibuat saat tiket dibuat
