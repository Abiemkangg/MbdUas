#  Trigger

DELIMITER //
CREATE TRIGGER KurangiKapasitas
AFTER INSERT ON Tiket
FOR EACH ROW
BEGIN
    UPDATE Jadwal
    SET kapasitas_tersisa = kapasitas_tersisa - 1
    WHERE jadwal_id = NEW.jadwal_id;
END ;
