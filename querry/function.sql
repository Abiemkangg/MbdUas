-- Function
DELIMITER //
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
END;
