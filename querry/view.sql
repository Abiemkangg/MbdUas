#  View

CREATE VIEW LaporanPenjualan AS
SELECT f.judul_film,
       j.tanggal,
       COUNT(t.tiket_id) AS jumlah_tiket_terjual,
       SUM(t.harga) AS total_pendapatan
FROM Tiket t
JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
JOIN Film f ON j.film_id = f.film_id
GROUP BY f.judul_film, j.tanggal;

CALL BuatTiket(1, 1,'A5','TKT005' );

SELECT * FROM Tiket;
SELECT * FROM jadwal;
