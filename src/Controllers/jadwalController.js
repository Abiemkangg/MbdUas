import pool from '../../config/db.js';

// Get semua jadwal
export const getAllJadwal = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT j.*, f.judul_film, f.genre, f.durasi, f.rating, s.nama_studio
       FROM Jadwal j
       JOIN Film f ON j.film_id = f.film_id
       JOIN Studio s ON j.studio_id = s.studio_id
       ORDER BY j.tanggal, j.waktu_mulai`
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get all jadwal:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get jadwal tayang (untuk user) - menggunakan view JadwalTayang
export const getJadwalTayang = async (req, res) => {
  try {
    const { tanggal } = req.query;

    let query = 'SELECT * FROM JadwalTayang';
    let params = [];

    if (tanggal) {
      query += ' WHERE tanggal = ?';
      params.push(tanggal);
    }

    query += ' ORDER BY tanggal, waktu_mulai';

    const [rows] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get jadwal tayang:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get daftar kursi tersedia - menggunakan view DaftarKursiTersedia
export const getDaftarKursiTersedia = async (req, res) => {
  try {
    const { jadwal_id } = req.query;

    let query = 'SELECT * FROM DaftarKursiTersedia';
    let params = [];

    if (jadwal_id) {
      query += ' WHERE jadwal_id = ?';
      params.push(jadwal_id);
    }

    const [rows] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get daftar kursi tersedia:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get kursi yang sudah terisi untuk jadwal tertentu
export const getKursiTerisi = async (req, res) => {
  try {
    const { jadwal_id } = req.params;

    const [rows] = await pool.query(
      `SELECT nomor_kursi, status_tiket 
       FROM Tiket 
       WHERE jadwal_id = ? AND status_tiket = 'Aktif'
       ORDER BY nomor_kursi`,
      [jadwal_id]
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get kursi terisi:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Tambah jadwal baru - menggunakan stored procedure TambahJadwal
export const createJadwal = async (req, res) => {
  try {
    const {
      film_id,
      studio_id,
      tanggal,
      waktu_mulai,
      waktu_selesai,
      harga_tiket,
      admin_id
    } = req.body;

    // Validasi input
    if (!film_id || !studio_id || !tanggal || !waktu_mulai || !waktu_selesai || !harga_tiket || !admin_id) {
      return res.status(400).json({
        success: false,
        message: 'Semua field harus diisi'
      });
    }

    const [results] = await pool.query(
      'CALL TambahJadwal(?, ?, ?, ?, ?, ?, ?)',
      [film_id, studio_id, tanggal, waktu_mulai, waktu_selesai, harga_tiket, admin_id]
    );

    const newJadwal = results[0][0];

    return res.status(201).json({
      success: true,
      message: 'Jadwal berhasil ditambahkan',
      data: newJadwal
    });
  } catch (error) {
    console.error('Error create jadwal:', error);
    
    // Handle specific error messages from stored procedure
    if (error.message.includes('bentrok')) {
      return res.status(409).json({
        success: false,
        message: 'Jadwal bentrok dengan jadwal lain di studio yang sama'
      });
    }
    
    if (error.message.includes('tidak dalam status tayang')) {
      return res.status(400).json({
        success: false,
        message: 'Film tidak dalam status tayang'
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Gagal menambahkan jadwal',
      error: error.message
    });
  }
};

// Get jadwal by ID
export const getJadwalById = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(
      `SELECT j.*, f.judul_film, f.genre, f.durasi, f.rating, s.nama_studio, s.kapasitas
       FROM Jadwal j
       JOIN Film f ON j.film_id = f.film_id
       JOIN Studio s ON j.studio_id = s.studio_id
       WHERE j.jadwal_id = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Jadwal tidak ditemukan'
      });
    }

    return res.status(200).json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Error get jadwal by id:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get semua studio
export const getAllStudio = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM Studio ORDER BY nama_studio');

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get all studio:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};
