import express from 'express';
import dotenv from 'dotenv';
import pool from '../config/db.js';
dotenv.config();

const app = express();
app.use(express.json());

app.get('/', (request, response) => {
  return response.json({
    message: "Hello World",
    subject: "Manajemen Basis Data",
  }); 
});

// app.post('/login');
// app.post('/register');

app.post('/api/transaksi', async (req, res) => {
  const { id_pelanggan, id_pengguna, metode_pembayaran, diskon, pajak } = req.body;

  try {
    const [result] = await pool.query(
      'CALL sp_buat_transaksi(?, ?, ?, ?, ?)',
      [id_pelanggan, id_pengguna, metode_pembayaran, diskon, pajak]
    );

    const rows = result[0];
    const data = rows[0];

    return res.status(201).json({
      message: "Transaksi berhasil diproses",
      data: data,
    });
  } catch (error) {
    console.error("Error processing transaction:", error);
    return res.status(500).json({
      error: "Internal Server Error"
    });
  }
});

app.get('/api/products/', async (req, res) => {
  try {
    const [result] = await pool.query('SELECT * FROM v_produk_lengkap');
    return res.status(200).json({
      message: "Products retrieved successfully",
      data: result,
    });
  } catch (error) {
    console.error("Error fetching products:", error);
    return res.status(500).json({
      error: "Internal Server Error"
    });
  }
})

app.delete('/api/transaksi/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const [result] = await pool.query('CALL sp_batal_transaksi(?)', [id]);

    return res.status(200).json({
      message: "Transaction deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting transaction:", error);
    return res.status(500).json({
      error: "Internal Server Error"
    });
  }
});

app.put('/api/film/:id', async (req, res) => {
  const { id } = req.params;
  const { judul_film, genre, durasi, sutradara, sinopsis, rating, tanggal_rilis, status_film } = req.body;

  try {
    const [result] = await pool.query(
      `UPDATE Film 
       SET judul_film = ?, genre = ?, durasi = ?, sutradara = ?, 
           sinopsis = ?, rating = ?, tanggal_rilis = ?, status_film = ?
       WHERE film_id = ?`,
      [judul_film, genre, durasi, sutradara, sinopsis, rating, tanggal_rilis, status_film, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Film tidak ditemukan!' });
    }

    res.status(200).json({
      message: '🎬 Data film berhasil diperbarui!',
      updated_film_id: id,
    });
  } catch (error) {
    console.error('Error mengupdate film:', error);
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/film/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const [result] = await pool.query('DELETE FROM Film WHERE film_id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Film tidak ditemukan atau sudah dihapus.' });
    }

    res.status(200).json({
      message: 'Film berhasil dihapus!',
      deleted_film_id: id,
    });
  } catch (error) {
    console.error('Error menghapus film:', error);
    res.status(500).json({ error: error.message });
  }
});



const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log("Server is running on http://localhost:" + PORT);
});