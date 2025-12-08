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

DELIMITER ;
