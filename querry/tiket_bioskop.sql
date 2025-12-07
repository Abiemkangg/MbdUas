CREATE DATABASE IF NOT EXISTS BioskopDB;
USE BioskopDB;

-- TABEL MASTER
CREATE TABLE Film (
    film_id INT AUTO_INCREMENT PRIMARY KEY,
    judul_film VARCHAR(100) NOT NULL,
    genre VARCHAR(50),
    durasi VARCHAR(20),        
    sutradara VARCHAR(100),
    sinopsis TEXT,
    rating VARCHAR(10),
    tanggal_rilis DATE,
    status_film VARCHAR(20),
    FULLTEXT (judul_film, sutradara, sinopsis)
) ENGINE=InnoDB;

CREATE TABLE Studio (
    studio_id INT AUTO_INCREMENT PRIMARY KEY,
    nama_studio VARCHAR(50) NOT NULL,
    kapasitas INT NOT NULL,
    INDEX idx_studio_nama (nama_studio)
) ENGINE=InnoDB;

CREATE TABLE Kasir (
    kasir_id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100),
    username VARCHAR(50) UNIQUE,
    password VARCHAR(100),
    no_telepon VARCHAR(20),
    tanggal_bergabung DATE,
    level_akses VARCHAR(20),
    FULLTEXT (nama, username, level_akses)
) ENGINE=InnoDB;

-- TABEL JADWAL & TIKET
CREATE TABLE Jadwal (
    jadwal_id INT AUTO_INCREMENT PRIMARY KEY,
    film_id INT,
    studio_id INT,
    tanggal DATE,
    waktu_mulai TIME,
    waktu_selesai TIME,
    harga_tiket DECIMAL(10,2),
    kapasitas_tersisa INT,
    FOREIGN KEY (film_id) REFERENCES Film(film_id),
    FOREIGN KEY (studio_id) REFERENCES Studio(studio_id),
    INDEX idx_jadwal_tanggal (tanggal),
    INDEX idx_jadwal_film (film_id),
    INDEX idx_jadwal_studio (studio_id)
) ENGINE=InnoDB;

CREATE TABLE Tiket (
    tiket_id INT AUTO_INCREMENT PRIMARY KEY,
    jadwal_id INT,
    kasir_id INT,
    kode_tiket VARCHAR(50),
    nomor_kursi VARCHAR(10),
    harga DECIMAL(10,2),
    tanggal_pembelian DATETIME,
    status_tiket VARCHAR(20),
    FOREIGN KEY (jadwal_id) REFERENCES Jadwal(jadwal_id),
    FOREIGN KEY (kasir_id) REFERENCES Kasir(kasir_id),
    CONSTRAINT unik_kursi_per_jadwal UNIQUE (jadwal_id, nomor_kursi),
    INDEX idx_tiket_kode (kode_tiket),
    INDEX idx_tiket_kasir (kasir_id),
    INDEX idx_tiket_status (status_tiket)
) ENGINE=InnoDB;

-- TABEL PEMBAYARAN
CREATE TABLE Pembayaran (
    pembayaran_id INT AUTO_INCREMENT PRIMARY KEY,
    tiket_id INT,
    jumlah_pembayaran DECIMAL(10,2),
    metode_pembayaran VARCHAR(20),
    tanggal_pembayaran DATETIME,
    status_pembayaran VARCHAR(20),
    FOREIGN KEY (tiket_id) REFERENCES Tiket(tiket_id),
    INDEX idx_pembayaran_metode (metode_pembayaran),
    INDEX idx_pembayaran_status (status_pembayaran)
) ENGINE=InnoDB;

CREATE TABLE Payment_Gateway (
    gateway_id INT AUTO_INCREMENT PRIMARY KEY,
    nama_gateway VARCHAR(50),
    api_key VARCHAR(100),
    status_gateway VARCHAR(20),
    FULLTEXT (nama_gateway)
) ENGINE=InnoDB;

CREATE TABLE Transaksi_Pembayaran (
    transaksi_id INT AUTO_INCREMENT PRIMARY KEY,
    pembayaran_id INT,
    gateway_id INT,
    reference_number VARCHAR(100),
    waktu_transaksi DATETIME,
    status_transaksi VARCHAR(20),
    FOREIGN KEY (pembayaran_id) REFERENCES Pembayaran(pembayaran_id),
    FOREIGN KEY (gateway_id) REFERENCES Payment_Gateway(gateway_id),
    INDEX idx_transaksi (reference_number, status_transaksi)
) ENGINE=InnoDB;

CREATE TABLE RiwayatTransaksi (
    riwayat_id INT AUTO_INCREMENT PRIMARY KEY,
    kasir_id INT,
    aksi VARCHAR(100),
    waktu_aksi DATETIME,
    keterangan TEXT,
    FOREIGN KEY (kasir_id) REFERENCES Kasir(kasir_id)
) ENGINE=InnoDB;


-- DATA DUMMY

INSERT INTO Film (judul_film, genre, durasi, sutradara, sinopsis, rating, tanggal_rilis, status_film)
VALUES
('Avengers: Endgame', 'Action', '180 menit', 'Anthony & Joe Russo', 'Pertarungan terakhir melawan Thanos', 'PG-13', '2019-04-26', 'Tayang'),
('Agak Laen', 'Comedy', '117 menit', 'Muhadkly Acho', 'Cerita tentang penjaga rumah hantu yang berubah jadi peluang bisnis', '13+', '2024-02-01', 'Tayang'),
('Captain America: Civil War', 'Action', '147 menit', 'Anthony & Joe Russo', 'Pertarungan internal antar Avengers akibat perbedaan pandangan politik', 'PG-13', '2016-04-27', 'Tayang');

INSERT INTO Studio (nama_studio, kapasitas)
VALUES
('Studio 1', 100),
('Studio 2', 80),
('Studio 3', 120);

INSERT INTO Kasir (nama, username, password, no_telepon, tanggal_bergabung, level_akses)
VALUES
('Rizki', 'rizki123', 'pass123', '081234567890', '2023-01-15', 'Kasir'),
('Nuel', 'nuel456', 'pass456', '089876543210', '2023-02-20', 'Kasir');

INSERT INTO Jadwal (film_id, studio_id, tanggal, waktu_mulai, waktu_selesai, harga_tiket, kapasitas_tersisa)
VALUES
(1, 1, '2025-09-25', '14:00:00', '17:00:00', 60000.00, 100),
(2, 2, '2025-09-25', '16:30:00', '18:30:00', 40000.00, 80),
(3, 3, '2025-09-26', '19:00:00', '21:30:00', 55000.00, 120);

INSERT INTO Tiket (jadwal_id, kasir_id, kode_tiket, nomor_kursi, harga, tanggal_pembelian, status_tiket)
VALUES
(1, 1, 'TKT001', 'A1', 60000.00, '2025-09-20 14:00:00', 'Aktif'),
(1, 2, 'TKT002', 'A2', 60000.00, '2025-09-20 14:05:00', 'Aktif');

INSERT INTO Pembayaran (tiket_id, jumlah_pembayaran, metode_pembayaran, tanggal_pembayaran, status_pembayaran)
VALUES
(1, 60000.00, 'Tunai', '2025-09-20 14:30:00', 'Lunas'),
(2, 60000.00, 'QRIS', '2025-09-20 14:35:00', 'Lunas');

INSERT INTO Payment_Gateway (nama_gateway, api_key, status_gateway)
VALUES
('Midtrans', 'APIKEY123', 'Aktif'),
('Xendit', 'APIKEY456', 'Aktif');

INSERT INTO Transaksi_Pembayaran (pembayaran_id, gateway_id, reference_number, waktu_transaksi, status_transaksi)
VALUES
(2, 1, 'REF123456', '2025-09-20 14:35:00', 'Berhasil');
