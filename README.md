# API Sistem Pemesanan Tiket Bioskop

API backend untuk sistem pemesanan tiket bioskop yang diakses oleh Admin dan Kasir.

## 📋 Fitur Utama

- **Authentication**: Login untuk Admin dan Kasir
- **Manajemen Film**: CRUD film (Admin)
- **Manajemen Jadwal**: Tambah jadwal tayang dengan validasi bentrok
- **Pemesanan Tiket**: Kasir dapat memproses pemesanan tiket
- **Pembatalan Tiket**: Kasir dapat membatalkan tiket
- **Laporan Penjualan**: Admin dapat melihat laporan dan statistik
- **Views**: User dapat melihat kursi tersedia dan detail tiket

## 🚀 Setup

1. **Clone repository**
```bash
git clone <repository-url>
cd test-api
```

2. **Install dependencies**
```bash
npm install
```

3. **Setup database**
   - Buat database MySQL
   - Import file SQL dari folder `querry/`:
     - `tiket_bioskop.sql` (struktur tabel dan data dummy)
     - `function.sql` (functions)
     - `procedure.sql` (stored procedures)
     - `trigger.sql` (triggers)
     - `view.sql` (views)

4. **Setup environment variables**
   - Copy `.env.example` menjadi `.env`
   - Sesuaikan konfigurasi database:
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=BioskopDB
PORT=3000
```

5. **Jalankan server**
```bash
npm start
# atau untuk development mode
npm run dev
```

Server akan berjalan di `http://localhost:3000`

## 📚 API Endpoints

### 🔐 Authentication

#### Login Kasir/Admin
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "rizki123",
  "password": "pass123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "kasir_id": 1,
    "nama": "Rizki",
    "level_akses": "Kasir"
  }
}
```

### 🎬 Film Management

#### Get Semua Film
```http
GET /api/films
```

#### Get Film by ID
```http
GET /api/films/:id
```

#### Tambah Film Baru (Admin)
```http
POST /api/films
Content-Type: application/json

{
  "judul_film": "Spiderman: No Way Home",
  "genre": "Action",
  "durasi": "148 menit",
  "sutradara": "Jon Watts",
  "sinopsis": "Peter Parker mencari bantuan Doctor Strange",
  "rating": "PG-13",
  "tanggal_rilis": "2021-12-15",
  "status_film": "Tayang",
  "admin_id": 1
}
```

#### Update Film (Admin)
```http
PUT /api/films/:id
Content-Type: application/json

{
  "judul_film": "Spiderman: No Way Home - Extended",
  "genre": "Action",
  "durasi": "160 menit",
  "sutradara": "Jon Watts",
  "sinopsis": "Peter Parker mencari bantuan Doctor Strange",
  "rating": "PG-13",
  "tanggal_rilis": "2021-12-15",
  "status_film": "Tayang",
  "admin_id": 1
}
```

#### Hapus Film (Admin)
```http
DELETE /api/films/:id
Content-Type: application/json

{
  "admin_id": 1
}
```

#### Get Statistik Film
```http
GET /api/films/statistik/all
```

#### Get Top 5 Film Terlaris
```http
GET /api/films/top/terlaris
```

### 📅 Jadwal Management

#### Get Semua Jadwal
```http
GET /api/jadwal
```

#### Get Jadwal Tayang (untuk User/Kasir)
```http
GET /api/jadwal/tayang/list?tanggal=2025-12-15
```

#### Get Daftar Kursi Tersedia
```http
GET /api/jadwal/kursi/tersedia?jadwal_id=1
```

#### Get Kursi yang Terisi
```http
GET /api/jadwal/:jadwal_id/kursi/terisi
```

#### Tambah Jadwal Baru (Admin)
```http
POST /api/jadwal
Content-Type: application/json

{
  "film_id": 1,
  "studio_id": 1,
  "tanggal": "2025-12-15",
  "waktu_mulai": "14:00:00",
  "waktu_selesai": "17:00:00",
  "harga_tiket": 65000,
  "admin_id": 1
}
```

### 🎟️ Tiket Management

#### Buat Tiket Baru (Kasir)
```http
POST /api/tiket
Content-Type: application/json

{
  "jadwal_id": 1,
  "kasir_id": 1,
  "nomor_kursi": "A10",
  "metode_pembayaran": "QRIS"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Tiket berhasil dibuat",
  "data": {
    "kode_tiket": "TKT000003",
    "harga": 60000,
    "nomor_kursi": "A10"
  }
}
```

#### Batalkan Tiket (Kasir)
```http
PUT /api/tiket/:kode_tiket/batal
Content-Type: application/json

{
  "kasir_id": 1
}
```

#### Get Tiket by Kode
```http
GET /api/tiket/kode/TKT000001
```

#### Get Detail Tiket (View)
```http
GET /api/tiket/detail/TKT000001
```

#### Hapus Tiket Batal (Admin Maintenance)
```http
DELETE /api/tiket/batal/hapus
Content-Type: application/json

{
  "admin_id": 1
}
```

### 💰 Pembayaran & Laporan

#### Get Dashboard Admin
```http
GET /api/dashboard/admin
```

#### Get Laporan Penjualan
```http
GET /api/laporan/penjualan?tanggal_mulai=2025-09-01&tanggal_akhir=2025-12-31
```

#### Get Laporan Penjualan (View)
```http
GET /api/laporan/penjualan/view?tanggal_mulai=2025-09-01&tanggal_akhir=2025-12-31
```

#### Get Statistik Pembayaran per Metode
```http
GET /api/pembayaran/statistik/metode?tanggal_mulai=2025-09-01&tanggal_akhir=2025-12-31
```

## 🗂️ Struktur Project

```
test-api/
├── config/
│   └── db.js                    # Database connection
├── src/
│   ├── Controllers/
│   │   ├── filmController.js
│   │   ├── jadwalController.js
│   │   ├── kasirController.js
│   │   ├── pembayaranController.js
│   │   └── tiketController.js
│   └── index.js                 # Main server file
├── querry/
│   ├── tiket_bioskop.sql        # Database schema
│   ├── function.sql             # SQL functions
│   ├── procedure.sql            # Stored procedures
│   ├── trigger.sql              # Database triggers
│   └── view.sql                 # Database views
├── .env                         # Environment variables
├── .env.example                 # Environment template
└── package.json
```

## 🔧 Stored Procedures yang Digunakan

1. `LoginUser` - Login kasir/admin
2. `BuatTiket` - Buat tiket baru dengan auto-generate kode
3. `BatalkanTiket` - Batalkan tiket
4. `TambahFilm` - Tambah film baru
5. `UpdateFilm` - Update data film
6. `HapusFilm` - Hapus film
7. `TambahJadwal` - Tambah jadwal dengan validasi bentrok
8. `LaporanPenjualan` - Generate laporan penjualan
9. `HapusTiketBatal` - Hapus semua tiket batal (maintenance)
10. `TampilkanTiket` - Tampilkan detail tiket

## 📊 Views yang Digunakan

1. `JadwalTayang` - Jadwal tayang untuk user
2. `DaftarKursiTersedia` - Ketersediaan kursi per jadwal
3. `LaporanPenjualan` - Laporan penjualan
4. `StatistikFilm` - Statistik performa film
5. `DetailTiket` - Detail lengkap tiket
6. `DashboardAdmin` - Dashboard ringkasan harian
7. `Top5FilmTerlaris` - Top 5 film terlaris
8. `RiwayatTransaksiKasir` - Riwayat transaksi per kasir

## 🔑 Level Akses

- **Admin**: 
  - Tambah/Update/Hapus Film
  - Tambah Jadwal
  - Lihat Laporan Penjualan
  - Hapus Tiket Batal (maintenance)
  
- **Kasir**:
  - Buat Tiket
  - Batalkan Tiket
  - Lihat Jadwal & Kursi Tersedia
  
- **User** (Read-only):
  - Lihat Jadwal Tayang
  - Lihat Kursi Tersedia
  - Lihat Detail Tiket (by kode)

## 🛠️ Technology Stack

- **Node.js** - Runtime
- **Express.js** - Web framework
- **MySQL2** - Database driver
- **dotenv** - Environment variables

## 📝 Notes

- Semua endpoint yang mengubah data memerlukan `kasir_id` atau `admin_id` untuk audit trail
- Trigger otomatis mengelola kapasitas kursi
- Kode tiket di-generate otomatis dengan format `TKT000001`
- Validasi jadwal bentrok dilakukan di stored procedure
- Semua transaksi menggunakan transaction untuk data consistency

## 👨‍💻 Development

Untuk development, gunakan:
```bash
npm run dev
```

Ini akan menjalankan server dengan auto-reload saat ada perubahan file.
