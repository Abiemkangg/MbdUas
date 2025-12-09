-- ============================================
-- STORED PROCEDURES UNTUK SISTEM PEMESANAN TIKET BIOSKOP
-- ============================================

DELIMITER //

-- 1. Procedure: Pemesanan Tiket (Use Case Kasir)
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
    -- Gunakan view LaporanPenjualan untuk filter tanggal
    SELECT * FROM LaporanPenjualan
    WHERE tanggal BETWEEN p_tanggal_mulai AND p_tanggal_akhir
    ORDER BY tanggal DESC, judul_film;
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
DROP PROCEDURE IF EXISTS LoginKasirAdmin//
CREATE PROCEDURE LoginUser(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(100)
)
BEGIN
    DECLARE user_id INT;
    DECLARE nama_user VARCHAR(100);
    DECLARE akses VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal proses login.';
    END;
    
    START TRANSACTION;
    
    -- Gunakan function ValidasiLogin
    IF ValidasiLogin(p_username, p_password) = TRUE THEN
        SELECT kasir_id, nama, level_akses INTO user_id, nama_user, akses
        FROM Kasir
        WHERE username = p_username
        AND MD5(p_password) = password;
        
        -- Log aktivitas login
        INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
        VALUES (user_id, 'Login', NOW(), CONCAT(nama_user, ' login sebagai ', akses));
        
        COMMIT;
        
        SELECT user_id AS kasir_id, nama_user AS nama, akses AS level_akses, 'success' AS status;
    ELSE
        ROLLBACK;
        SELECT 'failed' AS status, 'Username atau password salah' AS message;
    END IF;
END//

-- 10. Procedure: Menampilkan Tiket Berdasarkan Kode
DROP PROCEDURE IF EXISTS TampilkanTiket//
CREATE PROCEDURE TampilkanTiket(
    IN p_kode_tiket VARCHAR(50)
)
BEGIN
    -- Gunakan view DetailTiket untuk menampilkan data lengkap
    SELECT * FROM DetailTiket
    WHERE kode_tiket = p_kode_tiket;
END//

-- 11. Procedure: Update Status Tiket
DROP PROCEDURE IF EXISTS UpdateStatusTiket//
CREATE PROCEDURE UpdateStatusTiket(
    IN p_kode_tiket VARCHAR(50),
    IN p_status_baru VARCHAR(20),
    IN p_kasir_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal update status tiket.';
    END;
    
    START TRANSACTION;
    
    UPDATE Tiket 
    SET status_tiket = p_status_baru 
    WHERE kode_tiket = p_kode_tiket;
    
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_kasir_id, 'Update Status Tiket', NOW(), 
            CONCAT('Tiket ', p_kode_tiket, ' diubah menjadi ', p_status_baru));
    
    COMMIT;
END//

-- 12. Procedure: Update Jadwal (Admin)
DROP PROCEDURE IF EXISTS UpdateJadwal//
CREATE PROCEDURE UpdateJadwal(
    IN p_jadwal_id INT,
    IN p_film_id INT,
    IN p_studio_id INT,
    IN p_tanggal DATE,
    IN p_waktu_mulai TIME,
    IN p_waktu_selesai TIME,
    IN p_harga_tiket DECIMAL(10,2),
    IN p_admin_id INT
)
BEGIN
    DECLARE old_studio INT;
    DECLARE old_tanggal DATE;
    DECLARE old_waktu_mulai TIME;
    DECLARE old_waktu_selesai TIME;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal update jadwal.';
    END;
    
    START TRANSACTION;
    
    -- Cek apakah jadwal ada
    IF NOT EXISTS (SELECT 1 FROM Jadwal WHERE jadwal_id = p_jadwal_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jadwal tidak ditemukan!';
    END IF;
    
    -- Ambil data lama untuk validasi
    SELECT studio_id, tanggal, waktu_mulai, waktu_selesai 
    INTO old_studio, old_tanggal, old_waktu_mulai, old_waktu_selesai
    FROM Jadwal WHERE jadwal_id = p_jadwal_id;
    
    -- Validasi jika ada perubahan studio/waktu/tanggal
    IF (p_studio_id != old_studio OR p_tanggal != old_tanggal OR 
        p_waktu_mulai != old_waktu_mulai OR p_waktu_selesai != old_waktu_selesai) THEN
        
        -- Cek jadwal bentrok (exclude jadwal yang sedang diedit)
        IF EXISTS (
            SELECT 1 FROM Jadwal 
            WHERE studio_id = p_studio_id 
            AND tanggal = p_tanggal
            AND jadwal_id != p_jadwal_id
            AND (
                (p_waktu_mulai BETWEEN waktu_mulai AND waktu_selesai) OR
                (p_waktu_selesai BETWEEN waktu_mulai AND waktu_selesai) OR
                (waktu_mulai BETWEEN p_waktu_mulai AND p_waktu_selesai)
            )
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jadwal bentrok dengan jadwal lain di studio yang sama!';
        END IF;
    END IF;
    
    -- Validasi film aktif/tayang
    IF CekFilmAktif(p_film_id) = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Film tidak dalam status tayang!';
    END IF;
    
    -- Validasi waktu mulai < waktu selesai
    IF p_waktu_mulai >= p_waktu_selesai THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Waktu mulai harus lebih awal dari waktu selesai!';
    END IF;
    
    -- Update jadwal
    UPDATE Jadwal
    SET film_id = p_film_id,
        studio_id = p_studio_id,
        tanggal = p_tanggal,
        waktu_mulai = p_waktu_mulai,
        waktu_selesai = p_waktu_selesai,
        harga_tiket = p_harga_tiket
    WHERE jadwal_id = p_jadwal_id;
    
    -- Log aktivitas
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Update Jadwal', NOW(), 
            CONCAT('Jadwal ID ', p_jadwal_id, ' berhasil diupdate'));
    
    COMMIT;
    
    SELECT 'Jadwal berhasil diupdate' AS message, p_jadwal_id AS jadwal_id;
END//

-- 13. Procedure: Hapus Jadwal (Admin)
DROP PROCEDURE IF EXISTS HapusJadwal//
CREATE PROCEDURE HapusJadwal(
    IN p_jadwal_id INT,
    IN p_admin_id INT
)
BEGIN
    DECLARE tiket_aktif_count INT;
    DECLARE film_title VARCHAR(100);
    DECLARE jadwal_date DATE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal menghapus jadwal.';
    END;
    
    START TRANSACTION;
    
    -- Cek apakah jadwal ada
    IF NOT EXISTS (SELECT 1 FROM Jadwal WHERE jadwal_id = p_jadwal_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jadwal tidak ditemukan!';
    END IF;
    
    -- Ambil info jadwal untuk log
    SELECT f.judul_film, j.tanggal 
    INTO film_title, jadwal_date
    FROM Jadwal j
    JOIN Film f ON j.film_id = f.film_id
    WHERE j.jadwal_id = p_jadwal_id;
    
    -- Cek apakah ada tiket aktif
    SELECT COUNT(*) INTO tiket_aktif_count
    FROM Tiket
    WHERE jadwal_id = p_jadwal_id AND status_tiket = 'Aktif';
    
    IF tiket_aktif_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Tidak dapat menghapus jadwal yang memiliki tiket aktif!';
    END IF;
    
    -- Hapus tiket batal yang terkait (jika ada)
    DELETE FROM Pembayaran 
    WHERE tiket_id IN (
        SELECT tiket_id FROM Tiket 
        WHERE jadwal_id = p_jadwal_id AND status_tiket = 'Batal'
    );
    
    DELETE FROM Tiket 
    WHERE jadwal_id = p_jadwal_id AND status_tiket = 'Batal';
    
    -- Hapus jadwal
    DELETE FROM Jadwal WHERE jadwal_id = p_jadwal_id;
    
    -- Log aktivitas
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Hapus Jadwal', NOW(), 
            CONCAT('Jadwal "', film_title, '" tanggal ', jadwal_date, ' dihapus'));
    
    COMMIT;
    
    SELECT 'Jadwal berhasil dihapus' AS message;
END//

-- 14. Procedure: Tambah Kasir (Admin)
DROP PROCEDURE IF EXISTS TambahKasir//
CREATE PROCEDURE TambahKasir(
    IN p_nama VARCHAR(100),
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(100),
    IN p_no_telepon VARCHAR(15),
    IN p_level_akses VARCHAR(20),
    IN p_admin_id INT
)
BEGIN
    DECLARE new_kasir_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Gagal menambah kasir. Username mungkin sudah digunakan.';
    END;
    
    START TRANSACTION;
    
    -- Validasi input
    IF p_nama IS NULL OR p_nama = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nama tidak boleh kosong!';
    END IF;
    
    IF p_username IS NULL OR p_username = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username tidak boleh kosong!';
    END IF;
    
    IF p_password IS NULL OR p_password = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password tidak boleh kosong!';
    END IF;
    
    -- Validasi level akses
    IF p_level_akses NOT IN ('admin', 'kasir') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Level akses harus "admin" atau "kasir"!';
    END IF;
    
    -- Cek username sudah ada atau belum
    IF EXISTS (SELECT 1 FROM Kasir WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username sudah digunakan!';
    END IF;
    
    -- Insert kasir baru (password di-hash dengan MD5)
    INSERT INTO Kasir (nama, username, password, no_telepon, tanggal_bergabung, level_akses)
    VALUES (p_nama, p_username, MD5(p_password), p_no_telepon, CURDATE(), p_level_akses);
    
    SET new_kasir_id = LAST_INSERT_ID();
    
    -- Log aktivitas
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Tambah Kasir', NOW(), 
            CONCAT('Kasir baru "', p_nama, '" (', p_level_akses, ') ditambahkan dengan ID: ', new_kasir_id));
    
    COMMIT;
    
    SELECT new_kasir_id AS kasir_id, 
           p_nama AS nama, 
           p_username AS username,
           p_level_akses AS level_akses,
           'Kasir berhasil ditambahkan' AS message;
END//

-- 15. Procedure: Ganti Password (Kasir/Admin)
DROP PROCEDURE IF EXISTS GantiPassword//
CREATE PROCEDURE GantiPassword(
    IN p_kasir_id INT,
    IN p_password_lama VARCHAR(100),
    IN p_password_baru VARCHAR(100)
)
BEGIN
    DECLARE current_password VARCHAR(100);
    DECLARE user_nama VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal mengganti password.';
    END;
    
    START TRANSACTION;
    
    -- Validasi kasir ada
    IF NOT EXISTS (SELECT 1 FROM Kasir WHERE kasir_id = p_kasir_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kasir tidak ditemukan!';
    END IF;
    
    -- Validasi input
    IF p_password_lama IS NULL OR p_password_lama = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password lama tidak boleh kosong!';
    END IF;
    
    IF p_password_baru IS NULL OR p_password_baru = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password baru tidak boleh kosong!';
    END IF;
    
    IF LENGTH(p_password_baru) < 6 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password baru minimal 6 karakter!';
    END IF;
    
    -- Ambil password saat ini dan nama user
    SELECT password, nama INTO current_password, user_nama
    FROM Kasir WHERE kasir_id = p_kasir_id;
    
    -- Validasi password lama cocok
    IF MD5(p_password_lama) != current_password THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password lama tidak sesuai!';
    END IF;
    
    -- Validasi password baru tidak sama dengan password lama
    IF p_password_lama = p_password_baru THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password baru harus berbeda dari password lama!';
    END IF;
    
    -- Update password baru
    UPDATE Kasir
    SET password = MD5(p_password_baru)
    WHERE kasir_id = p_kasir_id;
    
    -- Log aktivitas
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_kasir_id, 'Ganti Password', NOW(), 
            CONCAT(user_nama, ' mengganti password'));
    
    COMMIT;
    
    SELECT 'Password berhasil diubah' AS message;
END//

-- 16. Procedure: Get Jadwal by Film (Kasir/User)
DROP PROCEDURE IF EXISTS GetJadwalByFilm//
CREATE PROCEDURE GetJadwalByFilm(
    IN p_film_id INT
)
BEGIN
    -- Validasi film ada
    IF NOT EXISTS (SELECT 1 FROM Film WHERE film_id = p_film_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Film tidak ditemukan!';
    END IF;
    
    -- Gunakan view JadwalTayang yang sudah filter tanggal >= hari ini
    SELECT * FROM JadwalTayang
    WHERE film_id = p_film_id
    ORDER BY tanggal ASC, waktu_mulai ASC;
END//

-- 17. Procedure: Update Kasir (Admin)
DROP PROCEDURE IF EXISTS UpdateKasir//
CREATE PROCEDURE UpdateKasir(
    IN p_kasir_id INT,
    IN p_nama VARCHAR(100),
    IN p_no_telepon VARCHAR(15),
    IN p_level_akses VARCHAR(20),
    IN p_admin_id INT
)
BEGIN
    DECLARE old_nama VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal update kasir.';
    END;
    
    START TRANSACTION;
    
    -- Validasi kasir ada
    IF NOT EXISTS (SELECT 1 FROM Kasir WHERE kasir_id = p_kasir_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kasir tidak ditemukan!';
    END IF;
    
    -- Validasi input
    IF p_nama IS NULL OR p_nama = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nama tidak boleh kosong!';
    END IF;
    
    -- Validasi level akses
    IF p_level_akses NOT IN ('admin', 'kasir', 'nonaktif') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Level akses harus "admin", "kasir", atau "nonaktif"!';
    END IF;
    
    -- Ambil nama lama untuk log
    SELECT nama INTO old_nama FROM Kasir WHERE kasir_id = p_kasir_id;
    
    -- Update data kasir
    UPDATE Kasir
    SET nama = p_nama,
        no_telepon = p_no_telepon,
        level_akses = p_level_akses
    WHERE kasir_id = p_kasir_id;
    
    -- Log aktivitas
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (p_admin_id, 'Update Kasir', NOW(), 
            CONCAT('Data kasir "', old_nama, '" (ID: ', p_kasir_id, ') diupdate'));
    
    COMMIT;
    
    SELECT 'Data kasir berhasil diupdate' AS message, p_kasir_id AS kasir_id;
END//

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

-- 10. Test Update Status Tiket
-- CALL UpdateStatusTiket('TKT000001', 'Sudah Masuk', 1);

-- 11. Test Lihat Riwayat Transaksi
-- SELECT * FROM RiwayatTransaksi ORDER BY waktu_aksi DESC;

-- ============================================
-- TESTING PROCEDURES BARU (12-17)
-- ============================================

-- 12. Test Update Jadwal
-- CALL UpdateJadwal(1, 1, 1, '2025-12-25', '19:00:00', '22:00:00', 55000.00, 1);

-- 13. Test Hapus Jadwal (pastikan tidak ada tiket aktif)
-- CALL HapusJadwal(5, 1);

-- 14. Test Tambah Kasir
-- CALL TambahKasir('Siti Nurhaliza', 'siti123', 'password123', '081234567891', 'kasir', 1);

-- 15. Test Ganti Password
-- CALL GantiPassword(1, 'pass123', 'password_baru123');

-- 16. Test Get Jadwal by Film
-- CALL GetJadwalByFilm(1);

-- 17. Test Update Kasir
-- CALL UpdateKasir(2, 'Nuel Updated', '081234567899', 'kasir', 1);