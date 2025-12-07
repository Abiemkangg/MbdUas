DELIMITER 




CREATE PROCEDURE BuatTiket (
    IN p_jadwal_id INT,
    IN p_kasir_id INT,
    IN p_nomor_kursi VARCHAR(10),
    IN p_kode_tiket VARCHAR(50),
    IN p_metode_pembayaran VARCHAR(20)
)
BEGIN
    DECLARE harga DECIMAL(10,2);
    DECLARE tiketBaruId INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
        VALUES (p_kasir_id, 'Gagal Membuat Tiket', NOW(), 'Terjadi error pada transaksi.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transaksi dibatalkan.';
    END;

    START TRANSACTION;

    IF CekKursiTersedia(p_jadwal_id, p_nomor_kursi) = TRUE THEN
        SELECT harga_tiket INTO harga FROM Jadwal WHERE jadwal_id = p_jadwal_id;
        INSERT INTO Tiket (jadwal_id, kasir_id, kode_tiket, nomor_kursi, harga, tanggal_pembelian, status_tiket)
        VALUES (p_jadwal_id, p_kasir_id, p_kode_tiket, p_nomor_kursi, harga, NOW(), 'Aktif');
        SET tiketBaruId = LAST_INSERT_ID();
        INSERT INTO Pembayaran (tiket_id, jumlah_pembayaran, metode_pembayaran, tanggal_pembayaran, status_pembayaran)
        VALUES (tiketBaruId, harga, p_metode_pembayaran, NOW(), 'Lunas');
        INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
        VALUES (p_kasir_id, 'Berhasil Membuat Tiket', NOW(), CONCAT('Tiket ', p_kode_tiket, ' berhasil dibuat.'));
        COMMIT;
    ELSE
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kursi sudah terisi.';
    END IF;
END 
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


-- Kasir membuat tiket baru
CALL BuatTiket(1, 1, 'A10', 'TKT010', 'QRIS');

-- Admin menambah film baru
CALL TambahFilm('Inside Out 2', 'Animation', '120 menit', 'Kelsey Mann', 'Petualangan Riley', 'PG', '2024-06-14', 'Tayang', 1);

-- Update status tiket
CALL UpdateStatusTiket('TKT010', 'Batal', 1);

-- Hapus tiket batal
CALL HapusTiketBatal(1);

-- Tampilkan laporan
CALL TampilkanLaporanPenjualan();

-- Lihat log transaksi
SELECT * FROM RiwayatTransaksi;
