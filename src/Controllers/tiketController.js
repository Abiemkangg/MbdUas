import pool from '../../config/db.js';

// Get semua tiket
export const getAllTiket = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT t.*, f.judul_film, j.tanggal, j.waktu_mulai, s.nama_studio, k.nama AS nama_kasir
       FROM Tiket t
       JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
       JOIN Film f ON j.film_id = f.film_id
       JOIN Studio s ON j.studio_id = s.studio_id
       JOIN Kasir k ON t.kasir_id = k.kasir_id
       ORDER BY t.tanggal_pembelian DESC`
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get all tiket:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Buat tiket baru - menggunakan stored procedure BuatTiket
export const createTiket = async (req, res) => {
  try {
    const {
      jadwal_id,
      kasir_id,
      nomor_kursi,
      metode_pembayaran
    } = req.body;

    // Validasi input
    if (!jadwal_id || !kasir_id || !nomor_kursi || !metode_pembayaran) {
      return res.status(400).json({
        success: false,
        message: 'Semua field harus diisi'
      });
    }

    const [results] = await pool.query(
      'CALL BuatTiket(?, ?, ?, ?)',
      [jadwal_id, kasir_id, nomor_kursi, metode_pembayaran]
    );

    const newTiket = results[0][0];

    return res.status(201).json({
      success: true,
      message: 'Tiket berhasil dibuat',
      data: newTiket
    });
  } catch (error) {
    console.error('Error create tiket:', error);
    
    // Handle specific error messages
    if (error.message.includes('Kursi sudah terisi')) {
      return res.status(409).json({
        success: false,
        message: 'Kursi sudah terisi atau tidak tersedia'
      });
    }
    
    if (error.message.includes('Kapasitas studio sudah penuh')) {
      return res.status(409).json({
        success: false,
        message: 'Kapasitas studio sudah penuh'
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Gagal membuat tiket',
      error: error.message
    });
  }
};

// Batalkan tiket - menggunakan stored procedure BatalkanTiket
export const batalkanTiket = async (req, res) => {
  try {
    const { kode_tiket } = req.params;
    const { kasir_id } = req.body;

    if (!kasir_id) {
      return res.status(400).json({
        success: false,
        message: 'kasir_id harus diisi'
      });
    }

    await pool.query('CALL BatalkanTiket(?, ?)', [kode_tiket, kasir_id]);

    return res.status(200).json({
      success: true,
      message: 'Tiket berhasil dibatalkan'
    });
  } catch (error) {
    console.error('Error batalkan tiket:', error);
    return res.status(500).json({
      success: false,
      message: 'Gagal membatalkan tiket',
      error: error.message
    });
  }
};

// Tampilkan tiket berdasarkan kode - menggunakan stored procedure TampilkanTiket
export const getTiketByKode = async (req, res) => {
  try {
    const { kode_tiket } = req.params;

    const [results] = await pool.query('CALL TampilkanTiket(?)', [kode_tiket]);

    const tiket = results[0][0];

    if (!tiket) {
      return res.status(404).json({
        success: false,
        message: 'Tiket tidak ditemukan'
      });
    }

    return res.status(200).json({
      success: true,
      data: tiket
    });
  } catch (error) {
    console.error('Error get tiket by kode:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Tampilkan detail tiket menggunakan view DetailTiket
export const getDetailTiket = async (req, res) => {
  try {
    const { kode_tiket } = req.params;

    const [rows] = await pool.query(
      'SELECT * FROM DetailTiket WHERE kode_tiket = ?',
      [kode_tiket]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tiket tidak ditemukan'
      });
    }

    return res.status(200).json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Error get detail tiket:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Hapus tiket batal (maintenance admin) - menggunakan stored procedure HapusTiketBatal
export const hapusTiketBatal = async (req, res) => {
  try {
    const { admin_id } = req.body;

    if (!admin_id) {
      return res.status(400).json({
        success: false,
        message: 'admin_id harus diisi'
      });
    }

    const [results] = await pool.query('CALL HapusTiketBatal(?)', [admin_id]);

    const result = results[0][0];

    return res.status(200).json({
      success: true,
      message: `${result.total_dihapus} tiket batal berhasil dihapus`,
      data: result
    });
  } catch (error) {
    console.error('Error hapus tiket batal:', error);
    return res.status(500).json({
      success: false,
      message: 'Gagal menghapus tiket batal',
      error: error.message
    });
  }
};

// Get tiket berdasarkan kasir_id
export const getTiketByKasir = async (req, res) => {
  try {
    const { kasir_id } = req.params;

    const [rows] = await pool.query(
      `SELECT t.*, f.judul_film, j.tanggal, j.waktu_mulai, s.nama_studio
       FROM Tiket t
       JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
       JOIN Film f ON j.film_id = f.film_id
       JOIN Studio s ON j.studio_id = s.studio_id
       WHERE t.kasir_id = ?
       ORDER BY t.tanggal_pembelian DESC`,
      [kasir_id]
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get tiket by kasir:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};
