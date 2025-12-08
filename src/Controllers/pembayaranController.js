import pool from '../../config/db.js';

// Get laporan penjualan - menggunakan stored procedure LaporanPenjualan
export const getLaporanPenjualan = async (req, res) => {
  try {
    const { tanggal_mulai, tanggal_akhir } = req.query;

    // Validasi input
    if (!tanggal_mulai || !tanggal_akhir) {
      return res.status(400).json({
        success: false,
        message: 'tanggal_mulai dan tanggal_akhir harus diisi'
      });
    }

    const [results] = await pool.query(
      'CALL LaporanPenjualan(?, ?)',
      [tanggal_mulai, tanggal_akhir]
    );

    return res.status(200).json({
      success: true,
      data: results[0]
    });
  } catch (error) {
    console.error('Error get laporan penjualan:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get laporan penjualan dari view
export const getLaporanPenjualanView = async (req, res) => {
  try {
    const { tanggal_mulai, tanggal_akhir } = req.query;

    let query = 'SELECT * FROM LaporanPenjualan';
    let params = [];

    if (tanggal_mulai && tanggal_akhir) {
      query += ' WHERE tanggal BETWEEN ? AND ?';
      params.push(tanggal_mulai, tanggal_akhir);
    }

    query += ' ORDER BY tanggal DESC';

    const [rows] = await pool.query(query, params);

    // Hitung total keseluruhan
    const totalPendapatan = rows.reduce((sum, row) => sum + parseFloat(row.total_pendapatan || 0), 0);
    const totalTiket = rows.reduce((sum, row) => sum + parseInt(row.jumlah_tiket_terjual || 0), 0);

    return res.status(200).json({
      success: true,
      data: rows,
      summary: {
        total_pendapatan: totalPendapatan,
        total_tiket_terjual: totalTiket
      }
    });
  } catch (error) {
    console.error('Error get laporan penjualan view:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get dashboard admin - menggunakan view DashboardAdmin
export const getDashboardAdmin = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM DashboardAdmin');

    return res.status(200).json({
      success: true,
      data: rows[0] || {}
    });
  } catch (error) {
    console.error('Error get dashboard admin:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get semua pembayaran
export const getAllPembayaran = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT p.*, t.kode_tiket, t.nomor_kursi, k.nama AS nama_kasir
       FROM Pembayaran p
       JOIN Tiket t ON p.tiket_id = t.tiket_id
       JOIN Kasir k ON t.kasir_id = k.kasir_id
       ORDER BY p.tanggal_pembayaran DESC`
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get all pembayaran:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get pembayaran by ID
export const getPembayaranById = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(
      `SELECT p.*, t.kode_tiket, t.nomor_kursi, t.jadwal_id, 
              k.nama AS nama_kasir, f.judul_film, j.tanggal, s.nama_studio
       FROM Pembayaran p
       JOIN Tiket t ON p.tiket_id = t.tiket_id
       JOIN Kasir k ON t.kasir_id = k.kasir_id
       JOIN Jadwal j ON t.jadwal_id = j.jadwal_id
       JOIN Film f ON j.film_id = f.film_id
       JOIN Studio s ON j.studio_id = s.studio_id
       WHERE p.pembayaran_id = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pembayaran tidak ditemukan'
      });
    }

    return res.status(200).json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Error get pembayaran by id:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get pembayaran berdasarkan metode pembayaran
export const getPembayaranByMetode = async (req, res) => {
  try {
    const { metode } = req.params;

    const [rows] = await pool.query(
      `SELECT p.*, t.kode_tiket, t.nomor_kursi, k.nama AS nama_kasir
       FROM Pembayaran p
       JOIN Tiket t ON p.tiket_id = t.tiket_id
       JOIN Kasir k ON t.kasir_id = k.kasir_id
       WHERE p.metode_pembayaran = ?
       ORDER BY p.tanggal_pembayaran DESC`,
      [metode]
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get pembayaran by metode:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get statistik pembayaran per metode
export const getStatistikPembayaran = async (req, res) => {
  try {
    const { tanggal_mulai, tanggal_akhir } = req.query;

    let query = `
      SELECT 
        metode_pembayaran,
        COUNT(*) AS total_transaksi,
        SUM(jumlah_pembayaran) AS total_nominal,
        AVG(jumlah_pembayaran) AS rata_rata_nominal
      FROM Pembayaran
      WHERE status_pembayaran = 'Lunas'
    `;
    let params = [];

    if (tanggal_mulai && tanggal_akhir) {
      query += ' AND DATE(tanggal_pembayaran) BETWEEN ? AND ?';
      params.push(tanggal_mulai, tanggal_akhir);
    }

    query += ' GROUP BY metode_pembayaran ORDER BY total_nominal DESC';

    const [rows] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get statistik pembayaran:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};
