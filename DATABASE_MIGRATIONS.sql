# 🗄️ DATABASE SCHEMA UPDATES

**File**: `SETUP_DATABASE_v4.0.sql`  
**Version**: 4.0.0  
**Compatibility**: MySQL 5.7+, MariaDB 10.3+

---



```sql
-- Run this in your MySQL client or import as SQL file
-- Make sure you're on the correct database:
USE inventaris;

-- Then execute the scripts below
```

---

## 📋 MIGRATION 1: Enhance Peminjaman Table

```sql
-- Add extended status tracking
ALTER TABLE peminjaman ADD COLUMN status_extended 
    VARCHAR(50) DEFAULT 'dipinjam' 
    COMMENT 'dipinjam, dikembalikan_sebagian, selesai'
    AFTER status;

-- Add timestamps
ALTER TABLE peminjaman ADD COLUMN created_at 
    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    AFTER keterangan_admin;

ALTER TABLE peminjaman ADD COLUMN updated_at 
    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    AFTER created_at;

-- Add index untuk faster queries
CREATE INDEX idx_peminjaman_status ON peminjaman(status);
CREATE INDEX idx_peminjaman_username ON peminjaman(username);
CREATE INDEX idx_peminjaman_tanggal ON peminjaman(tanggal_pinjam);
```

---

## 📋 MIGRATION 2: Create Return History Table

```sql
-- Detailed return tracking untuk analytics dan audit
CREATE TABLE IF NOT EXISTS return_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    return_item_id INT NOT NULL,
    peminjaman_id INT NOT NULL,
    kode_barang VARCHAR(50) NOT NULL,
    nama_barang VARCHAR(150) NOT NULL,
    username VARCHAR(100) NOT NULL COMMENT 'User yang mengembalikan',
    jumlah_dikembalikan INT NOT NULL,
    kondisi_barang VARCHAR(50) NOT NULL 
        COMMENT 'baik, rusak ringan, rusak berat, hilang',
    keterangan TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'recorded'
        COMMENT 'recorded, approved, adjusted',
    approved_by VARCHAR(100) COMMENT 'Admin yang approve',
    stok_adjustment INT COMMENT 'Berapa stok yang di-add kembali',
    damage_reported INT DEFAULT 0 COMMENT '1 if barang rusak/hilang',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (return_item_id) REFERENCES return_items(id) ON DELETE CASCADE,
    FOREIGN KEY (peminjaman_id) REFERENCES peminjaman(id) ON DELETE CASCADE,
    
    KEY idx_history_barang (kode_barang),
    KEY idx_history_user (username),
    KEY idx_history_created (created_at),
    KEY idx_history_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Detailed log of all item returns for audit trail';
```

---

## 📋 MIGRATION 3: Create Return Items Enhanced Table

```sql
-- Update existing return_items table dengan kolom tambahan
ALTER TABLE return_items ADD COLUMN status_detail 
    VARCHAR(50) DEFAULT 'pending'
    COMMENT 'pending, approved, rejected, adjusted'
    AFTER status;

ALTER TABLE return_items ADD COLUMN return_date_actual 
    DATE
    COMMENT 'Tanggal actual pengembalian (bisa berbeda dari request)'
    AFTER tanggal_return;

ALTER TABLE return_items ADD COLUMN quantity_returned_actual 
    INT
    COMMENT 'Jumlah actual yang dikembalikan'
    AFTER jumlah_dikembalikan;

-- Add index
CREATE INDEX idx_return_items_status ON return_items(status);
CREATE INDEX idx_return_items_peminjaman ON return_items(peminjaman_id);
```

---

## 📋 MIGRATION 4: Create System Config Table

```sql
-- Store system preferences, settings, theme
CREATE TABLE IF NOT EXISTS system_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    config_type VARCHAR(20) COMMENT 'string, int, boolean, json',
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    KEY idx_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default values
INSERT INTO system_config (config_key, config_value, config_type, description) VALUES
('app.theme', 'light', 'string', 'Application theme: light or dark'),
('app.language', 'id', 'string', 'Application language'),
('borrow.max_duration_days', '30', 'int', 'Maximum borrow duration in days'),
('borrow.max_items_per_user', '5', 'int', 'Max items a user can borrow'),
('return.low_stock_threshold', '5', 'int', 'Alert threshold for low stock'),
('app.timezone', 'Asia/Jakarta', 'string', 'Application timezone'),
('features.enable_dark_mode', 'true', 'boolean', 'Enable dark mode feature'),
('features.enable_export', 'true', 'boolean', 'Enable export to PDF/Excel'),
('features.enable_notifications', 'true', 'boolean', 'Enable toast notifications')
ON DUPLICATE KEY UPDATE config_value=VALUES(config_value);
```

---

## 📋 MIGRATION 5: Enhance User Table for Role Management

```sql
-- Add role column untuk access control
ALTER TABLE user ADD COLUMN role 
    VARCHAR(20) DEFAULT 'USER'
    COMMENT 'ADMIN, STAFF, USER, VIEWER'
    AFTER password;

ALTER TABLE user ADD COLUMN is_active 
    BOOLEAN DEFAULT TRUE
    AFTER role;

ALTER TABLE user ADD COLUMN last_login 
    TIMESTAMP NULL
    AFTER is_active;

-- Update role untuk existing users
UPDATE user SET role = 'ADMIN' WHERE username = 'admin';
UPDATE user SET role = 'USER' WHERE role IS NULL;

-- Add index untuk faster role-based queries
CREATE INDEX idx_user_role ON user(role);
CREATE INDEX idx_user_is_active ON user(is_active);
```

---

## 📋 MIGRATION 6: Create Notification Log Table

```sql
-- Track all notifications sent untuk audit
CREATE TABLE IF NOT EXISTS notification_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    type VARCHAR(50) COMMENT 'overdue, low_stock, return_approved, etc',
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'unread' COMMENT 'unread, read, archived',
    reference_type VARCHAR(50) COMMENT 'peminjaman, return_item, barang, etc',
    reference_id INT COMMENT 'ID dari reference_type',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    
    KEY idx_notifications_user (username),
    KEY idx_notifications_status (status),
    KEY idx_notifications_type (type),
    KEY idx_notifications_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Notification history for user activity tracking';
```

---

## 📋 MIGRATION 7: Create Activity Log Table

```sql
-- Comprehensive activity tracking untuk audit trail
CREATE TABLE IF NOT EXISTS activity_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL 
        COMMENT 'TAMBAH_BARANG, AJUKAN_PINJAM, APPROVE_RETURN, etc',
    resource_type VARCHAR(50) COMMENT 'barang, peminjaman, user, etc',
    resource_id INT,
    details JSON COMMENT 'Additional context as JSON',
    ip_address VARCHAR(50),
    user_agent VARCHAR(255),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    KEY idx_activity_user (username),
    KEY idx_activity_action (action),
    KEY idx_activity_created (created_at),
    KEY idx_activity_resource (resource_type, resource_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Complete audit trail of all user actions';
```

---

## 📊 MIGRATION SUMMARY

| Table | Changes | Purpose |
|-------|---------|---------|
| `peminjaman` | + status_extended, timestamps, indexes | Better tracking of borrow lifecycle |
| `return_items` | + status_detail, actual fields | More accurate return tracking |
| **return_history** (NEW) | Full tracking table | Audit trail & analytics |
| **system_config** (NEW) | Settings table | App configuration & preferences |
| `user` | + role, is_active, last_login | Role-based access control |
| **notification_log** (NEW) | Notification history | User notification audit |
| **activity_log** (NEW) | Activity tracking | Complete audit trail |

---

## ⚠️ NOTES

### Before Running:
```sql
-- BACKUP DATABASE FIRST!
-- Create backup:
mysqldump -u root -p inventaris > backup_inventaris_$(date +%Y%m%d).sql
```

### Rollback Instructions:
```sql
-- If something goes wrong, you can rollback by:
ALTER TABLE peminjaman DROP COLUMN status_extended;
ALTER TABLE peminjaman DROP COLUMN created_at;
ALTER TABLE peminjaman DROP COLUMN updated_at;
DROP TABLE IF EXISTS return_history;
DROP TABLE IF EXISTS system_config;
-- ... etc
```

### Verification:
```sql
-- Verify all changes applied correctly
DESCRIBE peminjaman;           -- Check new columns
DESCRIBE return_items;         -- Check new columns
SHOW TABLES LIKE '%history%';  -- Check new tables
SHOW TABLES LIKE '%config%';   -- Check config table
```

---

## 🔗 FOREIGN KEY RELATIONSHIPS

```
┌─────────┐
│  user   │
│ (users) │
└────┬────┘
     │
     ├──────────────────────┬───────────────────────┐
     │                      │                       │
     ▼                      ▼                       ▼
┌──────────┐    ┌──────────────┐         ┌─────────────────┐
│peminjaman│    │ return_items │         │activity_log     │
│(borrows) │◄───│(return reqs) │         │(audit trail)    │
└────┬─────┘    └──────┬───────┘         └─────────────────┘
     │                  │
     └──────┬───────────┘
            │
            ▼
      ┌──────────────┐
      │return_history│
      │(detailed log)│
      └──────────────┘
            │
            ▼
      ┌──────────┐
      │  barang  │
      │ (items)  │
      └──────────┘
```

---

## 📈 PERFORMANCE CONSIDERATIONS

All indexes should improve query performance:
- Searching by status
- Finding user's transactions  
- Filtering by date ranges
- Role-based access control

Recommended:
```sql
-- Run maintenance after large migrations
ANALYZE TABLE peminjaman;
ANALYZE TABLE return_items;
ANALYZE TABLE return_history;
ANALYZE TABLE barang;
ANALYZE TABLE user;
```

---

**Created**: 2026-05-01  
**Version**: 4.0.0
