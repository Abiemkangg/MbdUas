-- SISTEM PEMESANAN TIKET BIOSKOP

-- 1. Function: Cek Ketersediaan Kursi
DELIMITER //
DROP FUNCTION IF EXISTS CekKursiTersedia//
CREATE FUNCTION CekKursiTersedia(p_jadwal_id INT, p_nomor_kursi VARCHAR(10))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE hasil BOOLEAN;
    IF EXISTS (
        SELECT 1 FROM Tiket
        WHERE jadwal_id = p_jadwal_id
        AND nomor_kursi = p_nomor_kursi
        AND status_tiket = 'Aktif'
    ) THEN
        SET hasil = FALSE; -- kursi sudah dipesan
    ELSE
        SET hasil = TRUE;  -- kursi kosong
    END IF;
    RETURN hasil;
END//

-- 2. Function: Hitung Total Pendapatan Per Film
DROP FUNCTION IF EXISTS HitungTotalPendapatan//
CREATE FUNCTION HitungTotalPendapatan(p_film_id INT, p_tanggal_mulai DATE, p_tanggal_akhir DATE)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(15,2);
    
    SELECT COALESCE(SUM(t.harga), 0) INTO total
    FROM Tiket t
    JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
    WHERE j.film_id = p_film_id
    AND DATE(t.tanggal_pembelian) BETWEEN p_tanggal_mulai AND p_tanggal_akhir
    AND t.status_tiket = 'Aktif';
    
    RETURN total;
END//

-- 3. Function: Cek Jadwal Bentrok (untuk validasi saat tambah jadwal)
DROP FUNCTION IF EXISTS CekJadwalBentrok//
CREATE FUNCTION CekJadwalBentrok(
    p_studio_id INT, 
    p_tanggal DATE, 
    p_waktu_mulai TIME, 
    p_waktu_selesai TIME
)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE bentrok BOOLEAN;
    
    IF EXISTS (
        SELECT 1 FROM Jadwal
        WHERE studio_id = p_studio_id
        AND tanggal = p_tanggal
        AND (
            (p_waktu_mulai BETWEEN waktu_mulai AND waktu_selesai)
            OR (p_waktu_selesai BETWEEN waktu_mulai AND waktu_selesai)
            OR (waktu_mulai BETWEEN p_waktu_mulai AND p_waktu_selesai)
        )
    ) THEN
        SET bentrok = TRUE;
    ELSE
        SET bentrok = FALSE;
    END IF;
    
    RETURN bentrok;
END//

-- 4. Function: Generate Kode Tiket Otomatis
DROP FUNCTION IF EXISTS GenerateKodeTiket//
CREATE FUNCTION GenerateKodeTiket()
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE kode VARCHAR(50);
    DECLARE nomor INT;
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(kode_tiket, 4) AS UNSIGNED)), 0) + 1 
    INTO nomor
    FROM Tiket;
    
    SET kode = CONCAT('TKT', LPAD(nomor, 6, '0'));
    
    RETURN kode;
END//

-- 5. Function: Hitung Jumlah Kursi Tersedia untuk Jadwal
DROP FUNCTION IF EXISTS HitungKursiTersedia//
CREATE FUNCTION HitungKursiTersedia(p_jadwal_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE kapasitas INT;
    DECLARE terisi INT;
    DECLARE tersedia INT;
    
    SELECT s.kapasitas INTO kapasitas
    FROM Jadwal j
    JOIN Studio s ON j.studio_id = s.studio_id
    WHERE j.jadwal_id = p_jadwal_id;
    
    SELECT COUNT(*) INTO terisi
    FROM Tiket
    WHERE jadwal_id = p_jadwal_id
    AND status_tiket = 'Aktif';
    
    SET tersedia = kapasitas - terisi;
    
    RETURN tersedia;
END//

-- 6. Function: Validasi Login Kasir/Admin (dengan MD5 hash)
DROP FUNCTION IF EXISTS ValidasiLogin//
CREATE FUNCTION ValidasiLogin(p_username VARCHAR(50), p_password VARCHAR(100))
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE valid BOOLEAN;
    
    IF EXISTS (
        SELECT 1 FROM Kasir
        WHERE username = p_username
        AND password = MD5(p_password)
        AND level_akses IN ('admin', 'kasir')
    ) THEN
        SET valid = TRUE;
    ELSE
        SET valid = FALSE;
    END IF;
    
    RETURN valid;
END//

-- 7. Function: Cek Status Film Aktif
DROP FUNCTION IF EXISTS CekFilmAktif//
CREATE FUNCTION CekFilmAktif(p_film_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE aktif BOOLEAN;
    
    IF EXISTS (
        SELECT 1 FROM Film
        WHERE film_id = p_film_id
        AND status_film = 'Tayang'
    ) THEN
        SET aktif = TRUE;
    ELSE
        SET aktif = FALSE;
    END IF;
    
    RETURN aktif;
END//

-- 8. Function: Hitung Total Penjualan Kasir (untuk bonus/evaluasi)
DROP FUNCTION IF EXISTS HitungPenjualanKasir//
CREATE FUNCTION HitungPenjualanKasir(p_kasir_id INT, p_tanggal_mulai DATE, p_tanggal_akhir DATE)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(15,2);
    
    SELECT COALESCE(SUM(t.harga), 0) INTO total
    FROM Tiket t
    WHERE t.kasir_id = p_kasir_id
    AND DATE(t.tanggal_pembelian) BETWEEN p_tanggal_mulai AND p_tanggal_akhir
    AND t.status_tiket = 'Aktif';
    
    RETURN total;
END//

-- 9. Function: Cek Jadwal Sudah Lewat
DROP FUNCTION IF EXISTS CekJadwalLewat//
CREATE FUNCTION CekJadwalLewat(p_jadwal_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE lewat BOOLEAN;
    
    IF EXISTS (
        SELECT 1 FROM Jadwal
        WHERE jadwal_id = p_jadwal_id
        AND CONCAT(tanggal, ' ', waktu_selesai) < NOW()
    ) THEN
        SET lewat = TRUE;
    ELSE
        SET lewat = FALSE;
    END IF;
    
    RETURN lewat;
END//

-- 10. Function: Hitung Persentase Occupancy Studio
DROP FUNCTION IF EXISTS HitungOccupancyStudio//
CREATE FUNCTION HitungOccupancyStudio(p_studio_id INT, p_tanggal DATE)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE occupancy DECIMAL(5,2);
    DECLARE total_kursi INT;
    DECLARE total_terjual INT;
    
    -- Hitung total kapasitas studio untuk tanggal tersebut
    SELECT SUM(s.kapasitas) INTO total_kursi
    FROM Jadwal j
    JOIN Studio s ON j.studio_id = s.studio_id
    WHERE j.studio_id = p_studio_id
    AND j.tanggal = p_tanggal;
    
    -- Hitung total tiket terjual
    SELECT COUNT(t.tiket_id) INTO total_terjual
    FROM Jadwal j
    JOIN Tiket t ON j.jadwal_id = t.jadwal_id
    WHERE j.studio_id = p_studio_id
    AND j.tanggal = p_tanggal
    AND t.status_tiket = 'Aktif';
    
    IF total_kursi > 0 THEN
        SET occupancy = (total_terjual / total_kursi) * 100;
    ELSE
        SET occupancy = 0;
    END IF;
    
    RETURN ROUND(occupancy, 2);
END//

-- 11. Function: Generate Reference Number untuk Payment Gateway
DROP FUNCTION IF EXISTS GenerateReferenceNumber//
CREATE FUNCTION GenerateReferenceNumber()
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE ref_num VARCHAR(100);
    DECLARE timestamp_str VARCHAR(20);
    DECLARE random_num INT;
    
    SET timestamp_str = DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');
    SET random_num = FLOOR(1000 + RAND() * 9000);
    SET ref_num = CONCAT('REF', timestamp_str, random_num);
    
    RETURN ref_num;
END//

-- 12. Function: Validasi Nomor Kursi Format (A1-Z99)
DROP FUNCTION IF EXISTS ValidasiFormatKursi//
CREATE FUNCTION ValidasiFormatKursi(p_nomor_kursi VARCHAR(10))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE valid BOOLEAN;
    
    -- Format: Huruf (A-Z) + Angka (1-99)
    IF p_nomor_kursi REGEXP '^[A-Z][0-9]{1,2}$' THEN
        SET valid = TRUE;
    ELSE
        SET valid = FALSE;
    END IF;
    
    RETURN valid;
END//

DELIMITER ;
