import pool from '../../config/db.js';

// Get semua film
export const getAllFilm = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM Film ORDER BY tanggal_rilis DESC'
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get all film:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get film by ID
export const getFilmById = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(
      'SELECT * FROM Film WHERE film_id = ?',
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Film tidak ditemukan'
      });
    }

    return res.status(200).json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Error get film by id:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get statistik film - menggunakan view StatistikFilm
export const getStatistikFilm = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM StatistikFilm ORDER BY total_pendapatan DESC'
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get statistik film:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Get top 5 film terlaris - menggunakan view
export const getTop5FilmTerlaris = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM Top5FilmTerlaris');

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Error get top 5 film:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
      error: error.message
    });
  }
};

// Tambah film baru - menggunakan stored procedure TambahFilm
export const createFilm = async (req, res) => {
  try {
    const {
      judul_film,
      genre,
      durasi,
      sutradara,
      sinopsis,
      rating,
      tanggal_rilis,
      status_film,
      admin_id
    } = req.body;

    // Validasi input
    if (!judul_film || !genre || !admin_id) {
      return res.status(400).json({
        success: false,
        message: 'Judul film, genre, dan admin_id harus diisi'
      });
    }

    const [results] = await pool.query(
      'CALL TambahFilm(?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        judul_film,
        genre,
        durasi,
        sutradara,
        sinopsis,
        rating,
        tanggal_rilis,
        status_film || 'Tayang',
        admin_id
      ]
    );

    const newFilm = results[0][0];

    return res.status(201).json({
      success: true,
      message: 'Film berhasil ditambahkan',
      data: newFilm
    });
  } catch (error) {
    console.error('Error create film:', error);
    return res.status(500).json({
      success: false,
      message: 'Gagal menambahkan film',
      error: error.message
    });
  }
};

// Update film - menggunakan stored procedure UpdateFilm
export const updateFilm = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      judul_film,
      genre,
      durasi,
      sutradara,
      sinopsis,
      rating,
      tanggal_rilis,
      status_film,
      admin_id
    } = req.body;

    // Validasi input
    if (!admin_id) {
      return res.status(400).json({
        success: false,
        message: 'admin_id harus diisi'
      });
    }

    await pool.query(
      'CALL UpdateFilm(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        id,
        judul_film,
        genre,
        durasi,
        sutradara,
        sinopsis,
        rating,
        tanggal_rilis,
        status_film,
        admin_id
      ]
    );

    return res.status(200).json({
      success: true,
      message: 'Film berhasil diupdate'
    });
  } catch (error) {
    console.error('Error update film:', error);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengupdate film',
      error: error.message
    });
  }
};

// Delete film - menggunakan stored procedure HapusFilm
export const deleteFilm = async (req, res) => {
  try {
    const { id } = req.params;
    const { admin_id } = req.body;

    if (!admin_id) {
      return res.status(400).json({
        success: false,
        message: 'admin_id harus diisi'
      });
    }

    await pool.query('CALL HapusFilm(?, ?)', [id, admin_id]);

    return res.status(200).json({
      success: true,
      message: 'Film berhasil dihapus'
    });
  } catch (error) {
    console.error('Error delete film:', error);
    return res.status(500).json({
      success: false,
      message: 'Gagal menghapus film. Pastikan tidak ada jadwal aktif yang terkait',
      error: error.message
    });
  }
};
