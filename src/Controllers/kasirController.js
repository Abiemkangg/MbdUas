import pool from '../../config/db.js';

// Login Kasir/Admin - menggunakan stored procedure LoginUser
export const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username dan password harus diisi'
      });
    }

    const [results] = await pool.query(
      'CALL LoginUser(?, ?)',
      [username, password]
    );

    const user = results[0][0];

    if (user && user.status === 'success') {
      return res.status(200).json({
        success: true,
        message: 'Login berhasil',
        data: {
          kasir_id: user.kasir_id,
          nama: user.nama,
          level_akses: user.level_akses
        }
      });
    } else {
      return res.status(401).json({
        success: false,
        message: user?.message || 'Username atau password salah'
      });
    }
  } catch (error) {
    console.error('Error login:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get semua kasir (untuk admin)
export const getAllKasir = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT kasir_id, nama, username, no_telepon, tanggal_bergabung, level_akses FROM Kasir ORDER BY nama'
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get all kasir:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get riwayat transaksi kasir - menggunakan view RiwayatTransaksiKasir
export const getRiwayatTransaksi = async (req, res) => {
  try {
    const { kasir_id } = req.params;

    let query = 'SELECT * FROM RiwayatTransaksiKasir';
    let params = [];

    if (kasir_id) {
      query += ' WHERE kasir_id = ?';
      params.push(kasir_id);
    }

    query += ' ORDER BY waktu_aksi DESC LIMIT 50';

    const [rows] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get riwayat transaksi:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};
