import express from 'express';
import dotenv from 'dotenv';
import pool from '../config/db.js';

// Import Controllers
import * as kasirController from './Controllers/kasirController.js';
import * as  filmController from './Controllers/filmController.js';
import * as jadwalController from './Controllers/jadwalController.js';
import * as tiketController from './Controllers/tiketController.js';
import * as pembayaranController from './Controllers/pembayaranController.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS Middleware (optional, untuk frontend)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'API Sistem Pemesanan Tiket Bioskop',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      films: '/api/films',
      jadwal: '/api/jadwal',
      tiket: '/api/tiket',
      pembayaran: '/api/pembayaran'
    }
  });
});

// ============================================
// AUTHENTICATION ROUTES (Kasir & Admin)
// ============================================
app.post('/api/auth/login', kasirController.login);
app.get('/api/kasir', kasirController.getAllKasir);
app.get('/api/kasir/:kasir_id/riwayat', kasirController.getRiwayatTransaksi);
app.get('/api/riwayat', kasirController.getRiwayatTransaksi);

// ============================================
// FILM ROUTES
// ============================================
// GET - Semua film
app.get('/api/films', filmController.getAllFilm);

// GET - Film by ID
app.get('/api/films/:id', filmController.getFilmById);

// GET - Statistik film (Admin)
app.get('/api/films/statistik/all', filmController.getStatistikFilm);

// GET - Top 5 film terlaris
app.get('/api/films/top/terlaris', filmController.getTop5FilmTerlaris);

// POST - Tambah film baru (Admin)
app.post('/api/films', filmController.createFilm);

// PUT - Update film (Admin)
app.put('/api/films/:id', filmController.updateFilm);

// DELETE - Hapus film (Admin)
app.delete('/api/films/:id', filmController.deleteFilm);

// ============================================
// JADWAL ROUTES
// ============================================
// GET - Semua jadwal
app.get('/api/jadwal', jadwalController.getAllJadwal);

// GET - Jadwal by ID
app.get('/api/jadwal/:id', jadwalController.getJadwalById);

// GET - Jadwal tayang (untuk user/kasir lihat)
app.get('/api/jadwal/tayang/list', jadwalController.getJadwalTayang);

// GET - Daftar kursi tersedia
app.get('/api/jadwal/kursi/tersedia', jadwalController.getDaftarKursiTersedia);

// GET - Kursi yang sudah terisi untuk jadwal tertentu
app.get('/api/jadwal/:jadwal_id/kursi/terisi', jadwalController.getKursiTerisi);

// POST - Tambah jadwal baru (Admin)
app.post('/api/jadwal', jadwalController.createJadwal);

// GET - Semua studio
app.get('/api/studio', jadwalController.getAllStudio);

// ============================================
// TIKET ROUTES
// ============================================
// GET - Semua tiket
app.get('/api/tiket', tiketController.getAllTiket);

// GET - Tiket by kode (menggunakan procedure)
app.get('/api/tiket/kode/:kode_tiket', tiketController.getTiketByKode);

// GET - Detail tiket (menggunakan view)
app.get('/api/tiket/detail/:kode_tiket', tiketController.getDetailTiket);

// GET - Tiket by kasir
app.get('/api/tiket/kasir/:kasir_id', tiketController.getTiketByKasir);

// POST - Buat tiket baru (Kasir)
app.post('/api/tiket', tiketController.createTiket);

// PUT - Batalkan tiket (Kasir)
app.put('/api/tiket/:kode_tiket/batal', tiketController.batalkanTiket);

// DELETE - Hapus tiket batal (Admin maintenance)
app.delete('/api/tiket/batal/hapus', tiketController.hapusTiketBatal);

// ============================================
// PEMBAYARAN & LAPORAN ROUTES
// ============================================
// GET - Dashboard admin
app.get('/api/dashboard/admin', pembayaranController.getDashboardAdmin);

// GET - Laporan penjualan (menggunakan procedure)
app.get('/api/laporan/penjualan', pembayaranController.getLaporanPenjualan);

// GET - Laporan penjualan (menggunakan view)
app.get('/api/laporan/penjualan/view', pembayaranController.getLaporanPenjualanView);

// GET - Semua pembayaran
app.get('/api/pembayaran', pembayaranController.getAllPembayaran);

// GET - Pembayaran by ID
app.get('/api/pembayaran/:id', pembayaranController.getPembayaranById);

// GET - Pembayaran by metode
app.get('/api/pembayaran/metode/:metode', pembayaranController.getPembayaranByMetode);

// GET - Statistik pembayaran per metode
app.get('/api/pembayaran/statistik/metode', pembayaranController.getStatistikPembayaran);

// ============================================
// ERROR HANDLING
// ============================================
// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint tidak ditemukan'
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Global error:', err);
  res.status(500).json({
    success: false,
    message: 'Terjadi kesalahan pada server',
    error: err.message
  });
});

// ============================================
// START SERVER
// ============================================
app.listen(PORT, async () => {
  try {
    // Test database connection
    const connection = await pool.getConnection();
    console.log('✅ Database connected successfully');
    connection.release();
    
    console.log(`Server berjalan di http://localhost:${PORT}`);
    console.log('Dokumentasi API:');
    console.log('   - Auth:       http://localhost:' + PORT + '/api/auth/login');
    console.log('   - Films:      http://localhost:' + PORT + '/api/films');
    console.log('   - Jadwal:     http://localhost:' + PORT + '/api/jadwal');
    console.log('   - Tiket:      http://localhost:' + PORT + '/api/tiket');
    console.log('   - Pembayaran: http://localhost:' + PORT + '/api/pembayaran');
    console.log('   - Dashboard:  http://localhost:' + PORT + '/api/dashboard/admin');
  } catch (error) {
    console.error('Database connection failed:', error.message);
    process.exit(1);
  }
});

export default app;
