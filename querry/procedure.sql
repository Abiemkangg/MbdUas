-- ============================================
-- STORED PROCEDURES UNTUK SISTEM PEMESANAN TIKET BIOSKOP
-- ============================================

-- 1. Procedure: Pemesanan Tiket (Use Case Kasir)
DELIMITER //
DROP PROCEDURE IF EXISTS BuatTiket//
CREATE PROCEDURE BuatTiket (
    IN p_jadwal_id INT,
    IN p_kasir_id INT,
    IN p_nomor_kursi VARCHAR(10),
    IN p_metode_pembayaran VARCHAR(20)
)
BEGIN
    DECLARE harga DECIMAL(10,2);
    DECLARE tiketBaruId INT;
    DECLARE kode VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
        VALUES (p_kasir_id, 'Gagal Membuat Tiket', NOW(), 'Terjadi error pada transaksi.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transaksi dibatalkan.';
    END;

    START TRANSACTION;

    -- Validasi kursi tersedia
    IF CekKursiTersedia(p_jadwal_id, p_nomor_kursi) = TRUE THEN
        -- Generate kode tiket otomatis
        SET kode = GenerateKodeTiket();
        
        -- Ambil harga dari jadwal
        SELECT harga_tiket INTO harga FROM Jadwal WHERE jadwal_id = p_jadwal_id;
        
        -- Insert tiket
        INSERT INTO Tiket (jadwal_id, kasir_id, kode_tiket, nomor_kursi, harga, tanggal_pembelian, status_tiket)
        VALUES (p_jadwal_id, p_kasir_id, kode, p_nomor_kursi, harga, NOW(), 'Aktif');
        
        SET tiketBaruId = LAST_INSERT_ID();
        
        -- Insert pembayaran
        INSERT INTO Pembayaran (tiket_id, jumlah_pembayaran, metode_pembayaran, tanggal_pembayaran, status_pembayaran)
        VALUES (tiketBaruId, harga, p_metode_pembayaran, NOW(), 'Lunas');
        
        -- Log riwayat
        INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
        VALUES (p_kasir_id, 'Berhasil Membuat Tiket', NOW(), CONCAT('Tiket ', kode, ' berhasil dibuat untuk kursi ', p_nomor_kursi));
        
        COMMIT;
        
        -- Return kode tiket
        SELECT kode AS kode_tiket, harga, p_nomor_kursi AS nomor_kursi;
    ELSE
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kursi sudah terisi atau tidak tersedia.';
    END IF;
END//

-- 2. Procedure: Membatalkan Tiket (Use Case Kasir)
DROP PROCEDURE IF EXISTS BatalkanTiket//
CREATE PROCEDURE BatalkanTiket(
    IN p_kode_tiket VARCHAR(50),
    IN p_kasir_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal membatalkan tiket.';
    END;
    
    START TRANSACTION;
    
    -- Update status tiket
    UPDATE Tiket 
    SET status_tiket = 'Batal'
    WHERE kode_tiket = p_kode_tiket
    AND status_tiket = 'Aktif';
    
    -- Update status pembayaran
    UPDATE Pembayaran p
    JOIN Tiket t ON p.tiket_id = t.tiket_id
    SET p.status_pembayaran = 'Refund'
    WHERE t.kode_tiket = p_kode_tiket;
    
    -- Log riwayat
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_kasir_id, 'Batalkan Tiket', NOW(), CONCAT('Tiket ', p_kode_tiket, ' dibatalkan'));
    
    COMMIT;
END//

-- 3. Procedure: Menambah Film (Use Case Admin)
DROP PROCEDURE IF EXISTS TambahFilm//
CREATE PROCEDURE TambahFilm(
    IN p_judul_film VARCHAR(100),
    IN p_genre VARCHAR(50),
    IN p_durasi VARCHAR(20),
    IN p_sutradara VARCHAR(100),
    IN p_sinopsis TEXT,
    IN p_rating VARCHAR(10),
    IN p_tanggal_rilis DATE,
    IN p_status VARCHAR(20),
    IN p_admin_id INT
)
BEGIN
    DECLARE new_film_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal menambah film.';
    END;
    
    START TRANSACTION;
    
    INSERT INTO Film (judul_film, genre, durasi, sutradara, sinopsis, rating, tanggal_rilis, status_film)
    VALUES (p_judul_film, p_genre, p_durasi, p_sutradara, p_sinopsis, p_rating, p_tanggal_rilis, p_status);
    
    SET new_film_id = LAST_INSERT_ID();
    
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Tambah Film', NOW(), CONCAT('Film "', p_judul_film, '" ditambahkan dengan ID: ', new_film_id));
    
    COMMIT;
    
    SELECT new_film_id AS film_id, p_judul_film AS judul_film;
END//

-- 4. Procedure: Mengubah Film (Use Case Admin)
DROP PROCEDURE IF EXISTS UpdateFilm//
CREATE PROCEDURE UpdateFilm(
    IN p_film_id INT,
    IN p_judul_film VARCHAR(100),
    IN p_genre VARCHAR(50),
    IN p_durasi VARCHAR(20),
    IN p_sutradara VARCHAR(100),
    IN p_sinopsis TEXT,
    IN p_rating VARCHAR(10),
    IN p_tanggal_rilis DATE,
    IN p_status_film VARCHAR(20),
    IN p_admin_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Terjadi error, pembaruan dibatalkan!';
    END;

    START TRANSACTION;

    UPDATE Film
    SET judul_film = p_judul_film,
        genre = p_genre,
        durasi = p_durasi,
        sutradara = p_sutradara,
        sinopsis = p_sinopsis,
        rating = p_rating,
        tanggal_rilis = p_tanggal_rilis,
        status_film = p_status_film
    WHERE film_id = p_film_id;
    
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Update Film', NOW(), CONCAT('Film ID ', p_film_id, ' diupdate'));

    COMMIT;
END//

-- 5. Procedure: Menghapus Film (Use Case Admin)
DROP PROCEDURE IF EXISTS HapusFilm//
CREATE PROCEDURE HapusFilm(
    IN p_film_id INT,
    IN p_admin_id INT
)
BEGIN
    DECLARE judul VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal menghapus film. Pastikan tidak ada jadwal aktif.';
    END;
    
    START TRANSACTION;
    
    -- Ambil judul film untuk log
    SELECT judul_film INTO judul FROM Film WHERE film_id = p_film_id;
    
    -- Hapus film (akan error jika ada foreign key constraint)
    DELETE FROM Film WHERE film_id = p_film_id;
    
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Hapus Film', NOW(), CONCAT('Film "', judul, '" dihapus'));
    
    COMMIT;
END//

-- 6. Procedure: Menambah Jadwal (Use Case Admin)
DROP PROCEDURE IF EXISTS TambahJadwal//
CREATE PROCEDURE TambahJadwal(
    IN p_film_id INT,
    IN p_studio_id INT,
    IN p_tanggal DATE,
    IN p_waktu_mulai TIME,
    IN p_waktu_selesai TIME,
    IN p_harga_tiket DECIMAL(10,2),
    IN p_admin_id INT
)
BEGIN
    DECLARE kapasitas INT;
    DECLARE new_jadwal_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal menambah jadwal.';
    END;
    
    START TRANSACTION;
    
    -- Validasi jadwal bentrok
    IF CekJadwalBentrok(p_studio_id, p_tanggal, p_waktu_mulai, p_waktu_selesai) = TRUE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jadwal bentrok dengan jadwal lain di studio yang sama!';
    END IF;
    
    -- Validasi film aktif
    IF CekFilmAktif(p_film_id) = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Film tidak dalam status tayang!';
    END IF;
    
    -- Ambil kapasitas studio
    SELECT kapasitas INTO kapasitas FROM Studio WHERE studio_id = p_studio_id;
    
    -- Insert jadwal
    INSERT INTO Jadwal (film_id, studio_id, tanggal, waktu_mulai, waktu_selesai, harga_tiket, kapasitas_tersisa)
    VALUES (p_film_id, p_studio_id, p_tanggal, p_waktu_mulai, p_waktu_selesai, p_harga_tiket, kapasitas);
    
    SET new_jadwal_id = LAST_INSERT_ID();
    
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Tambah Jadwal', NOW(), CONCAT('Jadwal ID ', new_jadwal_id, ' ditambahkan'));
    
    COMMIT;
    
    SELECT new_jadwal_id AS jadwal_id;
END//

-- 7. Procedure: Melihat Laporan Penjualan (Use Case Admin)
DROP PROCEDURE IF EXISTS LaporanPenjualan//
CREATE PROCEDURE LaporanPenjualan(
    IN p_tanggal_mulai DATE,
    IN p_tanggal_akhir DATE
)
BEGIN
    SELECT 
        f.judul_film,
        j.tanggal,
        s.nama_studio,
        COUNT(t.tiket_id) AS jumlah_tiket_terjual,
        SUM(t.harga) AS total_pendapatan,
        j.harga_tiket,
        (SELECT COUNT(*) FROM Tiket WHERE jadwal_id = j.jadwal_id AND status_tiket = 'Batal') AS tiket_batal
    FROM Jadwal j
    JOIN Film f ON j.film_id = f.film_id
    JOIN Studio s ON j.studio_id = s.studio_id
    LEFT JOIN Tiket t ON j.jadwal_id = t.jadwal_id AND t.status_tiket = 'Aktif'
    WHERE j.tanggal BETWEEN p_tanggal_mulai AND p_tanggal_akhir
    GROUP BY j.jadwal_id, f.judul_film, j.tanggal, s.nama_studio, j.harga_tiket
    ORDER BY j.tanggal DESC, f.judul_film;
END//

-- 8. Procedure: Menghapus Tiket Batal (Use Case Admin - Maintenance)
DROP PROCEDURE IF EXISTS HapusTiketBatal//
CREATE PROCEDURE HapusTiketBatal(
    IN p_admin_id INT
)
BEGIN
    DECLARE jumlah_dihapus INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal menghapus tiket batal.';
    END;
    
    START TRANSACTION;
    
    -- Hitung jumlah yang akan dihapus
    SELECT COUNT(*) INTO jumlah_dihapus FROM Tiket WHERE status_tiket = 'Batal';
    
    -- Hapus pembayaran terkait dulu
    DELETE p FROM Pembayaran p
    JOIN Tiket t ON p.tiket_id = t.tiket_id
    WHERE t.status_tiket = 'Batal';
    
    -- Hapus tiket
    DELETE FROM Tiket WHERE status_tiket = 'Batal';
    
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Hapus Tiket Batal', NOW(), CONCAT(jumlah_dihapus, ' tiket batal dihapus.'));
    
    COMMIT;
    
    SELECT jumlah_dihapus AS total_dihapus;
END//

-- 9. Procedure: Login Kasir/Admin
DROP PROCEDURE IF EXISTS LoginUser//
CREATE PROCEDURE LoginUser(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(100)
)
BEGIN
    DECLARE user_id INT;
    DECLARE nama_user VARCHAR(100);
    DECLARE akses VARCHAR(20);
    
    SELECT kasir_id, nama, level_akses INTO user_id, nama_user, akses
    FROM Kasir
    WHERE username = p_username
    AND password = p_password;
    
    IF user_id IS NOT NULL THEN
        -- Log aktivitas login
        INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
        VALUES (user_id, 'Login', NOW(), CONCAT(nama_user, ' login sebagai ', akses));
        
        SELECT user_id AS kasir_id, nama_user AS nama, akses AS level_akses, 'success' AS status;
    ELSE
        SELECT 'failed' AS status, 'Username atau password salah' AS message;
    END IF;
END//

-- 10. Procedure: Menampilkan Tiket Berdasarkan Kode
DROP PROCEDURE IF EXISTS TampilkanTiket//
CREATE PROCEDURE TampilkanTiket(
    IN p_kode_tiket VARCHAR(50)
)
BEGIN
    SELECT 
        t.kode_tiket,
        t.nomor_kursi,
        t.harga,
        t.tanggal_pembelian,
        t.status_tiket,
        f.judul_film,
        j.tanggal,
        j.waktu_mulai,
        s.nama_studio,
        k.nama AS nama_kasir
    FROM Tiket t
    JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
    JOIN Film f ON j.film_id = f.film_id
    JOIN Studio s ON j.studio_id = s.studio_id
    JOIN Kasir k ON t.kasir_id = k.kasir_id
    WHERE t.kode_tiket = p_kode_tiket;
END//

DELIMITER ;

-- TambahFilm
DELIMITER 
DROP PROCEDURE IF EXISTS TambahFilm;
CREATE PROCEDURE TambahFilm(
    CREATE PROCEDURE TambahFilm(
    IN p_judul_film VARCHAR(100),
    IN p_genre VARCHAR(50),
    IN p_durasi VARCHAR(20),
    IN p_sutradara VARCHAR(100),
    IN p_sinopsis TEXT,
    IN p_rating VARCHAR(10),
    IN p_tanggal_rilis DATE,
    IN p_status VARCHAR(20),
    IN p_admin_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; END;
    START TRANSACTION;
    INSERT INTO Film (judul_film, genre, durasi, sutradara, sinopsis, rating, tanggal_rilis, status_film)
    VALUES (p_judul_film, p_genre, p_durasi, p_sutradara, p_sinopsis, p_rating, p_tanggal_rilis, p_status);
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Tambah Film', NOW(), CONCAT('Film "', p_judul_film, '" ditambahkan.'));
    COMMIT;
END 

DELIMITER ;

-- UpdateStatusTiket
DELIMITER 
CREATE PROCEDURE UpdateStatusTiket(
    IN p_kode_tiket VARCHAR(50),
    IN p_status_baru VARCHAR(20),
    IN p_kasir_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; END;
    START TRANSACTION;
    UPDATE Tiket SET status_tiket = p_status_baru WHERE kode_tiket = p_kode_tiket;
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_kasir_id, 'Update Status Tiket', NOW(), CONCAT('Tiket ', p_kode_tiket, ' jadi ', p_status_baru));
    COMMIT;
END 
DELIMITER ;

DELIMITER 
DROP PROCEDURE IF EXISTS UpdateFilm;
CREATE PROCEDURE UpdateFilm(

    IN p_judul_film VARCHAR(100),
    IN p_genre VARCHAR(50),
    IN p_durasi VARCHAR(20),
    IN p_sutradara VARCHAR(100),
    IN p_sinopsis TEXT,
    IN p_rating VARCHAR(10),
    IN p_tanggal_rilis DATE,
    IN p_status_film VARCHAR(20),
    IN p_film_id INT

)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Terjadi error, pembaruan dibatalkan!';
    END;

    START TRANSACTION;

    UPDATE Film
    SET judul_film = p_judul_film,
        genre = p_genre,
        durasi = p_durasi,
        sutradara = p_sutradara,
        sinopsis = p_sinopsis,
        rating = p_rating,
        tanggal_rilis = p_tanggal_rilis,
        status_film = p_status_film
    WHERE film_id = p_film_id;

    COMMIT;
END //

DELIMITER ;


-- HapusTiketBatal
DELIMITER 
CREATE PROCEDURE HapusTiketBatal(IN p_admin_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; END;
    START TRANSACTION;
    DELETE FROM Tiket WHERE status_tiket = 'Batal';
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Hapus Tiket Batal', NOW(), 'Semua tiket Batal dihapus.');
    COMMIT;
END 
DELIMITER ;

--  TampilkanLaporanPenjualan
DELIMITER 
CREATE PROCEDURE TampilkanLaporanPenjualan()
BEGIN
    START TRANSACTION;
    SELECT * FROM LaporanPenjualan;
    COMMIT;
END //
DELIMITER ;


-- ============================================
-- CONTOH TESTING PROCEDURES
-- ============================================

-- 1. Test Login
-- CALL LoginUser('rizki123', 'pass123');

-- 2. Test Buat Tiket (kasir)
-- CALL BuatTiket(1, 1, 'A10', 'QRIS');

-- 3. Test Batalkan Tiket
-- CALL BatalkanTiket('TKT000001', 1);

-- 4. Test Tambah Film (admin)
-- CALL TambahFilm('Inside Out 2', 'Animation', '120 menit', 'Kelsey Mann', 'Petualangan Riley', 'PG', '2024-06-14', 'Tayang', 1);

-- 5. Test Update Film (admin)
-- CALL UpdateFilm(1, 'Avengers: Endgame - Remastered', 'Action', '180 menit', 'Anthony & Joe Russo', 'Pertarungan terakhir melawan Thanos', 'PG-13', '2019-04-26', 'Tayang', 1);

-- 6. Test Tambah Jadwal (admin)
-- CALL TambahJadwal(1, 1, '2025-12-15', '14:00:00', '17:00:00', 65000.00, 1);

-- 7. Test Laporan Penjualan
-- CALL LaporanPenjualan('2025-09-01', '2025-12-31');

-- 8. Test Tampilkan Tiket
-- CALL TampilkanTiket('TKT000001');

-- 9. Test Hapus Tiket Batal (admin maintenance)
-- CALL HapusTiketBatal(1);

-- 10. Test Lihat Riwayat Transaksi
-- SELECT * FROM RiwayatTransaksi ORDER BY waktu_aksi DESC;
