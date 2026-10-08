-- ================================================================
-- QUICK FIX: Jalankan script ini di MySQL untuk setup database
-- ================================================================
-- Copy semua dan paste di MySQL Workbench atau phpMyAdmin
-- ================================================================

-- Pastikan sudah login dengan user yang punya privilege untuk CREATE DATABASE

-- 1. Create databases
CREATE DATABASE IF NOT EXISTS sisteminventaris CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS login CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. Setup login database
USE login;

CREATE TABLE IF NOT EXISTS users (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role     VARCHAR(20)  NOT NULL DEFAULT 'user',
    status   VARCHAR(20)  NOT NULL DEFAULT 'pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS password_reset_requests (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(100) NOT NULL,
    email           VARCHAR(100),
    token           VARCHAR(255) UNIQUE NOT NULL,
    reason          TEXT,
    status          VARCHAR(20)  DEFAULT 'pending',
    approved_by     VARCHAR(100),
    approved_at     DATETIME,
    rejected_at     DATETIME,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Insert default admin user
INSERT IGNORE INTO users (username, password, role, status)
VALUES ('admin', 'admin123', 'admin', 'active');

-- 4. Setup sisteminventaris database
USE sisteminventaris;

-- Barang table
CREATE TABLE IF NOT EXISTS barang (
    kode_barang VARCHAR(50)  NOT NULL PRIMARY KEY,
    nama_barang VARCHAR(150) NOT NULL,
    harga       INT          NOT NULL DEFAULT 0,
    stok        INT          NOT NULL DEFAULT 0,
    keterangan  TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Peminjaman table
DROP TABLE IF EXISTS peminjaman;
CREATE TABLE peminjaman (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(100) NOT NULL,
    kode_barang     VARCHAR(50)  NOT NULL,
    nama_barang     VARCHAR(150),
    jumlah          INT          NOT NULL DEFAULT 1,
    tanggal_pinjam  DATE         NOT NULL,
    tanggal_kembali DATE         NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'pending',
    status_return   VARCHAR(20)  DEFAULT 'belum_dikembalikan',
    tanggal_kembali_aktual DATE,
    keterangan_admin VARCHAR(255),
    diterima_oleh   VARCHAR(100),
    tanggal_diterima DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Return items table (BARU - yang sebelumnya missing)
DROP TABLE IF EXISTS return_items;
CREATE TABLE return_items (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    peminjaman_id   INT          NOT NULL,
    username        VARCHAR(100) NOT NULL,
    kode_barang     VARCHAR(50)  NOT NULL,
    nama_barang     VARCHAR(150),
    jumlah_dikembalikan INT       NOT NULL,
    tanggal_return  DATE         NOT NULL,
    kondisi_barang  VARCHAR(50)  DEFAULT 'baik',
    keterangan      TEXT,
    status          VARCHAR(20)  DEFAULT 'pending',
    disetujui_oleh  VARCHAR(100),
    tanggal_disetujui DATETIME,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (peminjaman_id) REFERENCES peminjaman(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Log aktivitas table
DROP TABLE IF EXISTS log_aktivitas;
CREATE TABLE log_aktivitas (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    username  VARCHAR(100),
    role      VARCHAR(20),
    aksi      VARCHAR(50),
    detail    TEXT,
    waktu     DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- DONE
SELECT 'Setup berhasil! Semua tabel sudah dibuat.' AS Status;
