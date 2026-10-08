# 📦 Sistem Inventaris Enterprise

**Status**: ✅ Production Ready | **Version**: 3.0.0 | **Quality**: ⭐⭐⭐⭐⭐

## 📚 DOKUMENTASI

**Semua dokumentasi telah dipindahkan ke folder `docs/`**

### ⭐ Mulai dari sini:
- **[docs/QUICK_START.md](docs/QUICK_START.md)** - Setup dalam 5 menit
- **[docs/DOKUMENTASI_ENTERPRISE.md](docs/DOKUMENTASI_ENTERPRISE.md)** - Panduan lengkap sistem
- **[docs/DOKUMENTASI_INDEX.md](docs/DOKUMENTASI_INDEX.md)** - Peta dokumentasi

### 📖 Dokumentasi Lengkap:
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Referensi teknis & data flow
- [docs/MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) - Panduan refactoring views (Phase 4)
- [docs/CHANGELOG.md](docs/CHANGELOG.md) - Riwayat versi
- [docs/PHASE_3_SUMMARY.md](docs/PHASE_3_SUMMARY.md) - Laporan Phase 3

---

## Struktur Project
```
src/
├── Main.java
├── model/         Barang, User, Peminjaman, LogBarang
├── view/          LoginView, RegisterView, BarangView,
│                  PeminjamanView, RiwayatPinjamView,
│                  UserManagementView, LogBarangView
├── controller/    AuthController, BarangController,
│                  PeminjamanController, UserController,
│                  LogBarangController
├── util/          DatabaseUtil, SessionManager, LogService
└── component/     BackgroundPanel, RoundedButton, RoundedPanel,
                   RoundedTextField, RoundedPasswordField
lib/
  └── mysql-connector-j-*.jar   ← taruh di sini
```

## Prasyarat
- Java JDK 11+
- MySQL 5.7+ / MariaDB 10.3+
- mysql-connector-j-9.x.jar (taruh di `lib/`)

## Setup Database

```sql
-- ── Database LOGIN ──────────────────────────────────────
CREATE DATABASE IF NOT EXISTS login CHARACTER SET utf8mb4;
USE login;

CREATE TABLE users (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50)          NOT NULL UNIQUE,
    password VARCHAR(255)         NOT NULL,
    role     ENUM('admin','user') NOT NULL DEFAULT 'user',
    status   VARCHAR(10)          NOT NULL DEFAULT 'pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Akun admin awal
INSERT INTO users (username, password, role, status)
VALUES ('admin', 'admin123', 'admin', 'approved');

-- ── Database INVENTARIS ─────────────────────────────────
CREATE DATABASE IF NOT EXISTS sisteminventaris CHARACTER SET utf8mb4;
USE sisteminventaris;

CREATE TABLE barang (
    kode_barang VARCHAR(20)  PRIMARY KEY,
    nama_barang VARCHAR(100) NOT NULL,
    harga       INT          NOT NULL DEFAULT 0,
    stok        INT          NOT NULL DEFAULT 0,
    keterangan  TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel berikut dibuat OTOMATIS oleh aplikasi:
-- log_aktivitas, log_barang, peminjaman
```

## Konfigurasi
Edit `src/util/DatabaseUtil.java`:
```java
private static final String HOST    = "localhost";
private static final String PORT    = "3306";
private static final String DB_USER = "root";
private static final String DB_PASS = "";     // ← isi password MySQL Anda
```

## Menjalankan

**Linux/Mac:**
```bash
mkdir -p out
find src -name "*.java" | xargs javac -cp "lib/*" -d out
java -cp "out:lib/*" Main
```

**Windows (CMD):**
```cmd
mkdir out
for /R src %f in (*.java) do javac -cp "lib\*" -d out "%f"
java -cp "out;lib\*" Main
```

## Fitur

| Fitur | Admin | User |
|---|---|---|
| Lihat daftar barang | ✅ | ✅ |
| CRUD barang | ✅ | ❌ |
| Ajukan peminjaman | ❌ | ✅ |
| Proses peminjaman (setujui/tolak) | ✅ | ❌ |
| Kelola akun pending | ✅ | ❌ |
| Log riwayat barang masuk/keluar | ✅ | ❌ |
| Lihat riwayat pinjam sendiri | ❌ | ✅ |
| Peringatan tenggat waktu | ✅ (admin) | ✅ (user) |
