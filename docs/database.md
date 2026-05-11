# TBCare — Dokumentasi Database

**Collaborative Monitoring System untuk Pasien Tuberkulosis (TBC)**
Versi Schema: v3

---

## 1. Gambaran Umum

TBCare adalah platform mobile berbasis Flutter yang menghubungkan pasien Tuberkulosis (TBC) dengan Pengawas Menelan Obat (PMO) secara real-time. Database dirancang menggunakan PostgreSQL dengan mempertimbangkan keamanan data medis, efisiensi query, dan skalabilitas sistem pengawasan multipasien.

### Tipe Data Khusus (ENUM)

Database mendefinisikan enam tipe ENUM untuk menjaga konsistensi status data:

| Tipe ENUM            | Nilai                                        | Keterangan                                   |
| -------------------- | -------------------------------------------- | -------------------------------------------- |
| `treatment_status`   | `active`, `completed`, `failed`              | Status periode pengobatan pasien             |
| `supervision_status` | `pending`, `approved`, `rejected`, `revoked` | Status relasi pengawasan pasien–pengawas     |
| `compliance_status`  | `pending`, `taken`, `missed`                 | Status kepatuhan minum obat per jadwal       |
| `escalation_status`  | `triggered`, `resolved`, `ignored`           | Status eskalasi alarm ketidakpatuhan         |
| `symptom_level`      | `normal`, `mild`, `severe`                   | Tingkat keparahan gejala yang dicatat pasien |
| `duration_type`      | `day`, `month`                               | Satuan durasi periode pengobatan             |

---

## 2. Deskripsi Tabel dan Field

### 2.1 Tabel: `users`

Tabel sentral yang menyimpan semua pengguna sistem (pasien, pengawas, dan tenaga kesehatan). Peran setiap pengguna ditentukan melalui relasi ke tabel `user_roles` dan `roles`.

| Nama Field         | Tipe Data    | Constraint       | Deskripsi                                              |
| ------------------ | ------------ | ---------------- | ------------------------------------------------------ |
| `id`               | SERIAL       | PRIMARY KEY      | Identitas unik pengguna (auto-increment)               |
| `name`             | VARCHAR(255) | NOT NULL         | Nama lengkap pengguna                                  |
| `email`            | VARCHAR(255) | NOT NULL, UNIQUE | Email login, harus unik di seluruh sistem              |
| `telephone_number` | VARCHAR(20)  | NULLABLE         | Nomor telepon pengguna                                 |
| `photo_url`        | VARCHAR(500) | NULLABLE         | URL foto profil pengguna                               |
| `password`         | VARCHAR(255) | NOT NULL         | Password ter-hash (bcrypt/Argon2)                      |
| `fcm_token`        | VARCHAR(255) | NULLABLE         | Token Firebase Cloud Messaging untuk push notification |

---

### 2.2 Tabel: `roles`

Mendefinisikan peran yang tersedia dalam sistem: pasien dan pengawas. Peran menentukan hak akses melalui relasi ke `permissions`.

| Nama Field | Tipe Data    | Constraint       | Deskripsi                                                      |
| ---------- | ------------ | ---------------- | -------------------------------------------------------------- |
| `id`       | SERIAL       | PRIMARY KEY      | Identitas unik peran                                           |
| `slug`     | VARCHAR(100) | NOT NULL, UNIQUE | Kode peran dalam format snake_case (mis. `pasien`, `pengawas`) |
| `name`     | VARCHAR(255) | NOT NULL         | Nama tampilan peran                                            |

---

### 2.3 Tabel: `permissions`

Mendefinisikan hak akses granular pada fitur-fitur sistem, seperti `view_patient_history`, `approve_supervision`, `upload_photo_evidence`, dsb.

| Nama Field | Tipe Data    | Constraint       | Deskripsi                                    |
| ---------- | ------------ | ---------------- | -------------------------------------------- |
| `id`       | SERIAL       | PRIMARY KEY      | Identitas unik permission                    |
| `slug`     | VARCHAR(100) | NOT NULL, UNIQUE | Kode permission (mis. `view_compliance_log`) |
| `name`     | VARCHAR(255) | NOT NULL         | Nama tampilan permission                     |

---

### 2.4 Tabel: `user_roles`

Tabel junction yang menghubungkan `users` dengan `roles` (many-to-many). Satu pengguna dapat memiliki lebih dari satu peran sekaligus.

| Nama Field | Tipe Data | Constraint                    | Deskripsi             |
| ---------- | --------- | ----------------------------- | --------------------- |
| `user_id`  | INTEGER   | PK, FK → `users(id)`, CASCADE | Referensi ke pengguna |
| `role_id`  | INTEGER   | PK, FK → `roles(id)`, CASCADE | Referensi ke peran    |

---

### 2.5 Tabel: `role_permissions`

Tabel junction yang memetakan hak akses ke peran (many-to-many). Memungkinkan konfigurasi RBAC (Role-Based Access Control) yang fleksibel.

| Nama Field      | Tipe Data | Constraint                          | Deskripsi               |
| --------------- | --------- | ----------------------------------- | ----------------------- |
| `role_id`       | INTEGER   | PK, FK → `roles(id)`, CASCADE       | Referensi ke peran      |
| `permission_id` | INTEGER   | PK, FK → `permissions(id)`, CASCADE | Referensi ke permission |

---

### 2.6 Tabel: `supervisions`

Merepresentasikan satu grup pengawasan yang dimiliki seorang pengawas. Setiap pengawas dapat memiliki satu grup (`supervision_code` unik) dan memantau banyak pasien melalui tabel `supervisions_patients`.

| Nama Field         | Tipe Data    | Constraint                          | Deskripsi                                                  |
| ------------------ | ------------ | ----------------------------------- | ---------------------------------------------------------- |
| `id`               | SERIAL       | PRIMARY KEY                         | Identitas unik grup pengawasan                             |
| `supervisor_id`    | INTEGER      | NOT NULL, FK → `users(id)`, CASCADE | Referensi ke pengguna berperan pengawas                    |
| `supervision_code` | VARCHAR(100) | UNIQUE, NULLABLE                    | Kode unik yang dibagikan ke pasien untuk bergabung ke grup |

---

### 2.7 Tabel: `supervisions_patients`

Mengelola relasi antara pasien dan grup pengawasan. Satu pasien hanya boleh memiliki satu pengawas aktif pada satu waktu, yang dienforce oleh partial unique index (lihat bagian 3). Alur status: `pending` → `approved` / `rejected`, dan dapat di-`revoke` setelahnya.

| Nama Field       | Tipe Data          | Constraint                                 | Deskripsi                                                |
| ---------------- | ------------------ | ------------------------------------------ | -------------------------------------------------------- |
| `id`             | SERIAL             | PRIMARY KEY                                | Identitas unik relasi                                    |
| `supervision_id` | INTEGER            | NOT NULL, FK → `supervisions(id)`, CASCADE | Referensi ke grup pengawasan                             |
| `patients_id`    | INTEGER            | NOT NULL, FK → `users(id)`, CASCADE        | Referensi ke pengguna berperan pasien                    |
| `status`         | supervision_status | NOT NULL, DEFAULT `pending`                | Status permintaan pengawasan                             |
| `joined_at`      | TIMESTAMP          | NULLABLE                                   | Waktu approval (diisi saat status berubah ke `approved`) |
| `request_at`     | TIMESTAMP          | NOT NULL, DEFAULT NOW()                    | Waktu pengiriman permintaan bergabung                    |

---

### 2.8 Tabel: `treatment_periods`

Mencatat periode pengobatan TB seorang pasien. Satu pasien dapat memiliki beberapa periode (mis. pengobatan ulang jika gagal). Nama periode ditentukan bebas oleh pasien (mis. _"Fase Intensif"_, _"Pengobatan Ulang 2025"_). Jadwal obat dan log gejala terikat pada periode ini.

| Nama Field            | Tipe Data        | Constraint                          | Deskripsi                                                        |
| --------------------- | ---------------- | ----------------------------------- | ---------------------------------------------------------------- |
| `id`                  | SERIAL           | PRIMARY KEY                         | Identitas unik periode pengobatan                                |
| `patients_id`         | INTEGER          | NOT NULL, FK → `users(id)`, CASCADE | Referensi ke pasien                                              |
| `name`                | VARCHAR(255)     | NOT NULL                            | Nama periode pengobatan yang ditentukan pasien                   |
| `start_date`          | DATE             | NOT NULL                            | Tanggal mulai periode pengobatan                                 |
| `actual_end_date`     | DATE             | NULLABLE                            | Tanggal selesai aktual (diisi saat periode benar-benar berakhir) |
| `prediction_end_date` | DATE             | NULLABLE                            | Tanggal prediksi selesai pengobatan                              |
| `duration`            | INTEGER          | NOT NULL                            | Durasi pengobatan dalam satuan `duration_type`                   |
| `duration_type`       | duration_type    | NOT NULL, DEFAULT `month`           | Satuan durasi: `day` atau `month`                                |
| `status`              | treatment_status | NOT NULL, DEFAULT `active`          | Status periode: `active` / `completed` / `failed`                |

---

### 2.9 Tabel: `medication_schedules`

Menyimpan jadwal minum obat per periode pengobatan. Setiap obat membuat satu baris tersendiri — jika pasien meminum tiga obat di jam yang sama, maka terdapat tiga baris dengan `schedule_time` yang sama. Pasien dapat mengkustomisasi waktu alarm sesuai preferensi.

| Nama Field            | Tipe Data    | Constraint                                      | Deskripsi                        |
| --------------------- | ------------ | ----------------------------------------------- | -------------------------------- |
| `id`                  | SERIAL       | PRIMARY KEY                                     | Identitas unik jadwal            |
| `treatment_period_id` | INTEGER      | NOT NULL, FK → `treatment_periods(id)`, CASCADE | Referensi ke periode pengobatan  |
| `med_name`            | VARCHAR(255) | NOT NULL                                        | Nama obat yang dijadwalkan       |
| `schedule_time`       | TIME         | NOT NULL                                        | Waktu minum obat yang ditetapkan |

---

### 2.10 Tabel: `compliance_logs`

Mencatat kepatuhan minum obat per entri jadwal. Pasien mengunggah foto bukti minum obat. Field `med_name` disimpan sebagai snapshot nama obat pada saat log dibuat, sehingga perubahan nama di `medication_schedules` tidak mempengaruhi riwayat. Pengawas memverifikasi foto tersebut. Data ini menjadi dasar compliance heatmap dan penghitungan eskalasi alarm.

| Nama Field    | Tipe Data         | Constraint                                         | Deskripsi                                                |
| ------------- | ----------------- | -------------------------------------------------- | -------------------------------------------------------- |
| `id`          | SERIAL            | PRIMARY KEY                                        | Identitas unik log kepatuhan                             |
| `schedule_id` | INTEGER           | NOT NULL, FK → `medication_schedules(id)`, CASCADE | Referensi ke jadwal minum obat                           |
| `med_name`    | VARCHAR(255)      | NOT NULL                                           | Snapshot nama obat saat log dibuat                       |
| `photo_url`   | VARCHAR(500)      | NULLABLE                                           | URL foto bukti minum obat (dihapus setelah 7 hari)       |
| `taken_at`    | TIMESTAMP         | NULLABLE                                           | Waktu aktual saat pasien minum obat                      |
| `status`      | compliance_status | NOT NULL, DEFAULT `pending`                        | Status kepatuhan: `pending` / `taken` / `missed`         |
| `verified_by` | INTEGER           | FK → `users(id)`, SET NULL                         | Referensi ke pengawas yang memverifikasi foto (nullable) |

---

### 2.11 Tabel: `symptom_logs`

Menyimpan catatan efek samping dan keluhan yang dicatat pasien secara manual. Tingkat keparahan (`level`) dipilih sendiri oleh pasien saat membuat catatan. Data ini dapat dilihat pengawas dan digunakan pasien saat konsultasi dokter.

| Nama Field            | Tipe Data     | Constraint                                      | Deskripsi                                                                  |
| --------------------- | ------------- | ----------------------------------------------- | -------------------------------------------------------------------------- |
| `id`                  | SERIAL        | PRIMARY KEY                                     | Identitas unik log gejala                                                  |
| `treatment_period_id` | INTEGER       | NOT NULL, FK → `treatment_periods(id)`, CASCADE | Referensi ke periode pengobatan                                            |
| `level`               | symptom_level | NOT NULL, DEFAULT `normal`                      | Tingkat keparahan gejala yang dipilih pasien: `normal` / `mild` / `severe` |
| `note`                | TEXT          | NULLABLE                                        | Deskripsi keluhan / efek samping pasien                                    |
| `created_at`          | TIMESTAMP     | NOT NULL, DEFAULT NOW()                         | Waktu pencatatan gejala                                                    |
| `edited_at`           | TIMESTAMP     | NULLABLE                                        | Waktu terakhir catatan diperbarui                                          |

---

### 2.12 Tabel: `escalation_logs`

Mencatat eskalasi alarm yang dipicu saat pasien melewati batas waktu konfirmasi minum obat. Sistem memicu eskalasi otomatis ketika `compliance_logs.status` berubah menjadi `missed`. Pengawas menerima push notification dan menangani eskalasi melalui dashboard.

| Nama Field          | Tipe Data         | Constraint                                    | Deskripsi                                             |
| ------------------- | ----------------- | --------------------------------------------- | ----------------------------------------------------- |
| `id`                | SERIAL            | PRIMARY KEY                                   | Identitas unik eskalasi                               |
| `compliance_log_id` | INTEGER           | NOT NULL, FK → `compliance_logs(id)`, CASCADE | Referensi ke log kepatuhan yang memicu eskalasi       |
| `status`            | escalation_status | NOT NULL, DEFAULT `triggered`                 | Status eskalasi: `triggered` / `resolved` / `ignored` |
| `action_note`       | TEXT              | NULLABLE                                      | Catatan tindakan yang diambil pengawas                |
| `handled_by`        | INTEGER           | FK → `users(id)`, SET NULL                    | Referensi ke pengawas yang menangani (nullable)       |
| `created_at`        | TIMESTAMP         | NOT NULL, DEFAULT NOW()                       | Waktu eskalasi dipicu otomatis                        |
| `resolved_at`       | TIMESTAMP         | NULLABLE                                      | Waktu eskalasi diselesaikan                           |

---

## 3. Constraints Khusus

### 3.1 Satu Pasien, Satu Pengawas Aktif

Aturan bisnis menetapkan bahwa satu pasien hanya boleh memiliki **satu pengawas aktif** pada satu waktu. Constraint ini dienforce di level database menggunakan **partial unique index**:

```sql
CREATE UNIQUE INDEX uidx_sp_one_active_supervisor_per_patient
    ON supervisions_patients (patients_id)
    WHERE status = 'approved';
```

**Mengapa partial index, bukan UNIQUE biasa?**
Karena constraint hanya perlu berlaku untuk baris dengan `status = 'approved'`. Dengan partial index, satu pasien tetap boleh menyimpan banyak riwayat `pending`, `rejected`, atau `revoked` — namun database akan menolak di level query jika ada upaya insert atau update yang menghasilkan dua baris `approved` untuk `patients_id` yang sama.

---

## 4. Pemetaan Fitur ke Tabel Database

| Fitur                         | Role     | Tabel Utama                                                                        | Keterangan Singkat                                                                       |
| ----------------------------- | -------- | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Smart Alarm & Konfirmasi Foto | Pasien   | `medication_schedules`, `compliance_logs`                                          | Jadwal obat memicu alarm; pasien upload foto → `compliance_logs.status = taken`          |
| Compliance Heatmap            | Pasien   | `compliance_logs`, `medication_schedules`, `treatment_periods`                     | Agregasi status per hari untuk visualisasi kalender                                      |
| History Minum Obat            | Pasien   | `compliance_logs`, `medication_schedules`                                          | Daftar detail kepatuhan per jadwal per hari                                              |
| Catatan Efek Samping          | Pasien   | `symptom_logs`, `treatment_periods`                                                | CRUD catatan gejala medis dengan level keparahan, terikat periode pengobatan             |
| Dashboard Progress Pasien     | Pasien   | `treatment_periods`, `compliance_logs`, `medication_schedules`                     | Persentase kepatuhan dan status periode pengobatan aktif                                 |
| Kustomisasi Jadwal Alarm      | Pasien   | `medication_schedules`                                                             | Update `schedule_time` sesuai preferensi pasien                                          |
| Mengatur Periode Pengobatan   | Pasien   | `treatment_periods`                                                                | CRUD periode pengobatan beserta nama, durasi, dan tanggal prediksi selesai               |
| Masukkan Kode Pengawas        | Pasien   | `supervisions`, `supervisions_patients`                                            | Pasien mencari supervision via kode → insert `supervisions_patients` (pending)           |
| Approve Permintaan Pengawasan | Pengawas | `supervisions_patients`                                                            | Pengawas update status → `approved` / `rejected`; `joined_at` diisi saat approved        |
| Eskalasi Alarm                | Pengawas | `escalation_logs`, `compliance_logs`, `users` (fcm_token)                          | Sistem insert `escalation_logs` ketika `compliance_logs.status` berubah menjadi `missed` |
| Melihat History Pasien        | Pengawas | `compliance_logs`, `symptom_logs`, `medication_schedules`, `supervisions_patients` | Query data pasien dalam grup yang sama (`supervision_id` sama)                           |
| Dashboard Pengawasan          | Pengawas | `supervisions_patients`, `compliance_logs`, `escalation_logs`, `treatment_periods` | Priority sorting berdasar frekuensi missed dose dan eskalasi aktif                       |
| Verifikasi Foto Bukti         | Pengawas | `compliance_logs`                                                                  | Update `verified_by` dan `status` setelah pengawas memvalidasi foto                      |

---

## 5. Alur Data Fitur Utama

### 5.1 Alur Konfirmasi Minum Obat (Evidence-Based Adherence)

1. **Jadwal dibuat** — `medication_schedules` diisi dengan `treatment_period_id`, `med_name`, `schedule_time`.
2. **Alarm berbunyi** — Aplikasi membaca `schedule_time` dari `medication_schedules` dan memicu alarm lokal di perangkat pasien.
3. **Pasien upload foto** — `compliance_logs` dibuat: `schedule_id` diisi, `med_name` di-snapshot dari jadwal, `photo_url` diisi, `taken_at = NOW()`, `status = pending`.
4. **Pengawas verifikasi** — Pengawas membaca `compliance_logs` (status = `pending`). Setelah validasi foto, update: `status = taken`, `verified_by = id pengawas`.
5. **Batas waktu terlewat** — Jika pasien tidak memberikan konfirmasi hingga batas waktu, sistem mengubah `compliance_logs.status = missed`, yang kemudian memicu alur eskalasi (lihat 5.3).

---

### 5.2 Alur Bergabung ke Grup Pengawasan

1. **Pengawas buat grup** — Insert ke `supervisions`; sistem generate `supervision_code` unik.
2. **Pasien masukkan kode** — Pasien input kode → query `supervisions WHERE supervision_code = kode`. Jika ditemukan, insert `supervisions_patients` (`status = pending`, `request_at = NOW()`).
3. **Pengawas review** — Pengawas baca `supervisions_patients WHERE status = pending`. Update `status = approved` → set `joined_at = NOW()`. Atau `status = rejected`. Jika pasien sudah memiliki pengawas aktif, database menolak insert `approved` melalui partial unique index.
4. **Revoke (opsional)** — Pengawas dapat update `status = revoked` kapan saja untuk mengeluarkan pasien dari pengawasan.

---

### 5.3 Alur Eskalasi Alarm (Smart Alarm & Escalation System)

Eskalasi dipicu secara otomatis ketika status `compliance_logs` berubah menjadi `missed`.

1. **Status berubah ke missed** — Sistem atau scheduler mengubah `compliance_logs.status = missed` pada entri yang melewati batas waktu konfirmasi tanpa upload foto.
2. **Eskalasi dibuat** — Sistem INSERT ke `escalation_logs`: `compliance_log_id` diisi, `status = triggered`, `created_at = NOW()`. Field `handled_by` dan `resolved_at` masih NULL.
3. **Push notification dikirim** — Sistem membaca `users.fcm_token` milik pengawas yang bertanggung jawab (melalui `supervisions_patients` → `supervisions` → `supervisor_id` → `users.fcm_token`), lalu mengirim push notification via Firebase Cloud Messaging (FCM).
4. **Pengawas menangani eskalasi** — Pengawas membuka dashboard eskalasi, mengisi `action_note`, kemudian update `escalation_logs`: `handled_by = id pengawas`, `status = resolved`, `resolved_at = NOW()`. Atau jika tidak ada tindakan, `status = ignored`.
5. **Riwayat tersimpan** — Seluruh data eskalasi (kapan dipicu, siapa yang menangani, kapan diselesaikan, catatan tindakan) tersimpan permanen di `escalation_logs` dan dapat diakses pengawas melalui fitur melihat history pasien.

---

_Dokumen ini dibuat berdasarkan skema `tbcare_database_schema_v3.sql` dan spesifikasi fitur TBCare._
