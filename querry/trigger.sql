-- ============================================
-- TRIGGERS UNTUK SISTEM PEMESANAN TIKET BIOSKOP
-- ============================================

-- 1. Trigger: Kurangi Kapasitas Setelah Tiket Dibuat
DELIMITER //
DROP TRIGGER IF EXISTS KurangiKapasitas//
CREATE TRIGGER KurangiKapasitas
AFTER INSERT ON Tiket
FOR EACH ROW
BEGIN
    -- Hanya kurangi jika status tiket aktif
    IF NEW.status_tiket = 'Aktif' THEN
        UPDATE Jadwal
        SET kapasitas_tersisa = kapasitas_tersisa - 1
        WHERE jadwal_id = NEW.jadwal_id;
    END IF;
END//

-- 2. Trigger: Tambah Kapasitas Kembali Setelah Tiket Dibatalkan
DROP TRIGGER IF EXISTS TambahKapasitas//
CREATE TRIGGER TambahKapasitas
AFTER UPDATE ON Tiket
FOR EACH ROW
BEGIN
    -- Jika status berubah dari Aktif ke Batal
    IF OLD.status_tiket = 'Aktif' AND NEW.status_tiket = 'Batal' THEN
        UPDATE Jadwal
        SET kapasitas_tersisa = kapasitas_tersisa + 1
        WHERE jadwal_id = NEW.jadwal_id;
    END IF;
END//

-- 3. Trigger: Validasi Kapasitas Sebelum Insert Tiket
DROP TRIGGER IF EXISTS ValidasiKapasitas//
CREATE TRIGGER ValidasiKapasitas
BEFORE INSERT ON Tiket
FOR EACH ROW
BEGIN
    DECLARE kapasitas_sisa INT;
    
    -- Cek kapasitas tersisa
    SELECT kapasitas_tersisa INTO kapasitas_sisa
    FROM Jadwal
    WHERE jadwal_id = NEW.jadwal_id;
    
    -- Validasi
    IF kapasitas_sisa <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Kapasitas studio sudah penuh!';
    END IF;
END//

-- 4. Trigger: Log Aktivitas Kasir saat Insert Tiket
DROP TRIGGER IF EXISTS LogTiketBaru//
CREATE TRIGGER LogTiketBaru
AFTER INSERT ON Tiket
FOR EACH ROW
BEGIN
    DECLARE nama_kasir VARCHAR(100);
    DECLARE judul VARCHAR(100);
    
    -- Ambil nama kasir
    SELECT nama INTO nama_kasir FROM Kasir WHERE kasir_id = NEW.kasir_id;
    
    -- Ambil judul film
    SELECT f.judul_film INTO judul
    FROM Jadwal j
    JOIN Film f ON j.film_id = f.film_id
    WHERE j.jadwal_id = NEW.jadwal_id;
    
    -- Insert log
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (
        NEW.kasir_id, 
        'Tiket Dibuat', 
        NOW(), 
        CONCAT('Kasir ', nama_kasir, ' membuat tiket ', NEW.kode_tiket, ' untuk film "', judul, '"')
    );
END//

-- 5. Trigger: Validasi Harga Tiket sebelum Insert
DROP TRIGGER IF EXISTS ValidasiHargaTiket//
CREATE TRIGGER ValidasiHargaTiket
BEFORE INSERT ON Tiket
FOR EACH ROW
BEGIN
    DECLARE harga_jadwal DECIMAL(10,2);
    
    -- Ambil harga dari jadwal
    SELECT harga_tiket INTO harga_jadwal
    FROM Jadwal
    WHERE jadwal_id = NEW.jadwal_id;
    
    -- Set harga tiket sesuai jadwal jika belum diset
    IF NEW.harga IS NULL OR NEW.harga = 0 THEN
        SET NEW.harga = harga_jadwal;
    END IF;
END//

-- 6. Trigger: Auto-set Tanggal Pembelian dan Status
DROP TRIGGER IF EXISTS SetDefaultTiket//
CREATE TRIGGER SetDefaultTiket
BEFORE INSERT ON Tiket
FOR EACH ROW
BEGIN
    -- Set tanggal pembelian jika belum ada
    IF NEW.tanggal_pembelian IS NULL THEN
        SET NEW.tanggal_pembelian = NOW();
    END IF;
    
    -- Set status default jika belum ada
    IF NEW.status_tiket IS NULL OR NEW.status_tiket = '' THEN
        SET NEW.status_tiket = 'Aktif';
    END IF;
END//

-- 7. Trigger: Update Kapasitas Tersisa saat Jadwal Dibuat
DROP TRIGGER IF EXISTS SetKapasitasJadwal//
CREATE TRIGGER SetKapasitasJadwal
BEFORE INSERT ON Jadwal
FOR EACH ROW
BEGIN
    DECLARE kapasitas_studio INT;
    
    -- Ambil kapasitas studio
    SELECT kapasitas INTO kapasitas_studio
    FROM Studio
    WHERE studio_id = NEW.studio_id;
    
    -- Set kapasitas_tersisa sama dengan kapasitas studio
    IF NEW.kapasitas_tersisa IS NULL OR NEW.kapasitas_tersisa = 0 THEN
        SET NEW.kapasitas_tersisa = kapasitas_studio;
    END IF;
END//

-- 8. Trigger: Log Perubahan Film oleh Admin
DROP TRIGGER IF EXISTS LogPerubahanFilm//
CREATE TRIGGER LogPerubahanFilm
AFTER UPDATE ON Film
FOR EACH ROW
BEGIN
    DECLARE perubahan TEXT;
    
    SET perubahan = '';
    
    IF OLD.judul_film != NEW.judul_film THEN
        SET perubahan = CONCAT(perubahan, 'Judul: ', OLD.judul_film, ' -> ', NEW.judul_film, '; ');
    END IF;
    
    IF OLD.status_film != NEW.status_film THEN
        SET perubahan = CONCAT(perubahan, 'Status: ', OLD.status_film, ' -> ', NEW.status_film, '; ');
    END IF;
    
    -- Hanya log jika ada perubahan
    IF perubahan != '' THEN
        INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
        VALUES (NULL, 'Update Film', NOW(), CONCAT('Film ID ', NEW.film_id, ' diubah: ', perubahan));
    END IF;
END//

-- 9. Trigger: Validasi Format Nomor Kursi sebelum Insert
DROP TRIGGER IF EXISTS ValidasiFormatNomorKursi//
CREATE TRIGGER ValidasiFormatNomorKursi
BEFORE INSERT ON Tiket
FOR EACH ROW
BEGIN
    -- Validasi format nomor kursi (A1-Z99)
    IF ValidasiFormatKursi(NEW.nomor_kursi) = FALSE THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Format nomor kursi tidak valid! Gunakan format: A1-Z99';
    END IF;
    
    -- Validasi nomor kursi tidak boleh kosong
    IF NEW.nomor_kursi IS NULL OR NEW.nomor_kursi = '' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Nomor kursi tidak boleh kosong!';
    END IF;
END//

-- 10. Trigger: Prevent Delete Film yang Memiliki Jadwal Aktif
DROP TRIGGER IF EXISTS PreventDeleteFilmAktif//
CREATE TRIGGER PreventDeleteFilmAktif
BEFORE DELETE ON Film
FOR EACH ROW
BEGIN
    DECLARE jadwal_count INT;
    
    -- Cek apakah ada jadwal yang masih aktif (tanggal >= hari ini)
    SELECT COUNT(*) INTO jadwal_count
    FROM Jadwal
    WHERE film_id = OLD.film_id
    AND tanggal >= CURDATE();
    
    IF jadwal_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Tidak dapat menghapus film yang memiliki jadwal aktif!';
    END IF;
END//

-- 11. Trigger: Log Pembayaran Baru
DROP TRIGGER IF EXISTS LogPembayaranBaru//
CREATE TRIGGER LogPembayaranBaru
AFTER INSERT ON Pembayaran
FOR EACH ROW
BEGIN
    DECLARE kasir_id_val INT;
    DECLARE kode_tiket_val VARCHAR(50);
    
    -- Ambil kasir_id dan kode_tiket dari tiket
    SELECT kasir_id, kode_tiket INTO kasir_id_val, kode_tiket_val
    FROM Tiket
    WHERE tiket_id = NEW.tiket_id;
    
    -- Log pembayaran
    INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
    VALUES (
        kasir_id_val, 
        'Pembayaran Diterima', 
        NOW(), 
        CONCAT('Pembayaran ', NEW.metode_pembayaran, ' sebesar Rp', FORMAT(NEW.jumlah_pembayaran, 0), ' untuk tiket ', kode_tiket_val)
    );
END//

-- 12. Trigger: Update Status Pembayaran saat Tiket Dibatalkan
DROP TRIGGER IF EXISTS UpdatePembayaranBatal//
CREATE TRIGGER UpdatePembayaranBatal
AFTER UPDATE ON Tiket
FOR EACH ROW
BEGIN
    -- Jika status berubah menjadi Batal, update status pembayaran juga
    IF OLD.status_tiket = 'Aktif' AND NEW.status_tiket = 'Batal' THEN
        UPDATE Pembayaran
        SET status_pembayaran = 'Refund'
        WHERE tiket_id = NEW.tiket_id;
    END IF;
END//

-- 13. Trigger: Auto-set Status Payment Gateway Default
DROP TRIGGER IF EXISTS SetDefaultGateway//
CREATE TRIGGER SetDefaultGateway
BEFORE INSERT ON Payment_Gateway
FOR EACH ROW
BEGIN
    IF NEW.status_gateway IS NULL OR NEW.status_gateway = '' THEN
        SET NEW.status_gateway = 'Aktif';
    END IF;
END//

-- 14. Trigger: Log Perubahan Jadwal
DROP TRIGGER IF EXISTS LogPerubahanJadwal//
CREATE TRIGGER LogPerubahanJadwal
AFTER UPDATE ON Jadwal
FOR EACH ROW
BEGIN
    DECLARE perubahan TEXT;
    
    SET perubahan = '';
    
    IF OLD.tanggal != NEW.tanggal THEN
        SET perubahan = CONCAT(perubahan, 'Tanggal: ', OLD.tanggal, ' -> ', NEW.tanggal, '; ');
    END IF;
    
    IF OLD.waktu_mulai != NEW.waktu_mulai THEN
        SET perubahan = CONCAT(perubahan, 'Waktu Mulai: ', OLD.waktu_mulai, ' -> ', NEW.waktu_mulai, '; ');
    END IF;
    
    IF OLD.harga_tiket != NEW.harga_tiket THEN
        SET perubahan = CONCAT(perubahan, 'Harga: Rp', FORMAT(OLD.harga_tiket, 0), ' -> Rp', FORMAT(NEW.harga_tiket, 0), '; ');
    END IF;
    
    IF perubahan != '' THEN
        INSERT INTO RiwayatTransaksi (kasir_id, aksi, waktu_aksi, keterangan)
        VALUES (NULL, 'Update Jadwal', NOW(), CONCAT('Jadwal ID ', NEW.jadwal_id, ' diubah: ', perubahan));
    END IF;
END//

-- 15. Trigger: Prevent Update Tiket untuk Jadwal yang Sudah Lewat
DROP TRIGGER IF EXISTS PreventUpdateTiketLewat//
CREATE TRIGGER PreventUpdateTiketLewat
BEFORE UPDATE ON Tiket
FOR EACH ROW
BEGIN
    -- Hanya cek jika mengubah status dari Aktif ke Batal
    IF OLD.status_tiket = 'Aktif' AND NEW.status_tiket = 'Batal' THEN
        -- Cek apakah jadwal sudah lewat
        IF CekJadwalLewat(NEW.jadwal_id) = TRUE THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Tidak dapat membatalkan tiket untuk jadwal yang sudah lewat!';
        END IF;
    END IF;
END//

DELIMITER ;
