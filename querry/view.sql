-- ============================================
-- VIEWS UNTUK SISTEM PEMESANAN TIKET BIOSKOP
-- ============================================

-- 1. View: Laporan Penjualan (untuk Admin)
DROP VIEW IF EXISTS LaporanPenjualan;
CREATE VIEW LaporanPenjualan AS
SELECT 
    f.film_id,
    f.judul_film,
    f.genre,
    j.tanggal,
    s.nama_studio,
    j.waktu_mulai,
    j.harga_tiket,
    COUNT(CASE WHEN t.status_tiket = 'Aktif' THEN 1 END) AS jumlah_tiket_terjual,
    SUM(CASE WHEN t.status_tiket = 'Aktif' THEN t.harga ELSE 0 END) AS total_pendapatan,
    COUNT(CASE WHEN t.status_tiket = 'Batal' THEN 1 END) AS tiket_dibatalkan,
    j.kapasitas_tersisa
FROM Jadwal j
JOIN Film f ON j.film_id = f.film_id
JOIN Studio s ON j.studio_id = s.studio_id
LEFT JOIN Tiket t ON j.jadwal_id = t.jadwal_id
GROUP BY j.jadwal_id, f.film_id, f.judul_film, f.genre, j.tanggal, s.nama_studio, j.waktu_mulai, j.harga_tiket, j.kapasitas_tersisa;

-- 2. View: Daftar Kursi Tersedia per Jadwal (untuk Kasir & User)
DROP VIEW IF EXISTS DaftarKursiTersedia;
CREATE VIEW DaftarKursiTersedia AS
SELECT 
    j.jadwal_id,
    f.judul_film,
    s.nama_studio,
    j.tanggal,
    j.waktu_mulai,
    j.waktu_selesai,
    j.harga_tiket,
    s.kapasitas AS total_kapasitas,
    COUNT(t.tiket_id) AS kursi_terisi,
    j.kapasitas_tersisa AS kursi_tersedia,
    CONCAT(ROUND((COUNT(t.tiket_id) / s.kapasitas * 100), 2), '%') AS persentase_terisi
FROM Jadwal j
JOIN Film f ON j.film_id = f.film_id
JOIN Studio s ON j.studio_id = s.studio_id
LEFT JOIN Tiket t ON j.jadwal_id = t.jadwal_id AND t.status_tiket = 'Aktif'
GROUP BY j.jadwal_id, f.judul_film, s.nama_studio, j.tanggal, j.waktu_mulai, j.waktu_selesai, j.harga_tiket, s.kapasitas, j.kapasitas_tersisa;

-- 3. View: Jadwal Tayang (untuk semua user melihat)
DROP VIEW IF EXISTS JadwalTayang;
CREATE VIEW JadwalTayang AS
SELECT 
    j.jadwal_id,
    f.judul_film,
    f.genre,
    f.durasi,
    f.rating,
    f.sinopsis,
    s.nama_studio,
    j.tanggal,
    j.waktu_mulai,
    j.waktu_selesai,
    j.harga_tiket,
    j.kapasitas_tersisa,
    CASE 
        WHEN j.kapasitas_tersisa > 20 THEN 'Tersedia Banyak'
        WHEN j.kapasitas_tersisa BETWEEN 1 AND 20 THEN 'Terbatas'
        ELSE 'Penuh'
    END AS status_ketersediaan
FROM Jadwal j
JOIN Film f ON j.film_id = f.film_id
JOIN Studio s ON j.studio_id = s.studio_id
WHERE f.status_film = 'Tayang'
AND j.tanggal >= CURDATE()
ORDER BY j.tanggal, j.waktu_mulai;

-- 4. View: Riwayat Transaksi Per Kasir (untuk Admin monitoring)
DROP VIEW IF EXISTS RiwayatTransaksiKasir;
CREATE VIEW RiwayatTransaksiKasir AS
SELECT 
    k.kasir_id,
    k.nama AS nama_kasir,
    k.level_akses,
    rt.aksi,
    rt.waktu_aksi,
    rt.keterangan,
    DATE(rt.waktu_aksi) AS tanggal
FROM RiwayatTransaksi rt
JOIN Kasir k ON rt.kasir_id = k.kasir_id
ORDER BY rt.waktu_aksi DESC;

-- 5. View: Statistik Film (untuk Admin analisis)
DROP VIEW IF EXISTS StatistikFilm;
CREATE VIEW StatistikFilm AS
SELECT 
    f.film_id,
    f.judul_film,
    f.genre,
    f.rating,
    f.status_film,
    COUNT(DISTINCT j.jadwal_id) AS total_jadwal,
    COUNT(t.tiket_id) AS total_tiket_terjual,
    SUM(CASE WHEN t.status_tiket = 'Aktif' THEN t.harga ELSE 0 END) AS total_pendapatan,
    ROUND(AVG(CASE WHEN t.status_tiket = 'Aktif' THEN t.harga END), 2) AS rata_rata_harga,
    MAX(t.tanggal_pembelian) AS penjualan_terakhir
FROM Film f
LEFT JOIN Jadwal j ON f.film_id = j.film_id
LEFT JOIN Tiket t ON j.jadwal_id = t.jadwal_id
GROUP BY f.film_id, f.judul_film, f.genre, f.rating, f.status_film;

-- 6. View: Detail Tiket untuk User (menampilkan tiket berdasarkan kode)
DROP VIEW IF EXISTS DetailTiket;
CREATE VIEW DetailTiket AS
SELECT 
    t.kode_tiket,
    t.nomor_kursi,
    t.harga,
    t.status_tiket,
    t.tanggal_pembelian,
    f.judul_film,
    f.genre,
    f.durasi,
    f.rating,
    s.nama_studio,
    j.tanggal AS tanggal_tayang,
    j.waktu_mulai,
    j.waktu_selesai,
    k.nama AS nama_kasir,
    p.metode_pembayaran,
    p.status_pembayaran
FROM Tiket t
JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
JOIN Film f ON j.film_id = f.film_id
JOIN Studio s ON j.studio_id = s.studio_id
JOIN Kasir k ON t.kasir_id = k.kasir_id
LEFT JOIN Pembayaran p ON t.tiket_id = p.tiket_id;

-- 7. View: Dashboard Admin (ringkasan harian)
DROP VIEW IF EXISTS DashboardAdmin;
CREATE VIEW DashboardAdmin AS
SELECT 
    CURDATE() AS tanggal,
    COUNT(DISTINCT CASE WHEN DATE(t.tanggal_pembelian) = CURDATE() THEN t.tiket_id END) AS tiket_hari_ini,
    SUM(CASE WHEN DATE(t.tanggal_pembelian) = CURDATE() AND t.status_tiket = 'Aktif' THEN t.harga ELSE 0 END) AS pendapatan_hari_ini,
    COUNT(DISTINCT CASE WHEN j.tanggal = CURDATE() THEN j.jadwal_id END) AS jadwal_hari_ini,
    COUNT(DISTINCT f.film_id) AS total_film_tayang
FROM Tiket t
JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
JOIN Film f ON j.film_id = f.film_id
WHERE f.status_film = 'Tayang';

-- 8. View: Top 5 Film Terlaris
DROP VIEW IF EXISTS Top5FilmTerlaris;
CREATE VIEW Top5FilmTerlaris AS
SELECT 
    f.judul_film,
    f.genre,
    COUNT(t.tiket_id) AS jumlah_tiket,
    SUM(t.harga) AS total_pendapatan
FROM Film f
JOIN Jadwal j ON f.film_id = j.film_id
JOIN Tiket t ON j.jadwal_id = t.jadwal_id
WHERE t.status_tiket = 'Aktif'
GROUP BY f.film_id, f.judul_film, f.genre
ORDER BY jumlah_tiket DESC
LIMIT 5;

-- ============================================
-- CONTOH QUERY MENGGUNAKAN VIEWS
-- ============================================

-- Melihat laporan penjualan
-- SELECT * FROM LaporanPenjualan WHERE tanggal BETWEEN '2025-09-01' AND '2025-12-31';

-- Melihat kursi tersedia untuk jadwal tertentu
-- SELECT * FROM DaftarKursiTersedia WHERE jadwal_id = 1;

-- Melihat jadwal tayang hari ini
-- SELECT * FROM JadwalTayang WHERE tanggal = CURDATE();

-- Melihat riwayat transaksi kasir tertentu
-- SELECT * FROM RiwayatTransaksiKasir WHERE kasir_id = 1 ORDER BY waktu_aksi DESC LIMIT 10;

-- Melihat statistik semua film
-- SELECT * FROM StatistikFilm ORDER BY total_pendapatan DESC;

-- Melihat detail tiket berdasarkan kode
-- SELECT * FROM DetailTiket WHERE kode_tiket = 'TKT000001';

-- Melihat dashboard admin
-- SELECT * FROM DashboardAdmin;

-- Melihat top 5 film terlaris
-- SELECT * FROM Top5FilmTerlaris;
