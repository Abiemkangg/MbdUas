-- ============================================
-- VIEWS UNTUK SISTEM PEMESANAN TIKET BIOSKOP
-- ============================================
-- View dibuat untuk setiap tabel dan kebutuhan reporting
-- ============================================

-- VIEW 1: View Film (Master Data Film dengan Statistik)
DROP VIEW IF EXISTS ViewFilm;
CREATE VIEW ViewFilm AS
SELECT 
    f.film_id,
    f.judul_film,
    f.genre,
    f.durasi,
    f.sutradara,
    f.sinopsis,
    f.rating,
    f.tanggal_rilis,
    f.status_film,
    COUNT(DISTINCT j.jadwal_id) AS total_jadwal,
    COUNT(t.tiket_id) AS total_tiket_terjual,
    COALESCE(SUM(CASE WHEN t.status_tiket = 'Aktif' THEN t.harga ELSE 0 END), 0) AS total_pendapatan
FROM Film f
LEFT JOIN Jadwal j ON f.film_id = j.film_id
LEFT JOIN Tiket t ON j.jadwal_id = t.jadwal_id
GROUP BY f.film_id, f.judul_film, f.genre, f.durasi, f.sutradara, f.sinopsis, f.rating, f.tanggal_rilis, f.status_film;

-- VIEW 2: View Studio (Master Data Studio dengan Kapasitas)
DROP VIEW IF EXISTS ViewStudio;
CREATE VIEW ViewStudio AS
SELECT 
    s.studio_id,
    s.nama_studio,
    s.kapasitas AS total_kapasitas,
    COUNT(DISTINCT j.jadwal_id) AS total_jadwal_aktif,
    COALESCE(SUM(j.kapasitas_tersisa), 0) AS total_kursi_tersisa_hari_ini
FROM Studio s
LEFT JOIN Jadwal j ON s.studio_id = j.studio_id AND j.tanggal >= CURDATE()
GROUP BY s.studio_id, s.nama_studio, s.kapasitas;

-- VIEW 3: View Kasir (Master Data Kasir dengan Aktivitas)
DROP VIEW IF EXISTS ViewKasir;
CREATE VIEW ViewKasir AS
SELECT 
    k.kasir_id,
    k.nama,
    k.username,
    k.no_telepon,
    k.tanggal_bergabung,
    k.level_akses,
    COUNT(DISTINCT t.tiket_id) AS total_tiket_dijual,
    COALESCE(SUM(CASE WHEN t.status_tiket = 'Aktif' THEN t.harga ELSE 0 END), 0) AS total_penjualan,
    (SELECT COUNT(*) FROM RiwayatTransaksi WHERE kasir_id = k.kasir_id) AS total_aktivitas
FROM Kasir k
LEFT JOIN Tiket t ON k.kasir_id = t.kasir_id
GROUP BY k.kasir_id, k.nama, k.username, k.no_telepon, k.tanggal_bergabung, k.level_akses;

-- VIEW 4: View Jadwal (Semua Jadwal dengan Info Lengkap)
DROP VIEW IF EXISTS ViewJadwal;
CREATE VIEW ViewJadwal AS
SELECT 
    j.jadwal_id,
    j.film_id,
    f.judul_film,
    f.genre,
    f.durasi,
    f.rating,
    j.studio_id,
    s.nama_studio,
    s.kapasitas AS total_kapasitas,
    j.tanggal,
    j.waktu_mulai,
    j.waktu_selesai,
    j.harga_tiket,
    j.kapasitas_tersisa,
    (s.kapasitas - j.kapasitas_tersisa) AS kursi_terisi,
    ROUND(((s.kapasitas - j.kapasitas_tersisa) / s.kapasitas * 100), 2) AS persentase_terisi,
    COUNT(t.tiket_id) AS jumlah_tiket_aktif
FROM Jadwal j
JOIN Film f ON j.film_id = f.film_id
JOIN Studio s ON j.studio_id = s.studio_id
LEFT JOIN Tiket t ON j.jadwal_id = t.jadwal_id AND t.status_tiket = 'Aktif'
GROUP BY j.jadwal_id, j.film_id, f.judul_film, f.genre, f.durasi, f.rating, j.studio_id, s.nama_studio, s.kapasitas, j.tanggal, j.waktu_mulai, j.waktu_selesai, j.harga_tiket, j.kapasitas_tersisa;

-- VIEW 5: View Tiket (Semua Tiket dengan Detail Lengkap)
DROP VIEW IF EXISTS ViewTiket;
CREATE VIEW ViewTiket AS
SELECT 
    t.tiket_id,
    t.kode_tiket,
    t.nomor_kursi,
    t.harga,
    t.tanggal_pembelian,
    t.status_tiket,
    t.jadwal_id,
    j.tanggal AS tanggal_tayang,
    j.waktu_mulai,
    j.waktu_selesai,
    f.film_id,
    f.judul_film,
    f.genre,
    f.durasi,
    f.rating,
    s.studio_id,
    s.nama_studio,
    k.kasir_id,
    k.nama AS nama_kasir,
    k.level_akses AS level_kasir,
    p.pembayaran_id,
    p.metode_pembayaran,
    p.status_pembayaran,
    p.tanggal_pembayaran
FROM Tiket t
JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
JOIN Film f ON j.film_id = f.film_id
JOIN Studio s ON j.studio_id = s.studio_id
JOIN Kasir k ON t.kasir_id = k.kasir_id
LEFT JOIN Pembayaran p ON t.tiket_id = p.tiket_id;

-- VIEW 6: View Pembayaran (Semua Pembayaran dengan Detail)
DROP VIEW IF EXISTS ViewPembayaran;
CREATE VIEW ViewPembayaran AS
SELECT 
    p.pembayaran_id,
    p.tiket_id,
    t.kode_tiket,
    p.jumlah_pembayaran,
    p.metode_pembayaran,
    p.tanggal_pembayaran,
    p.status_pembayaran,
    t.nomor_kursi,
    t.status_tiket,
    f.judul_film,
    j.tanggal AS tanggal_tayang,
    j.waktu_mulai,
    s.nama_studio,
    k.nama AS nama_kasir,
    k.level_akses
FROM Pembayaran p
JOIN Tiket t ON p.tiket_id = t.tiket_id
JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
JOIN Film f ON j.film_id = f.film_id
JOIN Studio s ON j.studio_id = s.studio_id
JOIN Kasir k ON t.kasir_id = k.kasir_id;

-- VIEW 7: View Payment Gateway (Master Payment Gateway dengan Statistik)
DROP VIEW IF EXISTS ViewPaymentGateway;
CREATE VIEW ViewPaymentGateway AS
SELECT 
    pg.gateway_id,
    pg.nama_gateway,
    pg.status_gateway,
    COUNT(tp.transaksi_id) AS total_transaksi,
    COUNT(CASE WHEN tp.status_transaksi = 'Berhasil' THEN 1 END) AS transaksi_berhasil,
    COUNT(CASE WHEN tp.status_transaksi = 'Gagal' THEN 1 END) AS transaksi_gagal,
    COUNT(CASE WHEN tp.status_transaksi = 'Pending' THEN 1 END) AS transaksi_pending
FROM Payment_Gateway pg
LEFT JOIN Transaksi_Pembayaran tp ON pg.gateway_id = tp.gateway_id
GROUP BY pg.gateway_id, pg.nama_gateway, pg.status_gateway;

-- VIEW 8: View Transaksi Pembayaran (Semua Transaksi Payment Gateway)
DROP VIEW IF EXISTS ViewTransaksiPembayaran;
CREATE VIEW ViewTransaksiPembayaran AS
SELECT 
    tp.transaksi_id,
    tp.pembayaran_id,
    tp.gateway_id,
    pg.nama_gateway,
    tp.reference_number,
    tp.waktu_transaksi,
    tp.status_transaksi,
    p.jumlah_pembayaran,
    p.metode_pembayaran,
    t.kode_tiket,
    f.judul_film,
    k.nama AS nama_kasir
FROM Transaksi_Pembayaran tp
JOIN Payment_Gateway pg ON tp.gateway_id = pg.gateway_id
JOIN Pembayaran p ON tp.pembayaran_id = p.pembayaran_id
JOIN Tiket t ON p.tiket_id = t.tiket_id
JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
JOIN Film f ON j.film_id = f.film_id
JOIN Kasir k ON t.kasir_id = k.kasir_id;

-- VIEW 9: View Riwayat Transaksi (Log Aktivitas Kasir/Admin)
DROP VIEW IF EXISTS ViewRiwayatTransaksi;
CREATE VIEW ViewRiwayatTransaksi AS
SELECT 
    r.riwayat_id,
    r.kasir_id,
    k.nama AS nama_kasir,
    k.level_akses,
    r.aksi,
    r.waktu_aksi,
    r.keterangan,
    DATE(r.waktu_aksi) AS tanggal_aksi,
    TIME(r.waktu_aksi) AS jam_aksi
FROM RiwayatTransaksi r
JOIN Kasir k ON r.kasir_id = k.kasir_id;

-- ============================================
-- VIEWS UNTUK REPORTING & ANALYTICS
-- ============================================

-- VIEW 10: Laporan Penjualan (untuk Admin)
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
